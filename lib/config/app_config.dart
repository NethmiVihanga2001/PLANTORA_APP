import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  // Primary LAN / Wi-Fi IP of host PC
  static const String pcIp = '172.20.10.2';

  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return 'http://$host:3000';
    }
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        return 'http://$pcIp:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  // --- Feature Toggles ---
  static const bool useMockDatabaseOnWeb = false;
}
