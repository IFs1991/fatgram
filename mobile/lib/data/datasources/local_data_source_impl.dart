import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../domain/models/activity.dart';
import '../../domain/models/user.dart';
import 'local_data_source.dart';

/// ローカルデータソースの実装
class LocalDataSourceImpl implements LocalDataSource {
  final SharedPreferences _prefs;
  final Database _database;

  // 定数
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUser = 'user';
  static const String _prefixSetting = 'setting_';

  // テーブル名
  static const String _tableActivities = 'activities';
  static const String _tableConversations = 'conversations';
  static const String _tableChatMessages = 'chat_messages';

  LocalDataSourceImpl({
    required SharedPreferences prefs,
    required Database database,
  })  : _prefs = prefs,
        _database = database;

  /// データベース初期化用の静的メソッド
  static Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fatgram.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // アクティビティテーブル
        await db.execute('''
        CREATE TABLE $_tableActivities (
          activity_id TEXT PRIMARY KEY,
          activity_type TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          calories_burned REAL NOT NULL,
          fat_burned_grams REAL NOT NULL,
          heart_rate_avg REAL,
          heart_rate_max REAL,
          steps INTEGER,
          distance REAL,
          heart_rate_data TEXT,
          is_synced INTEGER NOT NULL DEFAULT 0
        )
        ''');

        // 会話テーブル
        await db.execute('''
        CREATE TABLE $_tableConversations (
          conversation_id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
        ''');

        // チャットメッセージテーブル
        await db.execute('''
        CREATE TABLE $_tableChatMessages (
          message_id TEXT PRIMARY KEY,
          conversation_id TEXT NOT NULL,
          content TEXT NOT NULL,
          sender TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (conversation_id) REFERENCES $_tableConversations (conversation_id) ON DELETE CASCADE
        )
        ''');
      },
    );
  }

  // 認証関連

  @override
  Future<void> saveAuthToken({
    required String token,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    final tokenData = {
      'token': token,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
    };
    await _prefs.setString(_keyAuthToken, jsonEncode(tokenData));
  }

  @override
  Future<Map<String, dynamic>?> getAuthToken() async {
    final tokenString = _prefs.getString(_keyAuthToken);
    if (tokenString == null) {
      return null;
    }
    return jsonDecode(tokenString) as Map<String, dynamic>;
  }

  @override
  Future<void> deleteAuthToken() async {
    await _prefs.remove(_keyAuthToken);
  }

  // ユーザー関連

  @override
  Future<void> saveUser(User user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  @override
  Future<User?> getUser() async {
    final userString = _prefs.getString(_keyUser);
    if (userString == null) {
      return null;
    }
    final userJson = jsonDecode(userString) as Map<String, dynamic>;
    return User.fromJson(userJson);
  }

  @override
  Future<void> deleteUser() async {
    await _prefs.remove(_keyUser);
  }

  // アクティビティ関連

  @override
  Future<void> saveActivities(List<Activity> activities) async {
    final batch = _database.batch();
    for (final activity in activities) {
      final heartRateDataJson = activity.heartRateData != null
          ? jsonEncode(
              activity.heartRateData!.map((data) => data.toJson()).toList())
          : null;

      batch.insert(
        _tableActivities,
        {
          'activity_id': activity.activityId,
          'activity_type': activity.activityType,
          'start_time': activity.startTime.toIso8601String(),
          'end_time': activity.endTime.toIso8601String(),
          'calories_burned': activity.caloriesBurned,
          'fat_burned_grams': activity.fatBurnedGrams,
          'heart_rate_avg': activity.heartRateAvg,
          'heart_rate_max': activity.heartRateMax,
          'steps': activity.steps,
          'distance': activity.distance,
          'heart_rate_data': heartRateDataJson,
          'is_synced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  @override
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _database.query(
      _tableActivities,
      where: 'start_time >= ? AND end_time <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    return result.map((row) => _mapRowToActivity(row)).toList();
  }

  @override
  Future<List<Activity>> getUnsyncedActivities() async {
    final result = await _database.query(
      _tableActivities,
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return result.map((row) => _mapRowToActivity(row)).toList();
  }

  @override
  Future<void> markActivitiesAsSynced(List<String> activityIds) async {
    final batch = _database.batch();
    for (final id in activityIds) {
      batch.update(
        _tableActivities,
        {'is_synced': 1},
        where: 'activity_id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit();
  }

  // 会話履歴関連

  @override
  Future<void> saveConversation(Map<String, dynamic> conversation) async {
    await _database.insert(
      _tableConversations,
      {
        'conversation_id': conversation['id'],
        'title': conversation['title'],
        'created_at': conversation['created_at'],
        'updated_at': conversation['updated_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getConversations({
    int? limit,
    int? offset,
  }) async {
    final result = await _database.query(
      _tableConversations,
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );

    return result
        .map((row) => {
              'id': row['conversation_id'],
              'title': row['title'],
              'created_at': row['created_at'],
              'updated_at': row['updated_at'],
            })
        .toList();
  }

  @override
  Future<void> saveChatMessage({
    required String conversationId,
    required Map<String, dynamic> message,
  }) async {
    await _database.insert(
      _tableChatMessages,
      {
        'message_id': message['id'],
        'conversation_id': conversationId,
        'content': message['content'],
        'sender': message['sender'],
        'created_at': message['created_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getChatMessages({
    required String conversationId,
    int? limit,
    int? offset,
  }) async {
    final result = await _database.query(
      _tableChatMessages,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
      limit: limit,
      offset: offset,
    );

    return result
        .map((row) => {
              'id': row['message_id'],
              'content': row['content'],
              'sender': row['sender'],
              'created_at': row['created_at'],
            })
        .toList();
  }

  // 設定関連

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    final jsonValue = jsonEncode(value);
    await _prefs.setString('$_prefixSetting$key', jsonValue);
  }

  @override
  Future<dynamic> getSetting(String key) {
    final value = _prefs.getString('$_prefixSetting$key');
    if (value == null) {
      return Future.value(null);
    }
    return Future.value(jsonDecode(value));
  }

  // ユーティリティ

  Activity _mapRowToActivity(Map<String, dynamic> row) {
    List<HeartRateData>? heartRateData;
    if (row['heart_rate_data'] != null) {
      final List<dynamic> heartRateJson =
          jsonDecode(row['heart_rate_data'] as String) as List<dynamic>;
      heartRateData = heartRateJson
          .map((data) => HeartRateData.fromJson(data as Map<String, dynamic>))
          .toList();
    }

    return Activity(
      activityId: row['activity_id'] as String,
      activityType: row['activity_type'] as String,
      startTime: DateTime.parse(row['start_time'] as String),
      endTime: DateTime.parse(row['end_time'] as String),
      caloriesBurned: row['calories_burned'] as double,
      fatBurnedGrams: row['fat_burned_grams'] as double,
      heartRateAvg: row['heart_rate_avg'] as double?,
      heartRateMax: row['heart_rate_max'] as double?,
      steps: row['steps'] as int?,
      distance: row['distance'] as double?,
      heartRateData: heartRateData,
    );
  }

  // UserRepositoryImplがアクセスする専用のメソッド
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(_keyUser, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final userString = _prefs.getString(_keyUser);
    if (userString == null) {
      return null;
    }
    return jsonDecode(userString) as Map<String, dynamic>;
  }

  Future<void> clearUserData() async {
    await _prefs.remove(_keyUser);
  }
}