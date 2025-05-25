import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:uuid/uuid.dart';
import 'package:fatgram/core/error/exceptions.dart';
import 'package:fatgram/data/datasources/ai/gemini_api_client.dart';
import 'package:fatgram/domain/models/ai/chat_message.dart';
import 'package:fatgram/domain/repositories/ai/ai_chat_repository.dart';
import 'package:logger/logger.dart';

final aiChatRepositoryProvider = Provider<AIChatRepository>((ref) {
  final geminiClient = ref.watch(geminiClientProvider);
  return AIChatRepositoryImpl(
    apiClient: geminiClient,
    logger: Logger(),
  );
});

class AIChatRepositoryImpl implements AIChatRepository {
  final GeminiApiClient apiClient;
  final Logger logger;
  final Uuid _uuid = const Uuid();

  // メモリ内の会話履歴キャッシュ (実際のアプリでは永続化する)
  final Map<String, ChatConversation> _conversationCache = {};

  AIChatRepositoryImpl({
    required this.apiClient,
    required this.logger,
  });

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String message,
    Map<String, dynamic>? contextData,
  }) async {
    try {
      // 会話が存在するかチェック
      if (!_conversationCache.containsKey(conversationId)) {
        throw ValidationException(
          message: 'Conversation not found: $conversationId',
        );
      }

      final conversation = _conversationCache[conversationId]!;

      // ユーザーメッセージを作成
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        content: message,
        role: ChatMessageRole.user,
        timestamp: DateTime.now(),
      );

      // 会話履歴を更新（新しいインスタンスを作成）
      final updatedMessages = [...conversation.messages, userMessage];
      final updatedConversation = ChatConversation(
        id: conversation.id,
        messages: updatedMessages,
        createdAt: conversation.createdAt,
        updatedAt: DateTime.now(),
        title: conversation.title,
        metadata: conversation.metadata,
      );
      _conversationCache[conversationId] = updatedConversation;

      // Gemini AIへの入力用に会話履歴を変換
      final history = _convertToGeminiHistory(updatedMessages);

      // システム指示を用意（コンテキストデータがあれば追加）
      final Map<String, String> systemInstructions = {
        'role': 'You are a helpful fitness assistant in the FatGram app that provides advice on fat loss, workouts, and health.',
        'goal': 'Provide concise, actionable advice based on user data and fitness best practices.',
      };

      if (contextData != null) {
        systemInstructions.addAll(
          contextData.map((key, value) => MapEntry(key.toString(), value.toString()))
        );
      }

      // AI応答を取得
      final responseText = await apiClient.generateChatResponse(
        history: history,
        systemInstructions: systemInstructions,
      );

      // AI応答をメッセージに変換
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        content: responseText,
        role: ChatMessageRole.assistant,
        timestamp: DateTime.now(),
      );

      // 会話履歴に追加（新しいインスタンスを作成）
      final finalMessages = [...updatedMessages, assistantMessage];
      final finalConversation = ChatConversation(
        id: conversation.id,
        messages: finalMessages,
        createdAt: conversation.createdAt,
        updatedAt: DateTime.now(),
        title: conversation.title,
        metadata: conversation.metadata,
      );
      _conversationCache[conversationId] = finalConversation;

      return assistantMessage;
    } catch (e) {
      logger.e('Error sending message: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AIException(
        message: 'Failed to get AI response: ${e.toString()}',
      );
    }
  }

  @override
  Future<ChatConversation> createConversation({
    String? title,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final conversationId = _uuid.v4();
      final now = DateTime.now();

      // システムメッセージを作成
      final systemMessage = ChatMessage(
        id: _uuid.v4(),
        content: 'Hello! I am your FatGram AI assistant. How can I help you with your fitness journey today?',
        role: ChatMessageRole.system,
        timestamp: now,
      );

      // 新しい会話を作成
      final conversation = ChatConversation(
        id: conversationId,
        messages: [systemMessage],
        createdAt: now,
        updatedAt: now,
        title: title ?? 'New conversation',
        metadata: metadata,
      );

      // キャッシュに追加
      _conversationCache[conversationId] = conversation;

      return conversation;
    } catch (e) {
      logger.e('Error creating conversation: $e');
      throw AIException(
        message: 'Failed to create conversation: ${e.toString()}',
      );
    }
  }

  @override
  Future<ChatConversation> getConversationHistory(String conversationId) async {
    if (!_conversationCache.containsKey(conversationId)) {
      throw ValidationException(
        message: 'Conversation not found: $conversationId',
      );
    }
    return _conversationCache[conversationId]!;
  }

  @override
  Future<List<ChatConversation>> getUserConversations() async {
    // キャッシュから全ての会話を取得し、更新日時の降順でソート
    return _conversationCache.values
        .toList()
        ..sort((a, b) => (b.updatedAt ?? b.createdAt)
            .compareTo(a.updatedAt ?? a.createdAt));
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    if (!_conversationCache.containsKey(conversationId)) {
      throw ValidationException(
        message: 'Conversation not found: $conversationId',
      );
    }
    _conversationCache.remove(conversationId);
  }

  @override
  Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    if (!_conversationCache.containsKey(conversationId)) {
      throw ValidationException(
        message: 'Conversation not found: $conversationId',
      );
    }

    final conversation = _conversationCache[conversationId]!;
    final updatedConversation = ChatConversation(
      id: conversation.id,
      messages: conversation.messages,
      createdAt: conversation.createdAt,
      updatedAt: DateTime.now(),
      title: newTitle,
      metadata: conversation.metadata,
    );
    _conversationCache[conversationId] = updatedConversation;
  }

  // ChatMessageをGemini AIのContent形式に変換するヘルパーメソッド
  List<genai.Content> _convertToGeminiHistory(List<ChatMessage> messages) {
    // システムメッセージは含めない（別途systemInstructionsとして追加）
    final filteredMessages = messages
        .where((m) => m.role != ChatMessageRole.system)
        .toList();

    return filteredMessages.map((message) {
      String role;
      switch (message.role) {
        case ChatMessageRole.user:
          role = 'user';
          break;
        case ChatMessageRole.assistant:
          role = 'model';
          break;
        default:
          role = 'user'; // デフォルトはユーザー
      }

      return genai.Content(
        role: role,
        parts: [genai.TextPart(text: message.content)],
      );
    }).toList();
  }
}