import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fatgram/data/datasources/local/database/database_helper.dart';
import '../../../test_helper.dart';

class MockDatabase extends Mock implements Database {}

void main() {
  late DatabaseHelper databaseHelper;
  late MockDatabase mockDatabase;

  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(<Object?>[]);
    registerFallbackValue(ConflictAlgorithm.abort);
  });

  setUp(() {
    mockDatabase = MockDatabase();

    // デフォルトのMock設定
    when(() => mockDatabase.path).thenReturn('/test/path/database.db');
    when(() => mockDatabase.isOpen).thenReturn(true);
    when(() => mockDatabase.getVersion()).thenAnswer((_) async => 1);

    databaseHelper = DatabaseHelper.withDatabase(mockDatabase);
  });

  group('DatabaseHelper', () {
    group('データベース初期化', () {
      test('should initialize database with correct version', () async {
        // Arrange
        when(() => mockDatabase.getVersion()).thenAnswer((_) async => 1);

        // Act
        final version = await databaseHelper.getDatabaseVersion();

        // Assert
        expect(version, equals(1));
        verify(() => mockDatabase.getVersion()).called(1);
      });

      test('should create tables on first run', () async {
        // Arrange
        const createTableSql = '''
        CREATE TABLE activities (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          duration INTEGER NOT NULL,
          calories REAL NOT NULL,
          heartRate INTEGER,
          startTime TEXT NOT NULL,
          endTime TEXT NOT NULL,
          syncStatus INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
        ''';

        when(() => mockDatabase.execute(any())).thenAnswer((_) async {});

        // Act
        await databaseHelper.createTables();

        // Assert
        verify(() => mockDatabase.execute(any(that: contains('CREATE TABLE activities')))).called(1);
        verify(() => mockDatabase.execute(any(that: contains('CREATE TABLE conversations')))).called(1);
        verify(() => mockDatabase.execute(any(that: contains('CREATE TABLE health_data')))).called(1);
      });

      test('should handle database migration', () async {
        // Arrange
        const oldVersion = 1;
        const newVersion = 2;
        when(() => mockDatabase.execute(any())).thenAnswer((_) async {});

        // Act
        await databaseHelper.migrateTo(newVersion, oldVersion);

        // Assert
        verify(() => mockDatabase.execute(any())).called(greaterThan(0));
      });
    });

    group('トランザクション管理', () {
      test('should execute operations in transaction', () async {
        // Arrange
        var transactionExecuted = false;
        when(() => mockDatabase.transaction(any())).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function;
          transactionExecuted = true;
          final result = await callback(mockDatabase);
          return result;
        });

        // Act
        final result = await databaseHelper.executeInTransaction(() async {
          return 'result';
        });

        // Assert
        expect(transactionExecuted, isTrue);
        expect(result, equals('result'));
        verify(() => mockDatabase.transaction(any())).called(1);
      });

      test('should rollback transaction on error', () async {
        // Arrange
        when(() => mockDatabase.transaction(any())).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => databaseHelper.executeInTransaction(() async {
            throw Exception('Operation error');
          }),
          throwsException,
        );
      });
    });

    group('クエリ実行', () {
      test('should execute select query successfully', () async {
        // Arrange
        final expectedResults = [
          {'id': '1', 'name': 'Running'},
          {'id': '2', 'name': 'Cycling'},
        ];
        when(() => mockDatabase.query(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
          orderBy: any(named: 'orderBy'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => expectedResults);

        // Act
        final results = await databaseHelper.query(
          'activities',
          where: 'type = ?',
          whereArgs: ['running'],
          orderBy: 'startTime DESC',
          limit: 10,
        );

        // Assert
        expect(results, equals(expectedResults));
        verify(() => mockDatabase.query(
          'activities',
          where: 'type = ?',
          whereArgs: ['running'],
          orderBy: 'startTime DESC',
          limit: 10,
        )).called(1);
      });

      test('should execute insert successfully', () async {
        // Arrange
        const expectedId = 123;
        when(() => mockDatabase.insert(
          any(),
          any(),
          conflictAlgorithm: any(named: 'conflictAlgorithm'),
        )).thenAnswer((_) async => expectedId);

        final data = {'name': 'Running', 'type': 'cardio'};

        // Act
        final id = await databaseHelper.insert('activities', data);

        // Assert
        expect(id, equals(expectedId));
        verify(() => mockDatabase.insert(
          'activities',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        )).called(1);
      });

      test('should execute update successfully', () async {
        // Arrange
        const expectedRowsAffected = 1;
        when(() => mockDatabase.update(
          any(),
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => expectedRowsAffected);

        final data = {'name': 'Updated Running'};

        // Act
        final rowsAffected = await databaseHelper.update(
          'activities',
          data,
          where: 'id = ?',
          whereArgs: ['1'],
        );

        // Assert
        expect(rowsAffected, equals(expectedRowsAffected));
        verify(() => mockDatabase.update(
          'activities',
          data,
          where: 'id = ?',
          whereArgs: ['1'],
        )).called(1);
      });

      test('should execute delete successfully', () async {
        // Arrange
        const expectedRowsAffected = 1;
        when(() => mockDatabase.delete(
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        )).thenAnswer((_) async => expectedRowsAffected);

        // Act
        final rowsAffected = await databaseHelper.delete(
          'activities',
          where: 'id = ?',
          whereArgs: ['1'],
        );

        // Assert
        expect(rowsAffected, equals(expectedRowsAffected));
        verify(() => mockDatabase.delete(
          'activities',
          where: 'id = ?',
          whereArgs: ['1'],
        )).called(1);
      });
    });

    group('バッチ操作', () {
      test('should execute batch operations successfully', () async {
        // Arrange
        final mockBatch = MockBatch();
        when(() => mockDatabase.batch()).thenReturn(mockBatch);
        when(() => mockBatch.insert(any(), any())).thenReturn(0);
        when(() => mockBatch.commit()).thenAnswer((_) async => [1, 2, 3]);

        final operations = [
          {'table': 'activities', 'data': {'name': 'Running'}},
          {'table': 'activities', 'data': {'name': 'Cycling'}},
          {'table': 'activities', 'data': {'name': 'Swimming'}},
        ];

        // Act
        final results = await databaseHelper.batchInsert(operations);

        // Assert
        expect(results, equals([1, 2, 3]));
        verify(() => mockDatabase.batch()).called(1);
        verify(() => mockBatch.commit()).called(1);
      });
    });

    group('データベース情報', () {
      test('should get database path', () async {
        // Arrange
        const expectedPath = '/path/to/database.db';
        when(() => mockDatabase.path).thenReturn(expectedPath);

        // Act
        final path = databaseHelper.getDatabasePath();

        // Assert
        expect(path, equals(expectedPath));
      });

      test('should check if database is open', () {
        // Arrange
        when(() => mockDatabase.isOpen).thenReturn(true);

        // Act
        final isOpen = databaseHelper.isOpen();

        // Assert
        expect(isOpen, isTrue);
        verify(() => mockDatabase.isOpen).called(1);
      });

      test('should close database', () async {
        // Arrange
        when(() => mockDatabase.close()).thenAnswer((_) async {});

        // Act
        await databaseHelper.close();

        // Assert
        verify(() => mockDatabase.close()).called(1);
      });
    });

    group('エラーハンドリング', () {
      test('should handle database exception gracefully', () async {
        // Arrange
        when(() => mockDatabase.query(any())).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => databaseHelper.query('activities'),
          throwsException,
        );
      });

      test('should handle SQL syntax error', () async {
        // Arrange
        when(() => mockDatabase.execute(any())).thenThrow(Exception('SQL syntax error'));

        // Act & Assert
        expect(
          () => databaseHelper.execute('INVALID SQL'),
          throwsException,
        );
      });
    });

    group('データベースメンテナンス', () {
      test('should vacuum database', () async {
        // Arrange
        when(() => mockDatabase.execute('VACUUM')).thenAnswer((_) async {});

        // Act
        await databaseHelper.vacuum();

        // Assert
        verify(() => mockDatabase.execute('VACUUM')).called(1);
      });

      test('should get database size info', () async {
        // Arrange
        when(() => mockDatabase.rawQuery('PRAGMA page_count')).thenAnswer((_) async => [{'page_count': 100}]);
        when(() => mockDatabase.rawQuery('PRAGMA page_size')).thenAnswer((_) async => [{'page_size': 4096}]);
        when(() => mockDatabase.getVersion()).thenAnswer((_) async => 1);

        // Act
        final info = await databaseHelper.getDatabaseInfo();

        // Assert
        expect(info['size'], equals(100 * 4096));
        expect(info['path'], equals('/test/path/database.db'));
        expect(info['version'], equals(1));
        expect(info['isOpen'], equals(true));
        verify(() => mockDatabase.rawQuery('PRAGMA page_count')).called(1);
        verify(() => mockDatabase.rawQuery('PRAGMA page_size')).called(1);
      });
    });
  });
}

class MockBatch extends Mock implements Batch {}