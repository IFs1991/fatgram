import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/health/health_kit_datasource.dart';
import '../../data/datasources/health/health_connect_datasource.dart';
import '../entities/activity.dart';
import '../entities/health_data.dart';
import 'health_permission_service.dart';

/// 統合ヘルスサービス
/// HealthKitとHealth Connectを統一的に扱うためのサービス
class UnifiedHealthService {
  final HealthKitDataSource? _healthKitDataSource;
  final HealthConnectDataSource? _healthConnectDataSource;
  final HealthPermissionService _permissionService;

  // キャッシュとリアルタイム監視
  final Map<String, List<NormalizedActivity>> _cache = {};
  final Map<String, DateTime> _cacheExpiry = {};
  StreamController<NormalizedActivity>? _realtimeController;
  bool _isRealtimeMonitoringActive = false;
  final List<StreamSubscription> _subscriptions = [];

  // エラーコールバック
  Function(String)? onError;

  // コンカレンシー制御
  static const int _maxConcurrentRequests = 5;
  int _currentConcurrentRequests = 0;

  UnifiedHealthService({
    HealthKitDataSource? healthKitDataSource,
    HealthConnectDataSource? healthConnectDataSource,
    required HealthPermissionService permissionService,
  })  : _healthKitDataSource = healthKitDataSource,
        _healthConnectDataSource = healthConnectDataSource,
        _permissionService = permissionService;

  // ===================
  // プラットフォーム判定
  // ===================

  /// 現在のプラットフォームを取得
  HealthPlatform getCurrentPlatform() {
    if (Platform.isIOS) {
      return HealthPlatform.ios;
    } else if (Platform.isAndroid) {
      return HealthPlatform.android;
    } else {
      return HealthPlatform.unknown;
    }
  }

  /// プラットフォーム機能を取得
  Future<HealthPlatformCapabilities> getPlatformCapabilities() async {
    final platform = getCurrentPlatform();

    switch (platform) {
      case HealthPlatform.ios:
        return const HealthPlatformCapabilities(
          supportedDataTypes: [
            HealthDataType.activities,
            HealthDataType.heartRate,
            HealthDataType.steps,
            HealthDataType.calories,
            HealthDataType.distance,
            HealthDataType.sleep,
          ],
          hasBackgroundSync: true,
          hasRealtimeData: true,
          hasWriteCapability: true,
          requiredPermissions: ['workouts', 'heartRate', 'steps'],
          minimumOSVersion: '13.0',
        );
      case HealthPlatform.android:
        return const HealthPlatformCapabilities(
          supportedDataTypes: [
            HealthDataType.activities,
            HealthDataType.heartRate,
            HealthDataType.steps,
            HealthDataType.calories,
            HealthDataType.distance,
          ],
          hasBackgroundSync: true,
          hasRealtimeData: false,
          hasWriteCapability: true,
          requiredPermissions: [
            'android.permission.health.READ_EXERCISE',
            'android.permission.health.READ_HEART_RATE',
            'android.permission.health.READ_STEPS',
          ],
          minimumOSVersion: '8.0',
        );
      default:
        return const HealthPlatformCapabilities(
          supportedDataTypes: [],
          hasBackgroundSync: false,
          hasRealtimeData: false,
          hasWriteCapability: false,
          requiredPermissions: [],
        );
    }
  }

  /// プラットフォーム利用可能性をチェック
  Future<PlatformAvailability> checkPlatformAvailability() async {
    try {
      final isHealthKitAvailable = await _permissionService.isHealthKitAvailable();
      final isHealthConnectAvailable = await _permissionService.isHealthConnectAvailable();

      HealthPlatform recommendedPlatform;
      if (isHealthKitAvailable) {
        recommendedPlatform = HealthPlatform.ios;
      } else if (isHealthConnectAvailable) {
        recommendedPlatform = HealthPlatform.android;
      } else {
        recommendedPlatform = HealthPlatform.unknown;
      }

      return PlatformAvailability(
        isHealthKitAvailable: isHealthKitAvailable,
        isHealthConnectAvailable: isHealthConnectAvailable,
        recommendedPlatform: recommendedPlatform,
      );
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedHealthService: Error checking platform availability: $e');
      }
      onError?.call('Platform availability check failed: $e');

      return PlatformAvailability(
        isHealthKitAvailable: false,
        isHealthConnectAvailable: false,
        recommendedPlatform: HealthPlatform.unknown,
        errorMessage: e.toString(),
      );
    }
  }

  // ===================
  // 権限管理統合
  // ===================

  /// 権限をリクエスト
  Future<PermissionRequestResult> requestPermissions(List<String> permissions) async {
    try {
      final platform = getCurrentPlatform();
      bool success = false;

      switch (platform) {
        case HealthPlatform.ios:
          if (_healthKitDataSource != null) {
            success = await _healthKitDataSource!.requestPermissions(permissions);
          }
          break;
        case HealthPlatform.android:
          if (_healthConnectDataSource != null) {
            success = await _healthConnectDataSource!.requestPermissions(permissions);
          }
          break;
        default:
          success = false;
      }

      return PermissionRequestResult(
        isSuccess: success,
        grantedPermissions: success ? permissions : [],
        deniedPermissions: success ? [] : permissions,
      );
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedHealthService: Error requesting permissions: $e');
      }
      onError?.call('Permission request failed: $e');

      return PermissionRequestResult(
        isSuccess: false,
        grantedPermissions: [],
        deniedPermissions: permissions,
        errorMessage: e.toString(),
      );
    }
  }

  /// 権限状態を取得
  Future<PermissionStatus> getPermissionStatus() async {
    try {
      final platform = getCurrentPlatform();
      Map<String, bool> permissions = {};

      switch (platform) {
        case HealthPlatform.ios:
          permissions = await _permissionService.getAllHealthKitPermissions();
          break;
        case HealthPlatform.android:
          permissions = await _permissionService.getAllHealthConnectPermissions();
          break;
        default:
          permissions = {};
      }

      return PermissionStatus(
        workouts: permissions['workouts'] ?? false,
        heartRate: permissions['heartRate'] ?? false,
        steps: permissions['steps'] ?? false,
        calories: permissions['calories'] ?? false,
        distance: permissions['distance'] ?? false,
        sleep: permissions['sleep'] ?? false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedHealthService: Error getting permission status: $e');
      }
      onError?.call('Getting permission status failed: $e');

      return const PermissionStatus(
        workouts: false,
        heartRate: false,
        steps: false,
        calories: false,
        distance: false,
        sleep: false,
      );
    }
  }

  // ===================
  // データ正規化
  // ===================

  /// アクティビティデータを正規化
  NormalizedActivity normalizeActivityData(Map<String, dynamic> rawData) {
    try {
      final source = _determineDataSource(rawData);

      switch (source) {
        case HealthDataSource.healthKit:
          return _normalizeHealthKitActivity(rawData);
        case HealthDataSource.healthConnect:
          return _normalizeHealthConnectActivity(rawData);
        default:
          throw const DataNormalizationException('Unknown data source');
      }
    } catch (e) {
      throw DataNormalizationException('Failed to normalize activity data: $e');
    }
  }

  /// 心拍数データを正規化
  NormalizedHeartRateData normalizeHeartRateData(Map<String, dynamic> rawData) {
    try {
      final source = _determineDataSource(rawData);
      final samples = <HeartRateSample>[];

      if (rawData['samples'] is List) {
        final rawSamples = rawData['samples'] as List;

        for (final sample in rawSamples) {
          if (sample is Map<String, dynamic>) {
            switch (source) {
              case HealthDataSource.healthKit:
                samples.add(HeartRateSample(
                  value: (sample['value'] as num).toDouble(),
                  timestamp: sample['startDate'] as DateTime,
                ));
                break;
              case HealthDataSource.healthConnect:
                samples.add(HeartRateSample(
                  value: (sample['beatsPerMinute'] as num).toDouble(),
                  timestamp: DateTime.parse(sample['time'] as String),
                ));
                break;
              default:
                break;
            }
          }
        }
      }

      if (samples.isEmpty) {
        throw const DataNormalizationException('No valid heart rate samples found');
      }

      final values = samples.map((s) => s.value).toList();
      final averageHeartRate = values.reduce((a, b) => a + b) / values.length;
      final minHeartRate = values.reduce((a, b) => a < b ? a : b);
      final maxHeartRate = values.reduce((a, b) => a > b ? a : b);

      return NormalizedHeartRateData(
        samples: samples,
        averageHeartRate: averageHeartRate,
        minHeartRate: minHeartRate,
        maxHeartRate: maxHeartRate,
        startTime: samples.first.timestamp,
        endTime: samples.last.timestamp,
        source: source,
      );
    } catch (e) {
      throw DataNormalizationException('Failed to normalize heart rate data: $e');
    }
  }

  /// 距離データを正規化
  NormalizedDistance normalizeDistance(Map<String, dynamic> distanceData) {
    final distance = distanceData['distance'] as double;
    final unit = distanceData['unit'] as String?;

    double meters;
    switch (unit) {
      case 'kilometers':
        meters = distance * 1000;
        break;
      case 'miles':
        meters = distance * 1609.344;
        break;
      case 'feet':
        meters = distance / 3.28084;
        break;
      default:
        meters = distance; // デフォルトはメートル
    }

    return NormalizedDistance(meters: meters);
  }

  // ===================
  // 統合データ取得
  // ===================

  /// アクティビティを取得
  Future<List<NormalizedActivity>> getActivities({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      await _waitForConcurrencySlot();
      _currentConcurrentRequests++;

      final platform = getCurrentPlatform();
      List<Map<String, dynamic>> rawActivities = [];

      switch (platform) {
        case HealthPlatform.ios:
          if (_healthKitDataSource != null) {
            rawActivities = await _healthKitDataSource!.getActivities(
              startTime: startTime,
              endTime: endTime,
            );
          }
          break;
        case HealthPlatform.android:
          if (_healthConnectDataSource != null) {
            rawActivities = await _healthConnectDataSource!.readWorkouts(
              startTime: startTime,
              endTime: endTime,
            );
          }
          break;
        default:
          break;
      }

      final normalizedActivities = rawActivities
          .map((raw) => normalizeActivityData(raw))
          .where((activity) => activity.isValid)
          .toList();

      return normalizedActivities;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedHealthService: Error getting activities: $e');
      }
      onError?.call('Getting activities failed: $e');
      return [];
    } finally {
      _currentConcurrentRequests--;
    }
  }

  /// 心拍数データを取得
  Future<NormalizedHeartRateData> getHeartRateData({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      await _waitForConcurrencySlot();
      _currentConcurrentRequests++;

      final platform = getCurrentPlatform();
      List<Map<String, dynamic>> rawHeartRateData = [];

      switch (platform) {
        case HealthPlatform.ios:
          if (_healthKitDataSource != null) {
            rawHeartRateData = await _healthKitDataSource!.getHeartRateData(
              startDate: startTime,
              endDate: endTime,
            );
          }
          break;
        case HealthPlatform.android:
          if (_healthConnectDataSource != null) {
            rawHeartRateData = await _healthConnectDataSource!.readHeartRateSamples(
              startTime: startTime,
              endTime: endTime,
            );
          }
          break;
        default:
          break;
      }

      if (rawHeartRateData.isNotEmpty) {
        return normalizeHeartRateData(rawHeartRateData.first);
      } else {
        throw Exception('No heart rate data available');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedHealthService: Error getting heart rate data: $e');
      }
      onError?.call('Getting heart rate data failed: $e');
      rethrow;
    } finally {
      _currentConcurrentRequests--;
    }
  }

  /// アクティビティサマリーを取得
  Future<ActivitySummary> getActivitySummary({
    DateTime? startTime,
    DateTime? endTime,
    AggregationPeriod groupBy = AggregationPeriod.weekly,
  }) async {
    try {
      final activities = await getActivities(
        startTime: startTime,
        endTime: endTime,
      );

      final stats = await calculateActivityStatistics(activities);
      final weeklyBreakdown = _calculateWeeklyBreakdown(activities);
      final typeBreakdown = _calculateTypeBreakdown(activities);

      return ActivitySummary(
        totalWorkouts: stats.totalActivities,
        totalCalories: stats.totalCalories,
        totalDistance: stats.totalDistance,
        totalDuration: stats.totalDuration,
        averageWorkoutsPerWeek: stats.averageWorkoutsPerWeek,
        weeklyBreakdown: weeklyBreakdown,
        typeBreakdown: typeBreakdown,
      );
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedHealthService: Error getting activity summary: $e');
      }
      onError?.call('Getting activity summary failed: $e');
      rethrow;
    }
  }

  // ===================
  // リアルタイム更新
  // ===================

  /// リアルタイム監視を開始
  Stream<NormalizedActivity> startRealtimeMonitoring({
    RealtimeFilterCriteria? filterCriteria,
  }) {
    try {
      if (_realtimeController != null) {
        stopRealtimeMonitoring();
      }

      _realtimeController = StreamController<NormalizedActivity>.broadcast();
      _isRealtimeMonitoringActive = true;

      final platform = getCurrentPlatform();

      switch (platform) {
        case HealthPlatform.ios:
          if (_healthKitDataSource != null) {
            final stream = _healthKitDataSource!.startRealtimeMonitoring();
            final subscription = stream.listen(
              (rawActivity) {
                try {
                  final normalizedActivity = normalizeActivityData(rawActivity);
                  if (filterCriteria?.matches(normalizedActivity) ?? true) {
                    _realtimeController?.add(normalizedActivity);
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('UnifiedHealthService: Error processing realtime activity: $e');
                  }
                  onError?.call('Processing realtime activity failed: $e');
                }
              },
              onError: (error) {
                if (kDebugMode) {
                  print('UnifiedHealthService: Realtime monitoring error: $error');
                }
                onError?.call('Realtime monitoring error: $error');
              },
            );
            _subscriptions.add(subscription);
          }
          break;
        case HealthPlatform.android:
          // Health Connectはリアルタイム監視をサポートしていない
          // 代わりに定期的なポーリングを実装
          final timer = Timer.periodic(const Duration(minutes: 5), (_) async {
            try {
              final recentActivities = await getActivities(
                startTime: DateTime.now().subtract(const Duration(minutes: 10)),
                endTime: DateTime.now(),
              );

              for (final activity in recentActivities) {
                if (filterCriteria?.matches(activity) ?? true) {
                  _realtimeController?.add(activity);
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('UnifiedHealthService: Error in polling: $e');
              }
              onError?.call('Polling error: $e');
            }
          });

          // TimerをStreamSubscriptionとして管理するためのアダプタ
          late StreamSubscription subscription;
          subscription = Stream.periodic(const Duration(seconds: 1)).listen((_) {
            // タイマーが動作中かチェック
            if (!_isRealtimeMonitoringActive) {
              timer.cancel();
              subscription.cancel();
            }
          });
          _subscriptions.add(subscription);
          break;
        default:
          throw const RealtimeMonitoringException('Platform not supported for realtime monitoring');
      }

      return _realtimeController!.stream;
    } catch (e) {
      throw RealtimeMonitoringException('Failed to start realtime monitoring: $e');
    }
  }

  /// リアルタイム更新をシミュレート（テスト用）
  Future<void> simulateRealtimeUpdate(NormalizedActivity activity) async {
    if (_realtimeController != null && !_realtimeController!.isClosed) {
      _realtimeController!.add(activity);
    }
  }

  /// リアルタイム監視を停止
  Future<void> stopRealtimeMonitoring() async {
    try {
      _isRealtimeMonitoringActive = false;

      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();

      await _realtimeController?.close();
      _realtimeController = null;

      if (kDebugMode) {
        print('UnifiedHealthService: Realtime monitoring stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedHealthService: Error stopping realtime monitoring: $e');
      }
      onError?.call('Stopping realtime monitoring failed: $e');
    }
  }

  /// リアルタイム監視が有効かチェック
  bool get isRealtimeMonitoringActive => _isRealtimeMonitoringActive;

  // ===================
  // データ同期とキャッシュ
  // ===================

  /// プラットフォーム間でデータを同期
  Future<SyncResult> syncPlatformData({
    required List<HealthPlatform> platforms,
    required Duration timeRange,
  }) async {
    try {
      final endTime = DateTime.now();
      final startTime = endTime.subtract(timeRange);
      final conflicts = <DataConflict>[];
      int totalSynced = 0;

      // 各プラットフォームからデータを取得
      final allActivities = await getActivities(
        startTime: startTime,
        endTime: endTime,
      );

      totalSynced = allActivities.length;

      return SyncResult(
        isSuccess: true,
        syncedActivities: totalSynced,
        syncedHeartRateRecords: 0, // TODO: 実装
        syncedStepsRecords: 0, // TODO: 実装
        conflicts: conflicts,
        syncTime: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedHealthService: Error syncing platform data: $e');
      }
      onError?.call('Platform data sync failed: $e');

      return SyncResult(
        isSuccess: false,
        syncedActivities: 0,
        syncedHeartRateRecords: 0,
        syncedStepsRecords: 0,
        conflicts: [],
        syncTime: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// データ競合を解決
  Future<List<NormalizedActivity>> resolveDataConflicts(
    List<Map<String, dynamic>> conflictingData,
    ConflictResolutionStrategy strategy,
  ) async {
    switch (strategy) {
      case ConflictResolutionStrategy.mostRecent:
        // 最新のデータを選択
        final activities = conflictingData
            .map((data) => normalizeActivityData(data))
            .toList();
        activities.sort((a, b) => b.endTime.compareTo(a.endTime));
        return activities.take(1).toList();

      case ConflictResolutionStrategy.sourcePreference:
        // ソースの優先度に基づいて選択（HealthKit > Health Connect > その他）
        final activities = conflictingData
            .map((data) => normalizeActivityData(data))
            .toList();

        activities.sort((a, b) => _getSourcePriority(a.source).compareTo(_getSourcePriority(b.source)));
        return activities.take(1).toList();

      default:
        return conflictingData.map((data) => normalizeActivityData(data)).toList();
    }
  }

  /// データをキャッシュ
  Future<void> cacheData(String key, List<NormalizedActivity> data) async {
    _cache[key] = data;
    if (kDebugMode) {
      print('UnifiedHealthService: Cached ${data.length} activities with key: $key');
    }
  }

  /// 有効期限付きでデータをキャッシュ
  Future<void> cacheDataWithExpiry(
    String key,
    List<NormalizedActivity> data, {
    required DateTime expiryTime,
  }) async {
    _cache[key] = data;
    _cacheExpiry[key] = expiryTime;
    if (kDebugMode) {
      print('UnifiedHealthService: Cached ${data.length} activities with key: $key (expires: $expiryTime)');
    }
  }

  /// キャッシュされたデータを取得
  Future<List<NormalizedActivity>?> getCachedData(String key) async {
    // 有効期限をチェック
    if (_cacheExpiry.containsKey(key)) {
      final expiryTime = _cacheExpiry[key]!;
      if (DateTime.now().isAfter(expiryTime)) {
        _cache.remove(key);
        _cacheExpiry.remove(key);
        return null;
      }
    }

    return _cache[key];
  }

  // ===================
  // 統計とインサイト
  // ===================

  /// アクティビティ統計を計算
  Future<ActivityStatistics> calculateActivityStatistics(List<NormalizedActivity> activities) async {
    if (activities.isEmpty) {
      return const ActivityStatistics(
        totalActivities: 0,
        totalCalories: 0,
        totalDistance: 0,
        totalDuration: Duration.zero,
        averageCaloriesPerWorkout: 0,
        averageDistancePerWorkout: 0,
        averageDurationPerWorkout: Duration.zero,
        activityTypeCount: {},
        intensityDistribution: {},
      );
    }

    final totalCalories = activities
        .map((a) => a.calories ?? 0.0)
        .reduce((a, b) => a + b);

    final totalDistance = activities
        .map((a) => a.distance ?? 0.0)
        .reduce((a, b) => a + b);

    final totalDuration = activities
        .map((a) => a.duration)
        .reduce((a, b) => a + b);

    // アクティビティタイプの分布を計算
    final typeCount = <ActivityType, int>{};
    final intensityDistribution = <ActivityIntensity, int>{};

    for (final activity in activities) {
      typeCount[activity.type] = (typeCount[activity.type] ?? 0) + 1;
      intensityDistribution[activity.intensity] =
          (intensityDistribution[activity.intensity] ?? 0) + 1;
    }

    // 最も多いアクティビティタイプを特定
    ActivityType? mostCommonType;
    int maxCount = 0;
    for (final entry in typeCount.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommonType = entry.key;
      }
    }

    return ActivityStatistics(
      totalActivities: activities.length,
      totalCalories: totalCalories,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      averageCaloriesPerWorkout: totalCalories / activities.length,
      averageDistancePerWorkout: totalDistance / activities.length,
      averageDurationPerWorkout: Duration(
        microseconds: totalDuration.inMicroseconds ~/ activities.length,
      ),
      mostCommonActivityType: mostCommonType,
      activityTypeCount: typeCount,
      intensityDistribution: intensityDistribution,
    );
  }

  /// ヘルスインサイトを生成
  Future<HealthInsights> generateHealthInsights(HealthInsightTimeRange timeRange) async {
    // 基本的なインサイトを生成（実際のロジックはより複雑になる）
    final trends = <HealthTrend>[
      const HealthTrend(
        title: 'Workout Frequency',
        description: 'Your workout frequency has increased by 15% this month',
        direction: TrendDirection.improving,
        changePercentage: 15.0,
        dataType: HealthDataType.activities,
      ),
    ];

    final recommendations = <HealthRecommendation>[
      const HealthRecommendation(
        title: 'Increase Cardio',
        description: 'Consider adding more cardio exercises to your routine',
        type: RecommendationType.exercise,
        priority: 7,
      ),
    ];

    final achievements = <HealthAchievement>[
      HealthAchievement(
        title: 'Weekly Goal Achieved',
        description: 'You completed 5 workouts this week!',
        achievedDate: DateTime.now(),
        type: AchievementType.weeklyGoal,
      ),
    ];

    final riskFactors = <HealthRiskFactor>[
      const HealthRiskFactor(
        title: 'Low Activity Days',
        description: 'You have 3 consecutive days with no recorded activity',
        level: RiskLevel.medium,
        mitigation: ['Schedule shorter workouts', 'Set daily step goals'],
      ),
    ];

    return HealthInsights(
      trends: trends,
      recommendations: recommendations,
      achievements: achievements,
      riskFactors: riskFactors,
      generatedAt: DateTime.now(),
    );
  }

  /// アクティビティパターンを予測
  Future<ActivityPrediction> predictActivityPatterns(
    List<NormalizedActivity> historicalData,
    int predictionDays,
  ) async {
    // 簡単な予測ロジック（実際にはより高度な機械学習を使用する）
    final predictedActivities = <NormalizedActivity>[];

    if (historicalData.isNotEmpty) {
      // 過去の平均を基に予測
      final avgPerWeek = historicalData.length / 4; // 4週間と仮定
      final avgActivity = historicalData.first;

      for (int i = 0; i < predictionDays; i++) {
        if (i % 2 == 0) { // 隔日で予測
          predictedActivities.add(avgActivity.copyWith(
            id: 'predicted_$i',
            startTime: DateTime.now().add(Duration(days: i)),
            endTime: DateTime.now().add(Duration(days: i, hours: 1)),
          ));
        }
      }
    }

    return ActivityPrediction(
      predictedActivities: predictedActivities,
      confidence: historicalData.length > 30 ? 0.8 : 0.5,
      predictionDate: DateTime.now(),
      predictionWindow: Duration(days: predictionDays),
    );
  }

  // ===================
  // エラーハンドリングとフォールバック
  // ===================

  /// フォールバック付きアクティビティ取得
  Future<List<NormalizedActivity>> getActivitiesWithFallback({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      return await getActivities(startTime: startTime, endTime: endTime);
    } catch (e) {
      // キャッシュからフォールバックデータを取得
      final cacheKey = 'activities_${startTime?.toIso8601String()}_${endTime?.toIso8601String()}';
      final cachedData = await getCachedData(cacheKey);

      if (cachedData != null) {
        if (kDebugMode) {
          print('UnifiedHealthService: Using cached data as fallback');
        }
        return cachedData;
      }

      // デフォルト空データを返す
      return [];
    }
  }

  /// リトライ付きアクティビティ取得
  Future<List<NormalizedActivity>> getActivitiesWithRetry({
    DateTime? startTime,
    DateTime? endTime,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        return await getActivities(startTime: startTime, endTime: endTime);
      } catch (e) {
        attempts++;
        if (attempts > maxRetries) {
          rethrow;
        }

        if (kDebugMode) {
          print('UnifiedHealthService: Retry attempt $attempts failed, retrying...');
        }

        // 指数バックオフ
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }

    return [];
  }

  // ===================
  // パフォーマンス最適化
  // ===================

  /// 複数のデータリクエストをバッチ処理
  Future<List<DataResponse>> batchDataRequests(List<DataRequest> requests) async {
    final responses = <DataResponse>[];

    for (final request in requests) {
      try {
        dynamic data;

        switch (request.type) {
          case HealthDataType.activities:
            data = await getActivities(
              startTime: request.startTime,
              endTime: request.endTime,
            );
            break;
          case HealthDataType.heartRate:
            data = await getHeartRateData(
              startTime: request.startTime,
              endTime: request.endTime,
            );
            break;
          default:
            throw Exception('Unsupported data type: ${request.type}');
        }

        responses.add(DataResponse(
          type: request.type,
          isSuccess: true,
          data: data,
          responseTime: DateTime.now(),
        ));
      } catch (e) {
        responses.add(DataResponse(
          type: request.type,
          isSuccess: false,
          data: null,
          errorMessage: e.toString(),
          responseTime: DateTime.now(),
        ));
      }
    }

    return responses;
  }

  /// 大量データセットを処理
  Future<LargeDatasetProcessingResult> processLargeDataset(
    List<NormalizedActivity> dataset, {
    int batchSize = 1000,
  }) async {
    final startTime = DateTime.now();
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    for (int i = 0; i < dataset.length; i += batchSize) {
      final batch = dataset.skip(i).take(batchSize).toList();

      try {
        // バッチ処理（例：統計計算）
        await calculateActivityStatistics(batch);
        successful += batch.length;
      } catch (e) {
        failed += batch.length;
        errors.add('Batch ${i ~/ batchSize}: $e');
      }
    }

    final processingTime = DateTime.now().difference(startTime);

    return LargeDatasetProcessingResult(
      totalProcessed: dataset.length,
      successful: successful,
      failed: failed,
      processingTime: processingTime,
      errors: errors,
    );
  }

  // ===================
  // ヘルパーメソッド
  // ===================

  /// データソースを判定
  HealthDataSource _determineDataSource(Map<String, dynamic> data) {
    final sourceString = data['source'] as String?;

    switch (sourceString) {
      case 'healthkit':
        return HealthDataSource.healthKit;
      case 'health_connect':
        return HealthDataSource.healthConnect;
      default:
        return HealthDataSource.unknown;
    }
  }

  /// HealthKitアクティビティを正規化
  NormalizedActivity _normalizeHealthKitActivity(Map<String, dynamic> data) {
    return NormalizedActivity(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _mapHealthKitActivityType(data['type'] as String?),
      startTime: data['startDate'] as DateTime,
      endTime: data['endDate'] as DateTime,
      source: HealthDataSource.healthKit,
      calories: (data['totalEnergyBurned'] as num?)?.toDouble(),
      distance: (data['totalDistance'] as num?)?.toDouble(),
      name: data['name'] as String?,
    );
  }

  /// Health Connectアクティビティを正規化
  NormalizedActivity _normalizeHealthConnectActivity(Map<String, dynamic> data) {
    final energyBurned = data['totalEnergyBurned'];
    final distance = data['totalDistance'];

    return NormalizedActivity(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _mapHealthConnectActivityType(data['exerciseType'] as String?),
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: DateTime.parse(data['endTime'] as String),
      source: HealthDataSource.healthConnect,
      calories: energyBurned is Map ? (energyBurned['value'] as num?)?.toDouble() : null,
      distance: distance is Map ? (distance['value'] as num?)?.toDouble() : null,
      name: data['title'] as String?,
    );
  }

  /// HealthKitアクティビティタイプをマッピング
  ActivityType _mapHealthKitActivityType(String? type) {
    switch (type) {
      case 'HKWorkoutActivityTypeRunning':
        return ActivityType.running;
      case 'HKWorkoutActivityTypeWalking':
        return ActivityType.walking;
      case 'HKWorkoutActivityTypeCycling':
        return ActivityType.cycling;
      case 'HKWorkoutActivityTypeSwimming':
        return ActivityType.swimming;
      case 'HKWorkoutActivityTypeYoga':
        return ActivityType.yoga;
      default:
        return ActivityType.unknown;
    }
  }

  /// Health Connectアクティビティタイプをマッピング
  ActivityType _mapHealthConnectActivityType(String? type) {
    switch (type) {
      case 'EXERCISE_TYPE_RUNNING':
        return ActivityType.running;
      case 'EXERCISE_TYPE_WALKING':
        return ActivityType.walking;
      case 'EXERCISE_TYPE_BIKING':
        return ActivityType.cycling;
      case 'EXERCISE_TYPE_SWIMMING_POOL':
        return ActivityType.swimming;
      case 'EXERCISE_TYPE_YOGA':
        return ActivityType.yoga;
      default:
        return ActivityType.unknown;
    }
  }

  /// 週別の集計を計算
  Map<String, int> _calculateWeeklyBreakdown(List<NormalizedActivity> activities) {
    final breakdown = <String, int>{};

    for (final activity in activities) {
      final weekKey = '${activity.startTime.year}-W${_getWeekOfYear(activity.startTime)}';
      breakdown[weekKey] = (breakdown[weekKey] ?? 0) + 1;
    }

    return breakdown;
  }

  /// タイプ別の集計を計算
  Map<ActivityType, ActivityStatistics> _calculateTypeBreakdown(List<NormalizedActivity> activities) {
    final breakdown = <ActivityType, ActivityStatistics>{};

    final typeGroups = <ActivityType, List<NormalizedActivity>>{};
    for (final activity in activities) {
      typeGroups.putIfAbsent(activity.type, () => []).add(activity);
    }

    // TODO: 各タイプ別の統計を計算
    return breakdown;
  }

  /// 年の週数を取得
  int _getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(startOfYear).inDays;
    return (daysDifference / 7).ceil();
  }

  /// ソースの優先度を取得
  int _getSourcePriority(HealthDataSource source) {
    switch (source) {
      case HealthDataSource.healthKit:
        return 1;
      case HealthDataSource.healthConnect:
        return 2;
      case HealthDataSource.manual:
        return 3;
      case HealthDataSource.thirdParty:
        return 4;
      default:
        return 5;
    }
  }

  /// コンカレンシー制御
  Future<void> _waitForConcurrencySlot() async {
    while (_currentConcurrentRequests >= _maxConcurrentRequests) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// リソースのクリーンアップ
  void dispose() {
    stopRealtimeMonitoring();
    _cache.clear();
    _cacheExpiry.clear();

    if (kDebugMode) {
      print('UnifiedHealthService: Resources disposed');
    }
  }
}