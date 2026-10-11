import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? socket;

  // Stream controllers
  final _marketplaceController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();
  final _orderMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _locationController = StreamController<Map<String, dynamic>>.broadcast();
  final _orderStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _availableDeliveriesController = StreamController<Map<String, dynamic>>.broadcast();
  final _proximityController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _stockController = StreamController<Map<String, dynamic>>.broadcast();

  factory SocketService() => _instance;
  SocketService._internal();

  Stream<Map<String, dynamic>> get marketplaceStream => _marketplaceController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;
  Stream<Map<String, dynamic>> get orderMessageStream => _orderMessageController.stream;
  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;
  Stream<Map<String, dynamic>> get orderStatusStream => _orderStatusController.stream;
  Stream<Map<String, dynamic>> get availableDeliveriesStream => _availableDeliveriesController.stream;
  Stream<Map<String, dynamic>> get proximityStream => _proximityController.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  Stream<Map<String, dynamic>> get stockStream => _stockController.stream;

  void connect() {
    if (socket != null && socket!.connected) return;

    socket = IO.io(AppConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'extraHeaders': AppConfig.defaultHeaders,
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) => print('Socket.IO connected to ${AppConfig.baseUrl}'));

    socket!.on('marketplace_updated', (data) {
      if (data is Map) _marketplaceController.add(Map<String, dynamic>.from(data));
    });

    socket!.on('stock_updated', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _stockController.add(map);
        _marketplaceController.add(map);
      }
    });

    socket!.on('new_announcement', (data) {
      if (data is Map) {
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('receiveChatMessage', (data) {
      if (data is Map) _chatController.add(Map<String, dynamic>.from(data));
    });

    socket!.on('receiveMessage', (data) {
      if (data is Map) _orderMessageController.add(Map<String, dynamic>.from(data));
    });

    socket!.on('locationUpdated', (data) {
      if (data is Map) _locationController.add(Map<String, dynamic>.from(data));
    });

    socket!.on('order_status_updated', (data) {
      if (data is Map) _orderStatusController.add(Map<String, dynamic>.from(data));
    });

    socket!.on('order_deleted', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _orderStatusController.add({'status': 'Deleted', ...map});
      }
    });

    socket!.on('new_order', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _orderStatusController.add(map);
        _notificationController.add({
          'title': '📦 New Order Received!',
          'message': 'A new customer order just arrived.',
          'type': 'order',
          ...map,
        });
      }
    });

    socket!.on('available_delivery_updated', (data) {
      if (data is Map) _availableDeliveriesController.add(Map<String, dynamic>.from(data));
    });

    socket!.on('driver_delivery_ring', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _availableDeliveriesController.add(map);
        _notificationController.add({
          'title': map['title'] ?? '🚨 New Delivery Request!',
          'message': map['message'] ?? 'An order is ready for pickup!',
          'type': 'delivery',
          ...map,
        });
      }
    });

    socket!.on('rider_arriving_near', (data) {
      if (data is Map) _proximityController.add(Map<String, dynamic>.from(data));
    });

    socket!.onDisconnect((_) => print('Socket.IO disconnected'));
  }

  /// Subscribe to real-time notifications for a specific user.
  /// Call once after login with the authenticated user's ID.
  void listenForNotifications(String userId) {
    connect();
    // General notifications pushed by the backend
    socket?.on('notification_$userId', (data) {
      if (data is Map) _notificationController.add(Map<String, dynamic>.from(data));
    });
    // Direct chat messages for this user
    socket?.on('chat_message_$userId', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _chatController.add(map);
      }
    });
    // Order chat messages for this user
    socket?.on('order_message_$userId', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _orderMessageController.add(map);
      }
    });
    // Order status changes for this customer
    socket?.on('order_status_$userId', (data) {
      if (data is Map) _orderStatusController.add(Map<String, dynamic>.from(data));
    });
    // New orders for sellers
    socket?.on('new_order_$userId', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _orderStatusController.add(map);
        _notificationController.add({
          'title': '📦 New Order Received!',
          'message': 'A new order just arrived for your shop.',
          'type': 'order',
          ...map,
        });
      }
    });
  }

  void stopListeningForNotifications(String userId) {
    socket?.off('notification_$userId');
    socket?.off('chat_message_$userId');
    socket?.off('order_message_$userId');
    socket?.off('order_status_$userId');
    socket?.off('new_order_$userId');
  }

  void joinOrderRoom(String orderId) {
    connect();
    socket?.emit('joinOrderRoom', orderId);
  }

  void leaveOrderRoom(String orderId) {
    socket?.emit('leaveOrderRoom', orderId);
  }

  void updateLocation({
    required String orderId,
    required double lat,
    required double lng,
    double? heading,
    String? stage,
    double? distanceToCustomer,
  }) {
    connect();
    socket?.emit('updateLocation', {
      'orderId': orderId,
      'lat': lat,
      'lng': lng,
      'heading': heading ?? 0.0,
      'stage': stage ?? 'en_route',
      'distanceToCustomer': distanceToCustomer,
    });
  }

  void ringForDelivery(String orderId, double deliveryFee) {
    connect();
    socket?.emit('ringDelivery', {'orderId': orderId, 'deliveryFee': deliveryFee});
  }

  void acceptDelivery(String orderId, Map<String, dynamic> driverData) {
    connect();
    socket?.emit('acceptDelivery', {'orderId': orderId, ...driverData});
  }

  void completeDelivery(String orderId) {
    connect();
    socket?.emit('completeDelivery', {'orderId': orderId});
  }

  void disconnect() => socket?.disconnect();

  void joinChatRoom(String chatId) {
    connect();
    socket?.emit('joinChatRoom', chatId);
  }

  void leaveChatRoom(String chatId) {
    socket?.emit('leaveChatRoom', chatId);
  }

  void sendChatMessage(String chatId, String message, String senderId, {String? senderName}) {
    connect();
    socket?.emit('sendChatMessage', {
      'chatId': chatId,
      'message': message,
      'text': message,
      'senderId': senderId,
      'senderName': senderName,
    });
  }

  void sendOrderMessage({
    required String orderId,
    required String message,
    required String senderId,
    required String senderName,
  }) {
    connect();
    socket?.emit('sendMessage', {
      'orderId': orderId,
      'message': message,
      'text': message,
      'senderId': senderId,
      'senderName': senderName,
    });
  }
}
