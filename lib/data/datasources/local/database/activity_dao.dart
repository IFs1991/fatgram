import 'package:flutter/foundation.dart';
import 'database_helper.dart';

/// アクティビティデータアクセスオブジェクト
class ActivityDao {
  final DatabaseHelper _databaseHelper;

  ActivityDao(this._databaseHelper);

  static const String _tableName = 'activities';

  /// アクティビティを作成
  Future<int> createActivity(Map<String, dynamic> activityData) async {
    try {
      // 必要なフィールドの自動生成
      final now = DateTime.now().toIso8601String();
      activityData['createdAt'] = activityData['createdAt'] ?? now;
      activityData['updatedAt'] = activityData['updatedAt'] ?? now;
      activityData['syncStatus'] = activityData['syncStatus'] ?? 0;

      final id = await _databaseHelper.insert(_tableName, activityData);

      if (kDebugMode) {
        print('ActivityDao: Created activity with id $id');
      }

      return id;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error creating activity: $e');
      }
      rethrow;
    }
  }

  /// IDでアクティビティを取得
  Future<Map<String, dynamic>?> getActivityById(String id) async {
    try {
      final results = await _databaseHelper.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;

      if (kDebugMode) {
        print('ActivityDao: Retrieved activity $id');
      }

      return results.first;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting activity by id: $e');
      }
      rethrow;
    }
  }

  /// 全てのアクティビティを取得
  Future<List<Map<String, dynamic>>> getAllActivities() async {
    try {
      final results = await _databaseHelper.query(
        _tableName,
        orderBy: 'startTime DESC',
      );

      if (kDebugMode) {
        print('ActivityDao: Retrieved ${results.length} activities');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting all activities: $e');
      }
      rethrow;
    }
  }

  /// タイプ別アクティビティを取得
  Future<List<Map<String, dynamic>>> getActivitiesByType(String type) async {
    try {
      final results = await _databaseHelper.query(
        _tableName,
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'startTime DESC',
      );

      if (kDebugMode) {
        print('ActivityDao: Retrieved ${results.length} activities of type $type');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting activities by type: $e');
      }
      rethrow;
    }
  }

  /// 日付範囲でアクティビティを取得
  Future<List<Map<String, dynamic>>> getActivitiesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final results = await _databaseHelper.query(
        _tableName,
        where: 'startTime >= ? AND startTime <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'startTime DESC',
      );

      if (kDebugMode) {
        print('ActivityDao: Retrieved ${results.length} activities between $startDate and $endDate');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting activities by date range: $e');
      }
      rethrow;
    }
  }

  /// 最近のアクティビティを取得
  Future<List<Map<String, dynamic>>> getRecentActivities(int limit) async {
    try {
      final results = await _databaseHelper.query(
        _tableName,
        orderBy: 'startTime DESC',
        limit: limit,
      );

      if (kDebugMode) {
        print('ActivityDao: Retrieved ${results.length} recent activities');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting recent activities: $e');
      }
      rethrow;
    }
  }

  /// アクティビティを更新
  Future<int> updateActivity(String id, Map<String, dynamic> data) async {
    try {
      // 更新日時を自動設定
      data['updatedAt'] = DateTime.now().toIso8601String();

      final rowsAffected = await _databaseHelper.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (kDebugMode) {
        print('ActivityDao: Updated activity $id, rows affected: $rowsAffected');
      }

      return rowsAffected;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error updating activity: $e');
      }
      rethrow;
    }
  }

  /// 同期ステータスを更新
  Future<int> updateSyncStatus(String id, int syncStatus) async {
    try {
      final data = {
        'syncStatus': syncStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final rowsAffected = await _databaseHelper.update(
        _tableName,
        data,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (kDebugMode) {
        print('ActivityDao: Updated sync status for activity $id to $syncStatus');
      }

      return rowsAffected;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error updating sync status: $e');
      }
      rethrow;
    }
  }

  /// アクティビティを削除
  Future<int> deleteActivity(String id) async {
    try {
      final rowsAffected = await _databaseHelper.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (kDebugMode) {
        print('ActivityDao: Deleted activity $id, rows affected: $rowsAffected');
      }

      return rowsAffected;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error deleting activity: $e');
      }
      rethrow;
    }
  }

  /// タイプ別アクティビティを削除
  Future<int> deleteActivitiesByType(String type) async {
    try {
      final rowsAffected = await _databaseHelper.delete(
        _tableName,
        where: 'type = ?',
        whereArgs: [type],
      );

      if (kDebugMode) {
        print('ActivityDao: Deleted $rowsAffected activities of type $type');
      }

      return rowsAffected;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error deleting activities by type: $e');
      }
      rethrow;
    }
  }

  /// 古いアクティビティを削除
  Future<int> deleteOldActivities(DateTime cutoffDate) async {
    try {
      final rowsAffected = await _databaseHelper.delete(
        _tableName,
        where: 'startTime < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );

      if (kDebugMode) {
        print('ActivityDao: Deleted $rowsAffected old activities before $cutoffDate');
      }

      return rowsAffected;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error deleting old activities: $e');
      }
      rethrow;
    }
  }

  /// アクティビティ数を取得
  Future<int> getActivityCount() async {
    try {
      final results = await _databaseHelper.rawQuery('SELECT COUNT(*) FROM $_tableName');
      final count = results.first['COUNT(*)'] as int? ?? 0;

      if (kDebugMode) {
        print('ActivityDao: Total activity count: $count');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting activity count: $e');
      }
      return 0;
    }
  }

  /// 総カロリーを取得
  Future<double> getTotalCalories() async {
    try {
      final results = await _databaseHelper.rawQuery('SELECT SUM(calories) FROM $_tableName');
      final calories = results.first['SUM(calories)'] as double? ?? 0.0;

      if (kDebugMode) {
        print('ActivityDao: Total calories: $calories');
      }

      return calories;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting total calories: $e');
      }
      return 0.0;
    }
  }

  /// タイプ別統計情報を取得
  Future<List<Map<String, dynamic>>> getActivityStatsByType() async {
    try {
      final results = await _databaseHelper.rawQuery('''
        SELECT
          type,
          COUNT(*) as count,
          SUM(calories) as total_calories,
          SUM(duration) as total_duration,
          AVG(calories) as avg_calories,
          AVG(duration) as avg_duration,
          AVG(heartRate) as avg_heart_rate
        FROM $_tableName
        GROUP BY type
        ORDER BY count DESC
      ''');

      if (kDebugMode) {
        print('ActivityDao: Retrieved stats for ${results.length} activity types');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting activity stats by type: $e');
      }
      return [];
    }
  }

  /// 月別統計情報を取得
  Future<List<Map<String, dynamic>>> getMonthlyStats() async {
    try {
      final results = await _databaseHelper.rawQuery('''
        SELECT
          strftime('%Y-%m', startTime) as month,
          COUNT(*) as count,
          SUM(calories) as total_calories,
          SUM(duration) as total_duration
        FROM $_tableName
        GROUP BY month
        ORDER BY month DESC
        LIMIT 12
      ''');

      if (kDebugMode) {
        print('ActivityDao: Retrieved monthly stats for ${results.length} months');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting monthly stats: $e');
      }
      return [];
    }
  }

  /// 同期されていないアクティビティを取得
  Future<List<Map<String, dynamic>>> getUnsynchronizedActivities() async {
    try {
      final results = await _databaseHelper.query(
        _tableName,
        where: 'syncStatus = ?',
        whereArgs: [0],
        orderBy: 'createdAt ASC',
      );

      if (kDebugMode) {
        print('ActivityDao: Found ${results.length} unsynchronized activities');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting unsynchronized activities: $e');
      }
      rethrow;
    }
  }

  /// アクティビティを同期済みとしてマーク
  Future<void> markAsSynchronized(List<String> activityIds) async {
    try {
      await _databaseHelper.executeInTransaction(() async {
        final placeholders = List.filled(activityIds.length, '?').join(',');
        await _databaseHelper.update(
          _tableName,
          {
            'syncStatus': 1,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id IN ($placeholders)',
          whereArgs: activityIds,
        );
      });

      if (kDebugMode) {
        print('ActivityDao: Marked ${activityIds.length} activities as synchronized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error marking activities as synchronized: $e');
      }
      rethrow;
    }
  }

  /// 複数のアクティビティを一括作成
  Future<List<int>> createMultipleActivities(List<Map<String, dynamic>> activities) async {
    try {
      final results = <int>[];

      await _databaseHelper.executeInTransaction(() async {
        for (final activity in activities) {
          final id = await createActivity(activity);
          results.add(id);
        }
      });

      if (kDebugMode) {
        print('ActivityDao: Created ${results.length} activities in batch');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error creating multiple activities: $e');
      }
      rethrow;
    }
  }

  /// 週別のアクティビティを取得
  Future<List<Map<String, dynamic>>> getWeeklyActivities() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final results = await getActivitiesByDateRange(startOfWeek, endOfWeek);

      if (kDebugMode) {
        print('ActivityDao: Retrieved ${results.length} activities for current week');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting weekly activities: $e');
      }
      rethrow;
    }
  }

  /// 今日のアクティビティを取得
  Future<List<Map<String, dynamic>>> getTodaysActivities() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      final results = await getActivitiesByDateRange(startOfDay, endOfDay);

      if (kDebugMode) {
        print('ActivityDao: Retrieved ${results.length} activities for today');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error getting today\'s activities: $e');
      }
      rethrow;
    }
  }

  /// アクティビティの検索
  Future<List<Map<String, dynamic>>> searchActivities(String query) async {
    try {
      final results = await _databaseHelper.query(
        _tableName,
        where: 'name LIKE ? OR type LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'startTime DESC',
      );

      if (kDebugMode) {
        print('ActivityDao: Found ${results.length} activities matching "$query"');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error searching activities: $e');
      }
      rethrow;
    }
  }

  /// データベースのクリーンアップ
  Future<int> cleanup() async {
    try {
      // 90日以上古いアクティビティを削除
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final deletedCount = await deleteOldActivities(cutoffDate);

      if (kDebugMode) {
        print('ActivityDao: Cleanup completed, deleted $deletedCount old activities');
      }

      return deletedCount;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityDao: Error during cleanup: $e');
      }
      return 0;
    }
  }
}