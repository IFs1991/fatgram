import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fatgram/app/features/ai/chat/chat_controller.dart';
import 'package:fatgram/app/features/ai/chat/chat_screen.dart';
import 'package:fatgram/domain/models/ai/chat_message.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('会話履歴'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('エラー: ${state.error}'))
              : state.conversations.isEmpty
                  ? _buildEmptyState(context)
                  : _buildConversationsList(context, ref, state.conversations),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewConversation(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_chat.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 16),
          const Text(
            '会話履歴がありません',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'AIアシスタントと会話を始めてみましょう',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text('新しい会話を始める'),
            onPressed: () => _startNewConversation(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(
    BuildContext context,
    WidgetRef ref,
    List<ChatConversation> conversations,
  ) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final lastMessage = conversation.messages.isNotEmpty
            ? conversation.messages.last
            : null;
        final lastMessageText = lastMessage?.role == ChatMessageRole.system
            ? 'AIアシスタントを始めましょう'
            : lastMessage?.content.length ?? 0 > 50
                ? '${lastMessage!.content.substring(0, 50)}...'
                : lastMessage?.content ?? '';

        return Dismissible(
          key: Key(conversation.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('会話を削除'),
                  content: const Text('この会話を削除してもよろしいですか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('削除'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            ref.read(chatControllerProvider.notifier).deleteConversation(conversation.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('会話を削除しました')),
            );
          },
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.chat, color: Colors.white),
            ),
            title: Text(
              conversation.title ?? '会話 ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastMessageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateFormat.format(conversation.updatedAt ?? conversation.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            onTap: () => _openConversation(context, conversation.id),
            onLongPress: () => _showRenameDialog(context, ref, conversation),
          ),
        );
      },
    );
  }

  void _startNewConversation(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatScreen(),
      ),
    );
  }

  void _openConversation(BuildContext context, String conversationId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, ChatConversation conversation) {
    final controller = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('会話名の変更'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '会話名',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(chatControllerProvider.notifier).updateConversationTitle(
                    conversation.id,
                    controller.text.trim(),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}