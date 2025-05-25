import 'package:health/health.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/activity_model.dart';
import '../../domain/models/weekly_activity_stats.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final HealthFactory _health;
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  final String _userId;

  ActivityRepositoryImpl({
    required HealthFactory health,
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
    required String userId,
  })  : _health = health,
        _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _userId = userId;

  @override
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // まずローカルから取得を試みる
      final activities = await _localDataSource.getActivities(
        startDate: startDate,
        endDate: endDate,
        userId: _userId,
      );

      if (activities.isNotEmpty) {
        return activities;
      }

      // ローカルになければリモートから取得
      final remoteActivities = await _remoteDataSource.getActivities(
        startDate: startDate,
        endDate: endDate,
        userId: _userId,
      );

      if (remoteActivities.isNotEmpty) {
        // ローカルに保存
        await _localDataSource.saveActivities(remoteActivities);
      }

      return remoteActivities;
    } catch (e) {
      print('Failed to get activities: $e');
      return [];
    }
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    try {
      await _localDataSource.saveActivity(activity);
      await _remoteDataSource.saveActivity(activity);
    } catch (e) {
      print('Failed to save activity: $e');
    }
  }

  @override
  Future<List<Activity>> syncActivitiesFromHealthKit() async {
    try {
      // 許可をリクエスト
      final types = [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_WALKING_RUNNING,
      ];

      final permissions = await _health.requestAuthorization(types);

      if (!permissions) {
        throw Exception('Health data permissions not granted');
      }

      // 過去1週間のデータを取得
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      // HealthKitからデータを取得
      final healthData = await _health.getHealthDataFromTypes(
        oneWeekAgo,
        now,
        types
      );

      // 取得したデータをアクティビティに変換
      final activities = _convertHealthDataToActivities(healthData);

      // ローカルに保存
      if (activities.isNotEmpty) {
        await _localDataSource.saveActivities(activities);
      }

      return activities;
    } catch (e) {
      print('Failed to sync activities from HealthKit: $e');
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

      // 日ごとのデータを計算
      final Map<DateTime, List<Activity>> dailyActivities = {};

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
      print('Failed to get weekly activity stats: $e');

      // エラー時は空のデータを返す
      final emptyDailyStats = List.generate(7, (index) {
        final date = weekStartDate.add(Duration(days: index));
        return DailyStats.empty(date);
      });

      return WeeklyActivityStats.fromDailyStats(weekStartDate, emptyDailyStats);
    }
  }

  // HealthKitデータをアクティビティに変換するヘルパーメソッド
  List<Activity> _convertHealthDataToActivities(List<HealthDataPoint> healthData) {
    final activities = <Activity>[];
    final workouts = healthData.where((p) => p.type == HealthDataType.WORKOUT);

    for (final workout in workouts) {
      // 運動タイプを決定
      ActivityType activityType;
      switch (workout.workoutActivityType) {
        case HealthWorkoutActivityType.WALKING:
          activityType = ActivityType.walking;
          break;
        case HealthWorkoutActivityType.RUNNING:
          activityType = ActivityType.running;
          break;
        case HealthWorkoutActivityType.BIKING:
          activityType = ActivityType.cycling;
          break;
        case HealthWorkoutActivityType.SWIMMING:
          activityType = ActivityType.swimming;
          break;
        default:
          activityType = ActivityType.other;
      }

      // 期間を計算
      final durationInSeconds = workout.dateTo.difference(workout.dateFrom).inSeconds;

      // カロリーを取得
      final caloriesData = healthData.where((p) =>
        p.type == HealthDataType.ACTIVE_ENERGY_BURNED &&
        p.dateFrom.isAfter(workout.dateFrom) &&
        p.dateTo.isBefore(workout.dateTo)
      );

      double calories = 0;
      if (caloriesData.isNotEmpty) {
        calories = caloriesData
          .map((p) => double.tryParse(p.value.toString()) ?? 0)
          .reduce((a, b) => a + b);
      } else {
        // カロリーデータがない場合は推定
        // 簡易な推定: 体重70kg、MET値を運動タイプに応じて設定
        double met;
        switch (activityType) {
          case ActivityType.walking:
            met = 3.5;
            break;
          case ActivityType.running:
            met = 8.0;
            break;
          case ActivityType.cycling:
            met = 6.0;
            break;
          case ActivityType.swimming:
            met = 6.0;
            break;
          default:
            met = 4.0;
        }

        // カロリー計算: MET * 体重kg * 時間(時)
        final hours = durationInSeconds / 3600;
        calories = met * 70 * hours;
      }

      // アクティビティを作成
      final activity = Activity(
        timestamp: workout.dateFrom,
        type: activityType,
        durationInSeconds: durationInSeconds,
        caloriesBurned: calories,
        userId: _userId,
        metadata: {
          'source': workout.sourceName,
          'sourceId': workout.sourceId,
        },
      );

      activities.add(activity);
    }

    return activities;
  }
}