import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../config/app_config.dart';

class AssistantService {
  static const String _geminiApiKey = 'AIzaSyBO4jTWPSD2VOBUwPWsDRgezawoJAMAKkA';
  static String get _baseUrl => '${AppConfig.baseUrl}/api/ai/chat';

  Future<String> sendMessage(List<ChatMessage> history) async {
    if (history.isEmpty) return 'Hello! How can I help you?';

    final lastMessage = history.last.text;

    // 1. Try local backend server first (when plugged into USB with adb reverse)
    try {
      final formattedHistory = history.map((msg) => msg.toOpenAIMessage()).toList();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: AppConfig.headers({'Content-Type': 'application/json'}),
        body: jsonEncode({
          'message': lastMessage,
          'history': formattedHistory,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply']?.toString().trim();
        // Return server reply if it gave a genuine AI response rather than generic template
        if (reply != null && reply.isNotEmpty && !reply.startsWith('🌿 **Plantora AI Botanical Analysis for')) {
          return reply;
        }
      }
    } catch (_) {
      // Backend unreachable (e.g. USB cable unplugged) -> seamlessly fall back to direct Gemini
    }

    // 2. Direct Google Gemini API call (works everywhere: Wi-Fi, 4G, USB unplugged)
    try {
      final geminiReply = await _callGeminiDirectly(history);
      if (geminiReply.isNotEmpty) return geminiReply;
    } catch (e) {
      print('Direct Gemini error: $e');
    }

    // 3. Smart local botanical knowledge fallback
    return _getLocalFallback(lastMessage);
  }

  Future<String> _callGeminiDirectly(List<ChatMessage> history) async {
    final models = [
      'gemini-2.5-flash',
      'gemini-flash-latest',
      'gemini-2.5-pro',
      'gemini-3.5-flash',
    ];

    final contents = <Map<String, dynamic>>[];
    final recent = history.length > 8 ? history.sublist(history.length - 8) : history;
    for (final msg in recent) {
      final role = (msg.role == MessageRole.user) ? 'user' : 'model';
      contents.add({
        'role': role,
        'parts': [
          {'text': msg.text}
        ]
      });
    }

    const systemPrompt =
        'You are Plantora AI Botanical Expert, a knowledgeable, friendly, and accurate plant assistant. '
        'You provide precise plant care, identification, gardening advice, and botanical knowledge. '
        'Support English, Sinhala, Singlish (e.g. "Kumarika plant eka mokakda English valin kiyanne" -> Kumarika is Aloe Vera, '
        'Karapincha is Curry leaf, Kohomba is Neem), and Tamil. '
        'Answer questions clearly, conversationally, and helpfully with proper botanical and common names.';

    for (final model in models) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );

        final payload = {
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
          }
        };

        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text']?.toString().trim();
              if (text != null && text.isNotEmpty) {
                return text;
              }
            }
          }
        }
      } catch (e) {
        print('Direct Gemini model $model attempt failed: $e');
      }
    }

    throw Exception('Gemini online API unavailable');
  }

  String _getLocalFallback(String query) {
    final q = query.toLowerCase();
    if (q.contains('kumarika') || q.contains('aloe')) {
      return 'Kumarika plant eka English walin kiyanne **Aloe Vera** (Aloe barbadensis Miller) kiyala.\n\nලංකාවේ "Kumarika" කියන්නේ ඇලෝ වේරා අඩංගු නිෂ්පාදන සඳහා ජනප්‍රිය වෙළඳ නාමයක්. නමුත් ශාකය හඳුන්වන්නේ **Aloe Vera** නමින්.';
    }
    if (q.contains('karapincha') || q.contains('curry leaf')) {
      return 'Karapincha plant eka English walin kiyanne **Curry Tree / Curry Leaf Plant** (*Murraya koenigii*) kiyala.';
    }
    if (q.contains('kohomba') || q.contains('neem')) {
      return 'Kohomba plant eka English walin kiyanne **Neem Tree / Indian Lilac** (*Azadirachta indica*) kiyala.';
    }
    if (q.contains('kothala') || q.contains('himbutu')) {
      return 'Kothala Himbutu plant eka English / scientific name eka **Salacia reticulata** kiyala.';
    }
    return '🌿 Plantora AI:\n\nThank you for asking about "$query". Please check that your device has an active Wi-Fi or mobile data connection to receive full botanical insights.';
  }
}

class AssistantException implements Exception {
  final int statusCode;
  final String message;
  AssistantException(this.statusCode, this.message);

  @override
  String toString() => 'Service Error $statusCode: $message';
}
