import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// セキュアなストレージサービスを提供するクラス
/// 認証トークンや機密データの暗号化保存を担当
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
    mOptions: MacOsOptions(),
  );

  /// 値を暗号化して保存
  Future<void> write(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      if (kDebugMode) {
        print('SecureStorage: Saved key=$key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorage Error writing key=$key: $e');
      }
      rethrow;
    }
  }

  /// 暗号化された値を読み取り
  Future<String?> read(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (kDebugMode) {
        print('SecureStorage: Read key=$key, hasValue=${value != null}');
      }
      return value;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorage Error reading key=$key: $e');
      }
      return null;
    }
  }

  /// 指定されたキーのデータを削除
  Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
      if (kDebugMode) {
        print('SecureStorage: Deleted key=$key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorage Error deleting key=$key: $e');
      }
      rethrow;
    }
  }

  /// 全てのデータを削除
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
      if (kDebugMode) {
        print('SecureStorage: Deleted all data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorage Error deleting all: $e');
      }
      rethrow;
    }
  }

  /// 指定されたキーが存在するかチェック
  Future<bool> containsKey(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      return value != null;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorage Error checking key=$key: $e');
      }
      return false;
    }
  }

  /// 全てのキーを取得
  Future<Map<String, String>> readAll() async {
    try {
      final allData = await _secureStorage.readAll();
      if (kDebugMode) {
        print('SecureStorage: Read all data, count=${allData.length}');
      }
      return allData;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorage Error reading all: $e');
      }
      return {};
    }
  }

  /// 複数の値を一度に保存
  Future<void> writeAll(Map<String, String> data) async {
    try {
      for (final entry in data.entries) {
        await write(entry.key, entry.value);
      }
      if (kDebugMode) {
        print('SecureStorage: Wrote ${data.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorage Error writing all: $e');
      }
      rethrow;
    }
  }

  /// 指定されたプレフィックスを持つ全てのキーを削除
  Future<void> deleteByPrefix(String prefix) async {
    try {
      final allData = await readAll();
      final keysToDelete = allData.keys
          .where((key) => key.startsWith(prefix))
          .toList();

      for (final key in keysToDelete) {
        await delete(key);
      }

      if (kDebugMode) {
        print('SecureStorage: Deleted ${keysToDelete.length} keys with prefix=$prefix');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorage Error deleting by prefix=$prefix: $e');
      }
      rethrow;
    }
  }

  /// 認証関連データのクリア
  Future<void> clearAuthData() async {
    await deleteByPrefix('auth_');
    await deleteByPrefix('token_');
    await deleteByPrefix('session_');
  }

  /// ユーザー関連データのクリア
  Future<void> clearUserData() async {
    await deleteByPrefix('user_');
    await deleteByPrefix('profile_');
  }

  /// バックアップとリストア用のエクスポート（開発・デバッグ用）
  Future<Map<String, String>> exportData() async {
    if (!kDebugMode) {
      throw Exception('Export is only available in debug mode');
    }
    return await readAll();
  }

  /// バックアップからのインポート（開発・デバッグ用）
  Future<void> importData(Map<String, String> data) async {
    if (!kDebugMode) {
      throw Exception('Import is only available in debug mode');
    }
    await deleteAll();
    await writeAll(data);
  }
}