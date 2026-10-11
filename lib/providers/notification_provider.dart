import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String type; // 'order' | 'chat' | 'system' | 'promo' | 'care'
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'system',
    this.data = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now())
          : (json['timestamp'] != null
              ? (DateTime.tryParse(json['timestamp'].toString())?.toLocal() ?? DateTime.now())
              : DateTime.now()),
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'system',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────
class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  String? _currentUserId;
  StreamSubscription? _socketSub;
  StreamSubscription? _chatSub;

  /// Called by the UI (via overlay) to display an in-app popup banner.
  /// Set this from main.dart once the app is ready.
  void Function(AppNotification notif)? onInAppNotification;

  List<AppNotification> get notifications => _notifications;

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  // Alias for seller – same list (server already filters per userId)
  List<AppNotification> get sellerNotifications => _notifications;
  int get sellerUnreadCount => unreadCount;

  // Alias for driver
  List<AppNotification> get driverNotifications => _notifications;
  int get driverUnreadCount => unreadCount;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;

  // ── Init ──────────────────────────────────────────────────────────
  Future<void> init() async {
    final user = await AuthService().getCurrentUser();
    if (user == null) return;
    _currentUserId = user.id;
    await fetchNotifications();
    _subscribeToSocket(user.id);
    _subscribeToChatStream();
  }

  void _subscribeToSocket(String userId) {
    SocketService().listenForNotifications(userId);
    _socketSub?.cancel();
    _socketSub = SocketService().notificationStream.listen((data) {
      _handleIncoming(AppNotification.fromJson({
        'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': data['title'] ?? 'Notification',
        'message': data['message'] ?? '',
        'type': data['type'] ?? 'system',
        'data': data['data'] ?? {},
        'isRead': false,
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
      }));
    });
  }

  void _subscribeToChatStream() {
    _chatSub?.cancel();
    _chatSub = SocketService().chatStream.listen((data) async {
      if (data['message'] == null) return;
      try {
        final user = await AuthService().getCurrentUser();
        if (user != null && data['senderId'] == user.id) return;
      } catch (_) {}
      _handleIncoming(AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '💬 New Message',
        message: data['senderName'] != null
            ? '${data['senderName']}: ${data['message']}'
            : data['message'],
        type: 'chat',
        data: {
          'chatId': data['chatId'],
          'senderName': data['senderName'] ?? '',
        },
        timestamp: DateTime.now(),
      ));
    });
  }

  void _handleIncoming(AppNotification notif) {
    if (!_notificationsEnabled) return;
    // Avoid duplicates
    if (_notifications.any((n) => n.id == notif.id)) return;
    _notifications.insert(0, notif);
    notifyListeners();
    onInAppNotification?.call(notif);
  }

  // ── REST calls ────────────────────────────────────────────────────
  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await AuthService().getToken();
      if (token == null) return;
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/notifications'),
            headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List<dynamic> raw = jsonDecode(res.body);
        _notifications.clear();
        _notifications.addAll(raw.map((j) => AppNotification.fromJson(j)));
      }
    } catch (e) {
      debugPrint('NotificationProvider.fetchNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(AppNotification notification) async {
    notification.isRead = true;
    notifyListeners();
    try {
      final token = await AuthService().getToken();
      if (token == null) return;
      await http.patch(
        Uri.parse('${AppConfig.baseUrl}/notifications/${notification.id}/read'),
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      final token = await AuthService().getToken();
      if (token == null) return;
      await http.patch(
        Uri.parse('${AppConfig.baseUrl}/notifications/mark-all-read'),
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }

  Future<void> removeNotification(AppNotification notification) async {
    _notifications.remove(notification);
    notifyListeners();
    try {
      final token = await AuthService().getToken();
      if (token == null) return;
      await http.delete(
        Uri.parse('${AppConfig.baseUrl}/notifications/${notification.id}'),
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('removeNotification error: $e');
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    try {
      final token = await AuthService().getToken();
      if (token == null) return;
      await http.delete(
        Uri.parse('${AppConfig.baseUrl}/notifications/clear-all'),
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('clearAll error: $e');
    }
  }

  // ── Local-only (for chat/system added immediately) ────────────────
  void addNotification(String title, String message,
      {String? type, Map<String, dynamic>? data}) {
    if (!_notificationsEnabled) return;
    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type ?? 'system',
      data: data ?? {},
    );
    _handleIncoming(notif);
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void reset() {
    _currentUserId = null;
    _socketSub?.cancel();
    _chatSub?.cancel();
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _chatSub?.cancel();
    super.dispose();
  }
}
