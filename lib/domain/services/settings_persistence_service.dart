/// 設定データ永続化サービス
/// 2025年エンタープライズレベル実装: 暗号化ストレージ、クラウド同期、バックアップ対応
library settings_persistence_service;

import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';

import '../models/user_settings.dart';
import '../../core/security/enhanced_api_key_manager.dart';

/// ユーザー設定モデル（永続化対応）
class UserSettings {
  final String userId;
  final bool notificationsEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String theme; // 'light', 'dark', 'system'
  final String language; // 'ja', 'en', etc.
  final String units; // 'metric', 'imperial'
  final bool syncEnabled;
  final bool autoBackupEnabled;
  final String backupFrequency; // 'daily', 'weekly', 'monthly'
  final bool dataSaverMode;
  final bool analyticsEnabled;
  final Map<String, dynamic> customSettings;
  final DateTime lastUpdated;
  final DateTime lastSynced;

  const UserSettings({
    required this.userId,
    this.notificationsEnabled = true,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.theme = 'system',
    this.language = 'ja',
    this.units = 'metric',
    this.syncEnabled = true,
    this.autoBackupEnabled = true,
    this.backupFrequency = 'daily',
    this.dataSaverMode = false,
    this.analyticsEnabled = true,
    this.customSettings = const {},
    required this.lastUpdated,
    required this.lastSynced,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'notificationsEnabled': notificationsEnabled,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'theme': theme,
      'language': language,
      'units': units,
      'syncEnabled': syncEnabled,
      'autoBackupEnabled': autoBackupEnabled,
      'backupFrequency': backupFrequency,
      'dataSaverMode': dataSaverMode,
      'analyticsEnabled': analyticsEnabled,
      'customSettings': customSettings,
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastSynced': lastSynced.toIso8601String(),
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['userId'] as String,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? true,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'ja',
      units: json['units'] as String? ?? 'metric',
      syncEnabled: json['syncEnabled'] as bool? ?? true,
      autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? true,
      backupFrequency: json['backupFrequency'] as String? ?? 'daily',
      dataSaverMode: json['dataSaverMode'] as bool? ?? false,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
      customSettings: Map<String, dynamic>.from(json['customSettings'] as Map? ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      lastSynced: DateTime.parse(json['lastSynced'] as String),
    );
  }

  UserSettings copyWith({
    String? userId,
    bool? notificationsEnabled,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? theme,
    String? language,
    String? units,
    bool? syncEnabled,
    bool? autoBackupEnabled,
    String? backupFrequency,
    bool? dataSaverMode,
    bool? analyticsEnabled,
    Map<String, dynamic>? customSettings,
    DateTime? lastUpdated,
    DateTime? lastSynced,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      units: units ?? this.units,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      dataSaverMode: dataSaverMode ?? this.dataSaverMode,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      customSettings: customSettings ?? this.customSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }
}

/// 設定永続化サービス
class SettingsPersistenceService {
  static const String _hiveBoxName = 'user_settings';
  static const String _prefsPrefix = 'settings_';
  static const String _firestoreCollection = 'user_settings';
  
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final EnhancedApiKeyManager _encryptionManager;
  
  Box<String>? _hiveBox;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  
  /// 初期化
  Future<void> initialize({String? encryptionKey}) async {
    try {
      if (_isInitialized) return;
      
      // Hive初期化
      await Hive.initFlutter();
      _hiveBox = await Hive.openBox<String>(_hiveBoxName);
      
      // SharedPreferences初期化
      _prefs = await SharedPreferences.getInstance();
      
      // 暗号化マネージャー初期化
      _encryptionManager = EnhancedApiKeyManager(
        masterKey: encryptionKey ?? _generateDefaultEncryptionKey(),
      );
      await _encryptionManager.initialize();
      
      _isInitialized = true;
      _logger.i('Settings persistence service initialized');
      
    } catch (e) {
      _logger.e('Settings persistence initialization failed', error: e);
      throw Exception('Settings persistence initialization failed: $e');
    }
  }
  
  /// 設定保存（ローカル）
  Future<void> saveSettingsLocally(UserSettings settings) async {
    try {
      await _ensureInitialized();
      
      final settingsJson = settings.toJson();
      final jsonString = json.encode(settingsJson);
      
      // 暗号化
      final encryptedData = await _encryptionManager.encryptData(jsonString);
      
      // Hive保存（プライマリストレージ）
      await _hiveBox!.put(settings.userId, encryptedData);
      
      // SharedPreferences保存（バックアップ）
      await _prefs!.setString('${_prefsPrefix}${settings.userId}', encryptedData);
      
      // 最後の保存時刻記録
      await _prefs!.setString(
        '${_prefsPrefix}last_save_${settings.userId}',
        DateTime.now().toIso8601String(),
      );
      
      _logger.i('Settings saved locally for user: ${settings.userId}');
      
    } catch (e) {
      _logger.e('Local settings save failed', error: e);
      throw Exception('設定の保存に失敗しました: $e');
    }
  }
  
  /// 設定読み込み（ローカル）
  Future<UserSettings?> loadSettingsLocally(String userId) async {
    try {
      await _ensureInitialized();
      
      // Hiveから読み込み（プライマリ）
      String? encryptedData = _hiveBox!.get(userId);
      
      // フォールバック: SharedPreferencesから読み込み
      if (encryptedData == null) {
        encryptedData = _prefs!.getString('${_prefsPrefix}$userId');
      }
      
      if (encryptedData == null) {
        _logger.w('No local settings found for user: $userId');
        return null;
      }
      
      // 復号化
      final decryptedJson = await _encryptionManager.decryptData(encryptedData);
      final settingsJson = json.decode(decryptedJson) as Map<String, dynamic>;
      
      final settings = UserSettings.fromJson(settingsJson);
      _logger.i('Settings loaded locally for user: $userId');
      
      return settings;
      
    } catch (e) {
      _logger.e('Local settings load failed', error: e);
      
      // エラー時はデフォルト設定を返す
      return UserSettings(
        userId: userId,
        lastUpdated: DateTime.now(),
        lastSynced: DateTime(1970), // 未同期状態
      );
    }
  }
  
  /// 設定クラウド同期（アップロード）
  Future<void> syncSettingsToCloud(UserSettings settings) async {
    try {
      await _ensureInitialized();
      
      if (!settings.syncEnabled) {
        _logger.i('Cloud sync disabled for user: ${settings.userId}');
        return;
      }
      
      final settingsDoc = _firestore
          .collection(_firestoreCollection)
          .doc(settings.userId);
      
      final settingsData = settings.toJson();
      
      // クラウド同期タイムスタンプ更新
      settingsData['cloudSyncAt'] = FieldValue.serverTimestamp();
      settingsData['deviceId'] = await _getDeviceId();
      
      await settingsDoc.set(settingsData, SetOptions(merge: true));
      
      // ローカルの同期時刻更新
      final updatedSettings = settings.copyWith(
        lastSynced: DateTime.now(),
      );
      await saveSettingsLocally(updatedSettings);
      
      _logger.i('Settings synced to cloud for user: ${settings.userId}');
      
    } catch (e) {
      _logger.e('Cloud settings sync failed', error: e);
      throw Exception('設定のクラウド同期に失敗しました: $e');
    }
  }
  
  /// 設定クラウド同期（ダウンロード）
  Future<UserSettings?> syncSettingsFromCloud(String userId) async {
    try {
      await _ensureInitialized();
      
      final settingsDoc = await _firestore
          .collection(_firestoreCollection)
          .doc(userId)
          .get();
      
      if (!settingsDoc.exists) {
        _logger.w('No cloud settings found for user: $userId');
        return null;
      }
      
      final settingsData = settingsDoc.data()!;
      
      // サーバータイムスタンプをローカル時刻に変換
      if (settingsData['cloudSyncAt'] is Timestamp) {
        final timestamp = settingsData['cloudSyncAt'] as Timestamp;
        settingsData['lastSynced'] = timestamp.toDate().toIso8601String();
        settingsData.remove('cloudSyncAt');
      }
      
      final settings = UserSettings.fromJson(settingsData);
      
      // ローカルに保存
      await saveSettingsLocally(settings);
      
      _logger.i('Settings synced from cloud for user: $userId');
      return settings;
      
    } catch (e) {
      _logger.e('Cloud settings download failed', error: e);
      throw Exception('設定のクラウド取得に失敗しました: $e');
    }
  }
  
  /// 自動同期実行
  Future<UserSettings> autoSync(UserSettings localSettings) async {
    try {
      if (!localSettings.syncEnabled) {
        return localSettings;
      }
      
      // クラウドから最新設定を取得
      final cloudSettings = await syncSettingsFromCloud(localSettings.userId);
      
      if (cloudSettings == null) {
        // クラウドに設定が存在しない場合はアップロード
        await syncSettingsToCloud(localSettings);
        return localSettings;
      }
      
      // 競合解決: 最新の設定を使用
      if (cloudSettings.lastUpdated.isAfter(localSettings.lastUpdated)) {
        _logger.i('Using cloud settings (newer)');
        return cloudSettings;
      } else {
        // ローカルが新しい場合はクラウドにアップロード
        await syncSettingsToCloud(localSettings);
        return localSettings;
      }
      
    } catch (e) {
      _logger.e('Auto sync failed', error: e);
      // エラー時はローカル設定をそのまま返す
      return localSettings;
    }
  }
  
  /// 設定バックアップ作成
  Future<String> createBackup(String userId) async {
    try {
      await _ensureInitialized();
      
      final settings = await loadSettingsLocally(userId);
      if (settings == null) {
        throw Exception('設定が見つかりません');
      }
      
      final backupData = {
        'version': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'settings': settings.toJson(),
        'checksum': _calculateChecksum(settings.toJson()),
      };
      
      final backupString = json.encode(backupData);
      final encryptedBackup = await _encryptionManager.encryptData(backupString);
      
      _logger.i('Settings backup created for user: $userId');
      return encryptedBackup;
      
    } catch (e) {
      _logger.e('Settings backup creation failed', error: e);
      throw Exception('設定のバックアップ作成に失敗しました: $e');
    }
  }
  
  /// 設定バックアップ復元
  Future<UserSettings> restoreBackup(String backupData) async {
    try {
      await _ensureInitialized();
      
      // 復号化
      final decryptedBackup = await _encryptionManager.decryptData(backupData);
      final backupJson = json.decode(decryptedBackup) as Map<String, dynamic>;
      
      // チェックサム検証
      final settingsData = backupJson['settings'] as Map<String, dynamic>;
      final originalChecksum = backupJson['checksum'] as String;
      final calculatedChecksum = _calculateChecksum(settingsData);
      
      if (originalChecksum != calculatedChecksum) {
        throw Exception('バックアップデータが破損しています');
      }
      
      final settings = UserSettings.fromJson(settingsData);
      
      // 復元時刻を更新
      final restoredSettings = settings.copyWith(
        lastUpdated: DateTime.now(),
        lastSynced: DateTime.now(),
      );
      
      // ローカルに保存
      await saveSettingsLocally(restoredSettings);
      
      _logger.i('Settings restored from backup for user: ${settings.userId}');
      return restoredSettings;
      
    } catch (e) {
      _logger.e('Settings backup restore failed', error: e);
      throw Exception('設定の復元に失敗しました: $e');
    }
  }
  
  /// 設定削除（ローカル）
  Future<void> deleteSettingsLocally(String userId) async {
    try {
      await _ensureInitialized();
      
      // Hiveから削除
      await _hiveBox!.delete(userId);
      
      // SharedPreferencesから削除
      await _prefs!.remove('${_prefsPrefix}$userId');
      await _prefs!.remove('${_prefsPrefix}last_save_$userId');
      
      _logger.i('Local settings deleted for user: $userId');
      
    } catch (e) {
      _logger.e('Local settings deletion failed', error: e);
      throw Exception('設定の削除に失敗しました: $e');
    }
  }
  
  /// 設定削除（クラウド）
  Future<void> deleteSettingsFromCloud(String userId) async {
    try {
      await _firestore
          .collection(_firestoreCollection)
          .doc(userId)
          .delete();
      
      _logger.i('Cloud settings deleted for user: $userId');
      
    } catch (e) {
      _logger.e('Cloud settings deletion failed', error: e);
      throw Exception('クラウド設定の削除に失敗しました: $e');
    }
  }
  
  /// 初期化確認
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  /// デフォルト暗号化キー生成
  String _generateDefaultEncryptionKey() {
    final bytes = Uint8List.fromList(
      List.generate(32, (index) => index + 42)
    );
    return base64Encode(bytes);
  }
  
  /// チェックサム計算
  String _calculateChecksum(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// デバイスID取得
  Future<String> _getDeviceId() async {
    // 実装は device_info_plus パッケージを使用
    // ここでは簡易実装
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// 統計情報取得
  Map<String, dynamic> getStats() {
    return {
      'isInitialized': _isInitialized,
      'storageBackends': ['Hive', 'SharedPreferences', 'Cloud Firestore'],
      'encryptionEnabled': true,
      'autoSyncEnabled': true,
      'backupSupported': true,
    };
  }
  
  /// サービス終了
  Future<void> dispose() async {
    try {
      await _hiveBox?.close();
      _isInitialized = false;
      _logger.i('Settings persistence service disposed');
    } catch (e) {
      _logger.e('Settings persistence disposal failed', error: e);
    }
  }
}