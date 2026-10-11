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

  final List<ChatThread> _threads = [];

  List<ChatThread> get threads => _threads;

  List<ChatThread> get ongoingThreads => _threads.where((t) => t.deliveryStatus == 'ONGOING').toList();
  List<ChatThread> get previousThreads => _threads.where((t) => t.deliveryStatus == 'COMPLETED').toList();

  ChatThread? getThread(String id) {
    try {
      return _threads.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void addThread(ChatThread thread) {
    if (!_threads.any((t) => t.id == thread.id)) {
      _threads.add(thread);
      notifyListeners();
    }
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
    final idx = _threads.indexWhere((t) => t.id == threadId);
    if (idx != -1) {
      _threads[idx].messages.add(DriverMessage(text: text, isMe: true, timestamp: DateTime.now()));
      notifyListeners();
    }
  }
}
