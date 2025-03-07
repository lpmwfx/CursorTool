import 'dart:io';
import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;
import 'chat_model.dart';
import 'config.dart';

class ChatBrowser {
  final Config config;

  ChatBrowser(this.config);

  // Hent alle chat historikker fra databasen
  Future<List<ChatHistory>> listChatHistories() async {
    final dbPath = config.findCursorChatDb();
    final db = sqlite3.open(dbPath);

    try {
      final result = db.select('''
        SELECT id, title, created_at, updated_at
        FROM conversations
        ORDER BY updated_at DESC
      ''');

      final List<ChatHistory> chatHistories = [];

      for (final row in result) {
        final id = row['id'] as String;
        final title = row['title'] as String? ?? 'Unavngiven chat';
        
        // Hent beskeder for denne chat
        final messagesResult = db.select('''
          SELECT role, content, created_at
          FROM messages
          WHERE conversation_id = ?
          ORDER BY created_at ASC
        ''', [id]);

        final List<ChatMessage> messages = [];
        for (final msgRow in messagesResult) {
          messages.add(ChatMessage(
            role: msgRow['role'] as String? ?? 'assistant',
            content: msgRow['content'] as String? ?? '',
            timestamp: msgRow['created_at'] as int? ?? 0,
          ));
        }

        chatHistories.add(ChatHistory(
          id: id,
          title: title,
          messages: messages,
        ));
      }

      return chatHistories;
    } finally {
      db.dispose();
    }
  }

  // Gem chat historikker til JSON-filer
  Future<void> saveChatsToFiles(List<ChatHistory> chatHistories) async {
    final outputDir = Directory(config.outputPath);
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    for (final chat in chatHistories) {
      final filePath = path.join(config.outputPath, '${chat.id}.json');
      final file = File(filePath);
      await file.writeAsString(json.encode(chat.toMap()));
    }
  }
} 