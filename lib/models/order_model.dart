import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.accepted: return 'Accepted';
      case OrderStatus.preparing: return 'Preparing';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.accepted: return Colors.blue;
      case OrderStatus.preparing: return Colors.purple;
      case OrderStatus.shipped: return Colors.indigo;
      case OrderStatus.outForDelivery: return Colors.teal;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending: return Icons.more_horiz;
      case OrderStatus.accepted: return Icons.check_circle_outline;
      case OrderStatus.preparing: return Icons.restaurant;
      case OrderStatus.shipped: return Icons.local_shipping;
      case OrderStatus.outForDelivery: return Icons.directions_bike;
      case OrderStatus.delivered: return Icons.done_all;
      case OrderStatus.cancelled: return Icons.cancel;
    }
  }
}

class OrderItem {
  final String productId;
  final String title;
  final int quantity;
  final double price;
  final String sellerId;
  final String emoji;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
    required this.sellerId,
    required this.emoji,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      title: json['title'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      sellerId: json['sellerId'] ?? '',
      emoji: json['emoji'] ?? '🌿',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'title': title,
    'quantity': quantity,
    'price': price,
    'sellerId': sellerId,
    'emoji': emoji,
    'imageUrl': imageUrl,
  };
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final double totalAmount;
  final double? subtotalAmount;
  final double? discountAmount;
  final String? discountTitle;
  final double? deliveryFee;
  final String status;
  final DateTime createdAt;
  final String shippingAddress;
  final String phone;
  final String? customerAvatar;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverAvatar;
  final String? vehicleType;
  final String? vehiclePlate;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.items,
    required this.totalAmount,
    this.subtotalAmount,
    this.discountAmount,
    this.discountTitle,
    this.deliveryFee,
    required this.status,
    required this.createdAt,
    required this.shippingAddress,
    required this.phone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverAvatar,
    this.vehicleType,
    this.vehiclePlate,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerAvatar: json['customerAvatar'],
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      subtotalAmount: json['subtotalAmount'] != null ? (json['subtotalAmount'] as num).toDouble() : null,
      discountAmount: json['discountAmount'] != null ? (json['discountAmount'] as num).toDouble() : null,
      discountTitle: json['discountTitle'],
      deliveryFee: json['deliveryFee'] != null ? (json['deliveryFee'] as num).toDouble() : null,
      status: json['status'] ?? 'Pending',
      createdAt: _parseDateTime(json['createdAt']),
      shippingAddress: json['shippingAddress'] ?? '',
      phone: json['phone'] ?? '',
      driverId: json['driverId'],
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      driverAvatar: json['driverAvatar'],
      vehicleType: json['vehicleType'],
      vehiclePlate: json['vehiclePlate'],
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val.toLocal();
    if (val is Map) {
      final sec = val['_seconds'] ?? val['seconds'];
      if (sec is num) {
        return DateTime.fromMillisecondsSinceEpoch(sec.toInt() * 1000, isUtc: true).toLocal();
      }
    }
    if (val is String) {
      try {
        return DateTime.parse(val).toLocal();
      } catch (_) {}
    }
    if (val is num) {
      return DateTime.fromMillisecondsSinceEpoch(val.toInt(), isUtc: true).toLocal();
    }
    return DateTime.now();
  }

  OrderStatus get orderStatus {
    final s = status.trim().toLowerCase();
    switch (s) {
      case 'accepted': return OrderStatus.accepted;
      case 'preparing': return OrderStatus.preparing;
      case 'shipped': return OrderStatus.shipped;
      case 'out for delivery':
      case 'out_for_delivery': return OrderStatus.outForDelivery;
      case 'delivered': return OrderStatus.delivered;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<OrderItem>? items,
    double? totalAmount,
    double? subtotalAmount,
    double? discountAmount,
    String? discountTitle,
    double? deliveryFee,
    String? status,
    DateTime? createdAt,
    String? shippingAddress,
    String? phone,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverAvatar,
    String? vehicleType,
    String? vehiclePlate,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountTitle: discountTitle ?? this.discountTitle,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      phone: phone ?? this.phone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverAvatar: driverAvatar ?? this.driverAvatar,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
    );
  }
}
