import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:path/path.dart' as path;

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
      
      // Hent altid den fulde chat fra CLI værktøj for at sikre vi har det fulde indhold
      print('Henter fuld chat fra CLI værktøj');
      print('CLI sti: ${chatService.cliPath}');
      print('Workspace sti: ${chatService.workspacePath}');
      
      try {
        // Opret en output-mappe i workspace directoriet til at gemme JSON filen
        final outputDir = path.join(chatService.workspacePath, 'output');
        Directory(outputDir).createSync(recursive: true);
        
        // Hent den fulde chat via CLI værktøj
        print('Udfører runCliTool med argumenter: --extract ${chat.id} --format json --output $outputDir');
        final result = await chatService.runCliTool(['--extract', chat.id, '--format', 'json', '--output', outputDir]);
        
        print('CLI kommando afsluttet med kode: ${result.exitCode}');
        print('Stdout længde: ${result.stdout.toString().length}');
        print('Stderr: ${result.stderr}');
        
        if (result.exitCode == 0) {
          // Find filstien i outputtet
          final output = result.stdout.toString();
          print('CLI output: $output');
          
          // Forsøg at finde filstien i outputtet med regex
          final regex = RegExp(r'Chat udtrukket til: (.+\.json)');
          final match = regex.firstMatch(output);
          
          String jsonFilePath;
          if (match != null) {
            jsonFilePath = match.group(1)!;
            print('Fandt JSON fil sti i output: $jsonFilePath');
          } else {
            // Alternativt, gæt filstien baseret på ID
            jsonFilePath = path.join(outputDir, 'Chat_${chat.id}_${chat.id}.json');
            print('Kunne ikke finde filsti i output, gætter på: $jsonFilePath');
          }
          
          // Kontroller om filen eksisterer
          final jsonFile = File(jsonFilePath);
          if (await jsonFile.exists()) {
            print('JSON fil eksisterer: ${jsonFile.path}');
            
            try {
              // Læs JSON fra filen
              final jsonStr = await jsonFile.readAsString();
              print('Læste ${jsonStr.length} tegn fra JSON filen');
              
              try {
                // Parse JSON
                final jsonData = jsonDecode(jsonStr);
                print('JSON data decoded - keys: ${jsonData.keys.join(', ')}');
                
                // Opret chat model
                final fullChat = Chat.fromJson(jsonData);
                print('Chat objekt oprettet med ${fullChat.messages.length} beskeder');
                
                if (fullChat.messages.isNotEmpty) {
                  // Opdater chatten vi vil vise
                  chatToDisplay = fullChat;
                  print('Chatten opdateret til visning med ${chatToDisplay.messages.length} beskeder');
                  
                  // Gem til database hvis tilgængelig
                  try {
                    await chatService.saveChatToDatabase(fullChat);
                    print('Chat gemt til database');
                  } catch (e) {
                    print('Kunne ikke gemme chat til databasen: $e');
                  }
                } else {
                  print('Hentet chat har ingen beskeder');
                }
              } catch (e) {
                print('Fejl ved parsing af JSON: $e');
              }
            } catch (e) {
              print('Fejl ved læsning af JSON fil: $e');
            }
          } else {
            print('JSON fil blev ikke fundet: $jsonFilePath');
            
            // Prøv at liste filer i output-mappen for at finde den
            try {
              final dir = Directory(outputDir);
              if (await dir.exists()) {
                print('Indhold af output-mappen:');
                await for (final entity in dir.list()) {
                  print('- ${entity.path}');
                  if (entity is File && entity.path.contains(chat.id)) {
                    // Fandt en fil, der matcher chat ID'et
                    print('Matcher fil fundet: ${entity.path}');
                    
                    try {
                      // Læs JSON fra den matchende fil
                      final jsonStr = await entity.readAsString();
                      print('Læste ${jsonStr.length} tegn fra JSON filen');
                      
                      try {
                        // Parse JSON
                        final jsonData = jsonDecode(jsonStr);
                        print('JSON data decoded - keys: ${jsonData.keys.join(', ')}');
                        
                        // Opret chat model
                        final fullChat = Chat.fromJson(jsonData);
                        print('Chat objekt oprettet med ${fullChat.messages.length} beskeder');
                        
                        if (fullChat.messages.isNotEmpty) {
                          // Opdater chatten vi vil vise
                          chatToDisplay = fullChat;
                          print('Chatten opdateret til visning med ${chatToDisplay.messages.length} beskeder');
                          
                          // Gem til database hvis tilgængelig
                          try {
                            await chatService.saveChatToDatabase(fullChat);
                            print('Chat gemt til database');
                          } catch (e) {
                            print('Kunne ikke gemme chat til databasen: $e');
                          }
                          break; // Forlad løkken når vi har fundet og indlæst en gyldig fil
                        }
                      } catch (e) {
                        print('Fejl ved parsing af JSON: $e');
                      }
                    } catch (e) {
                      print('Fejl ved læsning af JSON fil: $e');
                    }
                  }
                }
              }
            } catch (e) {
              print('Fejl ved læsning af output-mappen: $e');
            }
          }
        } else {
          print('CLI kommando fejlede med kode: ${result.exitCode}');
          print('Stderr: ${result.stderr}');
        }
      } catch (e) {
        print('Fejl ved hentning af fuld chat: $e');
        print('Stacktrace: ${StackTrace.current}');
        // Vi fortsætter med den oprindelige chat hvis der opstår en fejl
      }
      
      // Luk loading dialog
      Navigator.of(context).pop();
      
      // Vis chatten i en ny dialog
      if (context.mounted) {
        if (chatToDisplay.messages.isEmpty || 
            (chatToDisplay.messages.length == 1 && 
             chatToDisplay.messages[0].content?.contains('Denne chat viser kun oversigten') == true)) {
          
          // Vis fejlbesked hvis der ikke er nogen beskeder at vise
          print('Ingen beskeder at vise - viser fejlbesked');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kunne ikke hente chat-indhold - prøv igen eller tjek indstillinger'),
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
        
        print('Viser dialog med ${chatToDisplay.messages.length} beskeder');
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
      print('Overordnet fejl ved visning af chat: $e');
      print('Stacktrace: ${StackTrace.current}');
      
      // Luk loading dialog hvis den stadig er åben
      if (context.mounted) {
        Navigator.of(context).pop();
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
