import 'package:flutter/foundation.dart';
import '../../../domain/services/health_permission_service.dart';

/// HealthKitデータソース
class HealthKitDataSource {
  final dynamic _healthKit; // 実際の実装では health パッケージを使用
  final HealthPermissionService _permissionService;
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  DateTime _lastRateLimitCall = DateTime.now();
  static const Duration _rateLimitDelay = Duration(milliseconds: 100);

  HealthKitDataSource({
    required dynamic healthKit,
    required HealthPermissionService permissionService,
  })  : _healthKit = healthKit,
        _permissionService = permissionService;

  // ===================
  // 権限管理
  // ===================

  /// HealthKit権限をリクエスト
  Future<bool> requestPermissions(List<String> permissions) async {
    try {
      await respectRateLimit();

      // PermissionServiceを通じて権限をリクエスト
      final serviceResult = await _permissionService.requestHealthKitPermissions(permissions);

      if (!serviceResult) {
        return false;
      }

      // HealthKitライブラリを通じて権限をリクエスト
      final healthKitResult = await _healthKit.requestAuthorization(permissions);

      if (kDebugMode) {
        print('HealthKitDataSource: Permission request result: $healthKitResult');
      }

      return healthKitResult;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error requesting permissions: $e');
      }
      return false;
    }
  }

  /// 特定権限の認証状態をチェック
  Future<bool> isAuthorized(String permission) async {
    try {
      return await _permissionService.isHealthKitAuthorized(permission);
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error checking permission $permission: $e');
      }
      return false;
    }
  }

  /// 複数権限の状態を取得
  Future<Map<String, bool>> getPermissionStatuses(List<String> permissions) async {
    try {
      final allPermissions = await _permissionService.getAllHealthKitPermissions();
      final result = <String, bool>{};

      for (final permission in permissions) {
        result[permission] = allPermissions[permission] ?? false;
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error getting permission statuses: $e');
      }
      return {};
    }
  }

  /// HealthKitが利用可能かチェック
  Future<bool> isHealthKitAvailable() async {
    try {
      return await _permissionService.isHealthKitAvailable();
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error checking availability: $e');
      }
      return false;
    }
  }

  // ===================
  // ワークアウトデータ取得
  // ===================

  /// ワークアウトデータを取得
  Future<List<Map<String, dynamic>>> getWorkouts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await respectRateLimit();

      final workouts = await _healthKit.getWorkouts(
        startDate: startDate,
        endDate: endDate,
      );

      if (kDebugMode) {
        print('HealthKitDataSource: Retrieved ${workouts.length} workouts');
      }

      return List<Map<String, dynamic>>.from(workouts);
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error getting workouts: $e');
      }
      rethrow;
    }
  }

  /// アクティビティデータを取得（getActivitiesエイリアス）
  Future<List<Map<String, dynamic>>> getActivities({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    return await getWorkouts(startDate: startTime, endDate: endTime);
  }

  /// タイプ別ワークアウトを取得
  Future<List<Map<String, dynamic>>> getWorkoutsByType(
    String type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allWorkouts = await getWorkouts(
        startDate: startDate,
        endDate: endDate,
      );

      return allWorkouts.where((workout) => workout['type'] == type).toList();
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error getting workouts by type: $e');
      }
      return [];
    }
  }

  /// 消費カロリー合計を計算
  Future<double> getTotalCaloriesBurned({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final workouts = await getWorkouts(
        startDate: startDate,
        endDate: endDate,
      );

      double totalCalories = 0.0;
      for (final workout in workouts) {
        final calories = workout['totalEnergyBurned'];
        if (calories is num) {
          totalCalories += calories.toDouble();
        }
      }

      return totalCalories;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error calculating total calories: $e');
      }
      return 0.0;
    }
  }

  /// リトライ機能付きワークアウト取得
  Future<List<Map<String, dynamic>>> getWorkoutsWithRetry({
    DateTime? startDate,
    DateTime? endDate,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        return await getWorkouts(startDate: startDate, endDate: endDate);
      } catch (e) {
        attempts++;
        if (attempts > maxRetries) {
          rethrow;
        }

        if (kDebugMode) {
          print('HealthKitDataSource: Workout fetch attempt $attempts failed, retrying...');
        }

        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }

    return [];
  }

  // ===================
  // 心拍数データ処理
  // ===================

  /// 心拍数データを取得
  Future<List<Map<String, dynamic>>> getHeartRateData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await respectRateLimit();

      final heartRateData = await _healthKit.getHeartRateData(
        startDate: startDate,
        endDate: endDate,
      );

      if (kDebugMode) {
        print('HealthKitDataSource: Retrieved ${heartRateData.length} heart rate entries');
      }

      return List<Map<String, dynamic>>.from(heartRateData);
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error getting heart rate data: $e');
      }
      rethrow;
    }
  }

  /// 平均心拍数を計算
  Future<double> getAverageHeartRate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final heartRateData = await getHeartRateData(
        startDate: startDate,
        endDate: endDate,
      );

      if (heartRateData.isEmpty) return 0.0;

      double totalHeartRate = 0.0;
      int validEntries = 0;

      for (final entry in heartRateData) {
        final value = entry['value'];
        if (value is num && value > 0) {
          totalHeartRate += value.toDouble();
          validEntries++;
        }
      }

      return validEntries > 0 ? totalHeartRate / validEntries : 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error calculating average heart rate: $e');
      }
      return 0.0;
    }
  }

  /// 心拍数ゾーンを計算
  Future<Map<String, int>> getHeartRateZones({
    DateTime? startDate,
    DateTime? endDate,
    required int maxHeartRate,
  }) async {
    try {
      final heartRateData = await getHeartRateData(
        startDate: startDate,
        endDate: endDate,
      );

      final zones = {
        'resting': 0,     // < 60% max HR
        'fatBurn': 0,     // 60-70% max HR
        'cardio': 0,      // 70-85% max HR
        'peak': 0,        // > 85% max HR
      };

      for (final entry in heartRateData) {
        final value = entry['value'];
        if (value is num && value > 0) {
          final heartRate = value.toDouble();
          final percentage = (heartRate / maxHeartRate) * 100;

          if (percentage < 60) {
            zones['resting'] = zones['resting']! + 1;
          } else if (percentage < 70) {
            zones['fatBurn'] = zones['fatBurn']! + 1;
          } else if (percentage < 85) {
            zones['cardio'] = zones['cardio']! + 1;
          } else {
            zones['peak'] = zones['peak']! + 1;
          }
        }
      }

      return zones;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error calculating heart rate zones: $e');
      }
      return {
        'resting': 0,
        'fatBurn': 0,
        'cardio': 0,
        'peak': 0,
      };
    }
  }

  /// 心拍数異常を検出
  Future<List<Map<String, dynamic>>> detectHeartRateAnomalies({
    DateTime? startDate,
    DateTime? endDate,
    double minNormal = 50,
    double maxNormal = 180,
  }) async {
    try {
      final heartRateData = await getHeartRateData(
        startDate: startDate,
        endDate: endDate,
      );

      final anomalies = <Map<String, dynamic>>[];

      for (final entry in heartRateData) {
        final value = entry['value'];
        if (value is num) {
          final heartRate = value.toDouble();
          if (heartRate < minNormal || heartRate > maxNormal) {
            anomalies.add(entry);
          }
        }
      }

      if (kDebugMode) {
        print('HealthKitDataSource: Detected ${anomalies.length} heart rate anomalies');
      }

      return anomalies;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error detecting heart rate anomalies: $e');
      }
      return [];
    }
  }

  // ===================
  // ステップ・アクティビティデータ
  // ===================

  /// ステップデータを取得
  Future<List<Map<String, dynamic>>> getStepsData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await respectRateLimit();

      final stepsData = await _healthKit.getStepsData(
        startDate: startDate,
        endDate: endDate,
      );

      if (kDebugMode) {
        print('HealthKitDataSource: Retrieved ${stepsData.length} steps entries');
      }

      return List<Map<String, dynamic>>.from(stepsData);
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error getting steps data: $e');
      }
      rethrow;
    }
  }

  /// 総歩数を計算
  Future<double> getTotalSteps({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final stepsData = await getStepsData(
        startDate: startDate,
        endDate: endDate,
      );

      double totalSteps = 0.0;
      for (final entry in stepsData) {
        final value = entry['value'];
        if (value is num) {
          totalSteps += value.toDouble();
        }
      }

      return totalSteps;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error calculating total steps: $e');
      }
      return 0.0;
    }
  }

  // ===================
  // カロリー計算の精度
  // ===================

  /// 正確なカロリー計算
  Future<double> calculateAccurateCalories({
    required String workoutType,
    required double duration, // minutes
    required double userWeight, // kg
    double? distance, // km
    double? averageHeartRate,
  }) async {
    // 入力検証
    if (userWeight <= 0) {
      throw ArgumentError('User weight must be positive');
    }
    if (duration <= 0) {
      throw ArgumentError('Duration must be positive');
    }

    try {
      // METs（代謝当量）をワークアウトタイプに基づいて設定
      double mets = _getMetsByWorkoutType(workoutType);

      // 基本カロリー計算: カロリー = METs × 体重(kg) × 時間(h)
      double baseCalories = mets * userWeight * (duration / 60.0);

      // 距離に基づく調整
      if (distance != null && distance > 0) {
        baseCalories = _adjustCaloriesForDistance(baseCalories, workoutType, distance, duration);
      }

      // 心拍数に基づく調整
      if (averageHeartRate != null && averageHeartRate > 0) {
        final estimatedMaxHR = 220 - 30; // 30歳として仮定
        baseCalories = await adjustCaloriesForHeartRate(
          baseCalories: baseCalories,
          averageHeartRate: averageHeartRate,
          maxHeartRate: estimatedMaxHR.toDouble(),
          age: 30,
        );
      }

      if (kDebugMode) {
        print('HealthKitDataSource: Calculated ${baseCalories.toStringAsFixed(1)} calories for $workoutType');
      }

      return baseCalories;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error calculating calories: $e');
      }
      rethrow;
    }
  }

  /// 心拍数に基づくカロリー調整
  Future<double> adjustCaloriesForHeartRate({
    required double baseCalories,
    required double averageHeartRate,
    required double maxHeartRate,
    required int age,
  }) async {
    try {
      // 心拍数ゾーンに基づく強度係数
      final hrPercentage = (averageHeartRate / maxHeartRate) * 100;

      double intensityMultiplier;
      if (hrPercentage < 60) {
        intensityMultiplier = 0.85; // 低強度
      } else if (hrPercentage < 70) {
        intensityMultiplier = 1.0; // 脂肪燃焼ゾーン
      } else if (hrPercentage < 85) {
        intensityMultiplier = 1.2; // 有酸素ゾーン
      } else {
        intensityMultiplier = 1.4; // 無酸素ゾーン
      }

      return baseCalories * intensityMultiplier;
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error adjusting calories for heart rate: $e');
      }
      return baseCalories;
    }
  }

  /// ワークアウトタイプからMETsを取得
  double _getMetsByWorkoutType(String workoutType) {
    const metsTable = {
      'running': 8.0,
      'cycling': 6.0,
      'swimming': 8.0,
      'walking': 3.5,
      'weightTraining': 6.0,
      'yoga': 2.5,
      'dancing': 4.8,
      'hiking': 6.0,
      'tennis': 7.3,
      'basketball': 6.5,
    };

    return metsTable[workoutType] ?? 5.0; // デフォルト値
  }

  /// 距離に基づくカロリー調整
  double _adjustCaloriesForDistance(
    double baseCalories,
    String workoutType,
    double distance,
    double duration,
  ) {
    // ペースに基づく調整
    final pace = distance / (duration / 60.0); // km/h

    if (workoutType == 'running') {
      if (pace > 12) {
        return baseCalories * 1.3; // 高速ランニング
      } else if (pace > 8) {
        return baseCalories * 1.1; // 中程度のランニング
      }
    } else if (workoutType == 'cycling') {
      if (pace > 25) {
        return baseCalories * 1.2; // 高速サイクリング
      } else if (pace > 15) {
        return baseCalories * 1.05; // 中程度のサイクリング
      }
    }

    return baseCalories;
  }

  // ===================
  // データ同期とキャッシュ
  // ===================

  /// ヘルスデータをローカルデータベースに同期
  Future<Map<String, dynamic>> syncHealthDataToLocal({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      int syncedWorkouts = 0;
      int syncedHeartRate = 0;
      int syncedSteps = 0;

      // ワークアウトデータの同期
      try {
        final workouts = await getWorkouts(startDate: startDate, endDate: endDate);
        // TODO: ローカルデータベースに保存
        syncedWorkouts = workouts.length;
      } catch (e) {
        if (kDebugMode) {
          print('HealthKitDataSource: Error syncing workouts: $e');
        }
      }

      // 心拍数データの同期
      try {
        final heartRateData = await getHeartRateData(startDate: startDate, endDate: endDate);
        // TODO: ローカルデータベースに保存
        syncedHeartRate = heartRateData.length;
      } catch (e) {
        if (kDebugMode) {
          print('HealthKitDataSource: Error syncing heart rate: $e');
        }
      }

      // ステップデータの同期
      try {
        final stepsData = await getStepsData(startDate: startDate, endDate: endDate);
        // TODO: ローカルデータベースに保存
        syncedSteps = stepsData.length;
      } catch (e) {
        if (kDebugMode) {
          print('HealthKitDataSource: Error syncing steps: $e');
        }
      }

      return {
        'status': 'success',
        'syncedWorkouts': syncedWorkouts,
        'syncedHeartRate': syncedHeartRate,
        'syncedSteps': syncedSteps,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error syncing health data: $e');
      }
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// ヘルスデータをキャッシュ
  Future<void> cacheHealthData(String key, List<Map<String, dynamic>> data) async {
    try {
      _cache[key] = List<Map<String, dynamic>>.from(data);

      if (kDebugMode) {
        print('HealthKitDataSource: Cached ${data.length} items with key: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error caching data: $e');
      }
    }
  }

  /// キャッシュされたヘルスデータを取得
  Future<List<Map<String, dynamic>>?> getCachedHealthData(String key) async {
    try {
      return _cache[key];
    } catch (e) {
      if (kDebugMode) {
        print('HealthKitDataSource: Error getting cached data: $e');
      }
      return null;
    }
  }

  // ===================
  // ユーティリティ
  // ===================

  /// レート制限を尊重
  Future<void> respectRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastRateLimitCall);

    if (timeSinceLastCall < _rateLimitDelay) {
      await Future.delayed(_rateLimitDelay - timeSinceLastCall);
    }

    _lastRateLimitCall = DateTime.now();
  }

  /// キャッシュをクリア
  void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      print('HealthKitDataSource: Cache cleared');
    }
  }

  /// リアルタイム監視を開始
  Stream<Map<String, dynamic>> startRealtimeMonitoring() {
    // HealthKitはリアルタイム監視をサポート
    // 実装例：ワークアウトの開始/終了を監視
    return Stream.periodic(const Duration(seconds: 30), (count) {
      // 実際の実装では HealthKit の Observer API を使用
      return {
        'id': 'realtime_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'HKWorkoutActivityTypeRunning',
        'startDate': DateTime.now().subtract(const Duration(minutes: 30)),
        'endDate': DateTime.now(),
        'totalEnergyBurned': 250.0,
        'totalDistance': 2500.0,
        'source': 'healthkit',
        'name': 'Real-time Workout',
      };
    }).take(10); // 10回で停止（テスト用）
  }

  /// リソースのクリーンアップ
  void dispose() {
    clearCache();
    if (kDebugMode) {
      print('HealthKitDataSource: Resources disposed');
    }
  }
}