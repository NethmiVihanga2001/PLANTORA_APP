import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../models/plant_model.dart';
import '../config/app_config.dart';

class PlantIdentificationService {
  static String get _baseUrl => AppConfig.baseUrl;

  /// Identify a plant from an image and optional user text.
  /// Refactored to use Uint8List for Web compatibility.
  static Future<Map<String, dynamic>> identifyPlant(Uint8List imageBytes, String fileName, {String? userText}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/ai/identify'));
      
      String safeFileName = fileName;
      if (!safeFileName.toLowerCase().endsWith('.jpg') && 
          !safeFileName.toLowerCase().endsWith('.jpeg') && 
          !safeFileName.toLowerCase().endsWith('.png')) {
        safeFileName += '.jpg';
      }

      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: safeFileName));
      if (userText != null) {
        request.fields['userText'] = userText;
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final decoded = json.decode(responseData);
        final plant = PlantModel(
          id: DateTime.now().toString(),
          name: decoded['commonName'] ?? 'Unknown Plant',
          scientificName: decoded['species'] ?? 'Unknown Species',
          family: 'Botanical',
          category: 'herb',
          description: decoded['description'] ?? decoded['careTips'] ?? '',
          imageUrl: '', 
          emoji: '🌿',
          commonNames: [],
          careInfo: CareInfo(
            wateringFrequency: decoded['watering'] ?? 'Regular watering',
            sunlightRequirement: decoded['sunlight'] ?? 'Full sunlight',
            soilType: decoded['soil'] ?? 'Well-draining soil',
            temperature: '20-30°C',
            humidity: 'Moderate to high',
            fertilizer: 'Monthly organic feeding',
            pruning: 'As needed',
            propagation: 'Cuttings / Seeds',
            growthRate: 'Medium',
            difficulty: 'Easy',
          ),
          diseases: [],
          uses: decoded['uses'] != null ? [decoded['uses'].toString()] : [],
          tags: [],
          confidenceScore: (decoded['confidence'] ?? 0.95).toDouble(),
        );

        return {
          'success': true,
          'plant': plant,
          'confidence': decoded['confidence'],
          'alternatives': <PlantModel>[],
        };
      } else {
        return {'success': false, 'message': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> chatWithPlant(Uint8List? imageBytes, String fileName, List<Map<String, String>> chatHistory, String newMessage) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/ai/chat'));
      
      String safeFileName = fileName;
      if (!safeFileName.toLowerCase().endsWith('.jpg') && 
          !safeFileName.toLowerCase().endsWith('.jpeg') && 
          !safeFileName.toLowerCase().endsWith('.png')) {
        safeFileName += '.jpg';
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: safeFileName));
      }
      request.fields['history'] = json.encode(chatHistory);
      request.fields['message'] = newMessage;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final decoded = json.decode(responseData);
        return {
          'success': true,
          'reply': decoded['reply'] ?? decoded['message'] ?? 'Here is your plant insight.',
        };
      } else {
        return {'success': false, 'message': 'API Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
