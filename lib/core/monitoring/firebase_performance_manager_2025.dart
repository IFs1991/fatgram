// Firebase Performance Manager 2025
// エンタープライズレベル統合テストスイート
// Firebase Performance Monitoring統合実装

import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Firebase Performance Manager 2025年版
/// 
/// エンタープライズレベルのパフォーマンス監視システム
/// - リアルタイム性能監視
/// - 自動メトリクス収集
/// - 異常検知・アラート
/// - 本番環境最適化
class FirebasePerformanceManager2025 {
  static final FirebasePerformanceManager2025 _instance = 
      FirebasePerformanceManager2025._internal();
  factory FirebasePerformanceManager2025() => _instance;
  FirebasePerformanceManager2025._internal();

  static late FirebasePerformance _performance;
  static final Logger _logger = Logger();
  static final Map<String, Trace> _activeTraces = {};
  static final Map<String, HttpMetric> _activeHttpMetrics = {};
  
  // エンタープライズメトリクス
  static const Map<String, int> _performanceTargets = {
    'app_startup_ms': 2000,          // アプリ起動時間 < 2秒
    'memory_usage_mb': 100,          // メモリ使用量 < 100MB
    'ai_response_ms': 500,           // AI応答時間 < 500ms
    'touch_response_ms': 16,         // タッチレスポンス < 16ms
    'frame_render_ms': 8,            // フレームレンダリング < 8ms (120fps)
    'network_timeout_ms': 5000,      // ネットワークタイムアウト < 5秒
    'database_query_ms': 100,        // データベースクエリ < 100ms
  };
  
  // パフォーマンス監視状態
  static bool _isInitialized = false;
  static bool _isMonitoringEnabled = true;
  static final StreamController<PerformanceAlert> _alertController = 
      StreamController<PerformanceAlert>.broadcast();
  
  /// 初期化
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _performance = FirebasePerformance.instance;
      
      // パフォーマンス収集有効化
      await _performance.setPerformanceCollectionEnabled(true);
      
      // データ処理有効化
      await _performance.setDataCollectionEnabled(true);
      
      _isInitialized = true;
      _logger.i('Firebase Performance Manager 2025初期化完了');
      
      // 自動監視開始
      _startAutomaticMonitoring();
      
    } catch (e) {
      _logger.e('Firebase Performance Manager初期化エラー: $e');
      rethrow;
    }
  }
  
  /// アプリ起動パフォーマンス監視
  static Future<void> monitorAppStartup() async {
    if (!_isInitialized) return;
    
    final trace = _performance.newTrace('app_startup_2025');
    
    try {
      await trace.start();
      trace.putAttribute('platform', defaultTargetPlatform.name);
      trace.putAttribute('version', '2025.6.24');
      trace.putAttribute('environment', kDebugMode ? 'debug' : 'release');
      
      _activeTraces['app_startup'] = trace;
      _logger.i('アプリ起動監視開始');
      
    } catch (e) {
      _logger.e('アプリ起動監視エラー: $e');
    }
  }
  
  /// アプリ起動完了
  static Future<void> appStartupCompleted({
    required int startupTimeMs,
    required int memoryUsageMb,
  }) async {
    final trace = _activeTraces['app_startup'];
    if (trace == null) return;
    
    try {
      // メトリクス設定
      trace.setMetric('startup_time_ms', startupTimeMs);
      trace.setMetric('memory_usage_mb', memoryUsageMb);
      
      // パフォーマンス評価
      if (startupTimeMs > _performanceTargets['app_startup_ms']!) {
        trace.putAttribute('performance_warning', 'startup_slow');
        _sendAlert(PerformanceAlert(
          type: AlertType.startupSlow,
          value: startupTimeMs,
          threshold: _performanceTargets['app_startup_ms']!,
          message: 'アプリ起動時間が目標値を超過: ${startupTimeMs}ms',
        ));
      }
      
      if (memoryUsageMb > _performanceTargets['memory_usage_mb']!) {
        trace.putAttribute('memory_warning', 'high_usage');
        _sendAlert(PerformanceAlert(
          type: AlertType.memoryHigh,
          value: memoryUsageMb,
          threshold: _performanceTargets['memory_usage_mb']!,
          message: 'メモリ使用量が目標値を超過: ${memoryUsageMb}MB',
        ));
      }
      
      await trace.stop();
      _activeTraces.remove('app_startup');
      
      _logger.i('アプリ起動監視完了 - 起動時間: ${startupTimeMs}ms, メモリ: ${memoryUsageMb}MB');
      
    } catch (e) {
      _logger.e('アプリ起動完了処理エラー: $e');
    }
  }
  
  /// AI応答パフォーマンス監視
  static Future<Trace> startAiResponseMonitoring({
    required String aiModel,
    required String requestType,
  }) async {
    if (!_isInitialized) throw StateError('Performance Manager未初期化');
    
    final trace = _performance.newTrace('ai_response_${aiModel}_$requestType');
    
    try {
      await trace.start();
      trace.putAttribute('ai_model', aiModel);
      trace.putAttribute('request_type', requestType);
      trace.putAttribute('timestamp', DateTime.now().toIso8601String());
      
      final traceKey = 'ai_${aiModel}_$requestType';
      _activeTraces[traceKey] = trace;
      
      _logger.d('AI応答監視開始: $aiModel - $requestType');
      return trace;
      
    } catch (e) {
      _logger.e('AI応答監視開始エラー: $e');
      rethrow;
    }
  }
  
  /// AI応答完了
  static Future<void> completeAiResponseMonitoring(
    Trace trace, {
    required int responseTimeMs,
    required bool isSuccess,
    String? errorMessage,
  }) async {
    try {
      // メトリクス設定
      trace.setMetric('response_time_ms', responseTimeMs);
      trace.setMetric('success', isSuccess ? 1 : 0);
      
      if (errorMessage != null) {
        trace.putAttribute('error_message', errorMessage);
      }
      
      // パフォーマンス評価
      if (responseTimeMs > _performanceTargets['ai_response_ms']!) {
        trace.putAttribute('performance_warning', 'response_slow');
        _sendAlert(PerformanceAlert(
          type: AlertType.aiResponseSlow,
          value: responseTimeMs,
          threshold: _performanceTargets['ai_response_ms']!,
          message: 'AI応答時間が目標値を超過: ${responseTimeMs}ms',
        ));
      }
      
      await trace.stop();
      _logger.d('AI応答監視完了 - 応答時間: ${responseTimeMs}ms, 成功: $isSuccess');
      
    } catch (e) {
      _logger.e('AI応答完了処理エラー: $e');
    }
  }
  
  /// UI/UX パフォーマンス監視
  static Future<void> monitorUiPerformance({
    required String screenName,
    required int frameCount,
    required List<int> frameTimesMs,
  }) async {
    if (!_isInitialized) return;
    
    final trace = _performance.newTrace('ui_performance_$screenName');
    
    try {
      await trace.start();
      trace.putAttribute('screen_name', screenName);
      trace.putAttribute('frame_count', frameCount.toString());
      
      // フレーム統計計算
      final avgFrameTime = frameTimesMs.reduce((a, b) => a + b) / frameTimesMs.length;
      final maxFrameTime = frameTimesMs.reduce((a, b) => a > b ? a : b);
      final smoothFrames = frameTimesMs.where((t) => t <= 16).length;
      final smoothnessRate = (smoothFrames / frameTimesMs.length) * 100;
      
      trace.setMetric('avg_frame_time_ms', avgFrameTime.round());
      trace.setMetric('max_frame_time_ms', maxFrameTime);
      trace.setMetric('smoothness_rate', smoothnessRate.round());
      
      // パフォーマンス評価
      if (smoothnessRate < 99.0) {
        trace.putAttribute('performance_warning', 'low_smoothness');
        _sendAlert(PerformanceAlert(
          type: AlertType.lowSmoothness,
          value: smoothnessRate.round(),
          threshold: 99,
          message: 'スムーズ率が目標値を下回る: ${smoothnessRate.toStringAsFixed(1)}%',
        ));
      }
      
      await trace.stop();
      _logger.d('UI性能監視完了 - $screenName: スムーズ率 ${smoothnessRate.toStringAsFixed(1)}%');
      
    } catch (e) {
      _logger.e('UI性能監視エラー: $e');
    }
  }
  
  /// ネットワークパフォーマンス監視
  static Future<HttpMetric> startNetworkMonitoring({
    required String url,
    required String httpMethod,
  }) async {
    if (!_isInitialized) throw StateError('Performance Manager未初期化');
    
    final metric = _performance.newHttpMetric(url, HttpMethod.values.firstWhere(
      (method) => method.name.toUpperCase() == httpMethod.toUpperCase(),
      orElse: () => HttpMethod.Get,
    ));
    
    try {
      await metric.start();
      
      final metricKey = '${httpMethod}_${Uri.parse(url).host}';
      _activeHttpMetrics[metricKey] = metric;
      
      _logger.d('ネットワーク監視開始: $httpMethod $url');
      return metric;
      
    } catch (e) {
      _logger.e('ネットワーク監視開始エラー: $e');
      rethrow;
    }
  }
  
  /// ネットワーク監視完了
  static Future<void> completeNetworkMonitoring(
    HttpMetric metric, {
    required int httpResponseCode,
    required int responseTimeMs,
    required int requestPayloadSize,
    required int responsePayloadSize,
  }) async {
    try {
      metric.httpResponseCode = httpResponseCode;
      metric.requestPayloadSize = requestPayloadSize;
      metric.responsePayloadSize = responsePayloadSize;
      
      // カスタムメトリクス
      metric.putAttribute('response_time_ms', responseTimeMs.toString());
      metric.putAttribute('timestamp', DateTime.now().toIso8601String());
      
      // パフォーマンス評価
      if (responseTimeMs > _performanceTargets['network_timeout_ms']!) {
        metric.putAttribute('performance_warning', 'network_slow');
        _sendAlert(PerformanceAlert(
          type: AlertType.networkSlow,
          value: responseTimeMs,
          threshold: _performanceTargets['network_timeout_ms']!,
          message: 'ネットワーク応答時間が目標値を超過: ${responseTimeMs}ms',
        ));
      }
      
      await metric.stop();
      _logger.d('ネットワーク監視完了 - 応答時間: ${responseTimeMs}ms, ステータス: $httpResponseCode');
      
    } catch (e) {
      _logger.e('ネットワーク監視完了エラー: $e');
    }
  }
  
  /// データベースパフォーマンス監視
  static Future<void> monitorDatabaseQuery({
    required String queryType,
    required String collection,
    required int queryTimeMs,
    required int resultCount,
  }) async {
    if (!_isInitialized) return;
    
    final trace = _performance.newTrace('database_query_${queryType}_$collection');
    
    try {
      await trace.start();
      trace.putAttribute('query_type', queryType);
      trace.putAttribute('collection', collection);
      trace.putAttribute('result_count', resultCount.toString());
      
      trace.setMetric('query_time_ms', queryTimeMs);
      trace.setMetric('result_count', resultCount);
      
      // パフォーマンス評価
      if (queryTimeMs > _performanceTargets['database_query_ms']!) {
        trace.putAttribute('performance_warning', 'query_slow');
        _sendAlert(PerformanceAlert(
          type: AlertType.databaseSlow,
          value: queryTimeMs,
          threshold: _performanceTargets['database_query_ms']!,
          message: 'データベースクエリが目標値を超過: ${queryTimeMs}ms',
        ));
      }
      
      await trace.stop();
      _logger.d('DB監視完了 - $queryType $collection: ${queryTimeMs}ms, 結果件数: $resultCount');
      
    } catch (e) {
      _logger.e('データベース監視エラー: $e');
    }
  }
  
  /// 自動監視開始
  static void _startAutomaticMonitoring() {
    if (!_isMonitoringEnabled) return;
    
    // メモリ使用量監視
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _monitorMemoryUsage();
    });
    
    // フレームレート監視
    developer.Timeline.startSync('performance_monitoring');
    
    _logger.i('自動パフォーマンス監視開始');
  }
  
  /// メモリ使用量監視
  static void _monitorMemoryUsage() {
    try {
      // 実際の実装では、dart:developer や外部パッケージを使用
      final memoryUsage = 45; // MB (仮の値)
      
      if (memoryUsage > _performanceTargets['memory_usage_mb']!) {
        _sendAlert(PerformanceAlert(
          type: AlertType.memoryHigh,
          value: memoryUsage,
          threshold: _performanceTargets['memory_usage_mb']!,
          message: 'メモリ使用量が継続的に高い: ${memoryUsage}MB',
        ));
      }
      
    } catch (e) {
      _logger.w('メモリ監視エラー: $e');
    }
  }
  
  /// アラート送信
  static void _sendAlert(PerformanceAlert alert) {
    _alertController.add(alert);
    _logger.w('パフォーマンスアラート: ${alert.message}');
  }
  
  /// アラートストリーム取得
  static Stream<PerformanceAlert> get alertStream => _alertController.stream;
  
  /// 監視有効/無効切り替え
  static void setMonitoringEnabled(bool enabled) {
    _isMonitoringEnabled = enabled;
    _logger.i('パフォーマンス監視: ${enabled ? '有効' : '無効'}');
  }
  
  /// カスタムメトリクス記録
  static Future<void> recordCustomMetric({
    required String name,
    required Map<String, dynamic> data,
    Map<String, String>? attributes,
  }) async {
    if (!_isInitialized) return;
    
    final trace = _performance.newTrace('custom_metric_$name');
    
    try {
      await trace.start();
      
      // 属性設定
      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }
      
      // データをメトリクスに変換
      data.forEach((key, value) {
        if (value is int) {
          trace.setMetric(key, value);
        } else if (value is double) {
          trace.setMetric(key, value.round());
        } else {
          trace.putAttribute(key, value.toString());
        }
      });
      
      await trace.stop();
      _logger.d('カスタムメトリクス記録: $name');
      
    } catch (e) {
      _logger.e('カスタムメトリクス記録エラー: $e');
    }
  }
  
  /// リソース解放
  static Future<void> dispose() async {
    // アクティブなトレースを停止
    for (final trace in _activeTraces.values) {
      try {
        await trace.stop();
      } catch (e) {
        _logger.w('トレース停止エラー: $e');
      }
    }
    _activeTraces.clear();
    
    // アクティブなHTTPメトリクスを停止
    for (final metric in _activeHttpMetrics.values) {
      try {
        await metric.stop();
      } catch (e) {
        _logger.w('HTTPメトリクス停止エラー: $e');
      }
    }
    _activeHttpMetrics.clear();
    
    await _alertController.close();
    _logger.i('Firebase Performance Manager 2025リソース解放完了');
  }
}

/// パフォーマンスアラート
class PerformanceAlert {
  final AlertType type;
  final int value;
  final int threshold;
  final String message;
  final DateTime timestamp;
  
  PerformanceAlert({
    required this.type,
    required this.value,
    required this.threshold,
    required this.message,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() => 'PerformanceAlert{type: $type, value: $value, threshold: $threshold, message: $message}';
}

/// アラートタイプ
enum AlertType {
  startupSlow,
  memoryHigh,
  aiResponseSlow,
  lowSmoothness,
  networkSlow,
  databaseSlow,
}

/// パフォーマンス統計
class PerformanceStats {
  final Map<String, int> metrics;
  final Map<String, String> attributes;
  final DateTime timestamp;
  
  PerformanceStats({
    required this.metrics,
    required this.attributes,
  }) : timestamp = DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'metrics': metrics,
    'attributes': attributes,
    'timestamp': timestamp.toIso8601String(),
  };
}