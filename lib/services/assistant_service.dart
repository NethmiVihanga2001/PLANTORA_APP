import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../config/app_config.dart';

class AssistantService {
  static String get _baseUrl => '${AppConfig.baseUrl}/api/ai/chat';

  Future<String> sendMessage(List<ChatMessage> history) async {
    if (history.isEmpty) return 'Hello! How can I help you?';

    final lastMessage = history.last.text;

    final formattedHistory = history.map((msg) => msg.toOpenAIMessage()).toList();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': lastMessage,
          'history': formattedHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'Sorry, I received an empty response.';
      } else {
        throw AssistantException(response.statusCode, 'Failed to connect to the server');
      }
    } catch (e) {
      throw AssistantException(500, e.toString());
    }
  }
}

class AssistantException implements Exception {
  final int statusCode;
  final String message;
  AssistantException(this.statusCode, this.message);

  @override
  String toString() => 'Service Error $statusCode: $message';
}
