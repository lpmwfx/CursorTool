import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import '../models/chat.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<ChatService>();
    final settingsService = context.watch<SettingsService>();

    if (chatService.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (chatService.lastError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Der opstod en fejl',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                chatService.lastError,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => chatService.loadChats(),
              child: const Text('Prøv igen'),
            ),
          ],
        ),
      );
    }

    if (chatService.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.grey,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen chats fundet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Klik på terminal-ikonet nedenfor for at åbne TUI browseren\neller tjek dine indstillinger.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => chatService.loadChats(),
              child: const Text('Genindlæs'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => chatService.loadChats(),
      child: ListView.builder(
        itemCount: chatService.chats.length,
        itemBuilder: (context, index) {
          final chat = chatService.chats[index];
          return _buildChatItem(context, chat);
        },
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Chat chat) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          chat.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Antal beskeder: ${chat.messages.length}',
            ),
            Text(
              'Sidst ændret: ${dateFormat.format(chat.lastMessageTime)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuItemSelected(context, value, chat),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('Vis chat'),
            ),
            const PopupMenuItem(
              value: 'markdown',
              child: Text('Udtræk som Markdown'),
            ),
            const PopupMenuItem(
              value: 'html',
              child: Text('Udtræk som HTML'),
            ),
            const PopupMenuItem(
              value: 'text',
              child: Text('Udtræk som tekst'),
            ),
            const PopupMenuItem(
              value: 'json',
              child: Text('Udtræk som JSON'),
            ),
          ],
        ),
        onTap: () => _viewChatContent(context, chat),
      ),
    );
  }

  Future<void> _handleMenuItemSelected(
    BuildContext context,
    String value,
    Chat chat,
  ) async {
    final chatService = context.read<ChatService>();

    if (value == 'view') {
      _viewChatContent(context, chat);
      return;
    }

    // Udtræk chat i det valgte format
    final success = await chatService.extractChat(chat.id, value);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat udtrukket som $value'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _viewChatContent(BuildContext context, Chat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chat.title),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: chat.messages.length,
            itemBuilder: (context, index) {
              final message = chat.messages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.isUser ? 'Du' : 'AI',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(message.content),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('HH:mm:ss').format(message.timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Luk'),
          ),
        ],
      ),
    );
  }
}
