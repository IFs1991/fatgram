import 'package:flutter/foundation.dart';
import 'local/shared_preferences_local_data_source.dart';
import 'local/database/database_helper.dart';
import 'local/database/activity_dao.dart';
import '../sync/sync_manager.dart';
import 'local_data_source.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/models/user_model.dart';

/// ローカルデータソースの完全実装
class LocalDataSourceImpl implements LocalDataSource {
  final SharedPreferencesLocalDataSource _preferencesDataSource;
  final DatabaseHelper _databaseHelper;
  final ActivityDao _activityDao;
  final SyncManager? _syncManager;

  LocalDataSourceImpl({
    required SharedPreferencesLocalDataSource preferencesDataSource,
    required DatabaseHelper databaseHelper,
    required ActivityDao activityDao,
    SyncManager? syncManager,
  })  : _preferencesDataSource = preferencesDataSource,
        _databaseHelper = databaseHelper,
        _activityDao = activityDao,
        _syncManager = syncManager;

  // ===================
  // ユーザーデータ管理
  // ===================

  /// ユーザーデータを保存
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _preferencesDataSource.saveUserData(userData);

      if (kDebugMode) {
        print('LocalDataSourceImpl: User data saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error saving user data: $e');
      }
      rethrow;
    }
  }

  /// ユーザーデータを取得
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userData = await _preferencesDataSource.getUserData();

      if (kDebugMode) {
        print('LocalDataSourceImpl: Retrieved user data (exists: ${userData != null})');
      }

      return userData;
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error retrieving user data: $e');
      }
      return null;
    }
  }

  /// ユーザーデータをクリア
  Future<void> clearUserData() async {
    try {
      await _preferencesDataSource.clearUserData();

      if (kDebugMode) {
        print('LocalDataSourceImpl: User data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error clearing user data: $e');
      }
      rethrow;
    }
  }

  // ===================
  // 認証管理
  // ===================

  /// 認証トークンを保存
  Future<void> saveAuthToken(String token) async {
    try {
      await _preferencesDataSource.saveAuthToken(token);

      if (kDebugMode) {
        print('LocalDataSourceImpl: Auth token saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error saving auth token: $e');
      }
      rethrow;
    }
  }

  /// 認証トークンを取得
  Future<String?> getAuthToken() async {
    try {
      return await _preferencesDataSource.getAuthToken();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error retrieving auth token: $e');
      }
      return null;
    }
  }

  /// 認証トークンをクリア
  Future<void> clearAuthToken() async {
    try {
      await _preferencesDataSource.clearAuthToken();

      if (kDebugMode) {
        print('LocalDataSourceImpl: Auth token cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error clearing auth token: $e');
      }
      rethrow;
    }
  }

  /// 認証状態をチェック
  Future<bool> isAuthenticated() async {
    try {
      final token = await getAuthToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error checking auth status: $e');
      }
      return false;
    }
  }

  // ===================
  // 設定管理
  // ===================

  /// アプリ設定を保存
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      await _preferencesDataSource.saveSettings(settings);

      if (kDebugMode) {
        print('LocalDataSourceImpl: Settings saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error saving settings: $e');
      }
      rethrow;
    }
  }

  /// アプリ設定を取得
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      return await _preferencesDataSource.getSettings();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error retrieving settings: $e');
      }
      return null;
    }
  }

  /// 特定の設定値を保存
  Future<void> setSetting(String key, dynamic value) async {
    try {
      if (value is String) {
        await _preferencesDataSource.setString(key, value);
      } else if (value is bool) {
        await _preferencesDataSource.setBool(key, value);
      } else if (value is int) {
        await _preferencesDataSource.setInt(key, value);
      } else if (value is double) {
        await _preferencesDataSource.setDouble(key, value);
      } else {
        throw ArgumentError('Unsupported value type: ${value.runtimeType}');
      }

      if (kDebugMode) {
        print('LocalDataSourceImpl: Setting $key saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error saving setting $key: $e');
      }
      rethrow;
    }
  }

  /// 特定の設定値を取得
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      if (T == String) {
        return _preferencesDataSource.getString(key, defaultValue: defaultValue as String?) as T?;
      } else if (T == bool) {
        return _preferencesDataSource.getBool(key, defaultValue: defaultValue as bool?) as T?;
      } else if (T == int) {
        return _preferencesDataSource.getInt(key, defaultValue: defaultValue as int?) as T?;
      } else if (T == double) {
        return _preferencesDataSource.getDouble(key, defaultValue: defaultValue as double?) as T?;
      } else {
        throw ArgumentError('Unsupported type: $T');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting setting $key: $e');
      }
      return defaultValue;
    }
  }

  // ===================
  // アクティビティ管理
  // ===================

  /// アクティビティを作成
  Future<int> createActivity(Map<String, dynamic> activityData) async {
    try {
      final id = await _activityDao.createActivity(activityData);

      // 自動同期が有効な場合は同期をトリガー
      _triggerAutoSync();

      if (kDebugMode) {
        print('LocalDataSourceImpl: Activity created with ID $id');
      }

      return id;
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error creating activity: $e');
      }
      rethrow;
    }
  }

  /// アクティビティを取得
  Future<Map<String, dynamic>?> getActivityById(String id) async {
    try {
      return await _activityDao.getActivityById(id);
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting activity $id: $e');
      }
      return null;
    }
  }

  /// 全アクティビティを取得
  Future<List<Map<String, dynamic>>> getAllActivities() async {
    try {
      return await _activityDao.getAllActivities();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting all activities: $e');
      }
      return [];
    }
  }

  /// タイプ別アクティビティを取得
  Future<List<Map<String, dynamic>>> getActivitiesByType(String type) async {
    try {
      return await _activityDao.getActivitiesByType(type);
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting activities by type: $e');
      }
      return [];
    }
  }

  /// 日付範囲でアクティビティを取得
  Future<List<Map<String, dynamic>>> getActivitiesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _activityDao.getActivitiesByDateRange(startDate, endDate);
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting activities by date range: $e');
      }
      return [];
    }
  }

  /// 最近のアクティビティを取得
  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    try {
      return await _activityDao.getRecentActivities(limit);
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting recent activities: $e');
      }
      return [];
    }
  }

  /// 今日のアクティビティを取得
  Future<List<Map<String, dynamic>>> getTodaysActivities() async {
    try {
      return await _activityDao.getTodaysActivities();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting today\'s activities: $e');
      }
      return [];
    }
  }

  /// アクティビティを更新
  Future<int> updateActivity(String id, Map<String, dynamic> data) async {
    try {
      final result = await _activityDao.updateActivity(id, data);

      // 自動同期が有効な場合は同期をトリガー
      _triggerAutoSync();

      if (kDebugMode) {
        print('LocalDataSourceImpl: Activity $id updated');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error updating activity $id: $e');
      }
      rethrow;
    }
  }

  /// アクティビティを削除
  Future<int> deleteActivity(String id) async {
    try {
      final result = await _activityDao.deleteActivity(id);

      // 自動同期が有効な場合は同期をトリガー
      _triggerAutoSync();

      if (kDebugMode) {
        print('LocalDataSourceImpl: Activity $id deleted');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error deleting activity $id: $e');
      }
      rethrow;
    }
  }

  /// アクティビティを検索
  Future<List<Map<String, dynamic>>> searchActivities(String query) async {
    try {
      return await _activityDao.searchActivities(query);
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error searching activities: $e');
      }
      return [];
    }
  }

  // ===================
  // 統計情報
  // ===================

  /// アクティビティ統計を取得
  Future<Map<String, dynamic>> getActivityStatistics() async {
    try {
      final count = await _activityDao.getActivityCount();
      final totalCalories = await _activityDao.getTotalCalories();
      final statsByType = await _activityDao.getActivityStatsByType();
      final monthlyStats = await _activityDao.getMonthlyStats();

      return {
        'totalCount': count,
        'totalCalories': totalCalories,
        'statsByType': statsByType,
        'monthlyStats': monthlyStats,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting activity statistics: $e');
      }
      return {};
    }
  }

  /// データベース統計を取得
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    try {
      final dbStats = await _databaseHelper.getStatistics();
      final dbInfo = await _databaseHelper.getDatabaseInfo();
      final pendingSync = await _databaseHelper.getPendingSyncCount();

      return {
        'database': dbInfo,
        'records': dbStats,
        'pendingSync': pendingSync,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting database statistics: $e');
      }
      return {};
    }
  }

  // ===================
  // 同期管理
  // ===================

  /// 同期状態を取得
  Future<Map<String, dynamic>> getSyncStatus() async {
    if (_syncManager == null) {
      return {
        'enabled': false,
        'message': 'Sync manager not configured',
      };
    }

    try {
      return await _syncManager!.getSyncStatus();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting sync status: $e');
      }
      return {
        'error': e.toString(),
        'enabled': true,
      };
    }
  }

  /// 手動同期を実行
  Future<SyncResult?> performSync() async {
    if (_syncManager == null) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Sync manager not configured');
      }
      return null;
    }

    try {
      return await _syncManager!.sync();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error performing sync: $e');
      }
      return null;
    }
  }

  /// 差分同期を実行
  Future<SyncResult?> performIncrementalSync() async {
    if (_syncManager == null) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Sync manager not configured');
      }
      return null;
    }

    try {
      return await _syncManager!.incrementalSync();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error performing incremental sync: $e');
      }
      return null;
    }
  }

  /// 自動同期をトリガー（内部使用）
  void _triggerAutoSync() {
    if (_syncManager == null) return;

    // バックグラウンドで自動同期を実行
    Future.delayed(Duration.zero, () async {
      try {
        final isBackgroundSyncDue = await _syncManager!.isBackgroundSyncDue();
        if (isBackgroundSyncDue) {
          final isOnline = await _syncManager!.isOnline();
          if (isOnline) {
            await _syncManager!.incrementalSync();
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('LocalDataSourceImpl: Auto sync error: $e');
        }
      }
    });
  }

  // ===================
  // メンテナンス
  // ===================

  /// データベースのクリーンアップ
  Future<Map<String, int>> performCleanup() async {
    try {
      final activityCleaned = await _activityDao.cleanup();
      await _databaseHelper.vacuum();

      final result = {
        'activitiesCleaned': activityCleaned,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (kDebugMode) {
        print('LocalDataSourceImpl: Cleanup completed - $result');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error during cleanup: $e');
      }
      return {
        'error': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// 全データをクリア
  Future<void> clearAllData() async {
    try {
      await _preferencesDataSource.clearAll();
      await _databaseHelper.deleteDatabase();

      if (kDebugMode) {
        print('LocalDataSourceImpl: All data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error clearing all data: $e');
      }
      rethrow;
    }
  }

  /// データベースのヘルスチェック
  Future<bool> performHealthCheck() async {
    try {
      return await _databaseHelper.healthCheck();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Health check failed: $e');
      }
      return false;
    }
  }

  /// リソースのクリーンアップ
  Future<void> dispose() async {
    try {
      await _databaseHelper.close();
      _syncManager?.dispose();

      if (kDebugMode) {
        print('LocalDataSourceImpl: Resources disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error disposing resources: $e');
      }
    }
  }

  // ===================
  // LocalDataSource インターフェース実装
  // ===================

  @override
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    try {
      final rawActivities = await _activityDao.getActivitiesByDateRange(startDate, endDate);
      
      // userId でフィルタリング
      final filteredActivities = rawActivities.where((activity) => 
        activity['userId'] == userId
      ).toList();

      // Map<String, dynamic> から Activity オブジェクトに変換
      return filteredActivities.map((activityMap) => Activity(
        id: activityMap['id']?.toString() ?? '',
        userId: activityMap['userId']?.toString() ?? userId,
        type: activityMap['type']?.toString() ?? '',
        name: activityMap['name']?.toString() ?? '',
        caloriesBurned: (activityMap['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
        durationMinutes: (activityMap['durationMinutes'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse(activityMap['date']?.toString() ?? '') ?? DateTime.now(),
        notes: activityMap['notes']?.toString(),
      )).toList();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting activities: $e');
      }
      return [];
    }
  }

  @override
  Future<void> saveActivity(Activity activity) async {
    try {
      final activityMap = {
        'id': activity.id,
        'userId': activity.userId,
        'type': activity.type,
        'name': activity.name,
        'caloriesBurned': activity.caloriesBurned,
        'durationMinutes': activity.durationMinutes,
        'date': activity.date.toIso8601String(),
        'notes': activity.notes,
        'syncStatus': 'pending', // 同期待ちマーク
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _activityDao.createActivity(activityMap);
      
      // 自動同期をトリガー
      _triggerAutoSync();

      if (kDebugMode) {
        print('LocalDataSourceImpl: Activity saved successfully - ${activity.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error saving activity: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> saveActivities(List<Activity> activities) async {
    try {
      for (final activity in activities) {
        await saveActivity(activity);
      }

      if (kDebugMode) {
        print('LocalDataSourceImpl: ${activities.length} activities saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error saving activities: $e');
      }
      rethrow;
    }
  }

  @override
  Future<List<Activity>> getUnsyncedActivities(String userId) async {
    try {
      final allActivities = await _activityDao.getAllActivities();
      
      // 未同期（syncStatus が 'pending'）でユーザーIDが一致するアクティビティをフィルタリング
      final unsyncedActivities = allActivities.where((activityMap) =>
        activityMap['userId'] == userId &&
        activityMap['syncStatus'] == 'pending'
      ).toList();

      // Activity オブジェクトに変換
      return unsyncedActivities.map((activityMap) => Activity(
        id: activityMap['id']?.toString() ?? '',
        userId: activityMap['userId']?.toString() ?? userId,
        type: activityMap['type']?.toString() ?? '',
        name: activityMap['name']?.toString() ?? '',
        caloriesBurned: (activityMap['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
        durationMinutes: (activityMap['durationMinutes'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse(activityMap['date']?.toString() ?? '') ?? DateTime.now(),
        notes: activityMap['notes']?.toString(),
      )).toList();
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting unsynced activities: $e');
      }
      return [];
    }
  }

  @override
  Future<void> markActivityAsSynced(String activityId) async {
    try {
      final updateData = {
        'syncStatus': 'synced',
        'syncedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _activityDao.updateActivity(activityId, updateData);

      if (kDebugMode) {
        print('LocalDataSourceImpl: Activity marked as synced - $activityId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error marking activity as synced: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> saveCurrentUser(User user) async {
    try {
      final userData = {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'createdAt': user.createdAt.toIso8601String(),
        'lastLoginAt': user.lastLoginAt?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _preferencesDataSource.saveUserData(userData);

      if (kDebugMode) {
        print('LocalDataSourceImpl: Current user saved - ${user.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error saving current user: $e');
      }
      rethrow;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final userData = await _preferencesDataSource.getUserData();
      
      if (userData == null) {
        return null;
      }

      return User(
        id: userData['id']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        name: userData['name']?.toString() ?? '',
        avatarUrl: userData['avatarUrl']?.toString(),
        createdAt: DateTime.tryParse(userData['createdAt']?.toString() ?? '') ?? DateTime.now(),
        lastLoginAt: DateTime.tryParse(userData['lastLoginAt']?.toString() ?? ''),
      );
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error getting current user: $e');
      }
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await _preferencesDataSource.clearUserData();

      if (kDebugMode) {
        print('LocalDataSourceImpl: Current user cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocalDataSourceImpl: Error clearing user: $e');
      }
      rethrow;
    }
  }
}