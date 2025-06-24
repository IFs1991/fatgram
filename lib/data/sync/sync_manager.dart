import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'conflict_resolver.dart';
import '../datasources/local/database/database_helper.dart';
import '../datasources/local/shared_preferences_local_data_source.dart';

/// 同期結果
class SyncResult {
  final bool isSuccess;
  final int syncedCount;
  final String? error;
  final String? message;
  final bool isIncremental;
  final DateTime timestamp;

  SyncResult({
    required this.isSuccess,
    this.syncedCount = 0,
    this.error,
    this.message,
    this.isIncremental = false,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'SyncResult(success: $isSuccess, synced: $syncedCount, incremental: $isIncremental, message: $message, error: $error)';
  }
}

/// データ同期管理クラス
class SyncManager {
  final Connectivity _connectivity;
  final DatabaseHelper _databaseHelper;
  final SharedPreferencesLocalDataSource _localDataSource;
  final ConflictResolver _conflictResolver;

  bool _isSyncInProgress = false;
  StreamController<bool>? _connectivityController;

  SyncManager({
    required Connectivity connectivity,
    required DatabaseHelper databaseHelper,
    required SharedPreferencesLocalDataSource localDataSource,
    required ConflictResolver conflictResolver,
  })  : _connectivity = connectivity,
        _databaseHelper = databaseHelper,
        _localDataSource = localDataSource,
        _conflictResolver = conflictResolver;

  /// 同期が実行中かどうか
  bool get isSyncInProgress => _isSyncInProgress;

  /// オンライン状態を確認
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final online = connectivityResult != ConnectivityResult.none;

      if (kDebugMode) {
        print('SyncManager: Connectivity status: $connectivityResult (online: $online)');
      }

      return online;
    } catch (e) {
      if (kDebugMode) {
        print('SyncManager: Error checking connectivity: $e');
      }
      return false;
    }
  }

  /// 接続状態の変更を監視するストリーム
  Stream<bool> get connectivityStream {
    _connectivityController ??= StreamController<bool>.broadcast();

    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      final isOnline = result != ConnectivityResult.none;
      _connectivityController?.add(isOnline);

      if (kDebugMode) {
        print('SyncManager: Connectivity changed to $result (online: $isOnline)');
      }
    });

    return _connectivityController!.stream;
  }

  /// メイン同期処理
  Future<SyncResult> sync() async {
    if (_isSyncInProgress) {
      return SyncResult(
        isSuccess: false,
        error: 'Sync already in progress',
      );
    }

    _isSyncInProgress = true;

    try {
      if (kDebugMode) {
        print('SyncManager: Starting sync...');
      }

      // オンライン状態をチェック
      if (!await isOnline()) {
        return SyncResult(
          isSuccess: false,
          error: 'Device is offline',
        );
      }

      // 同期が必要なデータを取得
      final pendingCounts = await _databaseHelper.getPendingSyncCount();
      final totalPending = pendingCounts['total'] ?? 0;

      if (totalPending == 0) {
        await _updateLastSyncTime();
        return SyncResult(
          isSuccess: true,
          syncedCount: 0,
          message: 'No pending data to sync',
        );
      }

      if (kDebugMode) {
        print('SyncManager: Found $totalPending items to sync');
      }

      // データ種別ごとに同期
      int totalSynced = 0;

      // アクティビティの同期
      if ((pendingCounts['activities'] ?? 0) > 0) {
        final activitySynced = await _syncActivities();
        totalSynced += activitySynced;
      }

      // 会話履歴の同期
      if ((pendingCounts['conversations'] ?? 0) > 0) {
        final conversationSynced = await _syncConversations();
        totalSynced += conversationSynced;
      }

      // ヘルスデータの同期
      if ((pendingCounts['healthData'] ?? 0) > 0) {
        final healthSynced = await _syncHealthData();
        totalSynced += healthSynced;
      }

      await _updateLastSyncTime();

      return SyncResult(
        isSuccess: true,
        syncedCount: totalSynced,
        message: 'Sync completed successfully',
      );
    } catch (e) {
      if (kDebugMode) {
        print('SyncManager: Sync error: $e');
      }
      return SyncResult(
        isSuccess: false,
        error: e.toString(),
      );
    } finally {
      _isSyncInProgress = false;
    }
  }

  /// 差分同期
  Future<SyncResult> incrementalSync() async {
    try {
      final lastSyncTime = _localDataSource.getString('last_sync_time');

      if (lastSyncTime == null) {
        if (kDebugMode) {
          print('SyncManager: No last sync time found, falling back to full sync');
        }
        final result = await sync();
        return SyncResult(
          isSuccess: result.isSuccess,
          syncedCount: result.syncedCount,
          error: result.error,
          message: result.message,
          isIncremental: false,
        );
      }

      if (!await isOnline()) {
        return SyncResult(
          isSuccess: false,
          error: 'Device is offline',
          isIncremental: true,
        );
      }

      final since = DateTime.parse(lastSyncTime);
      if (kDebugMode) {
        print('SyncManager: Performing incremental sync since $since');
      }

      // 指定時刻以降に更新されたデータを取得
      final recentActivities = await _databaseHelper.query(
        'activities',
        where: 'updatedAt > ? AND syncStatus = ?',
        whereArgs: [since.toIso8601String(), 0],
      );

      final recentConversations = await _databaseHelper.query(
        'conversations',
        where: 'updatedAt > ? AND syncStatus = ?',
        whereArgs: [since.toIso8601String(), 0],
      );

      final recentHealthData = await _databaseHelper.query(
        'health_data',
        where: 'updatedAt > ? AND syncStatus = ?',
        whereArgs: [since.toIso8601String(), 0],
      );

      final totalItems = recentActivities.length +
                        recentConversations.length +
                        recentHealthData.length;

      if (totalItems == 0) {
        return SyncResult(
          isSuccess: true,
          syncedCount: 0,
          message: 'No new data to sync',
          isIncremental: true,
        );
      }

      // 差分同期を実行
      int syncedCount = 0;
      syncedCount += await _syncDataList(recentActivities, 'activities');
      syncedCount += await _syncDataList(recentConversations, 'conversations');
      syncedCount += await _syncDataList(recentHealthData, 'health_data');

      await _updateLastSyncTime();

      return SyncResult(
        isSuccess: true,
        syncedCount: syncedCount,
        message: 'Incremental sync completed',
        isIncremental: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('SyncManager: Incremental sync error: $e');
      }
      return SyncResult(
        isSuccess: false,
        error: e.toString(),
        isIncremental: true,
      );
    }
  }

  /// データ競合の解決
  Future<Map<String, dynamic>> resolveDataConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    try {
      final resolved = _conflictResolver.resolveConflict(localData, remoteData);

      if (kDebugMode) {
        print('SyncManager: Conflict resolved for ${localData['id']}');
      }

      return resolved;
    } catch (e) {
      if (kDebugMode) {
        print('SyncManager: Error resolving conflict: $e');
      }
      rethrow;
    }
  }

  /// バックグラウンド同期のスケジュール
  Future<void> scheduleBackgroundSync(Duration interval) async {
    await _localDataSource.setInt('background_sync_interval', interval.inMinutes);

    if (kDebugMode) {
      print('SyncManager: Background sync scheduled every ${interval.inMinutes} minutes');
    }
  }

  /// バックグラウンド同期が必要かチェック
  Future<bool> isBackgroundSyncDue() async {
    try {
      final lastSyncStr = _localDataSource.getString('last_sync_time');
      final intervalMinutes = _localDataSource.getInt('background_sync_interval', defaultValue: 30);

      if (lastSyncStr == null) return true;

      final lastSync = DateTime.parse(lastSyncStr);
      final now = DateTime.now();
      final timeDiff = now.difference(lastSync);

      final isDue = timeDiff.inMinutes >= intervalMinutes!;

      if (kDebugMode) {
        print('SyncManager: Background sync due: $isDue (last: $lastSync, interval: ${intervalMinutes}min)');
      }

      return isDue;
    } catch (e) {
      if (kDebugMode) {
        print('SyncManager: Error checking background sync: $e');
      }
      return true; // エラーの場合は同期を実行
    }
  }

  /// 同期状態を取得
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final pendingCounts = await _databaseHelper.getPendingSyncCount();
      final lastSyncTime = _localDataSource.getString('last_sync_time');
      final backgroundInterval = _localDataSource.getInt('background_sync_interval', defaultValue: 30);

      return {
        'pendingCount': pendingCounts['total'] ?? 0,
        'pendingActivities': pendingCounts['activities'] ?? 0,
        'pendingConversations': pendingCounts['conversations'] ?? 0,
        'pendingHealthData': pendingCounts['healthData'] ?? 0,
        'lastSyncTime': lastSyncTime,
        'backgroundInterval': backgroundInterval,
        'hasPendingData': (pendingCounts['total'] ?? 0) > 0,
        'isOnline': await isOnline(),
        'isSyncInProgress': _isSyncInProgress,
      };
    } catch (e) {
      if (kDebugMode) {
        print('SyncManager: Error getting sync status: $e');
      }
      return {
        'error': e.toString(),
        'isOnline': false,
        'isSyncInProgress': _isSyncInProgress,
      };
    }
  }

  /// リトライ機能付き同期
  Future<SyncResult> syncWithRetry({int maxRetries = 3}) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        final result = await sync();
        if (result.isSuccess) {
          return result;
        }

        if (attempts == maxRetries) {
          return result;
        }

        attempts++;
        if (kDebugMode) {
          print('SyncManager: Sync attempt $attempts failed, retrying... (${result.error})');
        }

        // 指数バックオフで待機
        await Future.delayed(Duration(seconds: 2 * attempts));
      } catch (e) {
        attempts++;
        if (attempts > maxRetries) {
          return SyncResult(
            isSuccess: false,
            error: e.toString(),
          );
        }

        if (kDebugMode) {
          print('SyncManager: Sync attempt $attempts failed with exception, retrying...');
        }

        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }

    return SyncResult(
      isSuccess: false,
      error: 'Max retries exceeded',
    );
  }

  /// アクティビティの同期
  Future<int> _syncActivities() async {
    final activities = await _databaseHelper.query(
      'activities',
      where: 'syncStatus = ?',
      whereArgs: [0],
    );

    return await _syncDataList(activities, 'activities');
  }

  /// 会話履歴の同期
  Future<int> _syncConversations() async {
    final conversations = await _databaseHelper.query(
      'conversations',
      where: 'syncStatus = ?',
      whereArgs: [0],
    );

    return await _syncDataList(conversations, 'conversations');
  }

  /// ヘルスデータの同期
  Future<int> _syncHealthData() async {
    final healthData = await _databaseHelper.query(
      'health_data',
      where: 'syncStatus = ?',
      whereArgs: [0],
    );

    return await _syncDataList(healthData, 'health_data');
  }

  /// データリストの同期（実際のAPI呼び出しは別途実装）
  Future<int> _syncDataList(List<Map<String, dynamic>> dataList, String tableName) async {
    if (dataList.isEmpty) return 0;

    int syncedCount = 0;

    await _databaseHelper.executeInTransaction(() async {
      for (final data in dataList) {
        try {
          // TODO: 実際のAPI呼び出しをここに実装
          // final response = await _apiClient.uploadData(data);

          // 仮の成功処理（実際の実装では、API呼び出し結果に基づく）
          await _databaseHelper.update(
            tableName,
            {
              'syncStatus': 1,
              'updatedAt': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [data['id']],
          );

          syncedCount++;

          if (kDebugMode) {
            print('SyncManager: Synced $tableName item ${data['id']}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('SyncManager: Failed to sync $tableName item ${data['id']}: $e');
          }
          // 個別の同期失敗は全体の失敗にしない
        }
      }
    });

    return syncedCount;
  }

  /// 最終同期時刻を更新
  Future<void> _updateLastSyncTime() async {
    await _localDataSource.setString('last_sync_time', DateTime.now().toIso8601String());
  }

  /// リソースのクリーンアップ
  void dispose() {
    _connectivityController?.close();
    _connectivityController = null;
  }
}