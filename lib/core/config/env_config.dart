import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 環境変数とアプリケーション設定を管理するクラス
class EnvConfig {
  // プライベートコンストラクタで直接インスタンス化を防ぐ
  EnvConfig._();

  /// 環境変数ファイルを読み込む
  static Future<void> load() async {
    try {
      await dotenv.load();
    } catch (e) {
      // 環境変数ファイルが見つからない場合はデフォルト値を使用
      print('Warning: .env file not found, using default values');
    }
  }

  // API 設定
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.fatgram.com';

  static int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '') ?? defaultTimeout;

  // Firebase 設定
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? 'fatgram-project';

  static String get firebaseWebApiKey =>
      dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';

  // AI サービス設定
  static String get openAiApiKey =>
      dotenv.env['OPENAI_API_KEY'] ?? 'test-openai-key';

  static String get openAiModel =>
      dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo';

  // Gemini AI 設定（mobile版から統合）
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  // ウェブ検索API設定（mobile版から統合）
  static String get webSearchApiKey =>
      dotenv.env['WEB_SEARCH_API_KEY'] ?? '';

  // サブスクリプション設定
  static String get revenueCatApiKey =>
      dotenv.env['REVENUECAT_API_KEY'] ?? 'test-revenuecat-key';

  // 環境固有設定
  static String get environment =>
      dotenv.env['ENVIRONMENT'] ?? 'development';

  static bool get isDebugMode => environment == 'development';

  static bool get isProduction => environment == 'production';

  static bool get isStaging => environment == 'staging';

  // セキュリティ設定
  static String get encryptionKey =>
      dotenv.env['ENCRYPTION_KEY'] ?? 'default-encryption-key-32-chars';

  static String get jwtSecret =>
      dotenv.env['JWT_SECRET'] ?? 'default-jwt-secret';

  // デフォルト値
  static const int defaultTimeout = 30;
  static const int maxRetryAttempts = 3;
  static const int defaultCacheDuration = 300; // 5分

  // オプション設定（nullも許可）
  static String? get optionalConfig =>
      dotenv.env['OPTIONAL_CONFIG'] ?? 'default-optional-value';

  static String? get analyticsTrackingId =>
      dotenv.env['ANALYTICS_TRACKING_ID'];

  static String? get sentryDsn => dotenv.env['SENTRY_DSN'];

  // ヘルスデータ設定
  static bool get healthKitEnabled =>
      dotenv.env['HEALTHKIT_ENABLED']?.toLowerCase() == 'true';

  static bool get healthConnectEnabled =>
      dotenv.env['HEALTH_CONNECT_ENABLED']?.toLowerCase() == 'true';

  // 設定検証メソッド（mobile版から統合）
  /// Gemini AI設定が有効かどうかを確認
  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;

  /// ウェブ検索設定が有効かどうかを確認  
  static bool get isWebSearchConfigured => webSearchApiKey.isNotEmpty;

  /// AI機能全体が設定されているかを確認
  static bool get isAIConfigured => 
      (openAiApiKey.isNotEmpty && openAiApiKey != 'test-openai-key') ||
      isGeminiConfigured;

  /// 本番環境で必要な設定がすべて揃っているかを確認
  static bool get isProductionReady {
    if (!isProduction) return true;
    
    return firebaseWebApiKey.isNotEmpty &&
           (isAIConfigured || isGeminiConfigured) &&
           revenueCatApiKey.isNotEmpty &&
           revenueCatApiKey != 'test-revenuecat-key' &&
           encryptionKey != 'default-encryption-key-32-chars';
  }

  // ログ設定
  static String get logLevel =>
      dotenv.env['LOG_LEVEL'] ?? (isDebugMode ? 'debug' : 'info');

  static bool get enableFileLogging =>
      dotenv.env['ENABLE_FILE_LOGGING']?.toLowerCase() == 'true';

  // キャッシュ設定
  static int get cacheMaxSize =>
      int.tryParse(dotenv.env['CACHE_MAX_SIZE'] ?? '') ?? 100; // MB

  static int get cacheTTL =>
      int.tryParse(dotenv.env['CACHE_TTL'] ?? '') ?? defaultCacheDuration;

  // 必須環境変数の検証
  static void validateRequiredEnv() {
    final requiredVars = <String, String?>{
      'API_BASE_URL': apiBaseUrl,
      'FIREBASE_PROJECT_ID': firebaseProjectId,
      'OPENAI_API_KEY': openAiApiKey,
      'REVENUECAT_API_KEY': revenueCatApiKey,
      'ENCRYPTION_KEY': encryptionKey,
    };

    final missingVars = <String>[];

    for (final entry in requiredVars.entries) {
      if (entry.value == null || entry.value!.isEmpty) {
        missingVars.add(entry.key);
      }
    }

    if (missingVars.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missingVars.join(', ')}'
      );
    }

    // キーの長さ検証
    if (encryptionKey.length < 16) {
      throw Exception('ENCRYPTION_KEY must be at least 16 characters long');
    }
  }

  // 設定情報のサマリーを取得（デバッグ用）
  static Map<String, dynamic> getConfigSummary() {
    return {
      'environment': environment,
      'isDebugMode': isDebugMode,
      'apiBaseUrl': apiBaseUrl,
      'apiTimeout': apiTimeout,
      'firebaseProjectId': firebaseProjectId,
      'openAiModel': openAiModel,
      'healthKitEnabled': healthKitEnabled,
      'healthConnectEnabled': healthConnectEnabled,
      'logLevel': logLevel,
      'cacheMaxSize': cacheMaxSize,
      'cacheTTL': cacheTTL,
    };
  }

  // 環境変数の設定状況をチェック
  static Map<String, bool> checkEnvStatus() {
    return {
      'envFileLoaded': dotenv.isEveryDefined(['API_BASE_URL']),
      'hasApiConfig': apiBaseUrl.isNotEmpty,
      'hasFirebaseConfig': firebaseProjectId.isNotEmpty,
      'hasAiConfig': openAiApiKey.isNotEmpty,
      'hasSubscriptionConfig': revenueCatApiKey.isNotEmpty,
      'hasEncryptionKey': encryptionKey.length >= 16,
    };
  }
}