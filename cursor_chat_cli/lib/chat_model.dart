import 'dart:convert';
import 'package:intl/intl.dart';

/// Model klasser for chat historik

/// Repræsenterer en besked i en chat
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  /// Opret ChatMessage fra JSON objekt
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['text'] ?? json['content'] ?? '',
      isUser: json['role'] == 'user' ||
          json['role'] == 'user_edited' ||
          json['isUser'] == true,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Konverter ChatMessage til JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'role': isUser ? 'user' : 'assistant',
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// Repræsenterer en hel chat historik
class Chat {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime lastMessageTime;

  Chat({
    required this.id,
    required this.title,
    required this.messages,
  }) : lastMessageTime =
            messages.isNotEmpty ? messages.last.timestamp : DateTime.now();

  /// Opret Chat fra JSON string (fra SQLite database)
  static Chat? fromSqliteValue(String chatId, String jsonValue) {
    try {
      final data = jsonDecode(jsonValue);

      // Håndter forskellige JSON-formater
      if (data is List) {
        // Hvis det er et array, antag at det er beskeder
        final messages =
            data.map((msgJson) => ChatMessage.fromJson(msgJson)).toList();

        final title = messages.isNotEmpty
            ? _generateTitle(messages.first.content)
            : 'Chat $chatId';

        return Chat(
          id: chatId,
          title: title,
          messages: messages,
        );
      } else if (data is Map) {
        // Hvis det er et objekt, undersøg strukturen
        if (data.containsKey('messages')) {
          // Antagelse: { messages: [...] }
          final List<dynamic> messagesJson = data['messages'] ?? [];
          final messages = messagesJson
              .map((msgJson) => ChatMessage.fromJson(msgJson))
              .toList();

          final title = data['title'] ??
              (messages.isNotEmpty
                  ? _generateTitle(messages.first.content)
                  : 'Chat $chatId');

          return Chat(
            id: chatId,
            title: title,
            messages: messages,
          );
        } else if (data.containsKey('sessions')) {
          // Antagelse: { sessions: [{messages: [...]}] }
          final List<dynamic> sessionsJson = data['sessions'] ?? [];
          if (sessionsJson.isNotEmpty) {
            final sessionData = sessionsJson.last;
            final List<dynamic> messagesJson = sessionData['messages'] ?? [];

            final messages = messagesJson
                .map((msgJson) => ChatMessage.fromJson(msgJson))
                .toList();

            final title = sessionData['title'] ??
                (messages.isNotEmpty
                    ? _generateTitle(messages.first.content)
                    : 'Chat $chatId');

            return Chat(
              id: chatId,
              title: title,
              messages: messages,
            );
          }
        } else if (data.containsKey('chats')) {
          // Antagelse: { chats: [{title, messages: [...]}] }
          final List<dynamic> chatsJson = data['chats'] ?? [];
          if (chatsJson.isNotEmpty) {
            final chatData = chatsJson.last;
            final List<dynamic> messagesJson = chatData['messages'] ?? [];

            final messages = messagesJson
                .map((msgJson) => ChatMessage.fromJson(msgJson))
                .toList();

            final title = chatData['title'] ??
                (messages.isNotEmpty
                    ? _generateTitle(messages.first.content)
                    : 'Chat $chatId');

            return Chat(
              id: chatId,
              title: title,
              messages: messages,
            );
          }
        }
      }

      // Hvis vi ikke kunne genkende formatet
      return null;
    } catch (e) {
      print('Fejl ved parsing af chat data: $e');
      return null;
    }
  }

  /// Generer en titel baseret på den første besked
  static String _generateTitle(String content) {
    // Begræns til de første 50 tegn
    final truncated =
        content.length > 50 ? '${content.substring(0, 47)}...' : content;

    // Fjern newlines
    return truncated.replaceAll('\n', ' ').trim();
  }

  /// Konverter Chat til JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }
}
