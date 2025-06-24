import 'package:flutter/foundation.dart';
import '../../../domain/services/health_permission_service.dart';

/// Health Connect データソース (Android専用)
class HealthConnectDataSource {
  final dynamic _healthConnect; // 実際の実装では health パッケージを使用
  final HealthPermissionService _permissionService;
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  final Map<String, DateTime> _cacheExpiry = {};
  final Map<String, dynamic> _backgroundSyncConfig = {
    'intervalMinutes': 60,
    'syncOnWifiOnly': false,
    'isEnabled': false,
  };
  DateTime _lastRateLimitCall = DateTime.now();
  static const Duration _rateLimitDelay = Duration(milliseconds: 100);

  HealthConnectDataSource({
    required dynamic healthConnect,
    required HealthPermissionService permissionService,
  })  : _healthConnect = healthConnect,
        _permissionService = permissionService;

  // ===================
  // Android権限の取得
  // ===================

  /// Health Connectが利用可能かチェック
  Future<bool> isHealthConnectAvailable() async {
    try {
      final serviceAvailable = await _permissionService.isHealthConnectAvailable();
      if (!serviceAvailable) {
        return false;
      }

      final healthConnectAvailable = await _healthConnect.isAvailable();

      if (kDebugMode) {
        print('HealthConnectDataSource: Availability check - Service: $serviceAvailable, HC: $healthConnectAvailable');
      }

      return healthConnectAvailable;
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error checking availability: $e');
      }
      return false;
    }
  }

  /// Health Connect権限をリクエスト
  Future<bool> requestPermissions(List<String> permissions) async {
    try {
      await respectRateLimit();

      // PermissionServiceを通じて権限をリクエスト
      final serviceResult = await _permissionService.requestHealthConnectPermissions(permissions);

      if (!serviceResult) {
        return false;
      }

      // Health Connectライブラリを通じて権限をリクエスト
      final healthConnectResult = await _healthConnect.requestPermissions(permissions);

      if (kDebugMode) {
        print('HealthConnectDataSource: Permission request result: $healthConnectResult');
      }

      return healthConnectResult;
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error requesting permissions: $e');
      }
      return false;
    }
  }

  /// 特定権限の認証状態をチェック
  Future<bool> isPermissionGranted(String permission) async {
    try {
      return await _permissionService.isHealthConnectAuthorized(permission);
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error checking permission $permission: $e');
      }
      return false;
    }
  }

  /// 複数権限の状態を取得
  Future<Map<String, bool>> getPermissionStatuses(List<String> permissions) async {
    try {
      final allPermissions = await _permissionService.getAllHealthConnectPermissions();
      final result = <String, bool>{};

      for (final permission in permissions) {
        result[permission] = allPermissions[permission] ?? false;
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error getting permission statuses: $e');
      }
      return {};
    }
  }

  // ===================
  // データタイプのマッピング
  // ===================

  /// ワークアウトタイプをHealth Connect形式にマッピング
  String mapWorkoutType(String workoutType) {
    const workoutTypeMap = {
      'running': 'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_RUNNING',
      'cycling': 'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_BIKING',
      'swimming': 'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL',
      'walking': 'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_WALKING',
      'weightTraining': 'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING',
      'yoga': 'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_YOGA',
      'tennis': 'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_TENNIS',
      'basketball': 'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL',
    };

    return workoutTypeMap[workoutType] ??
           'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT';
  }

  /// データ単位をHealth Connect形式にマッピング
  String mapDataUnit(String dataType) {
    const unitMap = {
      'heartRate': 'beats_per_minute',
      'steps': 'count',
      'calories': 'kilocalories',
      'distance': 'meters',
      'weight': 'kilograms',
      'height': 'meters',
      'duration': 'seconds',
    };

    return unitMap[dataType] ?? 'unknown_unit';
  }

  /// データタイプがサポートされているかチェック
  bool isDataTypeSupported(String dataType) {
    const supportedTypes = {
      'heartRate',
      'steps',
      'calories',
      'distance',
      'workouts',
      'weight',
      'height',
    };

    return supportedTypes.contains(dataType);
  }

  /// Health ConnectデータをFatGram標準形式に変換
  Map<String, dynamic> convertToStandardFormat(Map<String, dynamic> healthConnectData) {
    final standardData = <String, dynamic>{
      'source': 'health_connect',
    };

    // レコードタイプに応じて変換
    if (healthConnectData['recordType'] == 'ExerciseSessionRecord') {
      // ワークアウトデータの変換
      standardData['type'] = _reverseMapWorkoutType(healthConnectData['exerciseType'] ?? '');
      standardData['startTime'] = healthConnectData['startTime'];
      standardData['endTime'] = healthConnectData['endTime'];
      standardData['name'] = healthConnectData['title'] ?? 'Workout';

      // エネルギー消費量の変換
      if (healthConnectData['totalEnergyBurned'] != null) {
        final energyData = healthConnectData['totalEnergyBurned'];
        if (energyData is Map && energyData['value'] != null) {
          standardData['totalEnergyBurned'] = energyData['value'].toDouble();
        }
      }

      // 距離の変換
      if (healthConnectData['totalDistance'] != null) {
        final distanceData = healthConnectData['totalDistance'];
        if (distanceData is Map && distanceData['value'] != null) {
          standardData['totalDistance'] = distanceData['value'].toDouble();
        }
      }
    }

    return standardData;
  }

  /// FatGram標準形式をHealth Connect形式に変換
  Map<String, dynamic> convertFromStandardFormat(Map<String, dynamic> standardData) {
    if (!standardData.containsKey('startTime') || !standardData.containsKey('endTime')) {
      throw ArgumentError('Missing required fields: startTime and endTime');
    }

    final healthConnectData = <String, dynamic>{
      'recordType': 'ExerciseSessionRecord',
      'startTime': standardData['startTime'],
      'endTime': standardData['endTime'],
      'exerciseType': mapWorkoutType(standardData['type'] ?? 'unknown'),
      'title': standardData['title'] ?? standardData['name'] ?? 'Workout',
    };

    // エネルギー消費量の変換
    if (standardData['totalEnergyBurned'] != null) {
      healthConnectData['totalEnergyBurned'] = {
        'value': standardData['totalEnergyBurned'].toDouble(),
        'unit': 'kilocalories',
      };
    }

    // 距離の変換
    if (standardData['distance'] != null) {
      healthConnectData['totalDistance'] = {
        'value': standardData['distance'].toDouble(),
        'unit': 'meters',
      };
    }

    return healthConnectData;
  }

  /// ワークアウトタイプを逆マッピング
  String _reverseMapWorkoutType(String healthConnectType) {
    const reverseMap = {
      'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_RUNNING': 'running',
      'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_BIKING': 'cycling',
      'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL': 'swimming',
      'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_WALKING': 'walking',
      'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING': 'weightTraining',
      'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_YOGA': 'yoga',
      'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_TENNIS': 'tennis',
      'androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_BASKETBALL': 'basketball',
    };

    return reverseMap[healthConnectType] ?? 'unknown';
  }

  // ===================
  // ワークアウトデータ取得
  // ===================

  /// ワークアウトデータを読み取り
  Future<List<Map<String, dynamic>>> readWorkouts({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      await respectRateLimit();

      final rawWorkouts = await _healthConnect.readWorkouts(
        startTime: startTime,
        endTime: endTime,
      );

      if (kDebugMode) {
        print('HealthConnectDataSource: Retrieved ${rawWorkouts.length} workouts');
      }

      // 標準形式に変換
      final standardWorkouts = rawWorkouts.map((workout) =>
        convertToStandardFormat(workout)).toList();

      return standardWorkouts;
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error reading workouts: $e');
      }
      rethrow;
    }
  }

  /// タイプ別ワークアウトを取得
  Future<List<Map<String, dynamic>>> readWorkoutsByType(
    String type, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final allWorkouts = await readWorkouts(
        startTime: startTime,
        endTime: endTime,
      );

      return allWorkouts.where((workout) => workout['type'] == type).toList();
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error reading workouts by type: $e');
      }
      return [];
    }
  }

  /// 総消費カロリーを計算
  Future<double> getTotalCaloriesBurned({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final workouts = await readWorkouts(
        startTime: startTime,
        endTime: endTime,
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
        print('HealthConnectDataSource: Error calculating total calories: $e');
      }
      return 0.0;
    }
  }

  /// リトライ機能付きワークアウト取得
  Future<List<Map<String, dynamic>>> readWorkoutsWithRetry({
    DateTime? startTime,
    DateTime? endTime,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        return await readWorkouts(startTime: startTime, endTime: endTime);
      } catch (e) {
        attempts++;
        if (attempts > maxRetries) {
          rethrow;
        }

        if (kDebugMode) {
          print('HealthConnectDataSource: Workout read attempt $attempts failed, retrying...');
        }

        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }

    return [];
  }

  /// フォールバック付きワークアウト取得
  Future<List<Map<String, dynamic>>> readWorkoutsWithFallback({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      return await readWorkouts(startTime: startTime, endTime: endTime);
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Workout read failed, returning fallback: $e');
      }
      return [];
    }
  }

  // ===================
  // 心拍数データ取得
  // ===================

  /// 心拍数データを読み取り
  Future<List<Map<String, dynamic>>> readHeartRateSamples({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      await respectRateLimit();

      final rawHeartRateData = await _healthConnect.readHeartRateSamples(
        startTime: startTime,
        endTime: endTime,
      );

      if (kDebugMode) {
        print('HealthConnectDataSource: Retrieved ${rawHeartRateData.length} heart rate entries');
      }

      return List<Map<String, dynamic>>.from(rawHeartRateData);
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error reading heart rate data: $e');
      }
      rethrow;
    }
  }

  /// 平均心拍数を計算
  Future<double> getAverageHeartRate({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final heartRateData = await readHeartRateSamples(
        startTime: startTime,
        endTime: endTime,
      );

      if (heartRateData.isEmpty) return 0.0;

      double totalHeartRate = 0.0;
      int validEntries = 0;

      for (final entry in heartRateData) {
        if (entry['samples'] is List) {
          final samples = entry['samples'] as List;
          for (final sample in samples) {
            final value = sample['beatsPerMinute'];
            if (value is num && value > 0) {
              totalHeartRate += value.toDouble();
              validEntries++;
            }
          }
        }
      }

      return validEntries > 0 ? totalHeartRate / validEntries : 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error calculating average heart rate: $e');
      }
      return 0.0;
    }
  }

  /// 心拍数異常を検出
  Future<List<Map<String, dynamic>>> detectHeartRateAnomalies({
    DateTime? startTime,
    DateTime? endTime,
    double minNormal = 50,
    double maxNormal = 180,
  }) async {
    try {
      final heartRateData = await readHeartRateSamples(
        startTime: startTime,
        endTime: endTime,
      );

      final anomalies = <Map<String, dynamic>>[];

      for (final entry in heartRateData) {
        if (entry['samples'] is List) {
          final samples = entry['samples'] as List;
          for (final sample in samples) {
            final value = sample['beatsPerMinute'];
            if (value is num) {
              final heartRate = value.toDouble();
              if (heartRate < minNormal || heartRate > maxNormal) {
                anomalies.add(sample);
              }
            }
          }
        }
      }

      if (kDebugMode) {
        print('HealthConnectDataSource: Detected ${anomalies.length} heart rate anomalies');
      }

      return anomalies;
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error detecting heart rate anomalies: $e');
      }
      return [];
    }
  }

  // ===================
  // ステップデータ取得
  // ===================

  /// ステップデータを読み取り
  Future<List<Map<String, dynamic>>> readStepsSamples({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      await respectRateLimit();

      final rawStepsData = await _healthConnect.readStepsSamples(
        startTime: startTime,
        endTime: endTime,
      );

      if (kDebugMode) {
        print('HealthConnectDataSource: Retrieved ${rawStepsData.length} steps entries');
      }

      return List<Map<String, dynamic>>.from(rawStepsData);
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error reading steps data: $e');
      }
      rethrow;
    }
  }

  /// 総歩数を計算
  Future<double> getTotalSteps({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final stepsData = await readStepsSamples(
        startTime: startTime,
        endTime: endTime,
      );

      double totalSteps = 0.0;
      for (final entry in stepsData) {
        final count = entry['count'];
        if (count is num) {
          totalSteps += count.toDouble();
        }
      }

      return totalSteps;
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error calculating total steps: $e');
      }
      return 0.0;
    }
  }

  // ===================
  // バックグラウンド同期
  // ===================

  /// バックグラウンド同期を有効化
  Future<void> enableBackgroundSync() async {
    try {
      await _healthConnect.enableBackgroundSync();
      _backgroundSyncConfig['isEnabled'] = true;

      if (kDebugMode) {
        print('HealthConnectDataSource: Background sync enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error enabling background sync: $e');
      }
      rethrow;
    }
  }

  /// バックグラウンド同期の状態をチェック
  Future<bool> isBackgroundSyncEnabled() async {
    return _backgroundSyncConfig['isEnabled'] ?? false;
  }

  /// バックグラウンド同期を設定
  Future<void> configureBackgroundSync({
    required int intervalMinutes,
    required bool syncOnWifiOnly,
  }) async {
    _backgroundSyncConfig['intervalMinutes'] = intervalMinutes;
    _backgroundSyncConfig['syncOnWifiOnly'] = syncOnWifiOnly;

    if (kDebugMode) {
      print('HealthConnectDataSource: Background sync configured - '
            'Interval: ${intervalMinutes}min, WiFi only: $syncOnWifiOnly');
    }
  }

  /// バックグラウンド同期設定を取得
  Map<String, dynamic> getBackgroundSyncConfig() {
    return Map.from(_backgroundSyncConfig);
  }

  // ===================
  // データ書き込み
  // ===================

  /// ワークアウトデータを書き込み
  Future<void> writeWorkout(Map<String, dynamic> workoutData) async {
    // 必須フィールドの検証
    if (!workoutData.containsKey('startTime') || !workoutData.containsKey('endTime')) {
      throw ArgumentError('Missing required fields: startTime and endTime');
    }

    try {
      await respectRateLimit();

      // 標準形式からHealth Connect形式に変換
      final healthConnectData = convertFromStandardFormat(workoutData);

      await _healthConnect.writeWorkout(healthConnectData);

      if (kDebugMode) {
        print('HealthConnectDataSource: Workout written successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error writing workout: $e');
      }
      rethrow;
    }
  }

  // ===================
  // データ同期とキャッシュ
  // ===================

  /// Health Connectデータをローカルストレージへ同期
  Future<Map<String, dynamic>> syncToLocalStorage({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      int syncedWorkouts = 0;
      int syncedHeartRate = 0;
      int syncedSteps = 0;

      // ワークアウトデータの同期
      try {
        final workouts = await readWorkouts(startTime: startTime, endTime: endTime);
        // TODO: ローカルデータベースに保存
        syncedWorkouts = workouts.length;
      } catch (e) {
        if (kDebugMode) {
          print('HealthConnectDataSource: Error syncing workouts: $e');
        }
      }

      // 心拍数データの同期
      try {
        final heartRateData = await readHeartRateSamples(startTime: startTime, endTime: endTime);
        // TODO: ローカルデータベースに保存
        syncedHeartRate = heartRateData.length;
      } catch (e) {
        if (kDebugMode) {
          print('HealthConnectDataSource: Error syncing heart rate: $e');
        }
      }

      // ステップデータの同期
      try {
        final stepsData = await readStepsSamples(startTime: startTime, endTime: endTime);
        // TODO: ローカルデータベースに保存
        syncedSteps = stepsData.length;
      } catch (e) {
        if (kDebugMode) {
          print('HealthConnectDataSource: Error syncing steps: $e');
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
        print('HealthConnectDataSource: Error syncing to local storage: $e');
      }
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// データをキャッシュ
  Future<void> cacheData(String key, List<Map<String, dynamic>> data) async {
    try {
      _cache[key] = List<Map<String, dynamic>>.from(data);

      if (kDebugMode) {
        print('HealthConnectDataSource: Cached ${data.length} items with key: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error caching data: $e');
      }
    }
  }

  /// 有効期限付きでデータをキャッシュ
  Future<void> cacheDataWithExpiry(
    String key,
    List<Map<String, dynamic>> data, {
    required DateTime expiryTime,
  }) async {
    try {
      _cache[key] = List<Map<String, dynamic>>.from(data);
      _cacheExpiry[key] = expiryTime;

      if (kDebugMode) {
        print('HealthConnectDataSource: Cached ${data.length} items with key: $key (expires: $expiryTime)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error caching data with expiry: $e');
      }
    }
  }

  /// キャッシュされたデータを取得
  Future<List<Map<String, dynamic>>?> getCachedData(String key) async {
    try {
      // 有効期限をチェック
      if (_cacheExpiry.containsKey(key)) {
        final expiryTime = _cacheExpiry[key]!;
        if (DateTime.now().isAfter(expiryTime)) {
          // 期限切れの場合はキャッシュを削除
          _cache.remove(key);
          _cacheExpiry.remove(key);
          return null;
        }
      }

      return _cache[key];
    } catch (e) {
      if (kDebugMode) {
        print('HealthConnectDataSource: Error getting cached data: $e');
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
    _cacheExpiry.clear();
    if (kDebugMode) {
      print('HealthConnectDataSource: Cache cleared');
    }
  }

  /// リソースのクリーンアップ
  void dispose() {
    clearCache();
    if (kDebugMode) {
      print('HealthConnectDataSource: Resources disposed');
    }
  }
}