import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:fatgram/core/security/enhanced_api_key_manager.dart';
import 'package:fatgram/data/datasources/local_data_source.dart';
import 'package:fatgram/data/datasources/remote_data_source.dart';
import 'package:fatgram/domain/services/unified_health_service.dart';
import 'package:fatgram/domain/models/activity_model.dart';
import 'package:fatgram/domain/models/user_model.dart';
import 'package:fatgram/domain/entities/activity.dart' as entity;

/// 統合テストヘルパークラス
/// Week 2で実装したDataSource統合の実際のテストを実行
class IntegrationTestHelper {
  static late EnhancedApiKeyManager apiKeyManager;
  static late LocalDataSource localDataSource;
  static late RemoteDataSource remoteDataSource;
  static late UnifiedHealthService healthService;

  /// テスト環境の初期化
  static Future<void> initializeTestEnvironment() async {
    // Enhanced API Key Manager の初期化
    apiKeyManager = EnhancedApiKeyManager(
      masterKey: 'integration_test_master_key_32_chars',
    );
    await apiKeyManager.initialize();
  }

  /// モックデータの生成
  static List<Activity> generateMockActivities({int count = 10}) {
    return List.generate(count, (index) => Activity(
      id: 'test_activity_$index',
      timestamp: DateTime.now().subtract(Duration(hours: index)),
      type: ActivityType.values[index % ActivityType.values.length],
      durationInSeconds: 1800 + (index * 300), // 30分 + index * 5分
      caloriesBurned: 150.0 + (index * 25), // 150 + index * 25 calories
      distanceInMeters: index % 2 == 0 ? 3000.0 + (index * 500) : null,
      userId: 'test_user_123',
      metadata: {
        'test_index': index,
        'generated_at': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// モック NormalizedActivity の生成
  static List<entity.NormalizedActivity> generateMockNormalizedActivities({int count = 5}) {
    return List.generate(count, (index) => entity.NormalizedActivity(
      id: 'normalized_activity_$index',
      startTime: DateTime.now().subtract(Duration(hours: index)),
      duration: Duration(minutes: 30 + (index * 15)),
      type: entity.ActivityType.values[index % entity.ActivityType.values.length],
      calories: 200.0 + (index * 50),
      distance: index % 3 == 0 ? 5000.0 + (index * 1000) : null,
      metadata: {
        'source': 'health_connect',
        'test_index': index,
      },
    ));
  }

  /// テストユーザーの生成
  static User generateTestUser() {
    return User(
      id: 'test_user_123',
      email: 'test@fatgram.com',
      displayName: 'Test User',
      height: 175,
      weight: 70,
      age: 30,
      isPremium: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    );
  }

  /// データ同期シナリオの実行
  static Future<SyncScenarioResult> executeDataSyncScenario({
    required LocalDataSource localDataSource,
    required RemoteDataSource remoteDataSource,
    bool simulateNetworkError = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final results = SyncScenarioResult();

    try {
      // 1. ローカルに複数のアクティビティを保存
      final activities = generateMockActivities(count: 5);
      
      for (final activity in activities) {
        await localDataSource.saveActivity(activity);
        results.localSaveCount++;
      }

      // 2. 未同期アクティビティの取得
      final unsyncedActivities = await localDataSource.getUnsyncedActivities('test_user_123');
      results.unsyncedCount = unsyncedActivities.length;

      // 3. リモート同期の実行
      if (!simulateNetworkError) {
        for (final activity in unsyncedActivities) {
          try {
            await remoteDataSource.saveActivity(activity);
            await localDataSource.markActivityAsSynced(activity.id);
            results.remoteSyncCount++;
          } catch (e) {
            results.syncErrors.add(e.toString());
          }
        }
      } else {
        // ネットワークエラーシミュレーション
        results.syncErrors.add('Network error simulated');
      }

      // 4. データ取得の確認
      final retrievedActivities = await localDataSource.getActivities(
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now(),
        userId: 'test_user_123',
      );
      results.retrievedCount = retrievedActivities.length;

      stopwatch.stop();
      results.executionTimeMs = stopwatch.elapsedMilliseconds;
      results.success = results.syncErrors.isEmpty;

    } catch (e) {
      stopwatch.stop();
      results.executionTimeMs = stopwatch.elapsedMilliseconds;
      results.success = false;
      results.syncErrors.add(e.toString());
    }

    return results;
  }

  /// セキュリティシナリオの実行
  static Future<SecurityScenarioResult> executeSecurityScenario() async {
    final results = SecurityScenarioResult();

    try {
      // 1. API キーの暗号化・復号化テスト
      const testApiKey = 'test_openai_key_12345';
      await apiKeyManager.storeApiKey(ApiProvider.openai, testApiKey);
      
      final retrievedKey = await apiKeyManager.getApiKey(ApiProvider.openai);
      results.apiKeyEncryptionSuccess = retrievedKey == testApiKey;

      // 2. セキュリティイベントの記録確認
      final securityEvents = apiKeyManager.getSecurityEventLog();
      results.securityEventCount = securityEvents.length;
      results.hasEncryptionEvents = securityEvents.any((event) => 
        event.type.contains('STORED') || event.type.contains('ACCESSED'));

      // 3. セキュリティメトリクスの確認
      final metrics = apiKeyManager.getSecurityMetrics();
      results.keyOperationsCount = metrics.toJson()['key_operations'] ?? 0;

      // 4. 監査データのエクスポート
      final auditData = await apiKeyManager.exportAuditData();
      results.auditDataComplete = auditData.containsKey('security_events') &&
                                  auditData.containsKey('metrics');

      // 5. バイオメトリクス設定（シミュレーション）
      await apiKeyManager.enableBiometricAuthentication();
      results.biometricEnabled = true;

      results.success = results.apiKeyEncryptionSuccess && 
                       results.hasEncryptionEvents && 
                       results.auditDataComplete;

    } catch (e) {
      results.success = false;
      results.error = e.toString();
    }

    return results;
  }

  /// パフォーマンステストシナリオの実行
  static Future<PerformanceScenarioResult> executePerformanceScenario({
    required LocalDataSource localDataSource,
    int activityCount = 1000,
  }) async {
    final results = PerformanceScenarioResult();
    final stopwatch = Stopwatch();

    try {
      // 1. 大量データの保存テスト
      stopwatch.start();
      final activities = generateMockActivities(count: activityCount);
      
      for (final activity in activities) {
        await localDataSource.saveActivity(activity);
      }
      
      stopwatch.stop();
      results.bulkSaveTimeMs = stopwatch.elapsedMilliseconds;

      // 2. 大量データの取得テスト
      stopwatch.reset();
      stopwatch.start();
      
      final retrievedActivities = await localDataSource.getActivities(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        userId: 'test_user_123',
      );
      
      stopwatch.stop();
      results.bulkRetrieveTimeMs = stopwatch.elapsedMilliseconds;
      results.retrievedCount = retrievedActivities.length;

      // 3. パフォーマンス要件の確認
      results.meetsPerformanceRequirements = 
        results.bulkSaveTimeMs < 10000 && // 10秒以下
        results.bulkRetrieveTimeMs < 2000; // 2秒以下

      results.success = results.meetsPerformanceRequirements;

    } catch (e) {
      results.success = false;
      results.error = e.toString();
    }

    return results;
  }

  /// ユーザージャーニーシナリオの実行
  static Future<UserJourneyResult> executeUserJourneyScenario({
    required LocalDataSource localDataSource,
    required RemoteDataSource remoteDataSource,
  }) async {
    final results = UserJourneyResult();

    try {
      // 1. ユーザー登録
      final testUser = generateTestUser();
      await localDataSource.saveCurrentUser(testUser);
      results.userRegistrationSuccess = true;

      // 2. ユーザー情報取得
      final retrievedUser = await localDataSource.getCurrentUser();
      results.userRetrievalSuccess = retrievedUser?.id == testUser.id;

      // 3. アクティビティ記録
      final activities = generateMockActivities(count: 3);
      for (final activity in activities) {
        await localDataSource.saveActivity(activity);
      }
      results.activityRecordingSuccess = true;

      // 4. データ同期
      try {
        await remoteDataSource.saveUser(testUser);
        for (final activity in activities) {
          await remoteDataSource.saveActivity(activity);
        }
        results.dataSyncSuccess = true;
      } catch (e) {
        results.dataSyncSuccess = false;
        results.syncError = e.toString();
      }

      // 5. ログアウト（データクリア）
      await localDataSource.clearUser();
      final clearedUser = await localDataSource.getCurrentUser();
      results.logoutSuccess = clearedUser == null;

      results.overallSuccess = results.userRegistrationSuccess &&
                              results.userRetrievalSuccess &&
                              results.activityRecordingSuccess &&
                              results.dataSyncSuccess &&
                              results.logoutSuccess;

    } catch (e) {
      results.overallSuccess = false;
      results.error = e.toString();
    }

    return results;
  }

  /// ウィジェットテスト用のアプリ起動ヘルパー
  static Future<void> launchApp(WidgetTester tester) async {
    // 実際のアプリの起動をシミュレーション
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('FatGram Integration Test')),
          body: const Center(
            child: Text('Integration Test Environment'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 統合テスト用のモック設定
  static void setupMocks({
    required MockLocalDataSource mockLocal,
    required MockRemoteDataSource mockRemote,
    required MockUnifiedHealthService mockHealth,
  }) {
    // LocalDataSource のモック設定
    when(mockLocal.saveActivity(any)).thenAnswer((_) async => {});
    when(mockLocal.getActivities(
      startDate: any,
      endDate: any,
      userId: any,
    )).thenAnswer((_) async => generateMockActivities(count: 5));
    when(mockLocal.getUnsyncedActivities(any))
        .thenAnswer((_) async => generateMockActivities(count: 2));
    when(mockLocal.markActivityAsSynced(any)).thenAnswer((_) async => {});
    when(mockLocal.saveCurrentUser(any)).thenAnswer((_) async => {});
    when(mockLocal.getCurrentUser()).thenAnswer((_) async => generateTestUser());
    when(mockLocal.clearUser()).thenAnswer((_) async => {});

    // RemoteDataSource のモック設定
    when(mockRemote.saveActivity(any)).thenAnswer((_) async => {});
    when(mockRemote.getActivities(
      startDate: any,
      endDate: any,
      userId: any,
    )).thenAnswer((_) async => generateMockActivities(count: 3));
    when(mockRemote.saveUser(any)).thenAnswer((_) async => {});
    when(mockRemote.getUser(any)).thenAnswer((_) async => generateTestUser());

    // UnifiedHealthService のモック設定
    when(mockHealth.getActivities(
      startTime: any,
      endTime: any,
    )).thenAnswer((_) async => generateMockNormalizedActivities(count: 3));
  }
}

/// データ同期シナリオの結果
class SyncScenarioResult {
  bool success = false;
  int localSaveCount = 0;
  int unsyncedCount = 0;
  int remoteSyncCount = 0;
  int retrievedCount = 0;
  int executionTimeMs = 0;
  List<String> syncErrors = [];
}

/// セキュリティシナリオの結果
class SecurityScenarioResult {
  bool success = false;
  bool apiKeyEncryptionSuccess = false;
  int securityEventCount = 0;
  bool hasEncryptionEvents = false;
  int keyOperationsCount = 0;
  bool auditDataComplete = false;
  bool biometricEnabled = false;
  String? error;
}

/// パフォーマンスシナリオの結果
class PerformanceScenarioResult {
  bool success = false;
  int bulkSaveTimeMs = 0;
  int bulkRetrieveTimeMs = 0;
  int retrievedCount = 0;
  bool meetsPerformanceRequirements = false;
  String? error;
}

/// ユーザージャーニーの結果
class UserJourneyResult {
  bool overallSuccess = false;
  bool userRegistrationSuccess = false;
  bool userRetrievalSuccess = false;
  bool activityRecordingSuccess = false;
  bool dataSyncSuccess = false;
  bool logoutSuccess = false;
  String? error;
  String? syncError;
}

/// モッククラスの基底
class MockLocalDataSource extends Mock implements LocalDataSource {}
class MockRemoteDataSource extends Mock implements RemoteDataSource {}
class MockUnifiedHealthService extends Mock implements UnifiedHealthService {}