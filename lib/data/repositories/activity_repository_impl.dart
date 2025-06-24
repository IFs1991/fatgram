import '../../domain/repositories/activity_repository.dart';
import '../../domain/models/activity_model.dart' as model;
import '../../domain/models/weekly_activity_stats.dart';
import '../../domain/entities/activity.dart' as entity;
import '../../domain/entities/health_data.dart';
import '../../domain/services/unified_health_service.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

/// アクティビティリポジトリの実装
class ActivityRepositoryImpl implements ActivityRepository {
  final UnifiedHealthService _unifiedHealthService;
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  final String _currentUserId; // ユーザーIDを管理

  ActivityRepositoryImpl({
    required UnifiedHealthService unifiedHealthService,
    required LocalDataSource localDataSource,
    required RemoteDataSource remoteDataSource,
    String? currentUserId,
  })  : _unifiedHealthService = unifiedHealthService,
        _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _currentUserId = currentUserId ?? 'default_user';

  @override
  Future<List<model.Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // まずローカルデータを確認（高速）
      final localActivities = await _localDataSource.getActivities(
        startDate: startDate,
        endDate: endDate,
        userId: _currentUserId,
      );

      // ローカルデータが存在する場合はそれを返し、バックグラウンドで同期
      if (localActivities.isNotEmpty) {
        // バックグラウンドでリモート同期
        _performBackgroundSync(startDate, endDate);
        return localActivities;
      }

      // ローカルデータがない場合、リモートから取得
      try {
        final remoteActivities = await _remoteDataSource.getActivities(
          startDate: startDate,
          endDate: endDate,
          userId: _currentUserId,
        );

        // リモートデータをローカルに保存
        for (final activity in remoteActivities) {
          await _localDataSource.saveActivity(activity);
        }

        return remoteActivities;
      } catch (remoteError) {
        // リモートが失敗した場合、ヘルスサービスから取得
        final normalizedActivities = await _unifiedHealthService.getActivities(
          startTime: startDate,
          endTime: endDate,
        );

        // NormalizedActivityをActivityに変換
        final activities = normalizedActivities.map((normalized) =>
          _convertNormalizedToActivity(normalized)).toList();

        // ローカルデータベースに保存
        for (final activity in activities) {
          await _localDataSource.saveActivity(activity);
        }

        return activities;
      }
    } catch (e) {
      // 全てのデータソースが失敗した場合、空のリストを返す
      return [];
    }
  }

  @override
  Future<void> saveActivity(model.Activity activity) async {
    try {
      // ローカルに即座に保存（UX優先）
      await _localDataSource.saveActivity(activity);

      // バックグラウンドでリモート同期
      _performActivitySync(activity);
    } catch (e) {
      // ローカル保存が失敗した場合のみエラーとする
      rethrow;
    }
  }

  /// アクティビティをバックグラウンドでリモート同期
  void _performActivitySync(model.Activity activity) {
    Future.microtask(() async {
      try {
        await _remoteDataSource.saveActivity(activity);
        
        // 同期成功時にローカルの同期状態を更新
        await _localDataSource.markActivityAsSynced(activity.id);
      } catch (e) {
        // リモート同期失敗時はローカルに記録（後で再試行）
        print('Background sync failed for activity ${activity.id}: $e');
      }
    });
  }

  @override
  Future<List<model.Activity>> syncActivitiesFromHealthKit() async {
    try {
      // 統合ヘルスサービスから過去7日間のデータを取得
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final normalizedActivities = await _unifiedHealthService.getActivities(
        startTime: startDate,
        endTime: endDate,
      );

      // NormalizedActivityをActivityに変換
      final activities = normalizedActivities.map((normalized) =>
        _convertNormalizedToActivity(normalized)).toList();

      // ローカルに保存
      for (final activity in activities) {
        await _localDataSource.saveActivity(activity);
      }

      return activities;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<WeeklyActivityStats> getWeeklyActivityStats({
    required DateTime weekStartDate,
  }) async {
    try {
      // 週の終了日を計算
      final weekEndDate = weekStartDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      // アクティビティを取得
      final activities = await getActivities(
        startDate: weekStartDate,
        endDate: weekEndDate,
      );

      // 日ごとのデータを計算してWeeklyActivityStatsを作成
      final Map<DateTime, List<model.Activity>> dailyActivities = {};

      // 7日間の空のマップを初期化
      for (int i = 0; i < 7; i++) {
        final date = DateTime(
          weekStartDate.year,
          weekStartDate.month,
          weekStartDate.day,
        ).add(Duration(days: i));

        dailyActivities[date] = [];
      }

      // アクティビティを日ごとに分類
      for (final activity in activities) {
        final activityDate = DateTime(
          activity.timestamp.year,
          activity.timestamp.month,
          activity.timestamp.day,
        );

        dailyActivities[activityDate] ??= [];
        dailyActivities[activityDate]!.add(activity);
      }

      // 日ごとの統計を作成
      final dailyStats = <DailyStats>[];

      dailyActivities.forEach((date, dayActivities) {
        double fatGramsBurned = 0;
        double caloriesBurned = 0;
        int totalDurationInSeconds = 0;

        for (final activity in dayActivities) {
          fatGramsBurned += activity.fatGramsBurned;
          caloriesBurned += activity.caloriesBurned;
          totalDurationInSeconds += activity.durationInSeconds;
        }

        dailyStats.add(DailyStats(
          date: date,
          fatGramsBurned: fatGramsBurned,
          caloriesBurned: caloriesBurned,
          totalDurationInSeconds: totalDurationInSeconds,
          activityCount: dayActivities.length,
        ));
      });

      // 日付でソート
      dailyStats.sort((a, b) => a.date.compareTo(b.date));

      // 週間統計を作成
      return WeeklyActivityStats.fromDailyStats(weekStartDate, dailyStats);
    } catch (e) {
      // エラー時は空のデータを返す
      final emptyDailyStats = List.generate(7, (index) {
        final date = weekStartDate.add(Duration(days: index));
        return DailyStats.empty(date);
      });

      return WeeklyActivityStats.fromDailyStats(weekStartDate, emptyDailyStats);
    }
  }

  /// NormalizedActivityをActivityに変換するヘルパーメソッド
  model.Activity _convertNormalizedToActivity(entity.NormalizedActivity normalized) {
    // ActivityTypeを変換
    model.ActivityType activityType;
    switch (normalized.type) {
      case entity.ActivityType.running:
        activityType = model.ActivityType.running;
        break;
      case entity.ActivityType.walking:
        activityType = model.ActivityType.walking;
        break;
      case entity.ActivityType.cycling:
        activityType = model.ActivityType.cycling;
        break;
      case entity.ActivityType.swimming:
        activityType = model.ActivityType.swimming;
        break;
      case entity.ActivityType.weightTraining:
        activityType = model.ActivityType.workout;
        break;
      default:
        activityType = model.ActivityType.other;
    }

    return model.Activity(
      timestamp: normalized.startTime,
      type: activityType,
      durationInSeconds: normalized.duration.inSeconds,
      caloriesBurned: normalized.calories ?? 0.0,
      distanceInMeters: normalized.distance,
      userId: _currentUserId,
      metadata: normalized.metadata ?? {},
    );
  }

  /// バックグラウンドで未同期データを同期
  void _performBackgroundSync(DateTime startDate, DateTime endDate) {
    Future.microtask(() async {
      try {
        // 未同期のアクティビティを取得
        final unsyncedActivities = await _localDataSource.getUnsyncedActivities(_currentUserId);
        
        // 指定期間内の未同期データのみを同期
        final targetActivities = unsyncedActivities.where((activity) =>
          activity.timestamp.isAfter(startDate) && 
          activity.timestamp.isBefore(endDate)
        ).toList();

        // バッチでリモートに同期
        for (final activity in targetActivities) {
          try {
            await _remoteDataSource.saveActivity(activity);
            await _localDataSource.markActivityAsSynced(activity.id);
          } catch (e) {
            print('Failed to sync activity ${activity.id}: $e');
            // 個別の失敗は続行
          }
        }

        // リモートから最新データを取得して差分更新
        try {
          final remoteActivities = await _remoteDataSource.getActivities(
            startDate: startDate,
            endDate: endDate,
            userId: _currentUserId,
          );

          // ローカルにない新しいアクティビティを保存
          for (final remoteActivity in remoteActivities) {
            // 既存チェック（IDで判定）
            final localActivities = await _localDataSource.getActivities(
              startDate: remoteActivity.timestamp.subtract(const Duration(minutes: 1)),
              endDate: remoteActivity.timestamp.add(const Duration(minutes: 1)),
              userId: _currentUserId,
            );

            final exists = localActivities.any((local) => local.id == remoteActivity.id);
            if (!exists) {
              await _localDataSource.saveActivity(remoteActivity);
            }
          }
        } catch (e) {
          print('Background sync from remote failed: $e');
        }
      } catch (e) {
        print('Background sync error: $e');
      }
    });
  }

  /// 同期状態の確認と修復
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final unsyncedCount = (await _localDataSource.getUnsyncedActivities(_currentUserId)).length;
      
      return {
        'hasUnsyncedData': unsyncedCount > 0,
        'unsyncedCount': unsyncedCount,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'hasUnsyncedData': false,
        'unsyncedCount': 0,
      };
    }
  }

  /// 強制的な完全同期
  Future<void> forceFullSync() async {
    try {
      // 全未同期データを取得
      final unsyncedActivities = await _localDataSource.getUnsyncedActivities(_currentUserId);
      
      // 全データをリモートに同期
      for (final activity in unsyncedActivities) {
        try {
          await _remoteDataSource.saveActivity(activity);
          await _localDataSource.markActivityAsSynced(activity.id);
        } catch (e) {
          print('Failed to sync activity ${activity.id}: $e');
          // エラーは記録するが処理は継続
        }
      }
      
      print('Force sync completed. Synced ${unsyncedActivities.length} activities.');
    } catch (e) {
      print('Force sync failed: $e');
      rethrow;
    }
  }
}