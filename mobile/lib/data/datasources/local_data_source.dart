import '../../domain/models/activity.dart';
import '../../domain/models/user.dart';

/// ローカルデータソースインターフェース
/// ローカルストレージとの通信を担当します
abstract class LocalDataSource {
  /// 認証トークンの保存
  Future<void> saveAuthToken({
    required String token,
    required String refreshToken,
    required DateTime expiresAt,
  });

  /// 認証トークンの取得
  Future<Map<String, dynamic>?> getAuthToken();

  /// 認証トークンの削除
  Future<void> deleteAuthToken();

  /// ユーザー情報の保存
  Future<void> saveUser(User user);

  /// ユーザー情報の取得
  Future<User?> getUser();

  /// ユーザー情報の削除
  Future<void> deleteUser();

  /// アクティビティの保存
  Future<void> saveActivities(List<Activity> activities);

  /// アクティビティの取得
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 未同期アクティビティの取得
  Future<List<Activity>> getUnsyncedActivities();

  /// アクティビティの同期状態更新
  Future<void> markActivitiesAsSynced(List<String> activityIds);

  /// 会話履歴の保存
  Future<void> saveConversation(Map<String, dynamic> conversation);

  /// 会話履歴の取得
  Future<List<Map<String, dynamic>>> getConversations({
    int? limit,
    int? offset,
  });

  /// 会話メッセージの保存
  Future<void> saveChatMessage({
    required String conversationId,
    required Map<String, dynamic> message,
  });

  /// 会話メッセージの取得
  Future<List<Map<String, dynamic>>> getChatMessages({
    required String conversationId,
    int? limit,
    int? offset,
  });

  /// アプリ設定の保存
  Future<void> saveSetting(String key, dynamic value);

  /// アプリ設定の取得
  Future<dynamic> getSetting(String key);
}