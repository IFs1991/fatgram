import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fatgram/domain/models/ai/chat_message.dart';
import 'package:fatgram/domain/repositories/ai/ai_chat_repository.dart';
import 'package:fatgram/data/repositories/ai/ai_chat_repository_impl.dart';

// チャットコントローラーの状態
class ChatState {
  final bool isLoading;
  final String? error;
  final List<ChatConversation> conversations;

  ChatState({
    this.isLoading = false,
    this.error,
    this.conversations = const [],
  });

  ChatState copyWith({
    bool? isLoading,
    String? error,
    List<ChatConversation>? conversations,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      conversations: conversations ?? this.conversations,
    );
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return ChatController(repository);
});

class ChatController extends StateNotifier<ChatState> {
  final AIChatRepository _repository;

  ChatController(this._repository) : super(ChatState()) {
    // 初期化時に会話一覧を読み込む
    loadConversations();
  }

  Future<void> loadConversations() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final conversations = await _repository.getUserConversations();
      state = state.copyWith(
        isLoading: false,
        conversations: conversations,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<ChatConversation> createConversation({
    String? title,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final conversation = await _repository.createConversation(
        title: title,
        metadata: metadata,
      );

      // 会話リストを更新
      final updatedConversations = [conversation, ...state.conversations];
      state = state.copyWith(
        isLoading: false,
        conversations: updatedConversations,
      );

      return conversation;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String message,
    Map<String, dynamic>? contextData,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _repository.sendMessage(
        conversationId: conversationId,
        message: message,
        contextData: contextData,
      );

      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<ChatConversation> getConversationHistory(String conversationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final conversation = await _repository.getConversationHistory(conversationId);
      state = state.copyWith(isLoading: false);
      return conversation;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.deleteConversation(conversationId);

      // 会話リストを更新
      final updatedConversations = state.conversations
          .where((conv) => conv.id != conversationId)
          .toList();

      state = state.copyWith(
        isLoading: false,
        conversations: updatedConversations,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.updateConversationTitle(conversationId, newTitle);

      // 会話リストを更新するために再取得
      await loadConversations();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}