import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String vehiclePlate;
  final String avatar;
  final double rating;
  final int totalDeliveries;
  final double lat;
  final double lng;
  final double distanceKm;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.avatar,
    required this.rating,
    required this.totalDeliveries,
    this.lat = 6.9147,
    this.lng = 79.8530,
    this.distanceKm = 0.5,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    vehicleType: json['vehicleType'] ?? 'Motorcycle',
    vehiclePlate: json['vehiclePlate'] ?? '',
    avatar: json['avatar'] ?? '',
    rating: (json['rating'] ?? 4.9).toDouble(),
    totalDeliveries: json['totalDeliveries'] ?? 10,
    lat: (json['lat'] as num?)?.toDouble() ?? 6.9147,
    lng: (json['lng'] as num?)?.toDouble() ?? 79.8530,
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.5,
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
        headers: AppConfig.headers({'Authorization': 'Bearer $token'}),
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
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }),
        body: jsonEncode({'driverId': driverId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error assigning driver: $e');
      return false;
    }
  }

  /// Fetches real driving road geometry from OSRM between two geographic points
  static Future<List<LatLng>> fetchRoadRoute(LatLng start, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List?;
          if (coordinates != null && coordinates.isNotEmpty) {
            return coordinates.map((c) {
              final lng = (c[0] as num).toDouble();
              final lat = (c[1] as num).toDouble();
              return LatLng(lat, lng);
            }).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM routing fetch fallback: $e');
    }
    return [start, destination];
  }

  Future<Map<String, dynamic>?> getActiveDeliveryLocation(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/$orderId/location'),
        headers: AppConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['location'] != null) {
          return Map<String, dynamic>.from(data['location']);
        }
      }
    } catch (_) {}
    return null;
  }
}
