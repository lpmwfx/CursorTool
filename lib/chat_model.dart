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

  /// Opret ChatMessage fra JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'] ?? '',
      isUser: json['role'] == 'user' || json['role'] == 'user_edited',
      timestamp:
          json['timestamp'] != null
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

  Chat({required this.id, required this.title, required this.messages})
    : lastMessageTime =
          messages.isNotEmpty ? messages.last.timestamp : DateTime.now();

  /// Opret Chat fra JSON
  factory Chat.fromJson(Map<String, dynamic> json, String chatId) {
    final List<dynamic> messagesJson = json['messages'] ?? [];

    // Konverter JSON beskeder til ChatMessage objekter
    final messages =
        messagesJson.map((msgJson) => ChatMessage.fromJson(msgJson)).toList();

    // Hvis der er noget metadata, der indeholder en titel, så brug den
    final metadata = json['metadata'] as Map<String, dynamic>?;
    final title = metadata?['title'] ?? 'Chat $chatId';

    return Chat(id: chatId, title: title, messages: messages);
  }

  /// Konverter Chat til JSON
  Map<String, dynamic> toJson() {
    return {
      'metadata': {'title': title},
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }
}
