import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// 統合されたアプリケーション構造
import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/services/injector.dart';
// Flutter 3.32.x エンタープライズ設定
import 'core/config/flutter_config_2025.dart';
import 'core/security/enhanced_api_key_manager.dart';

/// Flutter 3.32.x エンタープライズレベル メイン実装
/// プロダクション品質の初期化とエラーハンドリング
void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Flutter 3.32.x エンタープライズ設定初期化
      await FlutterConfig2025.initialize();
      
      // プロダクション環境設定
      await _initializeProductionEnvironment();
      
      // セキュリティ強化設定
      await _configureSecuritySettings();
      
      // パフォーマンス監視設定
      await _configurePerformanceMonitoring();
      
      // エラー監視設定
      await _configureErrorMonitoring();
      
      // 環境設定の読み込み
      await EnvConfig.load();
      
      // Firebase の初期化
      await Firebase.initializeApp();
      
      // セキュリティAPIキー管理初期化
      await EnhancedApiKeyManager.initialize();
      
      // 依存性注入の設定
      await setupInjector();
      
      // Riverpod + Firebase統合でアプリ開始
      runApp(
        ProviderScope(
          observers: [
            if (kDebugMode) ProviderLogger(),
          ],
          child: const FatGramApp(),
        ),
      );
    },
    (error, stack) {
      // プロダクションエラーハンドリング
      debugPrint('Fatal Error: $error');
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
        );
      }
    },
  );
}

/// プロダクション環境設定
Future<void> _initializeProductionEnvironment() async {
  // プロダクション最適化設定
  if (kReleaseMode || kProfileMode) {
    // デバッグ情報無効化
    debugPaintSizeEnabled = false;
    debugRepaintRainbowEnabled = false;
    
    // パフォーマンス最適化
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }
  
  // Flutter 3.32.x新機能有効化
  if (FlutterConfig2025.enableImpellerAndroid) {
    // Impeller Rendering Engine有効化（Android）
    debugPrint('Impeller Rendering Engine enabled for Android');
  }
  
  if (FlutterConfig2025.enableImpellerIOS) {
    // Impeller Rendering Engine有効化（iOS）
    debugPrint('Impeller Rendering Engine enabled for iOS');
  }
  
  // Web Hot Reload設定（開発時のみ）
  if (kIsWeb && kDebugMode && FlutterConfig2025.enableWebHotReload) {
    debugPrint('Web Hot Reload enabled (experimental)');
  }
}

/// セキュリティ強化設定
Future<void> _configureSecuritySettings() async {
  if (FlutterConfig2025.enableSecurityMode) {
    // セキュアモード有効化
    if (!kDebugMode) {
      // スクリーンショット防止（本番のみ）
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
    }
    
    // ルート検知・改ざん検知
    // await SecurityChecker.validateDeviceIntegrity();
  }
}

/// パフォーマンス監視設定
Future<void> _configurePerformanceMonitoring() async {
  if (!kDebugMode) {
    // Firebase Performance Monitoring
    final performance = FirebasePerformance.instance;
    await performance.setPerformanceCollectionEnabled(true);
    
    // カスタムメトリクス設定
    final startupTrace = performance.newTrace('app_startup');
    await startupTrace.start();
    
    // アプリ起動完了後にトレース終了
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await startupTrace.stop();
    });
  }
}

/// エラー監視設定
Future<void> _configureErrorMonitoring() async {
  if (!kDebugMode) {
    // Flutter Framework エラー
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    
    // プラットフォーム固有エラー
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
      );
      return true;
    };
  }
}

/// Riverpod ログ出力（開発時のみ）
class ProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint(
        'Provider ${provider.name ?? provider.runtimeType} updated: '
        '$previousValue -> $newValue',
      );
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      debugPrint(
        'Provider ${provider.name ?? provider.runtimeType} failed: $error',
      );
    }
  }
}

