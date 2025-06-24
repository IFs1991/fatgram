import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../core/storage/secure_storage_service.dart';

/// SharedPreferencesとSecureStorageを使用したローカルデータソース
class SharedPreferencesLocalDataSource {
  final SharedPreferences sharedPreferences;
  final SecureStorageService secureStorageService;

  SharedPreferencesLocalDataSource({
    required this.sharedPreferences,
    required this.secureStorageService,
  });

  // キー定数
  static const String _userDataKey = 'user_data';
  static const String _settingsKey = 'app_settings';
  static const String _authTokenKey = 'auth_token';

  /// ユーザーデータの保存
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final jsonString = jsonEncode(userData);
      await sharedPreferences.setString(_userDataKey, jsonString);
      if (kDebugMode) {
        print('SharedPreferences: Saved user data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user data: $e');
      }
      rethrow;
    }
  }

  /// ユーザーデータの取得
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonString = sharedPreferences.getString(_userDataKey);
      if (jsonString == null) return null;

      final userData = jsonDecode(jsonString) as Map<String, dynamic>;
      if (kDebugMode) {
        print('SharedPreferences: Retrieved user data');
      }
      return userData;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing user data: $e');
      }
      return null;
    }
  }

  /// ユーザーデータのクリア
  Future<void> clearUserData() async {
    try {
      await sharedPreferences.remove(_userDataKey);
      if (kDebugMode) {
        print('SharedPreferences: Cleared user data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing user data: $e');
      }
      rethrow;
    }
  }

  /// 認証トークンの保存（セキュア）
  Future<void> saveAuthToken(String token) async {
    try {
      await secureStorageService.write(_authTokenKey, token);
      if (kDebugMode) {
        print('SecureStorage: Saved auth token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving auth token: $e');
      }
      rethrow;
    }
  }

  /// 認証トークンの取得（セキュア）
  Future<String?> getAuthToken() async {
    try {
      final token = await secureStorageService.read(_authTokenKey);
      if (kDebugMode) {
        print('SecureStorage: Retrieved auth token (exists: ${token != null})');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving auth token: $e');
      }
      return null;
    }
  }

  /// 認証トークンのクリア（セキュア）
  Future<void> clearAuthToken() async {
    try {
      await secureStorageService.delete(_authTokenKey);
      if (kDebugMode) {
        print('SecureStorage: Cleared auth token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing auth token: $e');
      }
      rethrow;
    }
  }

  /// アプリ設定の保存
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = jsonEncode(settings);
      await sharedPreferences.setString(_settingsKey, jsonString);
      if (kDebugMode) {
        print('SharedPreferences: Saved app settings');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving settings: $e');
      }
      rethrow;
    }
  }

  /// アプリ設定の取得
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final jsonString = sharedPreferences.getString(_settingsKey);
      if (jsonString == null) {
        // デフォルト設定を返す
        return _getDefaultSettings();
      }

      final settings = jsonDecode(jsonString) as Map<String, dynamic>;
      if (kDebugMode) {
        print('SharedPreferences: Retrieved app settings');
      }
      return settings;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing settings, returning defaults: $e');
      }
      return _getDefaultSettings();
    }
  }

  /// デフォルト設定を取得
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'theme': 'light',
      'notifications': true,
      'language': 'en',
      'units': 'metric',
    };
  }

  /// 文字列値の保存
  Future<void> setString(String key, String value) async {
    try {
      await sharedPreferences.setString(key, value);
      if (kDebugMode) {
        print('SharedPreferences: Set string $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting string $key: $e');
      }
      rethrow;
    }
  }

  /// 文字列値の取得
  String? getString(String key, {String? defaultValue}) {
    try {
      return sharedPreferences.getString(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting string $key: $e');
      }
      return defaultValue;
    }
  }

  /// ブール値の保存
  Future<void> setBool(String key, bool value) async {
    try {
      await sharedPreferences.setBool(key, value);
      if (kDebugMode) {
        print('SharedPreferences: Set bool $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting bool $key: $e');
      }
      rethrow;
    }
  }

  /// ブール値の取得
  bool? getBool(String key, {bool? defaultValue}) {
    try {
      return sharedPreferences.getBool(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bool $key: $e');
      }
      return defaultValue;
    }
  }

  /// 整数値の保存
  Future<void> setInt(String key, int value) async {
    try {
      await sharedPreferences.setInt(key, value);
      if (kDebugMode) {
        print('SharedPreferences: Set int $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting int $key: $e');
      }
      rethrow;
    }
  }

  /// 整数値の取得
  int? getInt(String key, {int? defaultValue}) {
    try {
      return sharedPreferences.getInt(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting int $key: $e');
      }
      return defaultValue;
    }
  }

  /// 浮動小数点値の保存
  Future<void> setDouble(String key, double value) async {
    try {
      await sharedPreferences.setDouble(key, value);
      if (kDebugMode) {
        print('SharedPreferences: Set double $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting double $key: $e');
      }
      rethrow;
    }
  }

  /// 浮動小数点値の取得
  double? getDouble(String key, {double? defaultValue}) {
    try {
      return sharedPreferences.getDouble(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting double $key: $e');
      }
      return defaultValue;
    }
  }

  /// キーの存在確認
  bool containsKey(String key) {
    try {
      return sharedPreferences.containsKey(key);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking key $key: $e');
      }
      return false;
    }
  }

  /// 特定キーの削除
  Future<void> remove(String key) async {
    try {
      await sharedPreferences.remove(key);
      if (kDebugMode) {
        print('SharedPreferences: Removed key $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing key $key: $e');
      }
      rethrow;
    }
  }

  /// 全データのクリア
  Future<void> clearAll() async {
    try {
      await sharedPreferences.clear();
      await secureStorageService.deleteAll();
      if (kDebugMode) {
        print('SharedPreferences & SecureStorage: Cleared all data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all data: $e');
      }
      rethrow;
    }
  }

  /// 全てのキーを取得
  Set<String> getAllKeys() {
    try {
      return sharedPreferences.getKeys();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all keys: $e');
      }
      return <String>{};
    }
  }

  /// データのバックアップ（デバッグ用）
  Future<Map<String, dynamic>> backup() async {
    if (!kDebugMode) {
      throw Exception('Backup is only available in debug mode');
    }

    try {
      final prefs = <String, dynamic>{};
      for (final key in getAllKeys()) {
        final value = sharedPreferences.get(key);
        prefs[key] = value;
      }

      final secureData = await secureStorageService.exportData();

      return {
        'preferences': prefs,
        'secure': secureData,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error creating backup: $e');
      }
      rethrow;
    }
  }

  /// データのリストア（デバッグ用）
  Future<void> restore(Map<String, dynamic> backup) async {
    if (!kDebugMode) {
      throw Exception('Restore is only available in debug mode');
    }

    try {
      // Clear existing data
      await clearAll();

      // Restore preferences
      final prefs = backup['preferences'] as Map<String, dynamic>?;
      if (prefs != null) {
        for (final entry in prefs.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is String) {
            await setString(key, value);
          } else if (value is bool) {
            await setBool(key, value);
          } else if (value is int) {
            await setInt(key, value);
          } else if (value is double) {
            await setDouble(key, value);
          }
        }
      }

      // Restore secure data
      final secureData = backup['secure'] as Map<String, dynamic>?;
      if (secureData != null) {
        final stringSecureData = secureData.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        await secureStorageService.importData(stringSecureData);
      }

      if (kDebugMode) {
        print('Data restored successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring data: $e');
      }
      rethrow;
    }
  }
}