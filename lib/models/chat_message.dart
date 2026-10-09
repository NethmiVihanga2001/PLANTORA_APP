// lib/models/chat_message.dart

enum MessageRole { user, assistant }

class ChatMessage {
  final String text;
  final MessageRole role;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.role,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;

  Map<String, dynamic> toOpenAIMessage() => {
        'role': isUser ? 'user' : 'assistant',
        'content': text,
      };
}
