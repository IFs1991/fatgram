import '../../domain/models/activity.dart';
import '../../domain/models/user.dart';

/// リモートデータソースインターフェース
/// APIとの通信を担当します
abstract class RemoteDataSource {
  /// ユーザー登録
  Future<User> registerUser({
    required String email,
    required String password,
    required String displayName,
  });

  /// ユーザーログイン
  Future<User> loginUser({
    required String email,
    required String password,
  });

  /// トークンリフレッシュ
  Future<void> refreshToken({
    required String refreshToken,
  });

  /// ユーザープロファイル取得
  Future<User> getUserProfile();

  /// ユーザープロファイル更新
  Future<User> updateUserProfile({
    String? displayName,
    UserGoals? goals,
  });

  /// アクティビティデータの同期
  Future<Map<String, dynamic>> syncActivities({
    required List<Activity> activities,
  });

  /// アクティビティ履歴取得
  Future<Map<String, dynamic>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// サブスクリプション状態取得
  Future<Map<String, dynamic>> getSubscriptionStatus();

  /// サブスクリプション検証
  Future<Map<String, dynamic>> verifySubscription({
    required String receipt,
    required String platform,
  });

  /// AIチャットメッセージ送信
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? conversationId,
  });

  /// 会話履歴取得
  Future<Map<String, dynamic>> getConversations({
    int? limit,
    int? offset,
  });

  /// 週間レポート取得
  Future<Map<String, dynamic>> getWeeklyReport({
    required DateTime date,
  });
}