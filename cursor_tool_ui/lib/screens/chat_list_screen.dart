import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';
import 'dart:convert';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late ChatService _chatService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _chatService.loadChats();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ChatService>(
        builder: (context, chatService, child) {
          final chats = chatService.chats;
          final isLoading = chatService.isLoading || _isLoading;
          final errorMessage = chatService.lastError;

          return Stack(
            children: [
              if (errorMessage.isNotEmpty && chats.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fejl ved indlæsning af chats',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(errorMessage),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          _loadChats();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Prøv igen'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                        child: const Text('Gå til indstillinger'),
                      ),
                    ],
                  ),
                )
              else if (chats.isEmpty && !isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ingen chats fundet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Konfigurer CLI-værktøjet for at indlæse dine Cursor chats'
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          try {
                            final importedCount = await chatService.autoImportFromCursor();
                            
                            if (mounted && importedCount > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Importerede $importedCount chats')),
                              );
                              await _loadChats();
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ingen chats fundet')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Fejl: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Auto-importér Chats'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                        child: const Text('Gå til indstillinger'),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _buildChatListItem(context, chat);
                  },
                ),
              if (isLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadChats,
        tooltip: 'Genindlæs',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildChatListItem(BuildContext context, Chat chat) {
    // Truncate long titles
    final displayTitle = chat.title.length > 60
        ? '${chat.title.substring(0, 57)}...'
        : chat.title;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(displayTitle),
        subtitle: Text('ID: ${chat.id} • ${chat.messages.length} beskeder'),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            _viewChatContent(context, chat);
          },
        ),
        onTap: () {
          _viewChatContent(context, chat);
        },
      ),
    );
  }

  Future<void> _viewChatContent(BuildContext context, Chat chat) async {
    print('=====================');
    print('Starter _viewChatContent');
    print('Chat ID: ${chat.id}');
    print('Chat titel: ${chat.title}');
    print('Antal beskeder: ${chat.messages.length}');
    print('=====================');

    final chatService = Provider.of<ChatService>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Henter chat...'),
            ],
          ),
        );
      },
    );
    
    try {
      var chatToDisplay = chat;
      
      // Hvis chatten kun har én besked, er det en oversigtsvisning - hent den fulde chat
      if (chat.messages.length == 1 && chat.messages[0].content?.contains('Denne chat viser kun oversigten') == true) {
        print('Forsøger at hente fuld chat fra CLI værktøj');
        
        try {
          // Hent den fulde chat via CLI værktøj
          final result = await chatService.runCliTool(['--extract', chat.id, '--format', 'json']);
          
          if (result.exitCode == 0) {
            // Find JSON i output
            final output = result.stdout.toString();
            int jsonStart = output.indexOf('{');
            if (jsonStart >= 0) {
              final jsonStr = output.substring(jsonStart);
              
              // Parse JSON
              final jsonData = jsonDecode(jsonStr);
              
              // Opret chat model
              final fullChat = Chat.fromJson(jsonData);
              
              // Opdater chatten vi vil vise
              chatToDisplay = fullChat;
              
              // Gem til database hvis tilgængelig
              try {
                await chatService.saveChatToDatabase(fullChat);
              } catch (e) {
                print('Kunne ikke gemme chat til databasen: $e');
              }
            }
          }
        } catch (e) {
          print('Fejl ved hentning af fuld chat: $e');
          // Vi fortsætter med den oprindelige chat hvis der opstår en fejl
        }
      }
      
      // Luk loading dialog
      Navigator.of(context).pop();
      
      // Vis chatten i en ny dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chatToDisplay.title,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: chatToDisplay.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatToDisplay.messages[index];
                          return _buildMessageBubble(context, message);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      print('Fejl ved visning af chat: $e');
      
      // Luk loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Vis fejlbesked
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved visning af chat: $e')),
        );
      }
    }
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.isUser;
    final bgColor = isUser ? Colors.blue.shade100 : Colors.grey.shade100;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              isUser ? 'USER' : 'ASSISTANT',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
            ),
            child: MarkdownBody(
              data: message.content ?? 'Ingen indhold',
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                code: TextStyle(
                  backgroundColor: Colors.grey.shade200,
                  fontFamily: Platform.isWindows ? 'Consolas' : Platform.isMacOS ? 'Menlo' : 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              '${message.timestamp.day}/${message.timestamp.month}/${message.timestamp.year} ${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
