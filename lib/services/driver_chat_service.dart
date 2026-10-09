import 'package:flutter/material.dart';

class ChatThread {
  final String id;
  final String driverName;
  final String driverPhone;
  final String vehicleInfo;
  final String orderId;
  final String deliveryStatus; // 'ONGOING' or 'COMPLETED'
  final bool isOnline;
  final String lastMessageTime;
  final List<DriverMessage> messages;

  ChatThread({
    required this.id,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleInfo,
    required this.orderId,
    required this.deliveryStatus,
    this.isOnline = true,
    required this.lastMessageTime,
    required this.messages,
  });

  // Getters for backward compatibility
  String get otherParticipantName => driverName;
  String get otherParticipantRole => deliveryStatus == 'ONGOING' ? 'Ongoing Rider' : 'Previous Driver';
}

class DriverMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  DriverMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class DriverChatService extends ChangeNotifier {
  static final DriverChatService _instance = DriverChatService._internal();
  factory DriverChatService() => _instance;
  DriverChatService._internal();

  final List<ChatThread> _threads = [
    // 1. Ongoing Delivery Rider 1
    ChatThread(
      id: 'driver_ongoing_1',
      driverName: 'Kamal Perera (Eco Express)',
      driverPhone: '+94 77 123 4567',
      vehicleInfo: 'Yamaha EV Scooter (WP BI-8821)',
      orderId: 'ORD-9982',
      deliveryStatus: 'ONGOING',
      isOnline: true,
      lastMessageTime: '2 mins ago',
      messages: [
        DriverMessage(
          text: 'Hello! I picked up your Monstera plant from Green Haven Nursery.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        DriverMessage(
          text: 'Awesome! How long until you arrive?',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        DriverMessage(
          text: 'I am near your location now. Arriving in 10 mins!',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ],
    ),
    // 2. Ongoing Delivery Rider 2
    ChatThread(
      id: 'driver_ongoing_2',
      driverName: 'Sunil Shantha (Speedy Courier)',
      driverPhone: '+94 71 987 6543',
      vehicleInfo: 'Delivery Van (WP BZ-3310)',
      orderId: 'ORD-9940',
      deliveryStatus: 'ONGOING',
      isOnline: true,
      lastMessageTime: '25 mins ago',
      messages: [
        DriverMessage(
          text: 'Your organic pot set is loaded. On the way to your address.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
        ),
        DriverMessage(
          text: 'Please call when you reach the gate.',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
        ),
        DriverMessage(
          text: 'Will do! Estimated time 20-25 mins.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
      ],
    ),
    // 3. Previous Delivery Driver 1
    ChatThread(
      id: 'driver_past_1',
      driverName: 'Nimal Fernando (Plantora Express)',
      driverPhone: '+94 75 444 8899',
      vehicleInfo: 'TukTuk Express (WP AB-1234)',
      orderId: 'ORD-8821',
      deliveryStatus: 'COMPLETED',
      isOnline: false,
      lastMessageTime: 'Yesterday',
      messages: [
        DriverMessage(
          text: 'Package delivered safely at your front porch!',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        ),
        DriverMessage(
          text: 'Received in perfect condition. Thank you so much!',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    ),
    // 4. Previous Delivery Driver 2
    ChatThread(
      id: 'driver_past_2',
      driverName: 'Roshan Silva (Eco Delivery)',
      driverPhone: '+94 76 555 1122',
      vehicleInfo: 'Electric Bike (WP BC-5544)',
      orderId: 'ORD-7710',
      deliveryStatus: 'COMPLETED',
      isOnline: false,
      lastMessageTime: '3 days ago',
      messages: [
        DriverMessage(
          text: 'Your Fiddle Leaf Fig plant has been delivered.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        ),
        DriverMessage(
          text: 'Thank you for the quick delivery!',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
    ),
  ];

  List<ChatThread> get threads => _threads;

  List<ChatThread> get ongoingThreads => _threads.where((t) => t.deliveryStatus == 'ONGOING').toList();
  List<ChatThread> get previousThreads => _threads.where((t) => t.deliveryStatus == 'COMPLETED').toList();

  ChatThread getThread(String id) {
    return _threads.firstWhere((t) => t.id == id, orElse: () => _threads.first);
  }

  void deleteThread(String threadId) {
    _threads.removeWhere((t) => t.id == threadId);
    notifyListeners();
  }

  void clearAllThreads() {
    _threads.clear();
    notifyListeners();
  }

  void sendMessage(String threadId, String text) {
    final thread = _threads.firstWhere((t) => t.id == threadId);
    thread.messages.add(DriverMessage(text: text, isMe: true, timestamp: DateTime.now()));
    notifyListeners();

    // Simulate reply
    Future.delayed(const Duration(seconds: 2), () {
      thread.messages.add(DriverMessage(text: 'Okay, noted. Thank you!', isMe: false, timestamp: DateTime.now()));
      notifyListeners();
    });
  }
}
