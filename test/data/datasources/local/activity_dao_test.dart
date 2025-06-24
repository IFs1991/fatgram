import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fatgram/data/datasources/local/database/activity_dao.dart';
import 'package:fatgram/data/datasources/local/database/database_helper.dart';
import '../../../test_helper.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  late ActivityDao activityDao;
  late MockDatabaseHelper mockDatabaseHelper;

  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(<Object?>[]);
  });

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    activityDao = ActivityDao(mockDatabaseHelper);
  });

  group('ActivityDao', () {
    group('アクティビティの作成', () {
      test('should create activity successfully', () async {
        // Arrange
        final activityData = TestHelper.generateActivityData();
        const expectedId = 1;
        when(() => mockDatabaseHelper.insert(any(), any())).thenAnswer((_) async => expectedId);

        // Act
        final id = await activityDao.createActivity(activityData);

        // Assert
        expect(id, equals(expectedId));
        verify(() => mockDatabaseHelper.insert('activities', any(that: allOf([
          containsPair('id', activityData['id']),
          containsPair('name', activityData['name']),
          containsPair('type', activityData['type']),
          containsPair('duration', activityData['duration']),
          containsPair('calories', activityData['calories']),
        ])))).called(1);
      });

      test('should handle activity creation error', () async {
        // Arrange
        final activityData = TestHelper.generateActivityData();
        when(() => mockDatabaseHelper.insert(any(), any())).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => activityDao.createActivity(activityData),
          throwsException,
        );
      });
    });

    group('アクティビティの取得', () {
      test('should get activity by id successfully', () async {
        // Arrange
        const activityId = 'activity-123';
        final expectedActivity = {
          'id': activityId,
          'name': 'Morning Run',
          'type': 'running',
          'duration': 30,
          'calories': 250.5,
          'heartRate': 150,
          'startTime': '2024-01-01T06:00:00Z',
          'endTime': '2024-01-01T06:30:00Z',
          'syncStatus': 0,
          'createdAt': '2024-01-01T06:30:00Z',
          'updatedAt': '2024-01-01T06:30:00Z',
        };

        when(() => mockDatabaseHelper.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => [expectedActivity]);

        // Act
        final activity = await activityDao.getActivityById(activityId);

        // Assert
        expect(activity, isNotNull);
        expect(activity!['id'], equals(activityId));
        expect(activity['name'], equals('Morning Run'));
        verify(() => mockDatabaseHelper.query(
          'activities',
          where: 'id = ?',
          whereArgs: [activityId],
          limit: 1,
        )).called(1);
      });

      test('should return null when activity not found', () async {
        // Arrange
        const activityId = 'non-existent';
        when(() => mockDatabaseHelper.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => []);

        // Act
        final activity = await activityDao.getActivityById(activityId);

        // Assert
        expect(activity, isNull);
      });

      test('should get all activities successfully', () async {
        // Arrange
        final expectedActivities = [
          TestHelper.generateActivityData(),
          TestHelper.generateActivityData(),
          TestHelper.generateActivityData(),
        ];

        when(() => mockDatabaseHelper.query(
          any(),
          orderBy: any(named: 'orderBy'),
        )).thenAnswer((_) async => expectedActivities);

        // Act
        final activities = await activityDao.getAllActivities();

        // Assert
        expect(activities, hasLength(3));
        verify(() => mockDatabaseHelper.query(
          'activities',
          orderBy: 'startTime DESC',
        )).called(1);
      });

      test('should get activities by type successfully', () async {
        // Arrange
        const activityType = 'running';
        final expectedActivities = [
          TestHelper.generateActivityData()..['type'] = activityType,
          TestHelper.generateActivityData()..['type'] = activityType,
        ];

        when(() => mockDatabaseHelper.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
          orderBy: any(named: 'orderBy'),
        )).thenAnswer((_) async => expectedActivities);

        // Act
        final activities = await activityDao.getActivitiesByType(activityType);

        // Assert
        expect(activities, hasLength(2));
        expect(activities.every((a) => a['type'] == activityType), isTrue);
        verify(() => mockDatabaseHelper.query(
          'activities',
          where: 'type = ?',
          whereArgs: [activityType],
          orderBy: 'startTime DESC',
        )).called(1);
      });

      test('should get activities by date range successfully', () async {
        // Arrange
        final startDate = DateTime.parse('2024-01-01T00:00:00Z');
        final endDate = DateTime.parse('2024-01-31T23:59:59Z');
        final expectedActivities = [TestHelper.generateActivityData()];

        when(() => mockDatabaseHelper.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
          orderBy: any(named: 'orderBy'),
        )).thenAnswer((_) async => expectedActivities);

        // Act
        final activities = await activityDao.getActivitiesByDateRange(startDate, endDate);

        // Assert
        expect(activities, hasLength(1));
        verify(() => mockDatabaseHelper.query(
          'activities',
          where: 'startTime >= ? AND startTime <= ?',
          whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
          orderBy: 'startTime DESC',
        )).called(1);
      });

      test('should get recent activities successfully', () async {
        // Arrange
        const limit = 10;
        final expectedActivities = List.generate(5, (i) => TestHelper.generateActivityData());

        when(() => mockDatabaseHelper.query(
          any(),
          orderBy: any(named: 'orderBy'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => expectedActivities);

        // Act
        final activities = await activityDao.getRecentActivities(limit);

        // Assert
        expect(activities, hasLength(5));
        verify(() => mockDatabaseHelper.query(
          'activities',
          orderBy: 'startTime DESC',
          limit: limit,
        )).called(1);
      });
    });

    group('アクティビティの更新', () {
      test('should update activity successfully', () async {
        // Arrange
        const activityId = 'activity-123';
        final updateData = {
          'name': 'Updated Run',
          'duration': 45,
          'calories': 350.0,
          'updatedAt': DateTime.now().toIso8601String(),
        };
        const expectedRowsAffected = 1;

        when(() => mockDatabaseHelper.update(
          any(),
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => expectedRowsAffected);

        // Act
        final rowsAffected = await activityDao.updateActivity(activityId, updateData);

        // Assert
        expect(rowsAffected, equals(expectedRowsAffected));
        verify(() => mockDatabaseHelper.update(
          'activities',
          updateData,
          where: 'id = ?',
          whereArgs: [activityId],
        )).called(1);
      });

      test('should return 0 when updating non-existent activity', () async {
        // Arrange
        const activityId = 'non-existent';
        final updateData = {'name': 'Updated'};
        const expectedRowsAffected = 0;

        when(() => mockDatabaseHelper.update(
          any(),
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => expectedRowsAffected);

        // Act
        final rowsAffected = await activityDao.updateActivity(activityId, updateData);

        // Assert
        expect(rowsAffected, equals(0));
      });

      test('should update sync status successfully', () async {
        // Arrange
        const activityId = 'activity-123';
        const syncStatus = 1;
        const expectedRowsAffected = 1;

        when(() => mockDatabaseHelper.update(
          any(),
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => expectedRowsAffected);

        // Act
        final rowsAffected = await activityDao.updateSyncStatus(activityId, syncStatus);

        // Assert
        expect(rowsAffected, equals(expectedRowsAffected));
        verify(() => mockDatabaseHelper.update(
          'activities',
          any(that: containsPair('syncStatus', syncStatus)),
          where: 'id = ?',
          whereArgs: [activityId],
        )).called(1);
      });
    });

    group('アクティビティの削除', () {
      test('should delete activity successfully', () async {
        // Arrange
        const activityId = 'activity-123';
        const expectedRowsAffected = 1;

        when(() => mockDatabaseHelper.delete(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => expectedRowsAffected);

        // Act
        final rowsAffected = await activityDao.deleteActivity(activityId);

        // Assert
        expect(rowsAffected, equals(expectedRowsAffected));
        verify(() => mockDatabaseHelper.delete(
          'activities',
          where: 'id = ?',
          whereArgs: [activityId],
        )).called(1);
      });

      test('should delete activities by type successfully', () async {
        // Arrange
        const activityType = 'running';
        const expectedRowsAffected = 3;

        when(() => mockDatabaseHelper.delete(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => expectedRowsAffected);

        // Act
        final rowsAffected = await activityDao.deleteActivitiesByType(activityType);

        // Assert
        expect(rowsAffected, equals(expectedRowsAffected));
        verify(() => mockDatabaseHelper.delete(
          'activities',
          where: 'type = ?',
          whereArgs: [activityType],
        )).called(1);
      });

      test('should delete old activities successfully', () async {
        // Arrange
        final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
        const expectedRowsAffected = 5;

        when(() => mockDatabaseHelper.delete(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => expectedRowsAffected);

        // Act
        final rowsAffected = await activityDao.deleteOldActivities(cutoffDate);

        // Assert
        expect(rowsAffected, equals(expectedRowsAffected));
        verify(() => mockDatabaseHelper.delete(
          'activities',
          where: 'startTime < ?',
          whereArgs: [cutoffDate.toIso8601String()],
        )).called(1);
      });
    });

    group('統計情報', () {
      test('should get activity count successfully', () async {
        // Arrange
        const expectedCount = 42;
        when(() => mockDatabaseHelper.rawQuery(any())).thenAnswer((_) async => [
          {'COUNT(*)': expectedCount}
        ]);

        // Act
        final count = await activityDao.getActivityCount();

        // Assert
        expect(count, equals(expectedCount));
        verify(() => mockDatabaseHelper.rawQuery('SELECT COUNT(*) FROM activities')).called(1);
      });

      test('should get total calories successfully', () async {
        // Arrange
        const expectedCalories = 1500.5;
        when(() => mockDatabaseHelper.rawQuery(any())).thenAnswer((_) async => [
          {'SUM(calories)': expectedCalories}
        ]);

        // Act
        final calories = await activityDao.getTotalCalories();

        // Assert
        expect(calories, equals(expectedCalories));
        verify(() => mockDatabaseHelper.rawQuery('SELECT SUM(calories) FROM activities')).called(1);
      });

      test('should get activity statistics by type successfully', () async {
        // Arrange
        final expectedStats = [
          {'type': 'running', 'count': 10, 'total_calories': 1000.0, 'total_duration': 300},
          {'type': 'cycling', 'count': 5, 'total_calories': 800.0, 'total_duration': 150},
        ];

        when(() => mockDatabaseHelper.rawQuery(any())).thenAnswer((_) async => expectedStats);

        // Act
        final stats = await activityDao.getActivityStatsByType();

        // Assert
        expect(stats, hasLength(2));
        expect(stats[0]['type'], equals('running'));
        expect(stats[1]['type'], equals('cycling'));
        verify(() => mockDatabaseHelper.rawQuery(any(that: contains('GROUP BY type')))).called(1);
      });
    });

    group('同期機能', () {
      test('should get unsynchronized activities successfully', () async {
        // Arrange
        final expectedActivities = [
          TestHelper.generateActivityData()..['syncStatus'] = 0,
          TestHelper.generateActivityData()..['syncStatus'] = 0,
        ];

        when(() => mockDatabaseHelper.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
          orderBy: any(named: 'orderBy'),
        )).thenAnswer((_) async => expectedActivities);

        // Act
        final activities = await activityDao.getUnsynchronizedActivities();

        // Assert
        expect(activities, hasLength(2));
        expect(activities.every((a) => a['syncStatus'] == 0), isTrue);
        verify(() => mockDatabaseHelper.query(
          'activities',
          where: 'syncStatus = ?',
          whereArgs: [0],
          orderBy: 'createdAt ASC',
        )).called(1);
      });

      test('should mark activities as synchronized successfully', () async {
        // Arrange
        final activityIds = ['activity-1', 'activity-2', 'activity-3'];
        when(() => mockDatabaseHelper.executeInTransaction(any())).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          await callback();
        });
        when(() => mockDatabaseHelper.update(
          any(),
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => 1);

        // Act
        await activityDao.markAsSynchronized(activityIds);

        // Assert
        verify(() => mockDatabaseHelper.executeInTransaction(any())).called(1);
        verify(() => mockDatabaseHelper.update(
          'activities',
          any(that: containsPair('syncStatus', 1)),
          where: any(that: contains('id IN')),
          whereArgs: activityIds,
        )).called(1);
      });
    });

    group('エラーハンドリング', () {
      test('should handle database exception in query', () async {
        // Arrange
        when(() => mockDatabaseHelper.query(
          any(),
          orderBy: any(named: 'orderBy'),
        )).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => activityDao.getAllActivities(),
          throwsException,
        );
      });

      test('should handle null values gracefully', () async {
        // Arrange
        when(() => mockDatabaseHelper.rawQuery(any())).thenAnswer((_) async => [
          {'COUNT(*)': null}
        ]);

        // Act
        final count = await activityDao.getActivityCount();

        // Assert
        expect(count, equals(0));
      });
    });
  });
}