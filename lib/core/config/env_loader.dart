import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'env_config.dart';

/// 環境変数の読み込みと初期化を管理するクラス
class EnvLoader {
  static bool _isLoaded = false;

  /// 環境変数を読み込み、アプリケーションの初期化を行う
  static Future<void> load() async {
    if (_isLoaded) return;

    try {
      // 環境に応じた.envファイルを読み込む
      await _loadEnvFile();

      // 環境変数の読み込み
      await EnvConfig.load();

      // 必須環境変数の検証
      _validateEnvironment();

      _isLoaded = true;

      if (kDebugMode) {
        _logConfiguration();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading environment configuration: $e');
      }
      rethrow;
    }
  }

  /// 環境に応じた.envファイルを読み込む
  static Future<void> _loadEnvFile() async {
    final environment = Platform.environment['FLUTTER_ENV'] ?? 'development';

    final envFiles = [
      '.env.$environment.local',  // 環境固有のローカル設定
      '.env.local',               // ローカル設定
      '.env.$environment',        // 環境固有設定
      '.env',                     // デフォルト設定
    ];

    for (final envFile in envFiles) {
      try {
        if (await File(envFile).exists()) {
          await dotenv.load(fileName: envFile);
          if (kDebugMode) {
            print('Loaded environment file: $envFile');
          }
          break;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Could not load $envFile: $e');
        }
      }
    }
  }

  /// 環境変数の検証
  static void _validateEnvironment() {
    try {
      EnvConfig.validateRequiredEnv();
    } catch (e) {
      if (kDebugMode) {
        print('Environment validation warning: $e');
        print('Using default values for missing configuration');
      }
      // プロダクション環境では例外を再スロー
      if (EnvConfig.isProduction) {
        rethrow;
      }
    }
  }

  /// 設定情報をログ出力（デバッグ時のみ）
  static void _logConfiguration() {
    if (!kDebugMode) return;

    print('=== Environment Configuration ===');
    final config = EnvConfig.getConfigSummary();
    config.forEach((key, value) {
      // 機密情報はマスク
      final displayValue = _maskSensitiveValue(key, value);
      print('$key: $displayValue');
    });

    print('=== Environment Status ===');
    final status = EnvConfig.checkEnvStatus();
    status.forEach((key, value) {
      print('$key: $value');
    });
    print('================================');
  }

  /// 機密情報をマスクする
  static String _maskSensitiveValue(String key, dynamic value) {
    final sensitiveKeys = [
      'openaiApiKey',
      'revenueCatApiKey',
      'encryptionKey',
      'jwtSecret',
    ];

    if (sensitiveKeys.any((k) => key.toLowerCase().contains(k.toLowerCase()))) {
      if (value is String && value.isNotEmpty) {
        if (value.length <= 8) {
          return '***';
        }
        return '${value.substring(0, 4)}***${value.substring(value.length - 4)}';
      }
      return '***';
    }

    return value.toString();
  }

  /// 環境変数が読み込み済みかチェック
  static bool get isLoaded => _isLoaded;

  /// 設定をリロード（テスト用）
  static Future<void> reload() async {
    _isLoaded = false;
    dotenv.clean();
    await load();
  }

  /// 環境変数の手動設定（テスト用）
  static void setTestEnvironment(Map<String, String> testEnv) {
    if (!kDebugMode) {
      throw Exception('Test environment can only be set in debug mode');
    }

    dotenv.testLoad(fileInput: testEnv.entries
        .map((e) => '${e.key}=${e.value}')
        .join('\n'));
  }

  /// アプリケーション初期化時の前提条件チェック
  static void checkPreconditions() {
    if (!_isLoaded) {
      throw Exception('Environment not loaded. Call EnvLoader.load() first.');
    }

    final status = EnvConfig.checkEnvStatus();
    final criticalMissing = <String>[];

    if (!status['hasApiConfig']!) {
      criticalMissing.add('API configuration');
    }
    if (!status['hasFirebaseConfig']!) {
      criticalMissing.add('Firebase configuration');
    }
    if (!status['hasEncryptionKey']!) {
      criticalMissing.add('Encryption key');
    }

    if (criticalMissing.isNotEmpty && EnvConfig.isProduction) {
      throw Exception(
        'Critical configuration missing in production: ${criticalMissing.join(', ')}'
      );
    }
  }
}