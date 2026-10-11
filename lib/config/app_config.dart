import 'package:flutter/foundation.dart';

class AppConfig {
  // Public Cloud / Tunnel URL (Accessible worldwide on ANY phone, ANY network, Wi-Fi or Mobile Data)
  static const String publicBaseUrl = 'https://spiritualistically-transcendental-ted.ngrok-free.dev';
  
  // Local host Wi-Fi IP fallback
  static const String pcIp = '172.20.10.2';
  static String? _resolvedBaseUrl;

  static String get baseUrl {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return 'http://$host:3000';
    }
    // Default to the public cloud URL so all phones (user, friends, examiners) connect to the same server and shared database
    return publicBaseUrl;
  }

  static void setBaseUrl(String url) {
    _resolvedBaseUrl = url;
  }

  static const Map<String, String> defaultHeaders = {
    'ngrok-skip-browser-warning': '1',
    'User-Agent': 'PlantoraMobile/1.0',
  };

  static Map<String, String> headers([Map<String, String>? extra]) {
    final map = <String, String>{
      'ngrok-skip-browser-warning': '1',
      'User-Agent': 'PlantoraMobile/1.0',
    };
    if (extra != null) {
      map.addAll(extra);
    }
    return map;
  }

  // --- Feature Toggles ---
  static const bool useMockDatabaseOnWeb = false;
}
