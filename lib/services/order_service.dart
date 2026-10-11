import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/order_model.dart';
import 'auth_service.dart';

class OrderService {
  static String get _baseUrl => AppConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> placeOrder({
    required List<OrderItem> items,
    required double totalAmount,
    double? subtotalAmount,
    double? discountAmount,
    String? discountTitle,
    double? deliveryFee,
    String? shippingAddress,
    String? phone,
    String? customerName,
    String? customerAvatar,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    final prefs = await SharedPreferences.getInstance();
    
    final counterKey = 'order_counter_$dateStr';
    int dailyCounter = (prefs.getInt(counterKey) ?? 0) + 1;
    await prefs.setInt(counterKey, dailyCounter);
    
    final orderNumStr = dailyCounter.toString().padLeft(4, '0');
    final orderId = 'ORD-$dateStr-$orderNumStr';

    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/orders'),
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
        body: jsonEncode({
          'items': items.map((i) => i.toJson()).toList(),
          'totalAmount': totalAmount,
          'subtotalAmount': subtotalAmount,
          'discountAmount': discountAmount,
          'discountTitle': discountTitle,
          'deliveryFee': deliveryFee,
          'shippingAddress': shippingAddress ?? 'Colombo, Sri Lanka',
          'phone': phone ?? '+94 77 123 4567',
          'customerName': customerName,
          'customerAvatar': customerAvatar,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final realId = data['orderId'] ?? orderId;

        // Also cache locally
        final localOrders = prefs.getStringList('local_user_orders') ?? [];
        final newOrderMap = {
          'id': realId,
          'customerName': customerName ?? 'Nethmi Vihanga',
          'customerAvatar': customerAvatar,
          'items': items.map((i) => i.toJson()).toList(),
          'totalAmount': totalAmount,
          'subtotalAmount': subtotalAmount,
          'discountAmount': discountAmount,
          'discountTitle': discountTitle,
          'deliveryFee': deliveryFee,
          'shippingAddress': shippingAddress ?? 'Colombo, Sri Lanka',
          'phone': phone ?? '+94 77 123 4567',
          'status': 'Pending',
          'createdAt': now.toIso8601String(),
        };
        localOrders.insert(0, jsonEncode(newOrderMap));
        await prefs.setStringList('local_user_orders', localOrders);

        return {'success': true, 'orderId': realId};
      } else {
        String errorMsg = 'Failed to place order';
        try {
          final data = jsonDecode(response.body);
          errorMsg = data['error'] ?? data['message'] ?? errorMsg;
        } catch (_) {}
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      print('OrderService placeOrder network attempt skipped/failed, proceeding locally: $e');
    }

    try {
      final localOrders = prefs.getStringList('local_user_orders') ?? [];
      final newOrderMap = {
        'id': orderId,
        'customerName': customerName ?? 'Nethmi Vihanga',
        'customerAvatar': customerAvatar,
        'items': items.map((i) => i.toJson()).toList(),
        'totalAmount': totalAmount,
        'subtotalAmount': subtotalAmount,
        'discountAmount': discountAmount,
        'discountTitle': discountTitle,
        'deliveryFee': deliveryFee,
        'shippingAddress': shippingAddress ?? 'Colombo, Sri Lanka',
        'phone': phone ?? '+94 77 123 4567',
        'status': 'Pending',
        'createdAt': now.toIso8601String(),
      };
      localOrders.insert(0, jsonEncode(newOrderMap));
      await prefs.setStringList('local_user_orders', localOrders);
    } catch (_) {}

    return {'success': true, 'orderId': orderId};
  }

  Future<List<OrderModel>> getOrders() async {
    List<OrderModel> orders = [];
    bool networkSuccess = false;
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/orders'),
        headers: AppConfig.headers({
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        orders = data.map((o) => OrderModel.fromJson(o)).toList();
        networkSuccess = true;
      }
    } catch (e) {
      print('OrderService getOrders network failed, using local orders: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!networkSuccess) {
        final localOrdersJson = prefs.getStringList('local_user_orders') ?? [];
        orders = localOrdersJson.map((item) => OrderModel.fromJson(jsonDecode(item))).toList();
      } else {
        // Prune deleted orders from local cache so they don't phantom-reappear
        final serverIds = orders.map((o) => o.id.trim().toLowerCase()).toSet();
        final localOrdersJson = prefs.getStringList('local_user_orders') ?? [];
        final updatedLocal = localOrdersJson.where((item) {
          try {
            final map = jsonDecode(item);
            final id = (map['id'] ?? '').toString().trim().toLowerCase();
            return serverIds.contains(id);
          } catch (_) {
            return false;
          }
        }).toList();
        await prefs.setStringList('local_user_orders', updatedLocal);
      }

      final deletedIds = (prefs.getStringList('deleted_order_ids') ?? [])
          .map((id) => id.trim().toLowerCase())
          .toSet();
      orders.removeWhere((o) => deletedIds.contains(o.id.trim().toLowerCase()));
    } catch (_) {}

    return orders;
  }

  Future<bool> deleteOrder(String orderId) async {
    final cleanId = orderId.trim().toLowerCase();
    try {
      final token = await _authService.getToken();
      await http.delete(
        Uri.parse('$_baseUrl/orders/$orderId'),
        headers: AppConfig.headers({
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final localOrdersJson = prefs.getStringList('local_user_orders') ?? [];
      final updatedLocal = localOrdersJson.where((item) {
        try {
          final map = jsonDecode(item);
          return (map['id'] ?? '').toString().trim().toLowerCase() != cleanId;
        } catch (_) {
          return true;
        }
      }).toList();
      await prefs.setStringList('local_user_orders', updatedLocal);

      final deletedIds = prefs.getStringList('deleted_order_ids') ?? [];
      if (!deletedIds.any((id) => id.trim().toLowerCase() == cleanId)) {
        deletedIds.add(orderId);
        await prefs.setStringList('deleted_order_ids', deletedIds);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreOrder(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList('deleted_order_ids') ?? [];
      deletedIds.remove(orderId);
      await prefs.setStringList('deleted_order_ids', deletedIds);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    bool success = false;
    try {
      final token = await _authService.getToken();
      final response = await http.patch(
        Uri.parse('$_baseUrl/orders/$orderId/status'),
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        success = true;
      } else {
        print('updateOrderStatus error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('updateOrderStatus exception: $e');
    }

    if (success) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final localOrdersJson = prefs.getStringList('local_user_orders') ?? [];
        final updated = localOrdersJson.map((item) {
          try {
            final map = jsonDecode(item);
            if ((map['id'] ?? '').toString().trim().toLowerCase() == orderId.trim().toLowerCase()) {
              map['status'] = status;
            }
            return jsonEncode(map);
          } catch (_) {
            return item;
          }
        }).toList();
        await prefs.setStringList('local_user_orders', updated);
      } catch (_) {}
    }
    return success;
  }

  Future<bool> ringForDelivery(String orderId, double deliveryFee) async {
    try {
      final token = await _authService.getToken();
      await http.post(
        Uri.parse('$_baseUrl/orders/$orderId/ring-delivery'),
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
        body: jsonEncode({'deliveryFee': deliveryFee}),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}

    await updateOrderStatus(orderId, 'Shipped');
    return true;
  }

  Future<List<OrderModel>> getAvailableDeliveries() async {
    List<OrderModel> deliveries = [];
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/available-for-delivery'),
        headers: AppConfig.headers({
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        deliveries = data.map((o) => OrderModel.fromJson(o)).toList();
      }
    } catch (e) {
      print('OrderService getAvailableDeliveries error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final localOrdersJson = prefs.getStringList('local_user_orders') ?? [];
      final localOrders = localOrdersJson
          .map((item) => OrderModel.fromJson(jsonDecode(item)))
          .where((o) => o.status == 'Shipped' && (o.driverId == null || o.driverId!.isEmpty))
          .toList();

      for (final lo in localOrders) {
        if (!deliveries.any((d) => d.id == lo.id)) {
          deliveries.add(lo);
        }
      }
    } catch (_) {}

    return deliveries;
  }

  Future<bool> acceptDelivery(String orderId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.patch(
        Uri.parse('$_baseUrl/orders/$orderId/accept-delivery'),
        headers: AppConfig.headers({
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await updateOrderStatus(orderId, 'Out for Delivery');
        return true;
      }
    } catch (e) {
      print('OrderService acceptDelivery error: $e');
    }
    await updateOrderStatus(orderId, 'Out for Delivery');
    return true;
  }

  Future<List<OrderModel>> getMyDeliveries() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/my-deliveries'),
        headers: AppConfig.headers({
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((o) => OrderModel.fromJson(o)).toList();
      }
    } catch (_) {}
    return [];
  }
}
