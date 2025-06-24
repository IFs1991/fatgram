import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fatgram/data/datasources/health/health_connect_datasource.dart';
import 'package:fatgram/domain/services/health_permission_service.dart';
import '../../../test_helper.dart';

// MockHealthConnect (Android Health Connect API Mock)
class MockHealthConnect extends Mock {
  Future<bool> isAvailable();
  Future<bool> requestPermissions(List<String> permissions);
  Future<bool> isPermissionGranted(String permission);
  Future<List<Map<String, dynamic>>> readWorkouts({
    DateTime? startTime,
    DateTime? endTime,
  });
  Future<List<Map<String, dynamic>>> readHeartRateSamples({
    DateTime? startTime,
    DateTime? endTime,
  });
  Future<List<Map<String, dynamic>>> readStepsSamples({
    DateTime? startTime,
    DateTime? endTime,
  });
  Future<void> writeWorkout(Map<String, dynamic> workout);
  Future<void> enableBackgroundSync();
}

class MockHealthPermissionService extends Mock implements HealthPermissionService {}

void main() {
  late HealthConnectDataSource healthConnectDataSource;
  late MockHealthConnect mockHealthConnect;
  late MockHealthPermissionService mockPermissionService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(<String>[]);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockHealthConnect = MockHealthConnect();
    mockPermissionService = MockHealthPermissionService();
    healthConnectDataSource = HealthConnectDataSource(
      healthConnect: mockHealthConnect,
      permissionService: mockPermissionService,
    );
  });

  group('HealthConnectDataSource', () {
    group('Android権限の取得', () {
      test('should check Health Connect availability', () async {
        // Arrange
        when(() => mockHealthConnect.isAvailable())
            .thenAnswer((_) async => true);
        when(() => mockPermissionService.isHealthConnectAvailable())
            .thenAnswer((_) async => true);

        // Act
        final result = await healthConnectDataSource.isHealthConnectAvailable();

        // Assert
        expect(result, isTrue);
        verify(() => mockPermissionService.isHealthConnectAvailable()).called(1);
        verify(() => mockHealthConnect.isAvailable()).called(1);
      });

      test('should handle Health Connect unavailable', () async {
        // Arrange
        when(() => mockHealthConnect.isAvailable())
            .thenAnswer((_) async => false);
        when(() => mockPermissionService.isHealthConnectAvailable())
            .thenAnswer((_) async => false);

        // Act
        final result = await healthConnectDataSource.isHealthConnectAvailable();

        // Assert
        expect(result, isFalse);
      });

      test('should request Health Connect permissions successfully', () async {
        // Arrange
        final permissions = ['android.permission.health.READ_EXERCISE'];
        when(() => mockHealthConnect.requestPermissions(permissions))
            .thenAnswer((_) async => true);
        when(() => mockPermissionService.requestHealthConnectPermissions(permissions))
            .thenAnswer((_) async => true);

        // Act
        final result = await healthConnectDataSource.requestPermissions(permissions);

        // Assert
        expect(result, isTrue);
        verify(() => mockPermissionService.requestHealthConnectPermissions(permissions)).called(1);
        verify(() => mockHealthConnect.requestPermissions(permissions)).called(1);
      });

      test('should handle permission request failure', () async {
        // Arrange
        final permissions = ['android.permission.health.READ_EXERCISE'];
        when(() => mockHealthConnect.requestPermissions(permissions))
            .thenAnswer((_) async => false);
        when(() => mockPermissionService.requestHealthConnectPermissions(permissions))
            .thenAnswer((_) async => false);

        // Act
        final result = await healthConnectDataSource.requestPermissions(permissions);

        // Assert
        expect(result, isFalse);
      });

      test('should check specific permission status', () async {
        // Arrange
        const permission = 'android.permission.health.READ_EXERCISE';
        when(() => mockHealthConnect.isPermissionGranted(permission))
            .thenAnswer((_) async => true);
        when(() => mockPermissionService.isHealthConnectAuthorized(permission))
            .thenAnswer((_) async => true);

        // Act
        final result = await healthConnectDataSource.isPermissionGranted(permission);

        // Assert
        expect(result, isTrue);
        verify(() => mockPermissionService.isHealthConnectAuthorized(permission)).called(1);
      });

      test('should get all permission statuses', () async {
        // Arrange
        final permissions = [
          'android.permission.health.READ_EXERCISE',
          'android.permission.health.READ_HEART_RATE',
          'android.permission.health.READ_STEPS',
        ];
        when(() => mockPermissionService.getAllHealthConnectPermissions())
            .thenAnswer((_) async => {
              'android.permission.health.READ_EXERCISE': true,
              'android.permission.health.READ_HEART_RATE': true,
              'android.permission.health.READ_STEPS': false,
            });

        // Act
        final result = await healthConnectDataSource.getPermissionStatuses(permissions);

        // Assert
        expect(result['android.permission.health.READ_EXERCISE'], isTrue);
        expect(result['android.permission.health.READ_HEART_RATE'], isTrue);
        expect(result['android.permission.health.READ_STEPS'], isFalse);
        verify(() => mockPermissionService.getAllHealthConnectPermissions()).called(1);
      });

      test('should handle permission errors gracefully', () async {
        // Arrange
        const permission = 'android.permission.health.READ_EXERCISE';
        when(() => mockPermissionService.isHealthConnectAuthorized(permission))
            .thenThrow(Exception('Permission check failed'));

        // Act
        final result = await healthConnectDataSource.isPermissionGranted(permission);

        // Assert
        expect(result, isFalse);
      });
    });

    group('データタイプのマッピング', () {
      test('should map workout types correctly', () async {
        // Act
        final runningType = healthConnectDataSource.mapWorkoutType('running');
        final cyclingType = healthConnectDataSource.mapWorkoutType('cycling');
        final swimmingType = healthConnectDataSource.mapWorkoutType('swimming');
        final unknownType = healthConnectDataSource.mapWorkoutType('unknown');

        // Assert
        expect(runningType, equals('androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_RUNNING'));
        expect(cyclingType, equals('androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_BIKING'));
        expect(swimmingType, equals('androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL'));
        expect(unknownType, equals('androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_OTHER_WORKOUT'));
      });

      test('should map data units correctly', () async {
        // Act
        final heartRateUnit = healthConnectDataSource.mapDataUnit('heartRate');
        final stepsUnit = healthConnectDataSource.mapDataUnit('steps');
        final caloriesUnit = healthConnectDataSource.mapDataUnit('calories');
        final distanceUnit = healthConnectDataSource.mapDataUnit('distance');

        // Assert
        expect(heartRateUnit, equals('beats_per_minute'));
        expect(stepsUnit, equals('count'));
        expect(caloriesUnit, equals('kilocalories'));
        expect(distanceUnit, equals('meters'));
      });

      test('should validate data type compatibility', () async {
        // Act
        final isHeartRateSupported = healthConnectDataSource.isDataTypeSupported('heartRate');
        final isStepsSupported = healthConnectDataSource.isDataTypeSupported('steps');
        final isUnsupported = healthConnectDataSource.isDataTypeSupported('unsupported');

        // Assert
        expect(isHeartRateSupported, isTrue);
        expect(isStepsSupported, isTrue);
        expect(isUnsupported, isFalse);
      });

      test('should convert Health Connect data to standard format', () async {
        // Arrange
        final healthConnectData = {
          'recordType': 'ExerciseSessionRecord',
          'startTime': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'endTime': DateTime.now().toIso8601String(),
          'exerciseType': 'EXERCISE_TYPE_RUNNING',
          'totalEnergyBurned': {'value': 250.0, 'unit': 'kilocalories'},
          'title': 'Morning Run',
        };

        // Act
        final standardData = healthConnectDataSource.convertToStandardFormat(healthConnectData);

        // Assert
        expect(standardData['type'], equals('running'));
        expect(standardData['totalEnergyBurned'], equals(250.0));
        expect(standardData['name'], equals('Morning Run'));
        expect(standardData['source'], equals('health_connect'));
      });
    });

    group('ワークアウトデータ取得', () {
      test('should read workout data successfully', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 7));
        final endTime = DateTime.now();
        final mockWorkouts = [
          {
            'recordType': 'ExerciseSessionRecord',
            'startTime': startTime.toIso8601String(),
            'endTime': startTime.add(const Duration(minutes: 30)).toIso8601String(),
            'exerciseType': 'EXERCISE_TYPE_RUNNING',
            'totalEnergyBurned': {'value': 250.0, 'unit': 'kilocalories'},
            'title': 'Morning Run',
          },
          {
            'recordType': 'ExerciseSessionRecord',
            'startTime': startTime.add(const Duration(days: 1)).toIso8601String(),
            'endTime': startTime.add(const Duration(days: 1, minutes: 45)).toIso8601String(),
            'exerciseType': 'EXERCISE_TYPE_BIKING',
            'totalEnergyBurned': {'value': 320.0, 'unit': 'kilocalories'},
            'title': 'Cycling Session',
          },
        ];

        when(() => mockHealthConnect.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockWorkouts);

        // Act
        final result = await healthConnectDataSource.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result[0]['type'], equals('running'));
        expect(result[0]['totalEnergyBurned'], equals(250.0));
        expect(result[1]['type'], equals('cycling'));
        expect(result[1]['totalEnergyBurned'], equals(320.0));
        verify(() => mockHealthConnect.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        )).called(1);
      });

      test('should filter workouts by type', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 7));
        final endTime = DateTime.now();
        final mockWorkouts = [
          {
            'recordType': 'ExerciseSessionRecord',
            'exerciseType': 'EXERCISE_TYPE_RUNNING',
            'totalEnergyBurned': {'value': 250.0, 'unit': 'kilocalories'},
          },
          {
            'recordType': 'ExerciseSessionRecord',
            'exerciseType': 'EXERCISE_TYPE_BIKING',
            'totalEnergyBurned': {'value': 320.0, 'unit': 'kilocalories'},
          },
          {
            'recordType': 'ExerciseSessionRecord',
            'exerciseType': 'EXERCISE_TYPE_RUNNING',
            'totalEnergyBurned': {'value': 280.0, 'unit': 'kilocalories'},
          },
        ];

        when(() => mockHealthConnect.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockWorkouts);

        // Act
        final result = await healthConnectDataSource.readWorkoutsByType(
          'running',
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result.every((workout) => workout['type'] == 'running'), isTrue);
      });

      test('should calculate total calories from workouts', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 7));
        final endTime = DateTime.now();
        final mockWorkouts = [
          {
            'recordType': 'ExerciseSessionRecord',
            'totalEnergyBurned': {'value': 250.0, 'unit': 'kilocalories'},
          },
          {
            'recordType': 'ExerciseSessionRecord',
            'totalEnergyBurned': {'value': 320.0, 'unit': 'kilocalories'},
          },
          {
            'recordType': 'ExerciseSessionRecord',
            'totalEnergyBurned': {'value': 180.0, 'unit': 'kilocalories'},
          },
        ];

        when(() => mockHealthConnect.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockWorkouts);

        // Act
        final result = await healthConnectDataSource.getTotalCaloriesBurned(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, equals(750.0));
      });

      test('should handle empty workout data', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 7));
        final endTime = DateTime.now();

        when(() => mockHealthConnect.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => []);

        // Act
        final result = await healthConnectDataSource.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should handle workout data read errors', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 7));
        final endTime = DateTime.now();

        when(() => mockHealthConnect.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        )).thenThrow(Exception('Health Connect read error'));

        // Act & Assert
        expect(
          () => healthConnectDataSource.readWorkouts(
            startTime: startTime,
            endTime: endTime,
          ),
          throwsException,
        );
      });
    });

    group('心拍数データ取得', () {
      test('should read heart rate data successfully', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 2));
        final endTime = DateTime.now();
        final mockHeartRateData = [
          {
            'recordType': 'HeartRateRecord',
            'samples': [
              {
                'time': startTime.toIso8601String(),
                'beatsPerMinute': 75.0,
              },
              {
                'time': startTime.add(const Duration(minutes: 30)).toIso8601String(),
                'beatsPerMinute': 120.0,
              },
            ],
          },
        ];

        when(() => mockHealthConnect.readHeartRateSamples(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockHeartRateData);

        // Act
        final result = await healthConnectDataSource.readHeartRateData(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result[0]['value'], equals(75.0));
        expect(result[1]['value'], equals(120.0));
        verify(() => mockHealthConnect.readHeartRateSamples(
          startTime: startTime,
          endTime: endTime,
        )).called(1);
      });

      test('should calculate average heart rate', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 2));
        final endTime = DateTime.now();
        final mockHeartRateData = [
          {
            'recordType': 'HeartRateRecord',
            'samples': [
              {'beatsPerMinute': 75.0},
              {'beatsPerMinute': 120.0},
              {'beatsPerMinute': 85.0},
              {'beatsPerMinute': 90.0},
            ],
          },
        ];

        when(() => mockHealthConnect.readHeartRateSamples(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockHeartRateData);

        // Act
        final result = await healthConnectDataSource.getAverageHeartRate(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, equals(92.5)); // (75+120+85+90)/4
      });

      test('should detect heart rate anomalies', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 2));
        final endTime = DateTime.now();
        final mockHeartRateData = [
          {
            'recordType': 'HeartRateRecord',
            'samples': [
              {'beatsPerMinute': 75.0, 'time': startTime.toIso8601String()},
              {'beatsPerMinute': 200.0, 'time': startTime.add(const Duration(minutes: 10)).toIso8601String()}, // Anomaly
              {'beatsPerMinute': 80.0, 'time': startTime.add(const Duration(minutes: 20)).toIso8601String()},
              {'beatsPerMinute': 30.0, 'time': startTime.add(const Duration(minutes: 30)).toIso8601String()}, // Anomaly
            ],
          },
        ];

        when(() => mockHealthConnect.readHeartRateSamples(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockHeartRateData);

        // Act
        final result = await healthConnectDataSource.detectHeartRateAnomalies(
          startTime: startTime,
          endTime: endTime,
          minNormal: 50,
          maxNormal: 180,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result[0]['value'], equals(200.0));
        expect(result[1]['value'], equals(30.0));
      });
    });

    group('ステップデータ取得', () {
      test('should read steps data successfully', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 1));
        final endTime = DateTime.now();
        final mockStepsData = [
          {
            'recordType': 'StepsRecord',
            'count': 5000,
            'startTime': startTime.toIso8601String(),
            'endTime': startTime.add(const Duration(hours: 12)).toIso8601String(),
          },
          {
            'recordType': 'StepsRecord',
            'count': 8500,
            'startTime': startTime.add(const Duration(hours: 12)).toIso8601String(),
            'endTime': endTime.toIso8601String(),
          },
        ];

        when(() => mockHealthConnect.readStepsSamples(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockStepsData);

        // Act
        final result = await healthConnectDataSource.readStepsData(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, hasLength(2));
        expect(result[0]['value'], equals(5000.0));
        expect(result[1]['value'], equals(8500.0));
      });

      test('should calculate total daily steps', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 1));
        final endTime = DateTime.now();
        final mockStepsData = [
          {'recordType': 'StepsRecord', 'count': 3000},
          {'recordType': 'StepsRecord', 'count': 2500},
          {'recordType': 'StepsRecord', 'count': 1800},
        ];

        when(() => mockHealthConnect.readStepsSamples(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockStepsData);

        // Act
        final result = await healthConnectDataSource.getTotalSteps(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, equals(7300.0));
      });
    });

    group('バックグラウンド同期', () {
      test('should enable background sync successfully', () async {
        // Arrange
        when(() => mockHealthConnect.enableBackgroundSync())
            .thenAnswer((_) async {});

        // Act
        await healthConnectDataSource.enableBackgroundSync();

        // Assert
        verify(() => mockHealthConnect.enableBackgroundSync()).called(1);
      });

      test('should handle background sync errors', () async {
        // Arrange
        when(() => mockHealthConnect.enableBackgroundSync())
            .thenThrow(Exception('Background sync failed'));

        // Act & Assert
        expect(
          () => healthConnectDataSource.enableBackgroundSync(),
          throwsException,
        );
      });

      test('should check background sync status', () async {
        // Act
        final isEnabled = await healthConnectDataSource.isBackgroundSyncEnabled();

        // Assert - Default implementation returns false until properly configured
        expect(isEnabled, isFalse);
      });

      test('should configure background sync interval', () async {
        // Arrange
        const intervalMinutes = 15;

        // Act
        await healthConnectDataSource.configureBackgroundSync(
          intervalMinutes: intervalMinutes,
          syncOnWifiOnly: true,
        );

        // Assert - Verify configuration is stored
        final config = healthConnectDataSource.getBackgroundSyncConfig();
        expect(config['intervalMinutes'], equals(intervalMinutes));
        expect(config['syncOnWifiOnly'], isTrue);
      });
    });

    group('データ書き込み', () {
      test('should write workout data successfully', () async {
        // Arrange
        final workoutData = {
          'type': 'running',
          'startTime': DateTime.now().subtract(const Duration(hours: 1)),
          'endTime': DateTime.now(),
          'totalEnergyBurned': 250.0,
          'distance': 5000.0,
          'title': 'Morning Run',
        };

        when(() => mockHealthConnect.writeWorkout(any()))
            .thenAnswer((_) async {});

        // Act
        await healthConnectDataSource.writeWorkout(workoutData);

        // Assert
        verify(() => mockHealthConnect.writeWorkout(any())).called(1);
      });

      test('should handle workout write errors', () async {
        // Arrange
        final workoutData = {
          'type': 'running',
          'startTime': DateTime.now().subtract(const Duration(hours: 1)),
          'endTime': DateTime.now(),
        };

        when(() => mockHealthConnect.writeWorkout(any()))
            .thenThrow(Exception('Write failed'));

        // Act & Assert
        expect(
          () => healthConnectDataSource.writeWorkout(workoutData),
          throwsException,
        );
      });

      test('should validate workout data before writing', () async {
        // Arrange - Invalid data missing required fields
        final invalidWorkoutData = {
          'type': 'running',
          // Missing startTime and endTime
        };

        // Act & Assert
        expect(
          () => healthConnectDataSource.writeWorkout(invalidWorkoutData),
          throwsArgumentError,
        );
      });

      test('should convert standard format to Health Connect format', () async {
        // Arrange
        final standardData = {
          'type': 'running',
          'startTime': DateTime.now().subtract(const Duration(hours: 1)),
          'endTime': DateTime.now(),
          'totalEnergyBurned': 250.0,
          'distance': 5000.0,
          'title': 'Morning Run',
        };

        // Act
        final healthConnectData = healthConnectDataSource.convertFromStandardFormat(standardData);

        // Assert
        expect(healthConnectData['recordType'], equals('ExerciseSessionRecord'));
        expect(healthConnectData['exerciseType'], equals('androidx.health.connect.client.records.ExerciseSessionRecord.EXERCISE_TYPE_RUNNING'));
        expect(healthConnectData['totalEnergyBurned']['value'], equals(250.0));
        expect(healthConnectData['totalEnergyBurned']['unit'], equals('kilocalories'));
      });
    });

    group('エラーハンドリングとリトライ', () {
      test('should handle Health Connect unavailable gracefully', () async {
        // Arrange
        when(() => mockPermissionService.isHealthConnectAvailable())
            .thenAnswer((_) async => false);

        // Act
        final result = await healthConnectDataSource.isHealthConnectAvailable();

        // Assert
        expect(result, isFalse);
      });

      test('should retry failed operations', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 1));
        final endTime = DateTime.now();

        var callCount = 0;
        when(() => mockHealthConnect.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async {
          callCount++;
          if (callCount <= 2) {
            throw Exception('Temporary error');
          }
          return [TestHelper.generateActivityData()];
        });

        // Act
        final result = await healthConnectDataSource.readWorkoutsWithRetry(
          startTime: startTime,
          endTime: endTime,
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
        await healthConnectDataSource.respectRateLimit();
        await healthConnectDataSource.respectRateLimit();

        final endTime = DateTime.now();
        final elapsed = endTime.difference(startTime);

        // Assert
        expect(elapsed.inMilliseconds, greaterThan(100)); // Some delay expected
      });

      test('should handle permission denied errors', () async {
        // Arrange
        final permissions = ['android.permission.health.READ_EXERCISE'];
        when(() => mockHealthConnect.requestPermissions(permissions))
            .thenThrow(Exception('Permission denied'));

        // Act
        final result = await healthConnectDataSource.requestPermissions(permissions);

        // Assert
        expect(result, isFalse);
      });

      test('should handle network connectivity issues', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 1));
        final endTime = DateTime.now();

        when(() => mockHealthConnect.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        )).thenThrow(Exception('Network error'));

        // Act
        final result = await healthConnectDataSource.readWorkoutsWithFallback(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result, isEmpty); // Fallback returns empty list
      });
    });

    group('データ同期とキャッシュ', () {
      test('should sync Health Connect data to local storage', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(days: 1));
        final endTime = DateTime.now();
        final mockWorkouts = [TestHelper.generateActivityData()];
        final mockHeartRateData = [
          {'recordType': 'HeartRateRecord', 'samples': [{'beatsPerMinute': 75.0}]},
        ];
        final mockStepsData = [
          {'recordType': 'StepsRecord', 'count': 5000},
        ];

        when(() => mockHealthConnect.readWorkouts(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockWorkouts);
        when(() => mockHealthConnect.readHeartRateSamples(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockHeartRateData);
        when(() => mockHealthConnect.readStepsSamples(
          startTime: startTime,
          endTime: endTime,
        )).thenAnswer((_) async => mockStepsData);

        // Act
        final result = await healthConnectDataSource.syncToLocalStorage(
          startTime: startTime,
          endTime: endTime,
        );

        // Assert
        expect(result['status'], equals('success'));
        expect(result['syncedWorkouts'], equals(1));
        expect(result['syncedHeartRate'], equals(1));
        expect(result['syncedSteps'], equals(1));
      });

      test('should cache data for offline access', () async {
        // Arrange
        final mockData = [TestHelper.generateActivityData()];
        const cacheKey = 'health_connect_workouts_2024_01_01';

        // Act
        await healthConnectDataSource.cacheData(cacheKey, mockData);
        final cachedData = await healthConnectDataSource.getCachedData(cacheKey);

        // Assert
        expect(cachedData, isNotNull);
        expect(cachedData, hasLength(1));
      });

      test('should handle cache expiration', () async {
        // Arrange
        final expiredData = [TestHelper.generateActivityData()];
        const cacheKey = 'expired_data';
        final expiredTime = DateTime.now().subtract(const Duration(hours: 25));

        // Act
        await healthConnectDataSource.cacheDataWithExpiry(
          cacheKey,
          expiredData,
          expiryTime: expiredTime,
        );
        final cachedData = await healthConnectDataSource.getCachedData(cacheKey);

        // Assert
        expect(cachedData, isNull); // Should be null due to expiration
      });
    });
  });
}