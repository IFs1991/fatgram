import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum ChatMessageRole {
  user,
  assistant,
  system,
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required ChatMessageRole role,
    required DateTime timestamp,
    String? contextId,
    Map<String, dynamic>? metadata,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

@freezed
class ChatConversation with _$ChatConversation {
  const factory ChatConversation({
    required String id,
    required List<ChatMessage> messages,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? title,
    Map<String, dynamic>? metadata,
  }) = _ChatConversation;

  factory ChatConversation.fromJson(Map<String, dynamic> json) => _$ChatConversationFromJson(json);
}