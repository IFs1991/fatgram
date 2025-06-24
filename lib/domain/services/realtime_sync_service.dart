/// Firebase Firestoreリアルタイム同期サービス
/// 2025年最新技術: StreamSubscription管理、競合解決、5G最適化、オフライン対応
library realtime_sync_service;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../repositories/user_repository.dart';
import '../repositories/activity_repository.dart';

/// リアルタイム同期状態
enum SyncStatus {
  idle,
  syncing,
  error,
  offline,
  connected,
}

/// 同期イベント種別
enum SyncEventType {
  userUpdate,
  activityAdd,
  activityUpdate,
  activityDelete,
  bulkUpdate,
  conflictResolution,
}

/// 同期イベント
class SyncEvent {
  final SyncEventType type;
  final String? documentId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic>? metadata;

  const SyncEvent({
    required this.type,
    this.documentId,
    this.data,
    required this.timestamp,
    this.userId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'documentId': documentId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'metadata': metadata,
    };
  }
}

/// Firebase Firestore リアルタイム同期サービス
class RealtimeSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final Connectivity _connectivity = Connectivity();
  
  // Stream controllers
  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  final StreamController<SyncEvent> _eventController = StreamController<SyncEvent>.broadcast();
  final StreamController<User> _userUpdateController = StreamController<User>.broadcast();
  final StreamController<Activity> _activityUpdateController = StreamController<Activity>.broadcast();
  
  // StreamSubscriptions管理
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, DateTime> _lastSyncTimes = {};
  
  // サービス状態
  SyncStatus _currentStatus = SyncStatus.idle;
  bool _isInitialized = false;
  String? _currentUserId;
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  
  // 2025年最適化設定
  static const Duration _syncTimeout = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 5);
  static const int _maxRetryAttempts = 3;
  static const int _batchSize = 50;
  
  // パフォーマンス監視
  final Map<String, List<Duration>> _syncPerformance = {};
  
  /// 公開ストリーム
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<SyncEvent> get eventStream => _eventController.stream;
  Stream<User> get userUpdateStream => _userUpdateController.stream;
  Stream<Activity> get activityUpdateStream => _activityUpdateController.stream;
  
  /// 現在の同期状態
  SyncStatus get currentStatus => _currentStatus;
  
  /// 初期化
  Future<void> initialize({required String userId}) async {
    try {
      if (_isInitialized && _currentUserId == userId) {
        return;
      }
      
      _currentUserId = userId;
      
      // Firestore設定（2025年最適化）
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      // 接続状態監視開始
      await _startConnectivityMonitoring();
      
      // Firestore接続確認
      await _testFirestoreConnection();
      
      _isInitialized = true;
      _updateStatus(SyncStatus.connected);
      
      _logger.i('Realtime sync service initialized for user: $userId');
      
    } catch (e) {
      _logger.e('Realtime sync initialization failed', error: e);
      _updateStatus(SyncStatus.error);
      throw Exception('リアルタイム同期の初期化に失敗しました: $e');
    }
  }
  
  /// ユーザーデータのリアルタイム監視開始
  Future<void> startUserSync(String userId) async {
    try {
      await _ensureInitialized();
      
      final userDocRef = _firestore.collection('users').doc(userId);
      
      // 既存の監視を停止
      await _stopSubscription('user_$userId');
      
      // リアルタイム監視開始
      final subscription = userDocRef.snapshots().listen(
        (snapshot) async => await _handleUserUpdate(snapshot),
        onError: (error) => _handleSyncError('user_sync', error),
      );
      
      _subscriptions['user_$userId'] = subscription;
      _lastSyncTimes['user_$userId'] = DateTime.now();
      
      _logger.i('User realtime sync started: $userId');
      
    } catch (e) {
      _logger.e('User sync start failed', error: e);
      throw Exception('ユーザー同期の開始に失敗しました: $e');
    }
  }
  
  /// アクティビティデータのリアルタイム監視開始
  Future<void> startActivitySync(String userId, {DateTime? since}) async {
    try {
      await _ensureInitialized();
      
      Query activityQuery = _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);
      
      // 差分同期（5G最適化）
      if (since != null) {
        activityQuery = activityQuery.where('timestamp', isGreaterThan: since);
      }
      
      // 既存の監視を停止
      await _stopSubscription('activities_$userId');
      
      // リアルタイム監視開始
      final subscription = activityQuery.snapshots().listen(
        (snapshot) async => await _handleActivityUpdates(snapshot),
        onError: (error) => _handleSyncError('activity_sync', error),
      );
      
      _subscriptions['activities_$userId'] = subscription;
      _lastSyncTimes['activities_$userId'] = DateTime.now();
      
      _logger.i('Activity realtime sync started: $userId');
      
    } catch (e) {
      _logger.e('Activity sync start failed', error: e);
      throw Exception('アクティビティ同期の開始に失敗しました: $e');
    }
  }
  
  /// バッチ同期（大量データ対応）
  Future<void> performBatchSync(String userId, {int batchSize = 50}) async {
    try {
      _updateStatus(SyncStatus.syncing);
      final stopwatch = Stopwatch()..start();
      
      // ユーザーデータ同期
      await _syncUserData(userId);
      
      // アクティビティバッチ同期
      await _syncActivitiesBatch(userId, batchSize);
      
      stopwatch.stop();
      _recordSyncPerformance('batch_sync', stopwatch.elapsed);
      
      _updateStatus(SyncStatus.connected);
      
      _emitEvent(SyncEvent(
        type: SyncEventType.bulkUpdate,
        timestamp: DateTime.now(),
        userId: userId,
        metadata: {
          'batchSize': batchSize,
          'duration': stopwatch.elapsedMilliseconds,
        },
      ));
      
      _logger.i('Batch sync completed for user: $userId');
      
    } catch (e) {
      _logger.e('Batch sync failed', error: e);
      _updateStatus(SyncStatus.error);
      throw Exception('バッチ同期に失敗しました: $e');
    }
  }
  
  /// オフライン変更のアップロード
  Future<void> syncOfflineChanges(String userId) async {
    try {
      if (_connectivityStatus == ConnectivityResult.none) {
        _logger.w('No network connection - offline changes queued');
        return;
      }
      
      _updateStatus(SyncStatus.syncing);
      
      // 未同期データの検出・アップロード
      await _uploadPendingChanges(userId);
      
      _updateStatus(SyncStatus.connected);
      _logger.i('Offline changes synced for user: $userId');
      
    } catch (e) {
      _logger.e('Offline sync failed', error: e);
      _updateStatus(SyncStatus.error);
    }
  }
  
  /// 競合解決
  Future<T> resolveConflict<T>({
    required T localData,
    required T serverData,
    required DateTime localTimestamp,
    required DateTime serverTimestamp,
    required String documentId,
  }) async {
    try {
      // タイムスタンプベース解決（2025年標準）
      final T resolvedData;
      
      if (serverTimestamp.isAfter(localTimestamp)) {
        // サーバー優先
        resolvedData = serverData;
        _logger.i('Conflict resolved: server wins (newer) for $documentId');
      } else {
        // ローカル優先
        resolvedData = localData;
        _logger.i('Conflict resolved: local wins (newer) for $documentId');
      }
      
      _emitEvent(SyncEvent(
        type: SyncEventType.conflictResolution,
        documentId: documentId,
        timestamp: DateTime.now(),
        metadata: {
          'resolution': serverTimestamp.isAfter(localTimestamp) ? 'server' : 'local',
          'serverTimestamp': serverTimestamp.toIso8601String(),
          'localTimestamp': localTimestamp.toIso8601String(),
        },
      ));
      
      return resolvedData;
      
    } catch (e) {
      _logger.e('Conflict resolution failed', error: e);
      throw Exception('競合解決に失敗しました: $e');
    }
  }
  
  /// ユーザー更新処理
  Future<void> _handleUserUpdate(DocumentSnapshot snapshot) async {
    try {
      if (!snapshot.exists) {
        _logger.w('User document does not exist');
        return;
      }
      
      final userData = snapshot.data() as Map<String, dynamic>;
      final user = User.fromJson(userData);
      
      _userUpdateController.add(user);
      
      _emitEvent(SyncEvent(
        type: SyncEventType.userUpdate,
        documentId: snapshot.id,
        data: userData,
        timestamp: DateTime.now(),
        userId: user.id,
      ));
      
      _logger.i('User update processed: ${user.id}');
      
    } catch (e) {
      _logger.e('User update processing failed', error: e);
    }
  }
  
  /// アクティビティ更新処理
  Future<void> _handleActivityUpdates(QuerySnapshot snapshot) async {
    try {
      for (final change in snapshot.docChanges) {
        final activityData = change.doc.data() as Map<String, dynamic>;
        final activity = Activity.fromJson(activityData);
        
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            _activityUpdateController.add(activity);
            
            _emitEvent(SyncEvent(
              type: change.type == DocumentChangeType.added 
                  ? SyncEventType.activityAdd 
                  : SyncEventType.activityUpdate,
              documentId: change.doc.id,
              data: activityData,
              timestamp: DateTime.now(),
              userId: activity.userId,
            ));
            break;
            
          case DocumentChangeType.removed:
            _emitEvent(SyncEvent(
              type: SyncEventType.activityDelete,
              documentId: change.doc.id,
              timestamp: DateTime.now(),
              userId: activity.userId,
            ));
            break;
        }
      }
      
      _logger.i('Activity updates processed: ${snapshot.docChanges.length}');
      
    } catch (e) {
      _logger.e('Activity update processing failed', error: e);
    }
  }
  
  /// 接続状態監視
  Future<void> _startConnectivityMonitoring() async {
    _connectivity.onConnectivityChanged.listen((result) {
      _connectivityStatus = result;
      
      if (result == ConnectivityResult.none) {
        _updateStatus(SyncStatus.offline);
        _logger.w('Network connection lost - switching to offline mode');
      } else {
        _updateStatus(SyncStatus.connected);
        _logger.i('Network connection restored: ${result.name}');
        
        // 接続復旧時に自動同期
        if (_currentUserId != null) {
          syncOfflineChanges(_currentUserId!);
        }
      }
    });
  }
  
  /// Firestore接続テスト
  Future<void> _testFirestoreConnection() async {
    try {
      await _firestore.collection('_health_check').doc('test').get();
      _logger.i('Firestore connection verified');
    } catch (e) {
      _logger.w('Firestore connection test failed', error: e);
      throw Exception('Firestore connection failed');
    }
  }
  
  /// ユーザーデータ同期
  Future<void> _syncUserData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      await _handleUserUpdate(userDoc);
    }
  }
  
  /// アクティビティバッチ同期
  Future<void> _syncActivitiesBatch(String userId, int batchSize) async {
    Query query = _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(batchSize);
    
    DocumentSnapshot? lastDoc;
    int totalSynced = 0;
    
    do {
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) break;
      
      await _handleActivityUpdates(snapshot);
      
      lastDoc = snapshot.docs.last;
      totalSynced += snapshot.docs.length;
      
      _logger.i('Batch sync progress: $totalSynced activities');
      
    } while (lastDoc != null);
  }
  
  /// 未同期変更のアップロード
  Future<void> _uploadPendingChanges(String userId) async {
    // 実装: ローカルDBから未同期データを取得してアップロード
    _logger.i('Uploading pending changes for user: $userId');
    // TODO: 実際の未同期データ処理実装
  }
  
  /// 同期エラー処理
  void _handleSyncError(String context, dynamic error) {
    _logger.e('Sync error in $context', error: error);
    _updateStatus(SyncStatus.error);
    
    // 自動リトライ
    Timer(_retryDelay, () {
      if (_currentUserId != null) {
        _logger.i('Retrying sync after error');
        startUserSync(_currentUserId!);
        startActivitySync(_currentUserId!);
      }
    });
  }
  
  /// StreamSubscription停止
  Future<void> _stopSubscription(String key) async {
    final subscription = _subscriptions[key];
    if (subscription != null) {
      await subscription.cancel();
      _subscriptions.remove(key);
      _logger.i('Subscription stopped: $key');
    }
  }
  
  /// 状態更新
  void _updateStatus(SyncStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      _logger.i('Sync status updated: ${status.name}');
    }
  }
  
  /// イベント発行
  void _emitEvent(SyncEvent event) {
    _eventController.add(event);
  }
  
  /// パフォーマンス記録
  void _recordSyncPerformance(String operation, Duration duration) {
    _syncPerformance.putIfAbsent(operation, () => []).add(duration);
    
    // 最新100件のみ保持
    final performanceList = _syncPerformance[operation]!;
    if (performanceList.length > 100) {
      performanceList.removeAt(0);
    }
  }
  
  /// 初期化確認
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      throw Exception('RealtimeSyncService not initialized');
    }
  }
  
  /// 全同期停止
  Future<void> stopAllSync() async {
    try {
      // 全StreamSubscriptionを停止
      for (final key in _subscriptions.keys.toList()) {
        await _stopSubscription(key);
      }
      
      _updateStatus(SyncStatus.idle);
      _logger.i('All realtime sync stopped');
      
    } catch (e) {
      _logger.e('Stop sync failed', error: e);
    }
  }
  
  /// パフォーマンス統計取得
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _syncPerformance.entries) {
      final durations = entry.value;
      if (durations.isNotEmpty) {
        final totalMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a + b);
        stats[entry.key] = {
          'count': durations.length,
          'averageMs': totalMs / durations.length,
          'lastMs': durations.last.inMilliseconds,
        };
      }
    }
    
    return {
      'status': _currentStatus.name,
      'connectivity': _connectivityStatus.name,
      'activeSubscriptions': _subscriptions.length,
      'performance': stats,
      'lastSyncTimes': _lastSyncTimes.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }
  
  /// サービス終了
  Future<void> dispose() async {
    try {
      await stopAllSync();
      
      await _statusController.close();
      await _eventController.close();
      await _userUpdateController.close();
      await _activityUpdateController.close();
      
      _isInitialized = false;
      _logger.i('Realtime sync service disposed');
      
    } catch (e) {
      _logger.e('Sync service disposal failed', error: e);
    }
  }
}