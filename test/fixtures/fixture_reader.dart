import 'dart:convert';
import 'dart:io';

/// テストフィクスチャーを読み込むためのユーティリティクラス
class FixtureReader {
  /// フィクスチャーファイルのベースパス
  static const String _basePath = 'test/fixtures';

  /// JSONフィクスチャーファイルを読み込んで、Mapとして返す
  static Map<String, dynamic> readJson(String fileName) {
    final file = File('$_basePath/$fileName');
    if (!file.existsSync()) {
      throw FileSystemException('Fixture file not found: $fileName', file.path);
    }

    final jsonString = file.readAsStringSync();
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON in fixture file: $fileName', jsonString);
    }
  }

  /// JSONフィクスチャーファイルを読み込んで、Listとして返す
  static List<dynamic> readJsonList(String fileName) {
    final file = File('$_basePath/$fileName');
    if (!file.existsSync()) {
      throw FileSystemException('Fixture file not found: $fileName', file.path);
    }

    final jsonString = file.readAsStringSync();
    try {
      return json.decode(jsonString) as List<dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON in fixture file: $fileName', jsonString);
    }
  }

  /// テキストフィクスチャーファイルを読み込んで、文字列として返す
  static String readText(String fileName) {
    final file = File('$_basePath/$fileName');
    if (!file.existsSync()) {
      throw FileSystemException('Fixture file not found: $fileName', file.path);
    }

    return file.readAsStringSync();
  }

  /// フィクスチャーファイルが存在するかチェック
  static bool exists(String fileName) {
    final file = File('$_basePath/$fileName');
    return file.existsSync();
  }

  /// 利用可能なフィクスチャーファイルのリストを取得
  static List<String> getAvailableFixtures() {
    final directory = Directory(_basePath);
    if (!directory.existsSync()) {
      return [];
    }

    return directory
        .listSync()
        .whereType<File>()
        .map((file) => file.path.split('/').last)
        .toList();
  }

  /// フィクスチャーディレクトリを作成（存在しない場合）
  static void ensureFixtureDirectory() {
    final directory = Directory(_basePath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }
}

/// フィクスチャーファイル名の定数
class FixtureFiles {
  // ユーザー関連
  static const String user = 'user.json';
  static const String userList = 'user_list.json';
  static const String userProfile = 'user_profile.json';

  // アクティビティ関連
  static const String activity = 'activity.json';
  static const String activityList = 'activity_list.json';
  static const String workoutData = 'workout_data.json';

  // ヘルスデータ関連
  static const String healthData = 'health_data.json';
  static const String healthDataList = 'health_data_list.json';
  static const String heartRateData = 'heart_rate_data.json';

  // API レスポンス関連
  static const String successResponse = 'success_response.json';
  static const String errorResponse = 'error_response.json';
  static const String authResponse = 'auth_response.json';

  // 設定関連
  static const String appSettings = 'app_settings.json';
  static const String userPreferences = 'user_preferences.json';

  // AI関連
  static const String aiPrompts = 'ai_prompts.json';
  static const String aiResponses = 'ai_responses.json';
}