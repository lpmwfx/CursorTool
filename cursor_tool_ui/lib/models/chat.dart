class ChatMessage {
  final String? content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    this.content,
    required this.isUser,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'] ?? '',
      isUser: json['role'] == 'user' || json['isUser'] == true,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content ?? '',
      'role': isUser ? 'user' : 'assistant',
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class Chat {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  late final DateTime lastMessageTime;

  Chat({
    required this.id,
    required this.title,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [] {
    // Sikre at lastMessageTime altid er gyldig, selv hvis messages er tom
    lastMessageTime = this.messages.isNotEmpty 
        ? this.messages.last.timestamp 
        : DateTime.now();
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    final List<dynamic> messagesJson = json['messages'] ?? [];
    final messages = messagesJson
        .map((msgJson) => ChatMessage.fromJson(msgJson))
        .toList();

    return Chat(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unavngiven chat',
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }
}
