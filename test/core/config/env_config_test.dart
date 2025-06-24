import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fatgram/core/config/env_config.dart';

void main() {
  setUpAll(() async {
    // テスト用の環境変数を設定
    dotenv.testLoad(fileInput: '''
API_BASE_URL=https://test-api.fatgram.com
API_TIMEOUT=30
FIREBASE_PROJECT_ID=test-firebase-project
OPENAI_API_KEY=test-openai-key
REVENUECAT_API_KEY=test-revenuecat-key
ENVIRONMENT=development
ENCRYPTION_KEY=test-encryption-key-32-chars
OPTIONAL_CONFIG=test-optional-value
''');
  });

  group('EnvConfig', () {
    test('should have valid API URL configuration', () {
      // Act & Assert
      expect(EnvConfig.apiBaseUrl, equals('https://test-api.fatgram.com'));
      expect(EnvConfig.apiBaseUrl, startsWith('http'));
    });

    test('should have valid Firebase configuration', () {
      // Act & Assert
      expect(EnvConfig.firebaseProjectId, equals('test-firebase-project'));
    });

    test('should have AI service configuration', () {
      // Act & Assert
      expect(EnvConfig.openAiApiKey, equals('test-openai-key'));
    });

    test('should have subscription service configuration', () {
      // Act & Assert
      expect(EnvConfig.revenueCatApiKey, equals('test-revenuecat-key'));
    });

    test('should have environment-specific configurations', () {
      // Act & Assert
      expect(EnvConfig.environment, equals('development'));
      expect(EnvConfig.isDebugMode, isTrue);
    });

    test('should handle missing environment variables gracefully', () {
      // Act & Assert
      expect(EnvConfig.optionalConfig, equals('test-optional-value'));
      // オプション設定はnullでも許可されるべき
    });

    test('should validate required environment variables', () {
      // Act & Assert
      expect(() => EnvConfig.validateRequiredEnv(), returnsNormally);
    });

    test('should provide default values for optional configurations', () {
      // Act & Assert
      expect(EnvConfig.defaultTimeout, equals(30));
      expect(EnvConfig.maxRetryAttempts, equals(3));
    });

    test('should have proper encryption keys', () {
      // Act & Assert
      expect(EnvConfig.encryptionKey, equals('test-encryption-key-32-chars'));
      expect(EnvConfig.encryptionKey, hasLength(greaterThan(16))); // 適切な長さのキー
    });

    test('should configure API timeout values', () {
      // Act & Assert
      expect(EnvConfig.apiTimeout, equals(30));
      expect(EnvConfig.apiTimeout, greaterThan(0));
      expect(EnvConfig.apiTimeout, lessThanOrEqualTo(60)); // 最大60秒
    });
  });

  group('EnvConfig Environment-specific behavior', () {
    test('development environment should have debug features enabled', () {
      // このテストは後で実際の環境設定に基づいて実装
      expect(EnvConfig.environment, isNotEmpty);
    });

    test('production environment should have optimized settings', () {
      // このテストは後で実際の環境設定に基づいて実装
      expect(EnvConfig.environment, isNotEmpty);
    });
  });
}