import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/foundation.dart';
import 'package:fatgram/domain/services/unified_health_service.dart';
import 'package:fatgram/data/datasources/health/health_kit_datasource.dart';
import 'package:fatgram/data/datasources/health/health_connect_datasource.dart';
import 'package:fatgram/domain/entities/activity.dart';
import 'package:fatgram/domain/entities/health_data.dart';
import 'package:fatgram/domain/services/health_permission_service.dart';
import 'dart:async';
import '../../test_helper.dart';

// Mock classes
class MockHealthKitDataSource extends Mock implements HealthKitDataSource {}
class MockHealthConnectDataSource extends Mock implements HealthConnectDataSource {}
class MockHealthPermissionService extends Mock implements HealthPermissionService {}

void main() {
  late UnifiedHealthService unifiedHealthService;
  late MockHealthKitDataSource mockHealthKitDataSource;
  late MockHealthConnectDataSource mockHealthConnectDataSource;
  late MockHealthPermissionService mockPermissionService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(<String>[]);
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(TestHelper.generateActivityData());
  });

  setUp(() {
    mockHealthKitDataSource = MockHealthKitDataSource();
    mockHealthConnectDataSource = MockHealthConnectDataSource();
    mockPermissionService = MockHealthPermissionService();

    unifiedHealthService = UnifiedHealthService(
      healthKitDataSource: mockHealthKitDataSource,
      healthConnectDataSource: mockHealthConnectDataSource,
      permissionService: mockPermissionService,
    );
  });

  group('UnifiedHealthService', () {
    group('プラットフォーム判定', () {
      test('should detect iOS platform correctly', () async {
        // Act
        final platform = unifiedHealthService.getCurrentPlatform();

        // Assert
        expect(platform, isA<HealthPlatform>());
        expect([HealthPlatform.ios, HealthPlatform.android, HealthPlatform.unknown], contains(platform));
      });

      test('should return correct platform capabilities', () async {
        // Act
        final capabilities = await unifiedHealthService.getPlatformCapabilities();

        // Assert
        expect(capabilities, isA<HealthPlatformCapabilities>());
        expect(capabilities.supportedDataTypes, isNotEmpty);
        expect(capabilities.hasBackgroundSync, isA<bool>());
        expect(capabilities.hasRealtimeData, isA<bool>());
      });

      test('should check platform availability', () async {
        // Arrange
        when(() => mockPermissionService.isHealthKitAvailable())
            .thenAnswer((_) async => true);
        when(() => mockPermissionService.isHealthConnectAvailable())
            .thenAnswer((_) async => false);

        // Act
        final availability = await unifiedHealthService.checkPlatformAvailability();

        // Assert
        expect(availability.isHealthKitAvailable, isTrue);
        expect(availability.isHealthConnectAvailable, isFalse);
        expect(availability.recommendedPlatform, equals(HealthPlatform.ios));
      });

      test('should handle platform unavailability gracefully', () async {
        // Arrange
        when(() => mockPermissionService.isHealthKitAvailable())
            .thenAnswer((_) async => false);
        when(() => mockPermissionService.isHealthConnectAvailable())
            .thenAnswer((_) async => false);

        // Act
        final availability = await unifiedHealthService.checkPlatformAvailability();

        // Assert
        expect(availability.isHealthKitAvailable, isFalse);
        expect(availability.isHealthConnectAvailable, isFalse);
        expect(availability.recommendedPlatform, equals(HealthPlatform.unknown));
      });
    });

    group('権限管理統合', () {
      test('should request permissions for iOS platform', () async {
        // Arrange
        final permissions = ['workouts', 'heartRate', 'steps'];
        when(() => mockHealthKitDataSource.requestPermissions(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await unifiedHealthService.requestPermissions(permissions);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.grantedPermissions, containsAll(permissions));
        verify(() => mockHealthKitDataSource.requestPermissions(any())).called(1);
      });

      test('should request permissions for Android platform', () async {
        // Arrange
        final permissions = ['android.permission.health.READ_EXERCISE'];
        when(() => mockHealthConnectDataSource.requestPermissions(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await unifiedHealthService.requestPermissions(permissions);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockHealthConnectDataSource.requestPermissions(any())).called(1);
      });

      test('should get unified permission status', () async {
        // Arrange
        when(() => mockPermissionService.getAllHealthKitPermissions())
            .thenAnswer((_) async => {
              'workouts': true,
              'heartRate': true,
              'steps': false,
            });

        // Act
        final status = await unifiedHealthService.getPermissionStatus();

        // Assert
        expect(status.workouts, isTrue);
        expect(status.heartRate, isTrue);
        expect(status.steps, isFalse);
        expect(status.hasAllRequiredPermissions, isFalse);
      });

      test('should handle permission errors gracefully', () async {
        // Arrange
        when(() => mockHealthKitDataSource.requestPermissions(any()))
            .thenThrow(Exception('Permission request failed'));

        // Act
        final result = await unifiedHealthService.requestPermissions(['workouts']);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Permission request failed'));
      });
    });

    group('データ正規化', () {
      test('should normalize HealthKit workout data to standard format', () async {
        // Arrange
        final healthKitData = {
          'type': 'HKWorkoutActivityTypeRunning',
          'startDate': DateTime.now().subtract(const Duration(hours: 1)),
          'endDate': DateTime.now(),
          'totalEnergyBurned': 250.0,
          'totalDistance': 5000.0,
          'source': 'healthkit',
        };

        // Act
        final normalizedData = unifiedHealthService.normalizeActivityData(healthKitData);

        // Assert
        expect(normalizedData.type, equals(ActivityType.running));
        expect(normalizedData.source, equals(HealthDataSource.healthKit));
        expect(normalizedData.calories, equals(250.0));
        expect(normalizedData.distance, equals(5000.0));
        expect(normalizedData.startTime, isA<DateTime>());
        expect(normalizedData.endTime, isA<DateTime>());
      });

      test('should normalize Health Connect data to standard format', () async {
        // Arrange
        final healthConnectData = {
          'recordType': 'ExerciseSessionRecord',
          'exerciseType': 'EXERCISE_TYPE_RUNNING',
          'startTime': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'endTime': DateTime.now().toIso8601String(),
          'totalEnergyBurned': {'value': 300.0, 'unit': 'kilocalories'},
          'source': 'health_connect',
        };

        // Act
        final normalizedData = unifiedHealthService.normalizeActivityData(healthConnectData);

        // Assert
        expect(normalizedData.type, equals(ActivityType.running));
        expect(normalizedData.source, equals(HealthDataSource.healthConnect));
        expect(normalizedData.calories, equals(300.0));
      });

      test('should normalize heart rate data from different sources', () async {
        // Arrange
        final healthKitHeartRate = {
          'samples': [
            {'value': 75.0, 'startDate': DateTime.now()},
            {'value': 80.0, 'startDate': DateTime.now().add(const Duration(minutes: 1))},
          ],
          'source': 'healthkit',
        };

        final healthConnectHeartRate = {
          'samples': [
            {'beatsPerMinute': 75.0, 'time': DateTime.now().toIso8601String()},
            {'beatsPerMinute': 80.0, 'time': DateTime.now().add(const Duration(minutes: 1)).toIso8601String()},
          ],
          'source': 'health_connect',
        };

        // Act
        final normalizedHealthKit = unifiedHealthService.normalizeHeartRateData(healthKitHeartRate);
        final normalizedHealthConnect = unifiedHealthService.normalizeHeartRateData(healthConnectHeartRate);

        // Assert
        expect(normalizedHealthKit.samples, hasLength(2));
        expect(normalizedHealthConnect.samples, hasLength(2));
        expect(normalizedHealthKit.averageHeartRate, equals(77.5));
        expect(normalizedHealthConnect.averageHeartRate, equals(77.5));
      });

      test('should handle invalid data gracefully during normalization', () async {
        // Arrange
        final invalidData = {
          'invalidField': 'invalidValue',
        };

        // Act & Assert
        expect(
          () => unifiedHealthService.normalizeActivityData(invalidData),
          throwsA(isA<DataNormalizationException>()),
        );
      });

      test('should convert between different unit systems', () async {
        // Arrange - Distance in meters
        final metersData = {'distance': 5000.0, 'unit': 'meters'};

        // Act
        final normalizedDistance = unifiedHealthService.normalizeDistance(metersData);

        // Assert
        expect(normalizedDistance.meters, equals(5000.0));
        expect(normalizedDistance.kilometers, equals(5.0));
        expect(normalizedDistance.miles, closeTo(3.107, 0.01));
      });
    });

    group('統合データ取得', () {
      test('should fetch activities from appropriate platform', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 7));
        final endTime = DateTime.now();
        final mockActivities = [TestHelper.generateActivityData()];

        when(() => mockHealthKitDataSource.getActivities(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockActivities);

        // Act
        final activities = await unifiedHealthService.getActivities(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(activities, isNotEmpty);
        expect(activities.first, isA<NormalizedActivity>());
        verify(() => mockHealthKitDataSource.getActivities(
          startTime: startTime,
          endTime: endTime,
        )).called(1);
      });

      test('should fetch heart rate data from multiple sources', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 2));
        final endTime = DateTime.now();

        when(() => mockHealthKitDataSource.getHeartRateData(
          startDate: startTime,
          endDate: endTime,
        )).thenAnswer((_) async => [
          {'value': 75.0, 'startDate': startTime},
        ]);

        // Act
        final heartRateData = await unifiedHealthService.getHeartRateData(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(heartRateData, isA<NormalizedHeartRateData>());
        expect(heartRateData.samples, isNotEmpty);
      });

      test('should aggregate data from multiple time periods', () async {
        // Arrange
        final endTime = DateTime.now();
        final startTime = endTime.subtract(const Duration(days: 30));

        when(() => mockHealthKitDataSource.getActivities(
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        )).thenAnswer((_) async => [
          TestHelper.generateActivityData(),
          TestHelper.generateActivityData(),
        ]);

        // Act
        final summary = await unifiedHealthService.getActivitySummary(
          startTime: startTime,
          endTime: endTime,
          groupBy: AggregationPeriod.weekly,
        );

        // Assert
        expect(summary.totalWorkouts, greaterThan(0));
        expect(summary.totalCalories, greaterThan(0));
        expect(summary.averageWorkoutsPerWeek, greaterThan(0));
        expect(summary.weeklyBreakdown, isNotEmpty);
      });

      test('should handle data fetching errors gracefully', () async {
        // Arrange
        when(() => mockHealthKitDataSource.getActivities(
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        )).thenThrow(Exception('Data fetch failed'));

        // Act
        final activities = await unifiedHealthService.getActivities(
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now(),
        );

        // Assert
        expect(activities, isEmpty);
      });
    });

    group('リアルタイム更新', () {
      test('should start real-time monitoring', () async {
        // Arrange
        final controller = StreamController<NormalizedActivity>();
        when(() => mockHealthKitDataSource.startRealtimeMonitoring())
            .thenAnswer((_) => controller.stream.map((activity) => activity as Map<String, dynamic>));

        // Act
        final stream = unifiedHealthService.startRealtimeMonitoring();

        // Add test data
        final testActivity = NormalizedActivity(
          id: 'test_1',
          type: ActivityType.running,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(minutes: 30)),
          source: HealthDataSource.healthKit,
        );
        controller.add(testActivity);

        // Assert
        expect(stream, isA<Stream<NormalizedActivity>>());

        await expectLater(
          stream.take(1),
          emits(isA<NormalizedActivity>()),
        );

        controller.close();
      });

      test('should handle real-time data updates', () async {
        // Arrange
        final updates = <NormalizedActivity>[];
        final subscription = unifiedHealthService
            .startRealtimeMonitoring()
            .listen((activity) => updates.add(activity));

        // Act
        await unifiedHealthService.simulateRealtimeUpdate(NormalizedActivity(
          id: 'realtime_1',
          type: ActivityType.walking,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(minutes: 15)),
          source: HealthDataSource.healthKit,
        ));

        // Allow time for the update to be processed
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(updates, hasLength(1));
        expect(updates.first.type, equals(ActivityType.walking));

        subscription.cancel();
      });

      test('should filter real-time updates by criteria', () async {
        // Arrange
        final criteria = RealtimeFilterCriteria(
          minDuration: const Duration(minutes: 10),
          activityTypes: [ActivityType.running, ActivityType.cycling],
          minCalories: 100.0,
        );

        // Act
        final stream = unifiedHealthService.startRealtimeMonitoring(
          filterCriteria: criteria,
        );

        // Assert
        expect(stream, isA<Stream<NormalizedActivity>>());
      });

      test('should stop real-time monitoring', () async {
        // Arrange
        await unifiedHealthService.startRealtimeMonitoring();

        // Act
        await unifiedHealthService.stopRealtimeMonitoring();

        // Assert
        expect(unifiedHealthService.isRealtimeMonitoringActive, isFalse);
      });

      test('should handle real-time monitoring errors', () async {
        // Arrange
        when(() => mockHealthKitDataSource.startRealtimeMonitoring())
            .thenThrow(Exception('Real-time monitoring failed'));

        // Act & Assert
        expect(
          () => unifiedHealthService.startRealtimeMonitoring(),
          throwsA(isA<RealtimeMonitoringException>()),
        );
      });
    });

    group('データ同期とキャッシュ', () {
      test('should sync data between platforms', () async {
        // Arrange
        final mockData = [TestHelper.generateActivityData()];
        when(() => mockHealthKitDataSource.getActivities(
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        )).thenAnswer((_) async => mockData);

        // Act
        final syncResult = await unifiedHealthService.syncPlatformData(
          platforms: [HealthPlatform.ios, HealthPlatform.android],
          timeRange: const Duration(days: 7),
        );

        // Assert
        expect(syncResult.isSuccess, isTrue);
        expect(syncResult.syncedActivities, greaterThan(0));
        expect(syncResult.conflicts, isEmpty);
      });

      test('should resolve data conflicts during sync', () async {
        // Arrange
        final conflictingData = [
          TestHelper.generateActivityData(),
          TestHelper.generateActivityData(), // Same time period
        ];

        // Act
        final resolvedData = await unifiedHealthService.resolveDataConflicts(
          conflictingData,
          ConflictResolutionStrategy.mostRecent,
        );

        // Assert
        expect(resolvedData, hasLength(1)); // Conflicts resolved
      });

      test('should cache frequently accessed data', () async {
        // Arrange
        final cacheKey = 'activities_last_7_days';
        final mockData = [TestHelper.generateActivityData()];

        // Act
        final normalizedMockData = mockData.map((data) => unifiedHealthService.normalizeActivityData(data)).toList();
        await unifiedHealthService.cacheData(cacheKey, normalizedMockData);
        final cachedData = await unifiedHealthService.getCachedData(cacheKey);

        // Assert
        expect(cachedData, isNotNull);
        expect(cachedData, hasLength(1));
      });

      test('should invalidate expired cache data', () async {
        // Arrange
        final cacheKey = 'expired_data';
        final mockData = [TestHelper.generateActivityData()];
        final expiredTime = DateTime.now().subtract(const Duration(hours: 25));

        // Act
        final normalizedMockData = mockData.map((data) => unifiedHealthService.normalizeActivityData(data)).toList();
        await unifiedHealthService.cacheDataWithExpiry(
          cacheKey,
          normalizedMockData,
          expiryTime: expiredTime,
        );
        final cachedData = await unifiedHealthService.getCachedData(cacheKey);

        // Assert
        expect(cachedData, isNull);
      });
    });

    group('統計とインサイト', () {
      test('should calculate comprehensive activity statistics', () async {
        // Arrange
        final activities = [
          NormalizedActivity(
            id: '1',
            type: ActivityType.running,
            startTime: DateTime.now().subtract(const Duration(days: 1)),
            endTime: DateTime.now().subtract(const Duration(days: 1, hours: -1)),
            calories: 300.0,
            distance: 5000.0,
            source: HealthDataSource.healthKit,
          ),
          NormalizedActivity(
            id: '2',
            type: ActivityType.cycling,
            startTime: DateTime.now().subtract(const Duration(days: 2)),
            endTime: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
            calories: 400.0,
            distance: 15000.0,
            source: HealthDataSource.healthKit,
          ),
        ];

        // Act
        final stats = await unifiedHealthService.calculateActivityStatistics(activities);

        // Assert
        expect(stats.totalActivities, equals(2));
        expect(stats.totalCalories, equals(700.0));
        expect(stats.totalDistance, equals(20000.0));
        expect(stats.averageCaloriesPerWorkout, equals(350.0));
        expect(stats.mostCommonActivityType, isA<ActivityType>());
      });

      test('should generate health insights', () async {
        // Arrange
        final timeRange = HealthInsightTimeRange.lastMonth;

        // Act
        final insights = await unifiedHealthService.generateHealthInsights(timeRange);

        // Assert
        expect(insights.trends, isNotEmpty);
        expect(insights.recommendations, isNotEmpty);
        expect(insights.achievements, isA<List<HealthAchievement>>());
        expect(insights.riskFactors, isA<List<HealthRiskFactor>>());
      });

      test('should predict future activity patterns', () async {
        // Arrange
        final historicalData = List.generate(30, (index) => NormalizedActivity(
          id: 'activity_$index',
          type: ActivityType.running,
          startTime: DateTime.now().subtract(Duration(days: index)),
          endTime: DateTime.now().subtract(Duration(days: index, hours: -1)),
          source: HealthDataSource.healthKit,
        ));

        // Act
        final predictions = await unifiedHealthService.predictActivityPatterns(
          historicalData,
          7,
        );

        // Assert
        expect(predictions.predictedActivities, hasLength(7));
        expect(predictions.confidence, greaterThan(0.0));
        expect(predictions.confidence, lessThanOrEqualTo(1.0));
      });
    });

    group('エラーハンドリングとフォールバック', () {
      test('should handle platform unavailability with fallback', () async {
        // Arrange
        when(() => mockPermissionService.isHealthKitAvailable())
            .thenAnswer((_) async => false);
        when(() => mockPermissionService.isHealthConnectAvailable())
            .thenAnswer((_) async => false);

        // Act
        final data = await unifiedHealthService.getActivitiesWithFallback(
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now(),
        );

        // Assert
        expect(data, isA<List<NormalizedActivity>>());
        // Should return cached or default data
      });

      test('should retry failed operations automatically', () async {
        // Arrange
        var callCount = 0;
        when(() => mockHealthKitDataSource.getActivities(
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        )).thenAnswer((_) async {
          callCount++;
          if (callCount <= 2) {
            throw Exception('Temporary failure');
          }
          return [TestHelper.generateActivityData()];
        });

        // Act
        final activities = await unifiedHealthService.getActivitiesWithRetry(
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now(),
          maxRetries: 3,
        );

        // Assert
        expect(activities, hasLength(1));
        expect(callCount, equals(3));
      });

      test('should log errors for debugging', () async {
        // Arrange
        final errors = <String>[];
        unifiedHealthService.onError = (error) => errors.add(error);

        when(() => mockHealthKitDataSource.getActivities(
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        )).thenThrow(Exception('Test error'));

        // Act
        await unifiedHealthService.getActivities(
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now(),
        );

        // Assert
        expect(errors, isNotEmpty);
        expect(errors.first, contains('Test error'));
      });
    });

    group('パフォーマンス最適化', () {
      test('should batch multiple data requests', () async {
        // Arrange
        final requests = [
          DataRequest(
            type: HealthDataType.activities,
            startTime: DateTime.now().subtract(const Duration(days: 1)),
            endTime: DateTime.now(),
          ),
          DataRequest(
            type: HealthDataType.heartRate,
            startTime: DateTime.now().subtract(const Duration(hours: 2)),
            endTime: DateTime.now(),
          ),
        ];

        // Act
        final results = await unifiedHealthService.batchDataRequests(requests);

        // Assert
        expect(results, hasLength(2));
        expect(results[0].type, equals(HealthDataType.activities));
        expect(results[1].type, equals(HealthDataType.heartRate));
      });

      test('should limit concurrent requests', () async {
        // Arrange
        final startTime = DateTime.now();
        final requests = List.generate(10, (index) =>
          unifiedHealthService.getActivities(
            startTime: DateTime.now().subtract(Duration(days: index + 1)),
            endTime: DateTime.now().subtract(Duration(days: index)),
          )
        );

        // Act
        await Future.wait(requests);
        final endTime = DateTime.now();

        // Assert
        final duration = endTime.difference(startTime);
        // Should complete within reasonable time due to concurrency limiting
        expect(duration.inSeconds, lessThan(30));
      });

      test('should optimize memory usage for large datasets', () async {
        // Arrange
        final largeDataset = List.generate(10000, (index) => NormalizedActivity(
          id: 'activity_$index',
          type: ActivityType.running,
          startTime: DateTime.now().subtract(Duration(minutes: index)),
          endTime: DateTime.now().subtract(Duration(minutes: index - 30)),
          source: HealthDataSource.healthKit,
        ));

        // Act
        final processedData = await unifiedHealthService.processLargeDataset(
          largeDataset,
          batchSize: 1000,
        );

        // Assert
        expect(processedData.totalProcessed, equals(10000));
        expect(processedData.processingTime, lessThan(const Duration(seconds: 5)));
      });
    });
  });
}