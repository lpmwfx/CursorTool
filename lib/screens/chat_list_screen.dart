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
    try {
      // Begræns antallet af viste beskeder til maks 20 for at undgå overbelastning
      final displayMessages = chat.messages.take(20).toList();
      
      showDialog(
        context: context,
        builder: (context) {
          try {
            return AlertDialog(
              title: Text(chat.title),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6, // Begrænset højde
                child: displayMessages.isEmpty
                    ? const Center(
                        child: Text(
                          'Ingen beskeder at vise.\nBrug udtræk-funktionen for at se chatten i forskellige formater.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: displayMessages.length,
                        itemBuilder: (context, index) {
                          try {
                            final message = displayMessages[index];
                            
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
                                        Text(message.content ?? 'Ingen indhold'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    message.timestamp != null ? DateFormat('HH:mm:ss').format(message.timestamp) : 'Tidspunkt ukendt',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } catch (e, stackTrace) {
                            print('Fejl ved visning af besked: $e');
                            print('Stack trace: $stackTrace');
                            // Håndter eventuelle fejl med en fejl-widget
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  'Kunne ikke vise besked: $e',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          }
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Luk'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context); // Luk dialogen først
                    
                    // Vis en "udtræk-dialog" med forskellige formater
                    try {
                      final format = await showDialog<String>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: const Text('Udtræk chat som'),
                          children: [
                            _buildFormatOption(context, 'markdown', 'Markdown'),
                            _buildFormatOption(context, 'html', 'HTML'),
                            _buildFormatOption(context, 'text', 'Tekst'),
                            _buildFormatOption(context, 'json', 'JSON'),
                          ],
                        ),
                      );
                      
                      if (format != null && context.mounted) {
                        final chatService = context.read<ChatService>();
                        final success = await chatService.extractChat(chat.id, format);
                        
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Chat udtrukket som $format'),
                              action: SnackBarAction(
                                label: 'OK',
                                onPressed: () {},
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Fejl ved udtrækning: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fejl ved udtrækning: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Udtræk'),
                ),
              ],
            );
          } catch (e) {
            print('Fejl ved opbygning af dialog: $e');
            return AlertDialog(
              title: const Text('Fejl'),
              content: Text('Der opstod en fejl ved visning af chatten: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Luk'),
                ),
              ],
            );
          }
        },
      );
    } catch (e) {
      print('Kritisk fejl i _viewChatContent: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke vise chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Helper metode til at bygge format-muligheder
  Widget _buildFormatOption(BuildContext context, String value, String label) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(label),
      ),
    );
  }
}
