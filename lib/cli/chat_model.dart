class ChatMessage {
  final String content;
  final String role;
  final int timestamp;

  ChatMessage({
    required this.content,
    required this.role,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      content: map['content'] ?? '',
      role: map['role'] ?? 'assistant',
      timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'role': role,
      'timestamp': timestamp,
    };
  }
}

class ChatHistory {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final int lastMessageTime;

  ChatHistory({
    required this.id,
    required this.title,
    required this.messages,
  }) : lastMessageTime = messages.isNotEmpty 
        ? messages.last.timestamp 
        : DateTime.now().millisecondsSinceEpoch;

  factory ChatHistory.fromMap(Map<String, dynamic> map) {
    final List<dynamic> messagesMap = map['messages'] ?? [];
    final messages = messagesMap
        .map((msgMap) => ChatMessage.fromMap(msgMap))
        .toList();

    return ChatHistory(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unavngiven chat',
      messages: messages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((msg) => msg.toMap()).toList(),
    };
  }
} 