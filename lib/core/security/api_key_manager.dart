import 'dart:convert';
// import 'dart:typed_data'; // 未使用のため削除
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fatgram/core/error/exceptions.dart';
import 'package:logger/logger.dart';

/// APIプロバイダー列挙型
enum ApiProvider {
  openai,
  gemini,
  webSearch,
  revenueCat,
  firebase,
}

/// APIキーの暗号化・復号化・管理を行うクラス
class ApiKeyManager {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final Logger _logger;
  final String _encryptionKey;
  bool _isInitialized = false;

  // キーの接頭辞
  static const String _keyPrefix = 'fatgram_api_';
  // static const String _refreshTokenPrefix = 'fatgram_refresh_'; // 未使用のため削除

  ApiKeyManager({
    required String encryptionKey,
    Logger? logger,
  }) : _encryptionKey = encryptionKey,
       _logger = logger ?? Logger();

  /// APIキーマネージャーの初期化
  Future<void> initialize() async {
    try {
      if (_encryptionKey.length < 16) {
        throw const CacheException(
          message: 'Encryption key must be at least 16 characters long',
          code: 'INVALID_ENCRYPTION_KEY',
        );
      }

      // 初期化テスト用のダミーデータを暗号化・復号化してテスト
      const testData = 'initialization_test';
      final encrypted = _encryptData(testData);
      final decrypted = _decryptData(encrypted);

      if (decrypted != testData) {
        throw const CacheException(
          message: 'Encryption/decryption test failed',
          code: 'CRYPTO_TEST_FAILED',
        );
      }

      _isInitialized = true;
      _logger.i('ApiKeyManager: Initialized successfully');
    } catch (e) {
      _logger.e('ApiKeyManager: Initialization failed: $e');
      throw CacheException(
        message: 'Failed to initialize ApiKeyManager: ${e.toString()}',
        code: 'INITIALIZATION_FAILED',
      );
    }
  }

  /// 初期化状態を取得
  bool get isInitialized => _isInitialized;

  /// APIキーを暗号化してセキュアストレージに保存
  Future<String> storeApiKey(ApiProvider provider, String apiKey) async {
    _checkInitialized();

    if (apiKey.isEmpty) {
      throw const ValidationException(
        message: 'API key cannot be empty',
        code: 'EMPTY_API_KEY',
      );
    }

    try {
      final encryptedKey = _encryptData(apiKey);
      final storageKey = _getStorageKey(provider);

      await _secureStorage.write(
        key: storageKey,
        value: encryptedKey,
      );

      _logger.d('ApiKeyManager: Stored encrypted API key for ${provider.name}');
      return encryptedKey;
    } catch (e) {
      _logger.e('ApiKeyManager: Failed to store API key for ${provider.name}: $e');
      throw CacheException(
        message: 'Failed to store API key: ${e.toString()}',
        code: 'STORAGE_FAILED',
      );
    }
  }

  /// セキュアストレージからAPIキーを取得・復号化
  Future<String> getApiKey(ApiProvider provider) async {
    _checkInitialized();

    try {
      final storageKey = _getStorageKey(provider);
      final encryptedKey = await _secureStorage.read(key: storageKey);

      if (encryptedKey == null) {
        throw CacheException(
          message: 'API key not found for ${provider.name}',
          code: 'API_KEY_NOT_FOUND',
        );
      }

      final decryptedKey = _decryptData(encryptedKey);
      _logger.d('ApiKeyManager: Retrieved API key for ${provider.name}');
      return decryptedKey;
    } catch (e) {
      if (e is CacheException) rethrow;

      _logger.e('ApiKeyManager: Failed to get API key for ${provider.name}: $e');
      throw CacheException(
        message: 'Failed to retrieve API key: ${e.toString()}',
        code: 'RETRIEVAL_FAILED',
      );
    }
  }

  /// APIキーを削除
  Future<void> deleteApiKey(ApiProvider provider) async {
    _checkInitialized();

    try {
      final storageKey = _getStorageKey(provider);
      await _secureStorage.delete(key: storageKey);

      _logger.d('ApiKeyManager: Deleted API key for ${provider.name}');
    } catch (e) {
      _logger.e('ApiKeyManager: Failed to delete API key for ${provider.name}: $e');
      throw CacheException(
        message: 'Failed to delete API key: ${e.toString()}',
        code: 'DELETION_FAILED',
      );
    }
  }

  /// APIキーが存在するかチェック
  Future<bool> hasApiKey(ApiProvider provider) async {
    _checkInitialized();

    try {
      final storageKey = _getStorageKey(provider);
      final encryptedKey = await _secureStorage.read(key: storageKey);
      return encryptedKey != null && encryptedKey.isNotEmpty;
    } catch (e) {
      _logger.e('ApiKeyManager: Failed to check API key existence for ${provider.name}: $e');
      return false;
    }
  }

  /// APIキーをリフレッシュ（バックエンドから新しいキーを取得）
  Future<String> refreshApiKey(ApiProvider provider) async {
    _checkInitialized();

    try {
      // 実際の実装では、バックエンドAPIを呼び出して新しいAPIキーを取得する
      // ここではシミュレーション
      await Future.delayed(const Duration(milliseconds: 500));

      final newApiKey = _generateMockApiKey(provider);
      await storeApiKey(provider, newApiKey);

      _logger.i('ApiKeyManager: Refreshed API key for ${provider.name}');
      return newApiKey;
    } catch (e) {
      _logger.e('ApiKeyManager: Failed to refresh API key for ${provider.name}: $e');
      throw NetworkException(
        message: 'Failed to refresh API key: ${e.toString()}',
        code: 'REFRESH_FAILED',
      );
    }
  }

  /// 全てのAPIキーを削除
  Future<void> clearAllApiKeys() async {
    _checkInitialized();

    try {
      for (final provider in ApiProvider.values) {
        await deleteApiKey(provider);
      }
      _logger.i('ApiKeyManager: Cleared all API keys');
    } catch (e) {
      _logger.e('ApiKeyManager: Failed to clear all API keys: $e');
      throw CacheException(
        message: 'Failed to clear all API keys: ${e.toString()}',
        code: 'CLEAR_ALL_FAILED',
      );
    }
  }

  /// 保存されているAPIキーのリストを取得
  Future<List<ApiProvider>> getStoredApiProviders() async {
    _checkInitialized();

    final storedProviders = <ApiProvider>[];

    for (final provider in ApiProvider.values) {
      if (await hasApiKey(provider)) {
        storedProviders.add(provider);
      }
    }

    return storedProviders;
  }

  /// セキュリティ監査用の情報を取得
  Future<Map<String, dynamic>> getSecurityAuditInfo() async {
    _checkInitialized();

    final auditInfo = <String, dynamic>{
      'initialized': _isInitialized,
      'encryption_key_length': _encryptionKey.length,
      'stored_providers': [],
      'last_audit_time': DateTime.now().toIso8601String(),
    };

    final storedProviders = await getStoredApiProviders();
    auditInfo['stored_providers'] = storedProviders.map((p) => p.name).toList();

    return auditInfo;
  }

  // ===================
  // プライベートメソッド
  // ===================

  /// 初期化状態をチェック
  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('ApiKeyManager is not initialized. Call initialize() first.');
    }
  }

  /// ストレージキーを生成
  String _getStorageKey(ApiProvider provider) {
    return '$_keyPrefix${provider.name}';
  }

  /// データを暗号化
  String _encryptData(String data) {
    try {
      // 簡単な暗号化（本番環境ではより強力な暗号化を使用）
      final bytes = utf8.encode(data);
      final keyBytes = utf8.encode(_encryptionKey);

      // XOR暗号化（デモ用途、本番環境ではAES等を使用）
      final encrypted = <int>[];
      for (int i = 0; i < bytes.length; i++) {
        encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return base64.encode(encrypted);
    } catch (e) {
      throw CacheException(
        message: 'Encryption failed: ${e.toString()}',
        code: 'ENCRYPTION_FAILED',
      );
    }
  }

  /// データを復号化
  String _decryptData(String encryptedData) {
    try {
      final encrypted = base64.decode(encryptedData);
      final keyBytes = utf8.encode(_encryptionKey);

      // XOR復号化
      final decrypted = <int>[];
      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      throw CacheException(
        message: 'Decryption failed: ${e.toString()}',
        code: 'DECRYPTION_FAILED',
      );
    }
  }

  /// モックAPIキーを生成（テスト・デモ用）
  String _generateMockApiKey(ApiProvider provider) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final content = '${provider.name}_api_key_$timestamp';
    final hash = sha256.convert(utf8.encode(content)).toString();
    return '${provider.name}_${hash.substring(0, 32)}';
  }
}