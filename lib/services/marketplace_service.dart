import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../models/product_model.dart';
import '../config/app_config.dart';
import '../data/marketplace_data.dart';

class MarketplaceService {
  static String get _baseUrl => AppConfig.baseUrl;

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products')).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded != null && decoded is List && decoded.isNotEmpty) {
          final List<dynamic> data = decoded;
          final targetCat = category.toLowerCase().trim();

          final matching = data.where((p) {
            if (p == null || p is! Map) return false;
            if (targetCat == 'all') return true;
            final pCat = (p['category'] ?? '').toString().toLowerCase().trim();
            return pCat == targetCat || pCat.contains(targetCat) || targetCat.contains(pCat);
          }).toList();

          final List<ProductModel> serverProducts = matching.map((item) {
            DateTime parsedDate = DateTime.now();
            if (item['createdAt'] != null) {
              if (item['createdAt'] is String) {
                parsedDate = DateTime.tryParse(item['createdAt']) ?? DateTime.now();
              } else if (item['createdAt'] is Map) {
                final sec = item['createdAt']['_seconds'] ?? item['createdAt']['seconds'];
                if (sec != null && sec is num) {
                  parsedDate = DateTime.fromMillisecondsSinceEpoch(sec.toInt() * 1000);
                }
              }
            }

            return ProductModel(
              id: item['id']?.toString() ?? item['_id']?.toString() ?? '',
              title: item['title'] ?? 'Plant Listing',
              description: item['description'] ?? '',
              price: (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0,
              category: item['category'] ?? 'indoor',
              imageUrl: item['imageUrl'] ?? '',
              emoji: item['emoji'] ?? '🌿',
              sellerId: item['sellerId']?.toString() ?? '',
              sellerName: item['sellerName'] ?? 'Official Shop',
              sellerLocation: item['sellerLocation'] ?? 'Colombo, Sri Lanka',
              sellerAvatar: item['sellerAvatar'] ?? item['shopImage'] ?? item['avatarUrl'],
              rating: (item['rating'] ?? 0.0) is num ? (item['rating'] as num).toDouble() : 4.8,
              reviewCount: item['reviewCount'] ?? 0,
              stock: item['stock'] ?? 10,
              isAvailable: item['isAvailable'] ?? true,
              tags: item['tags'] is List ? List<String>.from(item['tags']) : [],
              createdAt: parsedDate,
            );
          }).toList();

          if (serverProducts.isNotEmpty) {
            return serverProducts;
          }
        }
      }
    } catch (e) {
      print('Error loading products from server: $e');
    }
    // Fallback if offline or empty server database
    return MarketplaceData.getProductsByCategory(category);
  }

  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    try {
      final allProducts = await getProductsByCategory('all');
      return allProducts.where((p) => p.sellerId == sellerId).toList();
    } catch (e) {
      print('Error loading products by seller: $e');
      return [];
    }
  }

  Future<String?> addProduct(Map<String, dynamic> productData, String token, {Uint8List? imageBytes, String? fileName}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/products'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['title'] = productData['title']?.toString() ?? '';
      request.fields['description'] = productData['description']?.toString() ?? '';
      request.fields['price'] = productData['price']?.toString() ?? '0';
      
      if (productData['originalPrice'] != null) {
        request.fields['originalPrice'] = productData['originalPrice'].toString();
      }
      if (productData['stock'] != null) {
        request.fields['stock'] = productData['stock'].toString();
      }
      
      request.fields['category'] = productData['category']?.toString() ?? '';
      request.fields['emoji'] = productData['emoji']?.toString() ?? '🌿';

      if (imageBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: fileName));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return null; // success
      } else {
        return 'Server returned ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      print('Error adding product: $e');
      return e.toString();
    }
  }

  Future<bool> updateProduct(String productId, Map<String, dynamic> productData, String token, {Uint8List? imageBytes, String? fileName}) async {
    try {
      final request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/products/$productId'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['title'] = productData['title'];
      request.fields['description'] = productData['description'];
      request.fields['price'] = productData['price'].toString();
      request.fields['category'] = productData['category'];
      request.fields['emoji'] = productData['emoji'];

      if (imageBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: fileName));
      }

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  Future<List<ProductModel>> getPopularProducts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products/popular')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded != null && decoded is List && decoded.isNotEmpty) {
          final List<dynamic> data = decoded;
          return data.map((item) {
            if (item == null || item is! Map) return null;
            return ProductModel(
              id: item['id']?.toString() ?? '',
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              price: (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0,
              category: item['category'] ?? '',
              imageUrl: item['imageUrl'] ?? '',
              emoji: item['emoji'] ?? '🌿',
              sellerId: item['sellerId']?.toString() ?? '',
              sellerName: item['sellerName'] ?? 'Official Shop',
              sellerLocation: item['sellerLocation'] ?? '',
              rating: (item['rating'] ?? 0.0) is num ? (item['rating'] as num).toDouble() : 0.0,
              reviewCount: item['reviewCount'] ?? 0,
              stock: item['stock'] ?? 10,
              isAvailable: item['isAvailable'] ?? true,
              tags: item['tags'] is List ? List<String>.from(item['tags']) : [],
              createdAt: DateTime.now(),
              originalPrice: item['originalPrice'] != null && item['originalPrice'] is num
                  ? (item['originalPrice'] as num).toDouble()
                  : null,
              orderCount: item['orderCount'] ?? 0,
            );
          }).whereType<ProductModel>().toList();
        }
      }
    } catch (e) {
      print('Error loading popular products: $e');
    }
    return MarketplaceData.sampleProducts.take(8).toList();
  }

  Future<ProductModel?> getDealOfDay() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/products/deal-of-day')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded != null && decoded is Map) {
          final item = decoded;
          return ProductModel(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? '',
            description: item['description'] ?? '',
            price: (item['price'] ?? 0.0) is num ? (item['price'] as num).toDouble() : 0.0,
            category: item['category'] ?? '',
            imageUrl: item['imageUrl'] ?? '',
            emoji: item['emoji'] ?? '🌿',
            sellerId: item['sellerId']?.toString() ?? '',
            sellerName: item['sellerName'] ?? 'Official Shop',
            sellerLocation: item['sellerLocation'] ?? '',
            rating: (item['rating'] ?? 0.0) is num ? (item['rating'] as num).toDouble() : 0.0,
            reviewCount: item['reviewCount'] ?? 0,
            stock: item['stock'] ?? 10,
            isAvailable: item['isAvailable'] ?? true,
            tags: item['tags'] is List ? List<String>.from(item['tags']) : [],
            createdAt: DateTime.now(),
            originalPrice: item['originalPrice'] != null && item['originalPrice'] is num
                ? (item['originalPrice'] as num).toDouble()
                : null,
            orderCount: 0,
          );
        }
      }
    } catch (e) {
      print('Error loading deal of day: $e');
    }
    return MarketplaceData.sampleProducts.isNotEmpty ? MarketplaceData.sampleProducts.first : null;
  }
}

