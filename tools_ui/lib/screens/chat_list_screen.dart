import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import '../models/chat.dart';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_markdown/flutter_markdown.dart';

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
      print("=====================");
      print("Starter _viewChatContent");
      print("Chat ID: ${chat.id}");
      print("Chat titel: ${chat.title}");
      print("Antal beskeder: ${chat.messages.length}");
      print("=====================");

      // Sikre at chat er valid
      if (chat.id.isEmpty) {
        throw Exception('Chat ID er tomt');
      }

      if (!context.mounted) {
        print('Context er ikke mounted - afbryder _viewChatContent');
        return;
      }

      // Vis chat i et separat vindue med fejlhåndtering
      try {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _ChatDetailScreen(chat: chat),
          ),
        );
      } catch (navigationError) {
        print('Navigation fejl: $navigationError');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kunne ikke åbne chat-skærm: $navigationError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Kritisk fejl i _viewChatContent: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kunne ikke vise chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Ny widget: Separat skærm til chat-detaljer
class _ChatDetailScreen extends StatefulWidget {
  final Chat chat;

  const _ChatDetailScreen({required this.chat});

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  late ScrollController _scrollController;
  bool _isLoading = false;
  String _error = '';
  String _jsonString = '';
  String _markdownContent = '';
  String _currentFormat = 'pretty'; // 'pretty', 'json', 'markdown', 'html'

  // Brug en Completer for at sikre, at vi ikke kalder setState under build
  bool _initialLoadStarted = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Konverter den eksisterende chat til JSON som fallback med det samme
    final chatJson = widget.chat.toJson();
    _jsonString = const JsonEncoder.withIndent('  ').convert(chatJson);

    // Generer markdown indhold fra chat-objektet
    _generateMarkdownFromChat(widget.chat);

    // Indlæs komplet chat efter første build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialLoadStarted) {
        _initialLoadStarted = true;
        _loadCompleteChat();
      }
    });
  }

  // Generer markdown indhold fra chat-objektet
  void _generateMarkdownFromChat(Chat chat) {
    try {
      final buffer = StringBuffer();

      buffer.writeln('# ${chat.title}');
      buffer.writeln('');
      buffer.writeln('**Chat ID:** ${chat.id}');
      buffer.writeln('**Antal beskeder:** ${chat.messages.length}');
      buffer.writeln(
          '**Sidst ændret:** ${DateFormat('dd/MM/yyyy HH:mm').format(chat.lastMessageTime)}');
      buffer.writeln('');
      buffer.writeln('## Beskedhistorik');
      buffer.writeln('');

      // Tilføj alle beskeder med tydeligt afsender-format
      int messageNumber = 1;
      for (final message in chat.messages) {
        try {
          final sender = message.isUser ? '**Du**' : '**AI**';
          final time = DateFormat('HH:mm:ss').format(message.timestamp);

          buffer.writeln('### Besked $messageNumber - $sender ($time)');
          buffer.writeln('');

          // Undgå null content
          final content = message.content?.trim() ?? '[Ingen indhold]';

          // Tjek om indholdet er for langt (over 100 linjer) - så forkorter vi det
          final contentLines = content.split('\n');
          if (contentLines.length > 100) {
            buffer.writeln('${contentLines.take(50).join('\n')}');
            buffer.writeln(
                '\n*... ${contentLines.length - 100} linjer udeladt ...*\n');
            buffer.writeln(
                '${contentLines.skip(contentLines.length - 50).join('\n')}');
          } else {
            buffer.writeln(content);
          }

          buffer.writeln('');
          buffer.writeln('---');
          buffer.writeln('');

          messageNumber++;
        } catch (messageError) {
          print('Fejl ved generering af markdown for besked: $messageError');
          buffer.writeln('### [Fejl ved visning af besked $messageNumber]');
          buffer.writeln('');
          buffer.writeln(
              'Der opstod en fejl ved generering af denne besked: $messageError');
          buffer.writeln('');
          buffer.writeln('---');
          buffer.writeln('');
          messageNumber++;
        }
      }

      _markdownContent = buffer.toString();
    } catch (e) {
      print('Kritisk fejl i _generateMarkdownFromChat: $e');
      _markdownContent =
          '# Fejl ved generering af markdown\n\nDer opstod en fejl: $e';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Hent det fulde chat-indhold via CLI
  Future<void> _loadCompleteChat() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final chatId = widget.chat.id;
      final outputPath = context.read<SettingsService>().outputPath;

      // Brug extractChat metoden i stedet for direkte CLI-kommando
      final chatService = context.read<ChatService>();

      print('Forsøger at udtrække chat ID $chatId til JSON format');

      // Forsøg at udtrække chaten til en JSON-fil
      final success = await chatService.extractChat(chatId, 'json');

      if (!mounted) return;

      if (!success) {
        setState(() {
          _error = 'Kunne ikke udtrække chat: ${chatService.lastError}';
        });
        return;
      }

      // Forsøg at læse den udtrukne JSON-fil
      try {
        final jsonFile = File('$outputPath/$chatId.json');
        if (await jsonFile.exists()) {
          final content = await jsonFile.readAsString();

          if (!mounted) return;

          try {
            // Validér og parse JSON
            final jsonData = json.decode(content);
            setState(() {
              _jsonString =
                  const JsonEncoder.withIndent('  ').convert(jsonData);

              // Forsøg at oprette Chat-objekt fra JSON
              try {
                // Tjek om vi har messages i JSON
                if (jsonData is Map<String, dynamic> &&
                    jsonData.containsKey('messages') &&
                    jsonData['messages'] is List) {
                  final chatMessages = jsonData['messages'] as List;

                  if (chatMessages.isNotEmpty) {
                    final fullChat = Chat.fromJson(jsonData);
                    _generateMarkdownFromChat(fullChat);
                    print(
                        'Genereret markdown fra ${fullChat.messages.length} beskeder');
                  } else {
                    _error = 'Chat indeholder ingen beskeder';
                  }
                } else {
                  _error = 'JSON mangler beskeddata';
                }
              } catch (chatError) {
                print('Fejl ved konvertering til Chat-objekt: $chatError');
                _error = 'Kunne ikke konvertere JSON til Chat: $chatError';
              }
            });
          } catch (jsonError) {
            print('JSON parse fejl: $jsonError');
            setState(() {
              _error = 'Kunne ikke parse JSON: $jsonError';
              // Vis rå indhold som fallback
              _jsonString = content;
            });
          }
        } else {
          setState(() {
            _error = 'Kunne ikke finde den udtrukne JSON-fil: $jsonFile';
          });
        }
      } catch (fileError) {
        setState(() {
          _error = 'Fejl ved læsning af fil: $fileError';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Kunne ikke hente chat: $e';
        });
      }
      print('Generel fejl ved hentning af chat: $e');
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
    try {
      final theme = Theme.of(context);

      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.chat.title,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // Format vælger
            IconButton(
              icon: Icon(_getFormatIcon()),
              tooltip: 'Skift visningsformat',
              onPressed: _showFormatDialog,
            ),
            // Udtræk knap
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _showExtractDialog(context),
              tooltip: 'Udtræk i andet format',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chat info-sektion
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText('Chat ID: ${widget.chat.id}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        SelectableText(
                            'Antal beskeder: ${widget.chat.messages.length}'),
                        const SizedBox(height: 4),
                        SelectableText(
                            'Sidst ændret: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.chat.lastMessageTime)}'),
                      ],
                    ),
                  ),
                ),
              ),
              // Statuslinje
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getFormatTitle(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Kopiér indhold',
                          onPressed: () {
                            try {
                              Clipboard.setData(ClipboardData(
                                  text: _currentFormat == 'json'
                                      ? _jsonString
                                      : _markdownContent));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Indhold kopieret til udklipsholder'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              print('Fejl ved kopiering til udklipsholder: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Kunne ikke kopiere: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Genindlæs',
                          onPressed: _loadCompleteChat,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              // Chat indhold
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                  child: Card(
                    elevation: 2,
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF242424)
                        : const Color(0xFFF5F5F5),
                    child: _buildContentWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Global error fallback
      print('KRITISK FEJL i build-metoden: $e');
      if (!mounted)
        return const SizedBox.shrink(); // Undgå at bygge hvis ikke mounted

      return Scaffold(
        appBar: AppBar(
          title: const Text('Fejl'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Der opstod en kritisk fejl',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Fejldetaljer: $e'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Gå tilbage'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Bygger det rette indholdswidget baseret på det valgte format
  Widget _buildContentWidget() {
    try {
      switch (_currentFormat) {
        case 'json':
          return Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12.0),
              child: SelectableText(
                _jsonString.isNotEmpty
                    ? _jsonString
                    : '{ "info": "Ingen JSON-data tilgængelig" }',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          );
        case 'markdown':
        case 'pretty':
        default:
          if (_markdownContent.trim().isEmpty) {
            return const Center(
              child: Text(
                'Ingen markdown-indhold tilgængeligt',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            );
          }

          try {
            return Markdown(
              controller: _scrollController,
              selectable: true,
              data: _markdownContent,
              padding: const EdgeInsets.all(12.0),
              onTapLink: (text, href, title) {
                if (href != null) {
                  // Her kunne man tilføje håndtering af link-tryk
                  print('Link tappet: $href');
                }
              },
            );
          } catch (markdownError) {
            // Fallback hvis Markdown-rendering fejler
            print('Fejl ved rendering af markdown: $markdownError');
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12.0),
              child: SelectableText(
                _markdownContent,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            );
          }
      }
    } catch (e) {
      print('Kritisk fejl i _buildContentWidget: $e');
      // Ultimativ fallback ved enhver fejl
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Der opstod en fejl ved visning af indhold: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _currentFormat =
                        'json'; // Skift til JSON-visning som fallback
                  });
                }
              },
              child: const Text('Prøv JSON-visning i stedet'),
            ),
          ],
        ),
      );
    }
  }

  // Returnerer ikonet for det aktuelle format
  IconData _getFormatIcon() {
    switch (_currentFormat) {
      case 'json':
        return Icons.data_object;
      case 'markdown':
      case 'pretty':
      default:
        return Icons.article;
    }
  }

  // Returnerer titlen for det aktuelle format
  String _getFormatTitle() {
    switch (_currentFormat) {
      case 'json':
        return 'JSON indhold:';
      case 'markdown':
        return 'Markdown indhold:';
      case 'pretty':
      default:
        return 'Chat indhold:';
    }
  }

  // Viser dialog til valg af visningsformat
  void _showFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Vælg visningsformat'),
        children: [
          _buildFormatViewOption(
              context, 'pretty', 'Pæn visning', Icons.article),
          _buildFormatViewOption(
              context, 'markdown', 'Markdown kode', Icons.code),
          _buildFormatViewOption(
              context, 'json', 'JSON data', Icons.data_object),
        ],
      ),
    );
  }

  // Bygger en mulighed i format-vælgeren
  Widget _buildFormatViewOption(
      BuildContext context, String format, String label, IconData icon) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context);
        setState(() {
          _currentFormat = format;
        });
      },
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          if (_currentFormat == format)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.check, size: 16, color: Colors.green),
            ),
        ],
      ),
    );
  }

  // Vis dialog til valg af format
  void _showExtractDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Udtræk chat som'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormatOption(context, 'markdown'),
            _buildFormatOption(context, 'html'),
            _buildFormatOption(context, 'text'),
            _buildFormatOption(context, 'json'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
        ],
      ),
    );
  }

  // Hjælper til format-valg
  Widget _buildFormatOption(BuildContext context, String format) {
    String label;
    IconData icon;

    switch (format) {
      case 'markdown':
        label = 'Markdown (.md)';
        icon = Icons.notes;
        break;
      case 'html':
        label = 'HTML (.html)';
        icon = Icons.code;
        break;
      case 'text':
        label = 'Tekst (.txt)';
        icon = Icons.text_fields;
        break;
      case 'json':
        label = 'JSON (.json)';
        icon = Icons.data_object;
        break;
      default:
        label = format;
        icon = Icons.file_present;
    }

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context); // Luk dialogen
        _extractChat(context, format);
      },
    );
  }

  // Udtræk chat i det valgte format
  void _extractChat(BuildContext context, String format) async {
    try {
      final chatService = context.read<ChatService>();
      final success = await chatService.extractChat(widget.chat.id, format);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat udtrukket som $format'),
            duration: const Duration(seconds: 2),
          ),
        );
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
  }
}
