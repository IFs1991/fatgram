import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLiteデータベースの管理を行うヘルパークラス
class DatabaseHelper {
  static const String _databaseName = 'fatgram.db';
  static const int _databaseVersion = 1;

  Database? _database;
  final Database? _mockDatabase;

  // シングルトンパターン
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal() : _mockDatabase = null;

  // テスト用コンストラクタ
  DatabaseHelper.withDatabase(this._mockDatabase);

  /// データベースインスタンスを取得
  Future<Database> get database async {
    if (_mockDatabase != null) return _mockDatabase!;
    _database ??= await _initDatabase();
    return _database!;
  }

  /// データベースの初期化
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// データベース設定
  Future<void> _onConfigure(Database db) async {
    // 外部キー制約を有効化
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// テーブル作成
  Future<void> _onCreate(Database db, int version) async {
    await createTables(db);
  }

  /// データベースアップグレード
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await migrateTo(newVersion, oldVersion, db);
  }

  /// 全てのテーブルを作成
  Future<void> createTables([Database? db]) async {
    final database = db ?? await this.database;

    // アクティビティテーブル
    await database.execute('''
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
    ''');

    // 会話履歴テーブル
    await database.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        message TEXT NOT NULL,
        response TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        context TEXT,
        syncStatus INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // ヘルスデータテーブル
    await database.execute('''
      CREATE TABLE health_data (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        source TEXT NOT NULL,
        syncStatus INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // インデックス作成
    await _createIndexes(database);

    if (kDebugMode) {
      print('Database: All tables created successfully');
    }
  }

  /// インデックス作成
  Future<void> _createIndexes(Database db) async {
    // アクティビティのインデックス
    await db.execute('CREATE INDEX idx_activities_start_time ON activities(startTime)');
    await db.execute('CREATE INDEX idx_activities_type ON activities(type)');
    await db.execute('CREATE INDEX idx_activities_sync_status ON activities(syncStatus)');

    // 会話履歴のインデックス
    await db.execute('CREATE INDEX idx_conversations_timestamp ON conversations(timestamp)');
    await db.execute('CREATE INDEX idx_conversations_sync_status ON conversations(syncStatus)');

    // ヘルスデータのインデックス
    await db.execute('CREATE INDEX idx_health_data_type ON health_data(type)');
    await db.execute('CREATE INDEX idx_health_data_timestamp ON health_data(timestamp)');
    await db.execute('CREATE INDEX idx_health_data_sync_status ON health_data(syncStatus)');
  }

  /// データベースマイグレーション
  Future<void> migrateTo(int newVersion, int oldVersion, [Database? db]) async {
    final database = db ?? await this.database;

    if (kDebugMode) {
      print('Database: Migrating from version $oldVersion to $newVersion');
    }

    // バージョン別マイグレーション
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateToVersion(database, version);
    }
  }

  /// 特定バージョンへのマイグレーション
  Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 2:
        // 例: 新しいカラム追加
        await db.execute('ALTER TABLE activities ADD COLUMN notes TEXT');
        break;
      case 3:
        // 例: 新しいテーブル追加
        await db.execute('''
          CREATE TABLE user_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE NOT NULL,
            value TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        break;
      default:
        if (kDebugMode) {
          print('Database: No migration needed for version $version');
        }
    }
  }

  /// クエリ実行
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// データ挿入
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await database;
    return await db.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm ?? ConflictAlgorithm.replace,
    );
  }

  /// データ更新
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// データ削除
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// 生SQL実行
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  /// 生クエリ実行
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// トランザクション実行
  Future<T> executeInTransaction<T>(Future<T> Function() action) async {
    final db = await database;
    return await db.transaction((_) async {
      return await action();
    });
  }

  /// バッチ挿入
  Future<List<Object?>> batchInsert(List<Map<String, dynamic>> operations) async {
    final db = await database;
    final batch = db.batch();

    for (final operation in operations) {
      final table = operation['table'] as String;
      final data = operation['data'] as Map<String, Object?>;
      batch.insert(table, data);
    }

    return await batch.commit();
  }

  /// バッチ更新
  Future<List<Object?>> batchUpdate(List<Map<String, dynamic>> operations) async {
    final db = await database;
    final batch = db.batch();

    for (final operation in operations) {
      final table = operation['table'] as String;
      final data = operation['data'] as Map<String, Object?>;
      final where = operation['where'] as String?;
      final whereArgs = operation['whereArgs'] as List<Object?>?;

      batch.update(table, data, where: where, whereArgs: whereArgs);
    }

    return await batch.commit();
  }

  /// データベースバージョン取得
  Future<int> getDatabaseVersion() async {
    final db = await database;
    return await db.getVersion();
  }

  /// データベースパス取得
  String getDatabasePath() {
    if (_mockDatabase != null) return _mockDatabase!.path;
    return _database?.path ?? '';
  }

  /// データベースが開いているかチェック
  bool isOpen() {
    if (_mockDatabase != null) return _mockDatabase!.isOpen;
    return _database?.isOpen ?? false;
  }

  /// データベースクローズ
  Future<void> close() async {
    if (_mockDatabase != null) {
      await _mockDatabase!.close();
      return;
    }
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// データベース削除
  Future<void> deleteDatabase() async {
    await close();
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);

    if (await File(path).exists()) {
      await File(path).delete();
      if (kDebugMode) {
        print('Database: Database file deleted');
      }
    }
  }

  /// VACUUM実行（データベース最適化）
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
    if (kDebugMode) {
      print('Database: VACUUM completed');
    }
  }

  /// データベース情報取得
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;

    final pageCountResult = await db.rawQuery('PRAGMA page_count');
    final pageSizeResult = await db.rawQuery('PRAGMA page_size');

    final pageCount = pageCountResult.first['page_count'] as int;
    final pageSize = pageSizeResult.first['page_size'] as int;

    return {
      'path': db.path,
      'version': await db.getVersion(),
      'pageCount': pageCount,
      'pageSize': pageSize,
      'size': pageCount * pageSize,
      'isOpen': db.isOpen,
    };
  }

  /// 統計情報取得
  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final activitiesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM activities')
    ) ?? 0;

    final conversationsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM conversations')
    ) ?? 0;

    final healthDataCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM health_data')
    ) ?? 0;

    return {
      'activities': activitiesCount,
      'conversations': conversationsCount,
      'healthData': healthDataCount,
      'total': activitiesCount + conversationsCount + healthDataCount,
    };
  }

  /// 同期が必要なデータの件数を取得
  Future<Map<String, int>> getPendingSyncCount() async {
    final db = await database;

    final activitiesPending = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM activities WHERE syncStatus = 0')
    ) ?? 0;

    final conversationsPending = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM conversations WHERE syncStatus = 0')
    ) ?? 0;

    final healthDataPending = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM health_data WHERE syncStatus = 0')
    ) ?? 0;

    return {
      'activities': activitiesPending,
      'conversations': conversationsPending,
      'healthData': healthDataPending,
      'total': activitiesPending + conversationsPending + healthDataPending,
    };
  }

  /// データベースのヘルスチェック
  Future<bool> healthCheck() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Database health check failed: $e');
      }
      return false;
    }
  }
}