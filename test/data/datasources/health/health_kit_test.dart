import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fatgram/data/datasources/health/health_kit_datasource.dart';
import 'package:fatgram/domain/services/health_permission_service.dart';
import '../../../test_helper.dart';

// MockHealthKit (外部パッケージのMock) - Abstract methods only
class MockHealthKit extends Mock {
  Future<bool> requestAuthorization(List<String> types);
  Future<bool> isAuthorized(String type);
  Future<List<Map<String, dynamic>>> getWorkouts({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<Map<String, dynamic>>> getHeartRateData({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<Map<String, dynamic>>> getStepsData({
    DateTime? startDate,
    DateTime? endDate,
  });
}

class MockHealthPermissionService extends Mock implements HealthPermissionService {}

void main() {
  late HealthKitDataSource healthKitDataSource;
  late MockHealthKit mockHealthKit;
  late MockHealthPermissionService mockPermissionService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    mockHealthKit = MockHealthKit();
    mockPermissionService = MockHealthPermissionService();
    healthKitDataSource = HealthKitDataSource(
      healthKit: mockHealthKit,
      permissionService: mockPermissionService,
    );
  });

  group('HealthKitDataSource', () {
    group('権限管理', () {
      test('should request HealthKit permissions successfully', () async {
        // Arrange
        final permissions = ['workouts', 'heartRate', 'steps', 'activeEnergyBurned'];
        when(() => mockHealthKit.requestAuthorization(permissions))
            .thenAnswer((_) async => true);
        when(() => mockPermissionService.requestHealthKitPermissions(permissions))
            .thenAnswer((_) async => true);

        // Act
        final result = await healthKitDataSource.requestPermissions(permissions);

        // Assert
        expect(result, isTrue);
        verify(() => mockPermissionService.requestHealthKitPermissions(permissions)).called(1);
        verify(() => mockHealthKit.requestAuthorization(permissions)).called(1);
      });

      test('should handle permission request failure', () async {
        // Arrange
        final permissions = ['workouts', 'heartRate'];
        when(() => mockHealthKit.requestAuthorization(permissions))
            .thenAnswer((_) async => false);
        when(() => mockPermissionService.requestHealthKitPermissions(permissions))
            .thenAnswer((_) async => false);

        // Act
        final result = await healthKitDataSource.requestPermissions(permissions);

        // Assert
        expect(result, isFalse);
      });

      test('should check specific permission status', () async {
        // Arrange
        const permissionType = 'workouts';
        when(() => mockHealthKit.isAuthorized(permissionType))
            .thenAnswer((_) async => true);
        when(() => mockPermissionService.isHealthKitAuthorized(permissionType))
            .thenAnswer((_) async => true);

        // Act
        final result = await healthKitDataSource.isAuthorized(permissionType);

        // Assert
        expect(result, isTrue);
        verify(() => mockPermissionService.isHealthKitAuthorized(permissionType)).called(1);
      });

      test('should get all permission statuses', () async {
        // Arrange
        final permissions = ['workouts', 'heartRate', 'steps'];
        when(() => mockPermissionService.getAllHealthKitPermissions())
            .thenAnswer((_) async => {
              'workouts': true,
              'heartRate': true,
              'steps': false,
            });

        // Act
        final result = await healthKitDataSource.getPermissionStatuses(permissions);

        // Assert
        expect(result['workouts'], isTrue);
        expect(result['heartRate'], isTrue);
        expect(result['steps'], isFalse);
        verify(() => mockPermissionService.getAllHealthKitPermissions()).called(1);
      });

      test('should handle permission check errors gracefully', () async {
        // Arrange
        const permissionType = 'workouts';
        when(() => mockPermissionService.isHealthKitAuthorized(permissionType))
            .thenThrow(Exception('Permission check failed'));

        // Act
        final result = await healthKitDataSource.isAuthorized(permissionType);

        // Assert
        expect(result, isFalse);
      });
    });

    group('ワークアウトデータ取得', () {
      test('should fetch workout data successfully', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();
        final mockWorkouts = [
          {
            'id': 'workout-1',
            'type': 'running',
            'startDate': startDate.toIso8601String(),
            'endDate': startDate.add(const Duration(minutes: 30)).toIso8601String(),
            'duration': 1800, // 30 minutes in seconds
            'totalEnergyBurned': 250.0,
            'totalDistance': 5000.0, // 5km in meters
          },
          {
            'id': 'workout-2',
            'type': 'cycling',
            'startDate': startDate.add(const Duration(days: 1)).toIso8601String(),
            'endDate': startDate.add(const Duration(days: 1, minutes: 45)).toIso8601String(),
            'duration': 2700, // 45 minutes in seconds
            'totalEnergyBurned': 320.0,
            'totalDistance': 15000.0, // 15km in meters
          },
        ];

        when(() => mockHealthKit.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockWorkouts);

        // Act
        final result = await healthKitDataSource.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result[0]['type'], equals('running'));
        expect(result[0]['totalEnergyBurned'], equals(250.0));
        expect(result[1]['type'], equals('cycling'));
        expect(result[1]['duration'], equals(2700));
        verify(() => mockHealthKit.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        )).called(1);
      });

      test('should filter workouts by type', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();
        final mockWorkouts = [
          {
            'id': 'workout-1',
            'type': 'running',
            'totalEnergyBurned': 250.0,
          },
          {
            'id': 'workout-2',
            'type': 'cycling',
            'totalEnergyBurned': 320.0,
          },
          {
            'id': 'workout-3',
            'type': 'running',
            'totalEnergyBurned': 280.0,
          },
        ];

        when(() => mockHealthKit.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockWorkouts);

        // Act
        final result = await healthKitDataSource.getWorkoutsByType(
          'running',
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result.every((workout) => workout['type'] == 'running'), isTrue);
      });

      test('should calculate total calories from workouts', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();
        final mockWorkouts = [
          {'totalEnergyBurned': 250.0},
          {'totalEnergyBurned': 320.0},
          {'totalEnergyBurned': 180.0},
        ];

        when(() => mockHealthKit.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockWorkouts);

        // Act
        final result = await healthKitDataSource.getTotalCaloriesBurned(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, equals(750.0));
      });

      test('should handle empty workout data', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();

        when(() => mockHealthKit.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => []);

        // Act
        final result = await healthKitDataSource.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should handle workout data fetch errors', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();

        when(() => mockHealthKit.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        )).thenThrow(Exception('HealthKit error'));

        // Act & Assert
        expect(
          () => healthKitDataSource.getWorkouts(
            startDate: startDate,
            endDate: endDate,
          ),
          throwsException,
        );
      });
    });

    group('心拍数データ処理', () {
      test('should fetch heart rate data successfully', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(hours: 2));
        final endDate = DateTime.now();
        final mockHeartRateData = [
          {
            'value': 75.0,
            'unit': 'bpm',
            'timestamp': startDate.toIso8601String(),
          },
          {
            'value': 120.0,
            'unit': 'bpm',
            'timestamp': startDate.add(const Duration(minutes: 30)).toIso8601String(),
          },
          {
            'value': 85.0,
            'unit': 'bpm',
            'timestamp': startDate.add(const Duration(hours: 1)).toIso8601String(),
          },
        ];

        when(() => mockHealthKit.getHeartRateData(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockHeartRateData);

        // Act
        final result = await healthKitDataSource.getHeartRateData(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, hasLength(3));
        expect(result[0]['value'], equals(75.0));
        expect(result[1]['value'], equals(120.0));
        verify(() => mockHealthKit.getHeartRateData(
          startDate: startDate,
          endDate: endDate,
        )).called(1);
      });

      test('should calculate average heart rate', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(hours: 2));
        final endDate = DateTime.now();
        final mockHeartRateData = [
          {'value': 75.0},
          {'value': 120.0},
          {'value': 85.0},
          {'value': 90.0},
        ];

        when(() => mockHealthKit.getHeartRateData(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockHeartRateData);

        // Act
        final result = await healthKitDataSource.getAverageHeartRate(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, equals(92.5)); // (75+120+85+90)/4
      });

      test('should get heart rate zones', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(hours: 2));
        final endDate = DateTime.now();
        final mockHeartRateData = [
          {'value': 60.0}, // Zone 1: Resting
          {'value': 120.0}, // Zone 2: Fat burn
          {'value': 150.0}, // Zone 3: Cardio
          {'value': 180.0}, // Zone 4: Peak
          {'value': 75.0}, // Zone 1: Resting
        ];

        when(() => mockHealthKit.getHeartRateData(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockHeartRateData);

        // Act
        final result = await healthKitDataSource.getHeartRateZones(
          startDate: startDate,
          endDate: endDate,
          maxHeartRate: 200,
        );

        // Assert
        expect(result['resting'], equals(2)); // 60, 75
        expect(result['fatBurn'], equals(1)); // 120
        expect(result['cardio'], equals(1)); // 150
        expect(result['peak'], equals(1)); // 180
      });

      test('should detect heart rate anomalies', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(hours: 2));
        final endDate = DateTime.now();
        final mockHeartRateData = [
          {'value': 75.0, 'timestamp': startDate.toIso8601String()},
          {'value': 200.0, 'timestamp': startDate.add(const Duration(minutes: 10)).toIso8601String()}, // Anomaly
          {'value': 80.0, 'timestamp': startDate.add(const Duration(minutes: 20)).toIso8601String()},
          {'value': 30.0, 'timestamp': startDate.add(const Duration(minutes: 30)).toIso8601String()}, // Anomaly
        ];

        when(() => mockHealthKit.getHeartRateData(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockHeartRateData);

        // Act
        final result = await healthKitDataSource.detectHeartRateAnomalies(
          startDate: startDate,
          endDate: endDate,
          minNormal: 50,
          maxNormal: 180,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result[0]['value'], equals(200.0));
        expect(result[1]['value'], equals(30.0));
      });
    });

    group('ステップ・アクティビティデータ', () {
      test('should fetch steps data successfully', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 1));
        final endDate = DateTime.now();
        final mockStepsData = [
          {
            'value': 5000.0,
            'unit': 'count',
            'timestamp': startDate.toIso8601String(),
          },
          {
            'value': 8500.0,
            'unit': 'count',
            'timestamp': startDate.add(const Duration(hours: 12)).toIso8601String(),
          },
        ];

        when(() => mockHealthKit.getStepsData(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockStepsData);

        // Act
        final result = await healthKitDataSource.getStepsData(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result[0]['value'], equals(5000.0));
        expect(result[1]['value'], equals(8500.0));
      });

      test('should calculate total daily steps', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 1));
        final endDate = DateTime.now();
        final mockStepsData = [
          {'value': 3000.0},
          {'value': 2500.0},
          {'value': 1800.0},
        ];

        when(() => mockHealthKit.getStepsData(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockStepsData);

        // Act
        final result = await healthKitDataSource.getTotalSteps(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, equals(7300.0));
      });
    });

    group('カロリー計算の精度', () {
      test('should calculate accurate calories for running', () async {
        // Arrange
        const userWeight = 70.0; // kg
        const duration = 30.0; // minutes
        const distance = 5.0; // km
        const avgHeartRate = 150.0;

        // Act
        final result = await healthKitDataSource.calculateAccurateCalories(
          workoutType: 'running',
          duration: duration,
          userWeight: userWeight,
          distance: distance,
          averageHeartRate: avgHeartRate,
        );

        // Assert
        expect(result, greaterThan(250.0)); // Reasonable for 30min run
        expect(result, lessThan(400.0));
      });

      test('should adjust calories based on heart rate zones', () async {
        // Arrange
        const userWeight = 70.0;
        const duration = 30.0;
        const baseCalories = 250.0;

        // Act - High intensity (cardio zone)
        final highIntensityCalories = await healthKitDataSource.adjustCaloriesForHeartRate(
          baseCalories: baseCalories,
          averageHeartRate: 160.0,
          maxHeartRate: 190.0,
          age: 30,
        );

        // Act - Low intensity (fat burn zone)
        final lowIntensityCalories = await healthKitDataSource.adjustCaloriesForHeartRate(
          baseCalories: baseCalories,
          averageHeartRate: 120.0,
          maxHeartRate: 190.0,
          age: 30,
        );

        // Assert
        expect(highIntensityCalories, greaterThan(baseCalories));
        expect(lowIntensityCalories, lessThan(highIntensityCalories));
      });

      test('should validate calorie calculation inputs', () async {
        // Act & Assert - Invalid weight
        expect(
          () => healthKitDataSource.calculateAccurateCalories(
            workoutType: 'running',
            duration: 30.0,
            userWeight: 0.0, // Invalid
            distance: 5.0,
            averageHeartRate: 150.0,
          ),
          throwsArgumentError,
        );

        // Act & Assert - Invalid duration
        expect(
          () => healthKitDataSource.calculateAccurateCalories(
            workoutType: 'running',
            duration: -10.0, // Invalid
            userWeight: 70.0,
            distance: 5.0,
            averageHeartRate: 150.0,
          ),
          throwsArgumentError,
        );
      });

      test('should handle different workout types', () async {
        // Arrange
        const userWeight = 70.0;
        const duration = 30.0;

        // Act
        final runningCalories = await healthKitDataSource.calculateAccurateCalories(
          workoutType: 'running',
          duration: duration,
          userWeight: userWeight,
          distance: 5.0,
          averageHeartRate: 150.0,
        );

        final cyclingCalories = await healthKitDataSource.calculateAccurateCalories(
          workoutType: 'cycling',
          duration: duration,
          userWeight: userWeight,
          distance: 15.0,
          averageHeartRate: 140.0,
        );

        final swimmingCalories = await healthKitDataSource.calculateAccurateCalories(
          workoutType: 'swimming',
          duration: duration,
          userWeight: userWeight,
          averageHeartRate: 160.0,
        );

        // Assert
        expect(runningCalories, greaterThan(0));
        expect(cyclingCalories, greaterThan(0));
        expect(swimmingCalories, greaterThan(0));
        // Swimming typically burns more calories than cycling
        expect(swimmingCalories, greaterThan(cyclingCalories));
      });
    });

    group('データ同期とキャッシュ', () {
      test('should sync health data to local database', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 1));
        final endDate = DateTime.now();
        final mockWorkouts = [
          TestHelper.generateActivityData(),
        ];
        final mockHeartRateData = [
          {'value': 75.0, 'timestamp': startDate.toIso8601String()},
        ];
        final mockStepsData = [
          {'value': 5000.0, 'timestamp': startDate.toIso8601String()},
        ];

        when(() => mockHealthKit.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockWorkouts);
        when(() => mockHealthKit.getHeartRateData(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockHeartRateData);
        when(() => mockHealthKit.getStepsData(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => mockStepsData);

        // Act
        final result = await healthKitDataSource.syncHealthDataToLocal(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result['syncedWorkouts'], equals(1));
        expect(result['syncedHeartRate'], equals(1));
        expect(result['syncedSteps'], equals(1));
        expect(result['status'], equals('success'));
      });

      test('should handle sync errors gracefully', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 1));
        final endDate = DateTime.now();

        when(() => mockHealthKit.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        )).thenThrow(Exception('Sync failed'));
        when(() => mockHealthKit.getHeartRateData(
          startDate: startDate,
          endDate: endDate,
        )).thenThrow(Exception('Heart rate sync failed'));
        when(() => mockHealthKit.getStepsData(
          startDate: startDate,
          endDate: endDate,
        )).thenThrow(Exception('Steps sync failed'));

        // Act
        final result = await healthKitDataSource.syncHealthDataToLocal(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result['status'], equals('success'));
        expect(result['syncedWorkouts'], equals(0));
        expect(result['syncedHeartRate'], equals(0));
        expect(result['syncedSteps'], equals(0));
      });

      test('should cache health data for offline access', () async {
        // Arrange
        final mockWorkouts = [TestHelper.generateActivityData()];
        const cacheKey = 'workouts_2024_01_01';

        // Act
        await healthKitDataSource.cacheHealthData(cacheKey, mockWorkouts);
        final cachedData = await healthKitDataSource.getCachedHealthData(cacheKey);

        // Assert
        expect(cachedData, isNotNull);
        expect(cachedData, hasLength(1));
      });
    });

    group('エラーハンドリング', () {
      test('should handle HealthKit unavailable error', () async {
        // Arrange
        when(() => mockPermissionService.isHealthKitAvailable())
            .thenAnswer((_) async => false);

        // Act
        final result = await healthKitDataSource.isHealthKitAvailable();

        // Assert
        expect(result, isFalse);
      });

      test('should retry failed operations', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 1));
        final endDate = DateTime.now();

        var callCount = 0;
        when(() => mockHealthKit.getWorkouts(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async {
          callCount++;
          if (callCount <= 2) {
            throw Exception('Temporary error');
          }
          return [TestHelper.generateActivityData()];
        });

        // Act
        final result = await healthKitDataSource.getWorkoutsWithRetry(
          startDate: startDate,
          endDate: endDate,
          maxRetries: 3,
        );

        // Assert
        expect(result, hasLength(1));
        expect(callCount, equals(3));
      });

      test('should respect rate limits', () async {
        // Arrange
        final startTime = DateTime.now();

        // Act
        await healthKitDataSource.respectRateLimit();
        await healthKitDataSource.respectRateLimit();

        final endTime = DateTime.now();
        final elapsed = endTime.difference(startTime);

        // Assert
        expect(elapsed.inMilliseconds, greaterThan(100)); // Some delay expected
      });
    });
  });
}