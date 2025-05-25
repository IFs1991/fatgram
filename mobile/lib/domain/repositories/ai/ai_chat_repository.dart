import 'package:fatgram/domain/models/ai/chat_message.dart';

abstract class AIChatRepository {
  /// チャットメッセージを送信し、AIからの応答を取得する
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String message,
    Map<String, dynamic>? contextData,
  });

  /// 新しい会話を作成する
  Future<ChatConversation> createConversation({
    String? title,
    Map<String, dynamic>? metadata,
  });

  /// 指定した会話のメッセージ履歴を取得する
  Future<ChatConversation> getConversationHistory(String conversationId);

  /// ユーザーの全会話リストを取得する
  Future<List<ChatConversation>> getUserConversations();

  /// 会話を削除する
  Future<void> deleteConversation(String conversationId);

  /// 会話のタイトルを更新する
  Future<void> updateConversationTitle(String conversationId, String newTitle);
}