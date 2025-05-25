import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:fatgram/domain/models/ai/chat_message.dart';
import 'package:uuid/uuid.dart';
import 'package:fatgram/app/features/ai/chat/chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;

  const ChatScreen({Key? key, this.conversationId}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _uuid = const Uuid();
  late String _conversationId;
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  final _assistant = const types.User(id: 'assistant', firstName: 'FatGram AI');

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.conversationId != null) {
      _conversationId = widget.conversationId!;
      await _loadConversationHistory();
    } else {
      final controller = ref.read(chatControllerProvider.notifier);
      final conversation = await controller.createConversation();
      _conversationId = conversation.id;
    }
  }

  Future<void> _loadConversationHistory() async {
    final controller = ref.read(chatControllerProvider.notifier);
    final conversation = await controller.getConversationHistory(_conversationId);

    setState(() {
      _messages.clear();
      for (final message in conversation.messages) {
        if (message.role == ChatMessageRole.system) continue;

        _messages.add(_convertToUIMessage(message));
      }
    });
  }

  types.Message _convertToUIMessage(ChatMessage message) {
    return types.TextMessage(
      id: message.id,
      text: message.content,
      author: message.role == ChatMessageRole.user ? _user : _assistant,
      createdAt: message.timestamp.millisecondsSinceEpoch,
    );
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      id: _uuid.v4(),
      author: _user,
      text: message.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _messages.insert(0, textMessage);
    });

    try {
      final controller = ref.read(chatControllerProvider.notifier);
      final response = await controller.sendMessage(
        conversationId: _conversationId,
        message: message.text,
      );

      final responseMessage = _convertToUIMessage(response);

      setState(() {
        _messages.insert(0, responseMessage);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI アシスタント'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversationHistory,
          ),
        ],
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        theme: DefaultChatTheme(
          primaryColor: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          inputBackgroundColor: Theme.of(context).cardColor,
          sentMessageBodyTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          receivedMessageBodyTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
        ),
        emptyState: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ai_assistant.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 20),
              const Text(
                'FatGram AI アシスタント',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'フィットネスや健康についての質問をしてみましょう',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}