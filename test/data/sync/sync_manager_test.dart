import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fatgram/data/sync/sync_manager.dart';
import 'package:fatgram/data/sync/conflict_resolver.dart';
import 'package:fatgram/data/datasources/local/database/database_helper.dart';
import 'package:fatgram/data/datasources/local/shared_preferences_local_data_source.dart';
import '../../test_helper.dart';

class MockConnectivity extends Mock implements Connectivity {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockSharedPreferencesLocalDataSource extends Mock implements SharedPreferencesLocalDataSource {}
class MockConflictResolver extends Mock implements ConflictResolver {}

void main() {
  late SyncManager syncManager;
  late MockConnectivity mockConnectivity;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockSharedPreferencesLocalDataSource mockLocalDataSource;
  late MockConflictResolver mockConflictResolver;

  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(<Object?>[]);
    registerFallbackValue(ConnectivityResult.none);
  });

  setUp(() {
    mockConnectivity = MockConnectivity();
    mockDatabaseHelper = MockDatabaseHelper();
    mockLocalDataSource = MockSharedPreferencesLocalDataSource();
    mockConflictResolver = MockConflictResolver();

    syncManager = SyncManager(
      connectivity: mockConnectivity,
      databaseHelper: mockDatabaseHelper,
      localDataSource: mockLocalDataSource,
      conflictResolver: mockConflictResolver,
    );
  });

  group('SyncManager', () {
    group('接続状態の管理', () {
      test('should detect online status correctly', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);

        // Act
        final isOnline = await syncManager.isOnline();

        // Assert
        expect(isOnline, isTrue);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should detect offline status correctly', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.none);

        // Act
        final isOnline = await syncManager.isOnline();

        // Assert
        expect(isOnline, isFalse);
      });

      test('should handle mobile connection as online', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.mobile);

        // Act
        final isOnline = await syncManager.isOnline();

        // Assert
        expect(isOnline, isTrue);
      });

      test('should listen to connectivity changes', () async {
        // Arrange
        final connectivityStream = Stream.fromIterable([
          ConnectivityResult.none,
          ConnectivityResult.wifi,
          ConnectivityResult.mobile,
        ]);
        when(() => mockConnectivity.onConnectivityChanged)
            .thenAnswer((_) => connectivityStream);

        // Act
        final results = <bool>[];
        await for (final isOnline in syncManager.connectivityStream.take(3)) {
          results.add(isOnline);
        }

        // Assert
        expect(results, equals([false, true, true]));
      });
    });

    group('データ同期の実行', () {
      test('should sync successfully when online', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        when(() => mockDatabaseHelper.getPendingSyncCount())
            .thenAnswer((_) async => {'activities': 2, 'total': 2});
        when(() => mockDatabaseHelper.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => [
          TestHelper.generateActivityData(),
          TestHelper.generateActivityData(),
        ]);

        // Act
        final result = await syncManager.sync();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.syncedCount, equals(2));
        verify(() => mockDatabaseHelper.getPendingSyncCount()).called(1);
      });

      test('should not sync when offline', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.none);

        // Act
        final result = await syncManager.sync();

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('offline'));
        verifyNever(() => mockDatabaseHelper.getPendingSyncCount());
      });

      test('should handle sync with no pending data', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        when(() => mockDatabaseHelper.getPendingSyncCount())
            .thenAnswer((_) async => {'total': 0});

        // Act
        final result = await syncManager.sync();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.syncedCount, equals(0));
        expect(result.message, contains('no pending data'));
      });

      test('should handle sync errors gracefully', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        when(() => mockDatabaseHelper.getPendingSyncCount())
            .thenThrow(Exception('Database error'));

        // Act
        final result = await syncManager.sync();

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Database error'));
      });
    });

    group('差分同期', () {
      test('should perform incremental sync successfully', () async {
        // Arrange
        final lastSyncTime = DateTime.now().subtract(const Duration(hours: 1));
        when(() => mockLocalDataSource.getString('last_sync_time'))
            .thenReturn(lastSyncTime.toIso8601String());
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        when(() => mockDatabaseHelper.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => [TestHelper.generateActivityData()]);

        // Act
        final result = await syncManager.incrementalSync();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.isIncremental, isTrue);
        verify(() => mockLocalDataSource.getString('last_sync_time')).called(1);
      });

      test('should fallback to full sync when no last sync time', () async {
        // Arrange
        when(() => mockLocalDataSource.getString('last_sync_time'))
            .thenReturn(null);
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        when(() => mockDatabaseHelper.getPendingSyncCount())
            .thenAnswer((_) async => {'total': 0});

        // Act
        final result = await syncManager.incrementalSync();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.isIncremental, isFalse);
      });

      test('should update last sync time after successful sync', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        when(() => mockDatabaseHelper.getPendingSyncCount())
            .thenAnswer((_) async => {'total': 0});
        when(() => mockLocalDataSource.setString(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await syncManager.sync();

        // Assert
        verify(() => mockLocalDataSource.setString(
          'last_sync_time',
          any(that: isNotEmpty),
        )).called(1);
      });
    });

    group('データ競合の解決', () {
      test('should detect and resolve conflicts', () async {
        // Arrange
        final localData = TestHelper.generateActivityData();
        final remoteData = TestHelper.generateActivityData()
          ..['id'] = localData['id']
          ..['updatedAt'] = DateTime.now().toIso8601String();

        when(() => mockConflictResolver.resolveConflict(any(), any()))
            .thenReturn(remoteData);
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);

        // Act
        final resolvedData = await syncManager.resolveDataConflict(localData, remoteData);

        // Assert
        expect(resolvedData, equals(remoteData));
        verify(() => mockConflictResolver.resolveConflict(localData, remoteData)).called(1);
      });

      test('should handle conflict resolution failure', () async {
        // Arrange
        final localData = TestHelper.generateActivityData();
        final remoteData = TestHelper.generateActivityData();

        when(() => mockConflictResolver.resolveConflict(any(), any()))
            .thenThrow(Exception('Conflict resolution failed'));

        // Act & Assert
        expect(
          () => syncManager.resolveDataConflict(localData, remoteData),
          throwsException,
        );
      });

      test('should prioritize more recent data in conflict', () async {
        // Arrange
        final now = DateTime.now();
        final localData = TestHelper.generateActivityData()
          ..['updatedAt'] = now.subtract(const Duration(minutes: 10)).toIso8601String();
        final remoteData = TestHelper.generateActivityData()
          ..['id'] = localData['id']
          ..['updatedAt'] = now.toIso8601String();

        when(() => mockConflictResolver.resolveConflict(any(), any()))
            .thenReturn(remoteData);

        // Act
        final resolvedData = await syncManager.resolveDataConflict(localData, remoteData);

        // Assert
        expect(resolvedData['updatedAt'], equals(remoteData['updatedAt']));
      });
    });

    group('バックグラウンド同期', () {
      test('should schedule background sync', () async {
        // Arrange
        when(() => mockLocalDataSource.setInt(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await syncManager.scheduleBackgroundSync(const Duration(minutes: 15));

        // Assert
        verify(() => mockLocalDataSource.setInt(
          'background_sync_interval',
          15,
        )).called(1);
      });

      test('should check if background sync is due', () async {
        // Arrange
        final lastSync = DateTime.now().subtract(const Duration(minutes: 20));
        when(() => mockLocalDataSource.getString('last_sync_time'))
            .thenReturn(lastSync.toIso8601String());
        when(() => mockLocalDataSource.getInt('background_sync_interval'))
            .thenReturn(15);

        // Act
        final isDue = await syncManager.isBackgroundSyncDue();

        // Assert
        expect(isDue, isTrue);
      });

      test('should not sync if background sync is not due', () async {
        // Arrange
        final lastSync = DateTime.now().subtract(const Duration(minutes: 5));
        when(() => mockLocalDataSource.getString('last_sync_time'))
            .thenReturn(lastSync.toIso8601String());
        when(() => mockLocalDataSource.getInt('background_sync_interval'))
            .thenReturn(15);

        // Act
        final isDue = await syncManager.isBackgroundSyncDue();

        // Assert
        expect(isDue, isFalse);
      });
    });

    group('同期状態の監視', () {
      test('should get sync status correctly', () async {
        // Arrange
        when(() => mockDatabaseHelper.getPendingSyncCount())
            .thenAnswer((_) async => {
              'activities': 5,
              'conversations': 2,
              'healthData': 3,
              'total': 10,
            });
        when(() => mockLocalDataSource.getString('last_sync_time'))
            .thenReturn(DateTime.now().toIso8601String());

        // Act
        final status = await syncManager.getSyncStatus();

        // Assert
        expect(status['pendingCount'], equals(10));
        expect(status['lastSyncTime'], isNotNull);
        expect(status['hasPendingData'], isTrue);
      });

      test('should detect when sync is in progress', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        when(() => mockDatabaseHelper.getPendingSyncCount())
            .thenAnswer((_) async => {'total': 1});
        when(() => mockDatabaseHelper.query(any(), where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => [TestHelper.generateActivityData()]);

        // Act
        final syncFuture = syncManager.sync();
        final isInProgress = syncManager.isSyncInProgress;

        // Assert
        expect(isInProgress, isTrue);
        await syncFuture;
        expect(syncManager.isSyncInProgress, isFalse);
      });

      test('should prevent concurrent syncs', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        when(() => mockDatabaseHelper.getPendingSyncCount())
            .thenAnswer((_) async => {'total': 0});

        // Act
        final sync1 = syncManager.sync();
        final sync2 = syncManager.sync();

        final results = await Future.wait([sync1, sync2]);

        // Assert
        expect(results[0].isSuccess, isTrue);
        expect(results[1].isSuccess, isFalse);
        expect(results[1].error, contains('sync in progress'));
      });
    });

    group('エラーハンドリング', () {
      test('should handle connectivity check failure', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Connectivity check failed'));

        // Act
        final isOnline = await syncManager.isOnline();

        // Assert
        expect(isOnline, isFalse);
      });

      test('should retry sync on failure', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);

        var callCount = 0;
        when(() => mockDatabaseHelper.getPendingSyncCount()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('Temporary error');
          }
          return {'total': 0};
        });

        // Act
        final result = await syncManager.syncWithRetry(maxRetries: 2);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockDatabaseHelper.getPendingSyncCount()).called(2);
      });

      test('should give up after max retries', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        when(() => mockDatabaseHelper.getPendingSyncCount())
            .thenThrow(Exception('Persistent error'));

        // Act
        final result = await syncManager.syncWithRetry(maxRetries: 2);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Persistent error'));
        verify(() => mockDatabaseHelper.getPendingSyncCount()).called(3); // initial + 2 retries
      });
    });
  });
}