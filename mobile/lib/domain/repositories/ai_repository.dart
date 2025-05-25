/// AIアシスタントリポジトリインターフェース
abstract class AiRepository {
  /// チャットメッセージ送信
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    String? conversationId,
  });

  /// 会話履歴取得
  Future<List<Map<String, dynamic>>> getConversations({
    int? limit,
    int? offset,
  });

  /// 会話詳細取得
  Future<Map<String, dynamic>> getConversationDetails({
    required String conversationId,
    int? limit,
    int? offset,
  });

  /// 新しい会話の作成
  Future<String> createConversation({
    required String title,
  });

  /// 会話の削除
  Future<void> deleteConversation({
    required String conversationId,
  });

  /// AIによるフィットネスアドバイス取得
  Future<Map<String, dynamic>> getFitnessAdvice({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// AIによる目標設定アドバイス取得
  Future<Map<String, dynamic>> getGoalSettingAdvice();
}