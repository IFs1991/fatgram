import 'package:health/health.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

/// アクティビティリポジトリの実装
class ActivityRepositoryImpl implements ActivityRepository {
  final HealthFactory _health;
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  final Uuid _uuid;

  ActivityRepositoryImpl({
    required HealthFactory health,
    required RemoteDataSource remoteDataSource,
    required LocalDataSource localDataSource,
  })  : _health = health,
        _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _uuid = const Uuid();

  @override
  Future<void> saveActivities(List<Activity> activities) async {
    await _localDataSource.saveActivities(activities);
  }

  @override
  Future<Map<String, dynamic>> syncActivities() async {
    try {
      // 未同期のアクティビティを取得
      final unsyncedActivities = await _localDataSource.getUnsyncedActivities();

      if (unsyncedActivities.isEmpty) {
        return {'success': true, 'message': 'No activities to sync'};
      }

      // リモートに同期
      final result = await _remoteDataSource.syncActivities(
        activities: unsyncedActivities,
      );

      // 同期したアクティビティを更新
      await _localDataSource.markActivitiesAsSynced(
        unsyncedActivities.map((a) => a.activityId).toList(),
      );

      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  @override
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _localDataSource.getActivities(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      // ローカルから取得できない場合はリモートから取得
      final remoteResult = await _remoteDataSource.getActivities(
        startDate: startDate,
        endDate: endDate,
      );

      final activities = _mapRemoteActivitiesToModel(remoteResult);

      // ローカルに保存
      await _localDataSource.saveActivities(activities);

      return activities;
    }
  }

  @override
  Future<double> getTotalFatBurned({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final activities = await getActivities(
      startDate: startDate,
      endDate: endDate,
    );

    double total = 0.0;
    for (final activity in activities) {
      total += activity.fatBurnedGrams;
    }
    return total;
  }

  @override
  Future<Map<String, dynamic>> getActivityTypeStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final activities = await getActivities(
      startDate: startDate,
      endDate: endDate,
    );

    // アクティビティタイプごとに集計
    final stats = <String, Map<String, dynamic>>{};

    for (final activity in activities) {
      if (!stats.containsKey(activity.activityType)) {
        stats[activity.activityType] = {
          'count': 0,
          'totalCalories': 0.0,
          'totalFatBurnedGrams': 0.0,
          'totalDuration': 0.0,
        };
      }

      final durationInHours = activity.endTime
          .difference(activity.startTime)
          .inSeconds / 3600;

      stats[activity.activityType]!['count'] = stats[activity.activityType]!['count'] + 1;
      stats[activity.activityType]!['totalCalories'] =
          stats[activity.activityType]!['totalCalories'] + activity.caloriesBurned;
      stats[activity.activityType]!['totalFatBurnedGrams'] =
          stats[activity.activityType]!['totalFatBurnedGrams'] + activity.fatBurnedGrams;
      stats[activity.activityType]!['totalDuration'] =
          stats[activity.activityType]!['totalDuration'] + durationInHours;
    }

    return {
      'stats': stats,
      'totalActivities': activities.length,
      'totalCalories': activities.fold(0.0, (sum, a) => sum + a.caloriesBurned),
      'totalFatBurnedGrams': activities.fold(0.0, (sum, a) => sum + a.fatBurnedGrams),
    };
  }

  @override
  Future<Map<String, dynamic>> getWeeklyReport({
    required DateTime date,
  }) async {
    // 週の開始日（月曜日）と終了日（日曜日）を計算
    final dayOfWeek = date.weekday;
    final startOfWeek = date.subtract(Duration(days: dayOfWeek - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    // 日別のデータを取得
    final dailyData = <String, Map<String, dynamic>>{};

    for (int i = 0; i < 7; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final nextDate = currentDate.add(const Duration(days: 1));

      final activities = await getActivities(
        startDate: currentDate,
        endDate: nextDate.subtract(const Duration(seconds: 1)),
      );

      dailyData[currentDate.toIso8601String().split('T')[0]] = {
        'totalActivities': activities.length,
        'totalCalories': activities.fold(0.0, (sum, a) => sum + a.caloriesBurned),
        'totalFatBurnedGrams': activities.fold(0.0, (sum, a) => sum + a.fatBurnedGrams),
        'activityTypes': activities.map((a) => a.activityType).toSet().toList(),
      };
    }

    // 週全体の集計
    final weeklyStats = await getActivityTypeStats(
      startDate: startDate,
      endDate: endDate,
    );

    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'dailyData': dailyData,
      'weeklyStats': weeklyStats,
    };
  }

  @override
  Future<Map<String, dynamic>> getWeeklyActivityStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // アクティビティを取得
      final activities = await getActivities(
        startDate: startDate,
        endDate: endDate,
      );

      if (activities.isEmpty) {
        return {
          'totalActivities': 0,
          'totalCalories': 0.0,
          'totalFatBurned': 0.0,
          'activityTypes': <String>[],
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        };
      }

      // 集計
      double totalCalories = 0.0;
      double totalFatBurned = 0.0;
      final activityTypes = <String>{};

      for (final activity in activities) {
        totalCalories += activity.caloriesBurned;
        totalFatBurned += activity.fatBurnedGrams;
        activityTypes.add(activity.activityType);
      }

      return {
        'totalActivities': activities.length,
        'totalCalories': totalCalories,
        'totalFatBurned': totalFatBurned,
        'activityTypes': activityTypes.toList(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
    } catch (e) {
      print('Error getting weekly activity stats: $e');
      return {
        'totalActivities': 0,
        'totalCalories': 0.0,
        'totalFatBurned': 0.0,
        'activityTypes': <String>[],
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // ヘルスデータから活動データを取得（今後HealthKit/Health Connectと連携）
  Future<List<Activity>> fetchHealthActivities({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final types = [
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.WORKOUT,
    ];

    try {
      // 権限リクエスト
      await _requestHealthPermissions(types);

      // データ取得
      final healthData = await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        types,
      );

      return _processHealthData(healthData, startDate, endDate);
    } catch (e) {
      print('Health data fetch error: $e');
      return [];
    }
  }

  // ヘルスデータのアクセス許可をリクエスト
  Future<void> _requestHealthPermissions(List<HealthDataType> types) async {
    await _health.requestAuthorization(types);
  }

  // ヘルスデータをActivityモデルに変換
  List<Activity> _processHealthData(
    List<HealthDataPoint> healthData,
    DateTime startDate,
    DateTime endDate,
  ) {
    // ワークアウトデータを抽出
    final workouts = healthData
        .where((p) => p.type == HealthDataType.WORKOUT)
        .toList();

    // ワークアウトごとにActivityを作成
    final activities = <Activity>[];

    for (final workout in workouts) {
      final workoutType = workout.sourceId;
      final workoutStart = workout.dateFrom;
      final workoutEnd = workout.dateTo;

      // このワークアウト期間中のデータを抽出
      final workoutData = healthData.where((p) =>
          p.dateFrom.isAfter(workoutStart) &&
          p.dateTo.isBefore(workoutEnd) &&
          p.type != HealthDataType.WORKOUT);

      // カロリー計算
      final caloriesData = workoutData
          .where((p) => p.type == HealthDataType.ACTIVE_ENERGY_BURNED);

      double totalCalories = 0;

      if (caloriesData.isNotEmpty) {
        totalCalories = caloriesData
            .map((p) => double.tryParse(p.value.toString()) ?? 0)
            .reduce((a, b) => a + b);
      }

      // 脂肪燃焼量計算（1gの脂肪 = 約7.2kcal）
      final fatBurnedGrams = totalCalories / 7.2;

      // 心拍数データ
      final heartRateData = workoutData
          .where((p) => p.type == HealthDataType.HEART_RATE)
          .map((p) => HeartRateData(
                timestamp: p.dateFrom,
                value: (double.tryParse(p.value.toString()) ?? 0).round(),
              ))
          .toList();

      // 平均・最大心拍数
      double? heartRateAvg;
      double? heartRateMax;

      if (heartRateData.isNotEmpty) {
        final heartRates = heartRateData.map((d) => d.value).toList();
        heartRateAvg = heartRates.reduce((a, b) => a + b) / heartRates.length;
        heartRateMax = heartRates.reduce((a, b) => a > b ? a : b).toDouble();
      }

      // 歩数
      final stepsData = workoutData
          .where((p) => p.type == HealthDataType.STEPS);

      int? steps;

      if (stepsData.isNotEmpty) {
        steps = stepsData
            .map((p) => int.tryParse(p.value.toString()) ?? 0)
            .reduce((a, b) => a + b);
      }

      // 距離
      final distanceData = workoutData
          .where((p) => p.type == HealthDataType.DISTANCE_WALKING_RUNNING);

      double? distance;

      if (distanceData.isNotEmpty) {
        distance = distanceData
            .map((p) => double.tryParse(p.value.toString()) ?? 0)
            .reduce((a, b) => a + b);
      }

      // Activityモデル作成
      final activity = Activity(
        activityId: _uuid.v4(),
        activityType: _mapWorkoutTypeToActivityType(workoutType),
        startTime: workoutStart,
        endTime: workoutEnd,
        caloriesBurned: totalCalories,
        fatBurnedGrams: fatBurnedGrams,
        heartRateAvg: heartRateAvg,
        heartRateMax: heartRateMax,
        steps: steps,
        distance: distance,
        heartRateData: heartRateData,
      );

      activities.add(activity);
    }

    return activities;
  }

  // ワークアウトタイプをアクティビティタイプにマッピング
  String _mapWorkoutTypeToActivityType(String workoutType) {
    // プラットフォーム固有のワークアウトタイプをアプリ内の標準タイプに変換
    final Map<String, String> typeMapping = {
      'HKWorkoutActivityTypeRunning': 'running',
      'HKWorkoutActivityTypeWalking': 'walking',
      'HKWorkoutActivityTypeCycling': 'cycling',
      'HKWorkoutActivityTypeHiking': 'hiking',
      'HKWorkoutActivityTypeSwimming': 'swimming',
      'com.google.android.gms.fitness.workout_exercise.running': 'running',
      'com.google.android.gms.fitness.workout_exercise.walking': 'walking',
      'com.google.android.gms.fitness.workout_exercise.biking': 'cycling',
      'com.google.android.gms.fitness.workout_exercise.hiking': 'hiking',
      'com.google.android.gms.fitness.workout_exercise.swimming': 'swimming',
    };

    return typeMapping[workoutType] ?? 'other';
  }

  // リモートデータをActivityモデルに変換
  List<Activity> _mapRemoteActivitiesToModel(Map<String, dynamic> remoteResult) {
    final List<dynamic> rawActivities = remoteResult['activities'] ?? [];
    return rawActivities
        .map((data) => Activity.fromJson(data as Map<String, dynamic>))
        .toList();
  }
}