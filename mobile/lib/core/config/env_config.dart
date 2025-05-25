import 'package:flutter/foundation.dart';

/// アプリケーションの環境設定を管理するクラス
class EnvConfig {
  /// Gemini AI APIキー
  /// 本番環境では環境変数やセキュアストレージから読み込む
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // ビルド時に設定されない場合のデフォルト値
  );

  /// ウェブ検索API用のキー
  static const String webSearchApiKey = String.fromEnvironment(
    'WEB_SEARCH_API_KEY',
    defaultValue: '',
  );

  /// APIエンドポイントのベースURL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kDebugMode
      ? 'https://dev-api.fatgram.app/v1'
      : 'https://api.fatgram.app/v1',
  );

  /// 現在の環境がデバッグモードかどうか
  static bool get isDebug => kDebugMode;

  /// 環境設定が有効かどうかを確認
  static bool get isConfigured {
    return geminiApiKey.isNotEmpty && webSearchApiKey.isNotEmpty;
  }
}