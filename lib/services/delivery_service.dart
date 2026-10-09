import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';

class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String vehiclePlate;
  final String avatar;
  final double rating;
  final int totalDeliveries;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.avatar,
    required this.rating,
    required this.totalDeliveries,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    vehicleType: json['vehicleType'] ?? 'Bike',
    vehiclePlate: json['vehiclePlate'] ?? '',
    avatar: json['avatar'] ?? '',
    rating: (json['rating'] ?? 4.5).toDouble(),
    totalDeliveries: json['totalDeliveries'] ?? 0,
  );

  IconData get vehicleIcon {
    switch (vehicleType.toLowerCase()) {
      case 'car': return Icons.directions_car_rounded;
      case 'van': return Icons.airport_shuttle_rounded;
      case 'truck': return Icons.local_shipping_rounded;
      default: return Icons.two_wheeler_rounded;
    }
  }
}

class DeliveryService {
  static String get _baseUrl => AppConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<DriverModel>> getAvailableDrivers() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/available'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((d) => DriverModel.fromJson(d)).toList();
      }
    } catch (e) {
      print('Error fetching drivers: $e');
    }
    return [];
  }

  Future<bool> assignDriver(String orderId, String driverId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.patch(
        Uri.parse('$_baseUrl/orders/$orderId/assign-driver'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'driverId': driverId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error assigning driver: $e');
      return false;
    }
  }
}
