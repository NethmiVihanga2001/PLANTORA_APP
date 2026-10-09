import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_model.dart';

/// A service to handle local data storage (History and Favorites).
/// Uses SharedPreferences for Web compatibility instead of sqflite.
class DatabaseService {
  static const _historyKey = 'plant_scan_history';
  static const _favoritesKey = 'plant_favorites';

  // --- Scan History ---

  Future<void> saveScan(PlantModel plant, String imagePath, double confidence) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    
    final newEntry = {
      'id': plant.id,
      'name': plant.name,
      'scientificName': plant.scientificName,
      'emoji': plant.emoji,
      'imagePath': imagePath,
      'confidence': confidence,
      'timestamp': DateTime.now().toIso8601String(),
      'plantData': jsonEncode(plant.toMap()),
    };
    
    historyJson.insert(0, jsonEncode(newEntry));
    // Keep only last 50 scans
    if (historyJson.length > 50) historyJson.removeLast();
    
    await prefs.setStringList(_historyKey, historyJson);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    return historyJson.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // --- Favorites ---

  Future<void> toggleFavorite(PlantModel plant) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    
    final index = favoritesJson.indexWhere((item) {
      final data = jsonDecode(item);
      return data['id'] == plant.id;
    });

    if (index != -1) {
      favoritesJson.removeAt(index);
    } else {
      favoritesJson.add(jsonEncode({
        'id': plant.id,
        'plantData': jsonEncode(plant.toMap()),
      }));
    }
    
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }

  Future<bool> isFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson.any((item) => jsonDecode(item)['id'] == id);
  }

  Future<List<PlantModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson.map((item) {
      final decoded = jsonDecode(item);
      return PlantModel.fromMap(jsonDecode(decoded['plantData'] as String));
    }).toList();
  }

  // --- Chat History ---
  static const _chatHistoryKey = 'plantora_chat_history';

  Future<void> saveChatSession(String sessionId, String title, List<Map<String, String>> messages, String? imagePath, Uint8List? imageBytes) async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistoryJson = prefs.getStringList(_chatHistoryKey) ?? [];
    
    // Remove existing session if we are updating it
    chatHistoryJson.removeWhere((item) => jsonDecode(item)['sessionId'] == sessionId);
    
    String? base64Image;
    if (imageBytes != null) {
      base64Image = base64Encode(imageBytes);
    }
    
    final newSession = {
      'sessionId': sessionId,
      'title': title,
      'timestamp': DateTime.now().toIso8601String(),
      'messages': messages,
      'imagePath': imagePath,
      'imageBase64': base64Image,
    };
    
    chatHistoryJson.insert(0, jsonEncode(newSession));
    
    // Keep only last 50 chats to prevent SharedPreferences from getting too bloated
    if (chatHistoryJson.length > 50) chatHistoryJson.removeLast();
    
    await prefs.setStringList(_chatHistoryKey, chatHistoryJson);
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistoryJson = prefs.getStringList(_chatHistoryKey) ?? [];
    return chatHistoryJson.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  Future<void> deleteChatSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistoryJson = prefs.getStringList(_chatHistoryKey) ?? [];
    chatHistoryJson.removeWhere((item) => jsonDecode(item)['sessionId'] == sessionId);
    await prefs.setStringList(_chatHistoryKey, chatHistoryJson);
  }

  Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatHistoryKey);
  }
}
