import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ChatService {
  static String get _baseUrl => AppConfig.baseUrl;

  Future<Map<String, dynamic>?> initiateChat(
      String customerId, String sellerId, String customerName, String sellerName, String? sellerAvatar) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/initiate'),
        headers: AppConfig.headers({'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
        body: json.encode({
          'customerId': customerId,
          'sellerId': sellerId,
          'customerName': customerName,
          'sellerName': sellerName,
          'sellerAvatar': sellerAvatar,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error initiating chat: $e');
    }
    return null;
  }

  Future<List<dynamic>> getUserChats(String userId) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/user/$userId'),
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('Error fetching user chats: $e');
    }
    return [];
  }

  Future<List<dynamic>> getChatMessages(String chatId) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/$chatId/messages'),
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
    return [];
  }

  Future<bool> sendMessage(String chatId, String senderId, String text, {String? senderName}) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/$chatId/message'),
        headers: AppConfig.headers({'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
        body: json.encode({
          'senderId': senderId,
          'senderName': senderName,
          'text': text,
          'message': text,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending message: $e');
    }
    return false;
  }

  Future<bool> sendOrderMessage(String orderId, String senderId, String text, {String? senderName}) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/orders/$orderId/message'),
        headers: AppConfig.headers({'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
        body: json.encode({
          'senderId': senderId,
          'senderName': senderName,
          'text': text,
          'message': text,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending order message: $e');
    }
    return false;
  }
}
