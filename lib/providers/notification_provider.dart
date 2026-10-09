import 'package:flutter/foundation.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';

class AppNotification {
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? type;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type,
    this.data,
  });
}

class NotificationProvider extends ChangeNotifier {
  NotificationProvider() {
    SocketService().chatStream.listen((data) async {
      if (data != null && data['message'] != null) {
        try {
          final user = await AuthService().getCurrentUser();
          if (user != null && data['senderId'] == user.id) {
            return; // Don't notify for own messages
          }
        } catch (e) {}
        
        addNotification(
          'New Message',
          data['message'],
          type: 'chat',
          data: {
            'chatId': data['chatId'],
            'senderName': data['senderName'] ?? 'New Message',
          },
        );
      }
    });
  }

  final List<AppNotification> _notifications = [
    AppNotification(
      title: 'Order Out for Delivery 🚚',
      message: 'Driver Saman is on the way with your Monstera Deliciosa order #DEL-8392. Estimated arrival: 15 mins.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      isRead: false,
      type: 'order',
      data: {'orderId': 'DEL-8392'},
    ),
    AppNotification(
      title: '20% OFF Rewards Unlocked! 🎉',
      message: 'You have earned 250 Cheer Points! Redeem now for 20% discount on your next indoor plant.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
      type: 'promo',
    ),
    AppNotification(
      title: 'Plant Care Reminder 🪴',
      message: 'Your Fiddle Leaf Fig needs watering today. Place it near indirect sunlight for healthy leaves.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
      type: 'care',
    ),
    AppNotification(
      title: 'Welcome to Plantora! 🌿',
      message: 'Start exploring rare plants, connect with verified local nurseries, and enjoy instant driver deliveries.',
      timestamp: DateTime.now().subtract(const Duration(hours: 24)),
      isRead: true,
      type: 'system',
    ),
  ];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  final List<AppNotification> _sellerNotifications = [
    AppNotification(
      title: 'New Order Received! 📦',
      message: 'You have a new order #ORD-9912 for 2x Fiddle Leaf Fig. Please prepare for shipping.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      type: 'order',
    ),
    AppNotification(
      title: 'Low Stock Alert ⚠️',
      message: 'Your inventory for "Monstera Albo" is running low (2 left). Restock soon to avoid missing out on sales.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: 'inventory',
    ),
    AppNotification(
      title: 'Payout Successful 💰',
      message: 'Your weekly payout of Rs. 14,500 has been transferred to your registered bank account.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: 'finance',
    ),
  ];

  List<AppNotification> get sellerNotifications => _sellerNotifications;
  int get sellerUnreadCount => _sellerNotifications.where((n) => !n.isRead).length;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void addNotification(String title, String message, {String? type, Map<String, dynamic>? data}) {
    if (!_notificationsEnabled) return;
    _notifications.insert(0, AppNotification(
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      data: data,
    ));
    notifyListeners();
  }

  void markAsRead(AppNotification notification) {
    notification.isRead = true;
    notifyListeners();
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    for (var n in _sellerNotifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void removeNotification(AppNotification notification) {
    _notifications.remove(notification);
    _sellerNotifications.remove(notification);
    notifyListeners();
  }
}
