import '../repositories/ai_repository.dart';

/// チャットメッセージ送信ユースケース
class SendChatMessage {
  final AiRepository repository;

  SendChatMessage(this.repository);

  Future<Map<String, dynamic>> call({
    required String message,
    String? conversationId,
  }) {
    return repository.sendChatMessage(
      message: message,
      conversationId: conversationId,
    );
  }
}

/// 会話履歴取得ユースケース
class GetConversations {
  final AiRepository repository;

  GetConversations(this.repository);

  Future<List<Map<String, dynamic>>> call({
    int? limit,
    int? offset,
  }) {
    return repository.getConversations(
      limit: limit,
      offset: offset,
    );
  }
}

/// 会話詳細取得ユースケース
class GetConversationDetails {
  final AiRepository repository;

  GetConversationDetails(this.repository);

  Future<Map<String, dynamic>> call({
    required String conversationId,
    int? limit,
    int? offset,
  }) {
    return repository.getConversationDetails(
      conversationId: conversationId,
      limit: limit,
      offset: offset,
    );
  }
}

/// 会話作成ユースケース
class CreateConversation {
  final AiRepository repository;

  CreateConversation(this.repository);

  Future<String> call({
    required String title,
  }) {
    return repository.createConversation(
      title: title,
    );
  }
}

/// 会話削除ユースケース
class DeleteConversation {
  final AiRepository repository;

  DeleteConversation(this.repository);

  Future<void> call({
    required String conversationId,
  }) {
    return repository.deleteConversation(
      conversationId: conversationId,
    );
  }
}

/// フィットネスアドバイス取得ユースケース
class GetFitnessAdvice {
  final AiRepository repository;

  GetFitnessAdvice(this.repository);

  Future<Map<String, dynamic>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getFitnessAdvice(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// 目標設定アドバイス取得ユースケース
class GetGoalSettingAdvice {
  final AiRepository repository;

  GetGoalSettingAdvice(this.repository);

  Future<Map<String, dynamic>> call() {
    return repository.getGoalSettingAdvice();
  }
}