import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? socket;
  
  // Stream controller to broadcast marketplace events
  final _marketplaceController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  Stream<Map<String, dynamic>> get marketplaceStream => _marketplaceController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;

  void connect() {
    socket = IO.io(AppConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('Socket.IO connected');
    });

    socket!.on('marketplace_updated', (data) {
      print('Marketplace updated event received: $data');
      _marketplaceController.add(data);
    });

    socket!.on('receiveChatMessage', (data) {
      _chatController.add(data);
    });

    socket!.onDisconnect((_) => print('Socket.IO disconnected'));
  }

  void disconnect() {
    socket?.disconnect();
  }

  void joinChatRoom(String chatId) {
    socket?.emit('joinChatRoom', chatId);
  }

  void sendChatMessage(String chatId, String message, String senderId) {
    socket?.emit('sendChatMessage', {
      'chatId': chatId,
      'message': message,
      'senderId': senderId,
    });
  }
}
