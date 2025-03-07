import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'chat_browser.dart';
import 'chat_model.dart';
import 'config.dart';

class ChatExtractor {
  final Config config;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  ChatExtractor(this.config);

  // Udtræk en specifik chat eller alle chats
  Future<void> extractChat(String chatId) async {
    final browser = ChatBrowser(config);
    final chatHistories = await browser.listChatHistories();
    
    if (chatId == 'all') {
      // Udtræk alle chats
      await _extractAllChats(chatHistories);
    } else {
      // Udtræk en specifik chat
      final chat = chatHistories.firstWhere(
        (c) => c.id == chatId,
        orElse: () => throw Exception('Chat med ID $chatId ikke fundet'),
      );
      
      await _extractSingleChat(chat);
    }
  }

  // Udtræk alle chats
  Future<void> _extractAllChats(List<ChatHistory> chatHistories) async {
    for (final chat in chatHistories) {
      await _extractSingleChat(chat);
    }
  }

  // Udtræk en enkelt chat
  Future<void> _extractSingleChat(ChatHistory chat) async {
    final outputDir = Directory(config.outputPath);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    String content;
    String extension;

    switch (config.outputFormat.toLowerCase()) {
      case 'json':
        content = json.encode(chat.toMap());
        extension = 'json';
        break;
      case 'markdown':
      case 'md':
        content = _formatAsMarkdown(chat);
        extension = 'md';
        break;
      case 'html':
        content = _formatAsHtml(chat);
        extension = 'html';
        break;
      case 'text':
      default:
        content = _formatAsText(chat);
        extension = 'txt';
        break;
    }

    final filePath = path.join(config.outputPath, '${chat.id}.$extension');
    final file = File(filePath);
    await file.writeAsString(content);
  }

  // Formater chat som tekst
  String _formatAsText(ChatHistory chat) {
    final buffer = StringBuffer();
    buffer.writeln('Chat: ${chat.title}');
    buffer.writeln('ID: ${chat.id}');
    buffer.writeln('');

    for (final message in chat.messages) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
      buffer.writeln('${message.role.toUpperCase()} (${_dateFormat.format(timestamp)}):');
      buffer.writeln(message.content);
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // Formater chat som markdown
  String _formatAsMarkdown(ChatHistory chat) {
    final buffer = StringBuffer();
    buffer.writeln('# ${chat.title}');
    buffer.writeln('');
    buffer.writeln('*Chat ID: ${chat.id}*');
    buffer.writeln('');

    for (final message in chat.messages) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
      buffer.writeln('## ${message.role.toUpperCase()} - ${_dateFormat.format(timestamp)}');
      buffer.writeln('');
      buffer.writeln(message.content);
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // Formater chat som HTML
  String _formatAsHtml(ChatHistory chat) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>${chat.title}</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }');
    buffer.writeln('    .message { margin-bottom: 20px; padding: 10px; border-radius: 5px; }');
    buffer.writeln('    .user { background-color: #e6f7ff; }');
    buffer.writeln('    .assistant { background-color: #f0f0f0; }');
    buffer.writeln('    .timestamp { font-size: 0.8em; color: #666; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <h1>${chat.title}</h1>');
    buffer.writeln('  <p><em>Chat ID: ${chat.id}</em></p>');

    for (final message in chat.messages) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
      final isUser = message.role == 'user';
      buffer.writeln('  <div class="message ${isUser ? 'user' : 'assistant'}">');
      buffer.writeln('    <div class="timestamp">${message.role.toUpperCase()} - ${_dateFormat.format(timestamp)}</div>');
      buffer.writeln('    <div class="content">${_htmlEscape(message.content)}</div>');
      buffer.writeln('  </div>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  // Escape HTML special characters
  String _htmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;')
        .replaceAll('\n', '<br>');
  }
} 