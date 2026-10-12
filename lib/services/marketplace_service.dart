import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../config/app_config.dart';
import '../data/marketplace_data.dart';
import 'auth_service.dart';

class MarketplaceService {
  static String get _baseUrl => AppConfig.baseUrl;
  final AuthService _authService = AuthService();
  static List<ProductModel> _cachedProducts = [];

  static Future<void> _saveCacheToPrefs(List<ProductModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList('cached_marketplace_products', jsonList);
    } catch (_) {}
  }

  static Future<List<ProductModel>> _loadCacheFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('cached_marketplace_products') ?? [];
      if (jsonList.isNotEmpty) {
        return jsonList.map((str) => ProductModel.fromJson(jsonDecode(str))).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    List<ProductModel> products = [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products'),
        headers: AppConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded != null && decoded is List && decoded.isNotEmpty) {
          final List<dynamic> data = decoded;
          products = data.map((item) => ProductModel.fromJson(item)).toList();
          _cachedProducts = products;
          _saveCacheToPrefs(products);
        }
      }
    } catch (e) {
      print('MarketplaceService getProductsByCategory network failed/skipped: $e');
    }

    if (products.isEmpty) {
      if (_cachedProducts.isNotEmpty) {
        products = List<ProductModel>.from(_cachedProducts);
      } else {
        final offlineSaved = await _loadCacheFromPrefs();
        if (offlineSaved.isNotEmpty) {
          products = offlineSaved;
          _cachedProducts = offlineSaved;
        } else {
          products = MarketplaceData.getProductsByCategory('all');
        }
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getStringList('local_seller_products') ?? [];
      final deletedIds = prefs.getStringList('deleted_product_ids') ?? [];

      for (final jsonStr in localJson) {
        try {
          final pMap = jsonDecode(jsonStr);
          final pModel = ProductModel.fromJson(pMap);
          final existingIdx = products.indexWhere((existing) => existing.id == pModel.id);
          if (existingIdx != -1) {
            products[existingIdx] = pModel;
          } else {
            products.insert(0, pModel);
          }
        } catch (_) {}
      }

      products.removeWhere((p) => deletedIds.contains(p.id));
    } catch (_) {}

    final targetCat = category.toLowerCase().trim();
    if (targetCat == 'all') return products;

    return products.where((p) {
      final pCat = p.category.toLowerCase().trim();
      if (pCat == targetCat) return true;
      if (p.tags.any((t) => t.toLowerCase().trim() == targetCat)) return true;

      final title = p.title.toLowerCase();
      final desc = p.description.toLowerCase();

      if (targetCat == 'herbal') {
        return pCat.contains('herb') ||
            p.tags.any((t) => t.contains('herb')) ||
            title.contains('karapincha') ||
            title.contains('turmeric') ||
            title.contains('turemeric') ||
            title.contains('kaha') ||
            title.contains('kahabiliya') ||
            title.contains('pol pala') ||
            title.contains('curry') ||
            title.contains('gotu kola') ||
            title.contains('aloe') ||
            desc.contains('herbal') ||
            desc.contains('leaf');
      }
      if (targetCat == 'medicinal') {
        return pCat.contains('med') ||
            p.tags.any((t) => t.contains('med')) ||
            title.contains('karapincha') ||
            title.contains('turmeric') ||
            title.contains('turemeric') ||
            title.contains('kaha') ||
            title.contains('kahabiliya') ||
            title.contains('pol pala') ||
            title.contains('neem') ||
            title.contains('aloe') ||
            title.contains('komarika') ||
            desc.contains('medicinal');
      }
      if (targetCat == 'culinary') {
        return pCat.contains('culin') ||
            p.tags.any((t) => t.contains('culin')) ||
            title.contains('karapincha') ||
            title.contains('curry') ||
            title.contains('turmeric') ||
            title.contains('turemeric') ||
            title.contains('chilli') ||
            title.contains('miris');
      }
      if (targetCat == 'outdoor') {
        return pCat.contains('outdoor') || p.tags.any((t) => t.contains('outdoor'));
      }
      if (targetCat == 'indoor') {
        return pCat.contains('indoor') || p.tags.any((t) => t.contains('indoor'));
      }
      if (targetCat == 'rare') {
        return pCat.contains('rare') || p.tags.any((t) => t.contains('rare'));
      }
      if (targetCat == 'aromatic') {
        return pCat.contains('aromatic') || p.tags.any((t) => t.contains('aromatic'));
      }
      if (targetCat == 'tea') {
        return pCat.contains('tea') || p.tags.any((t) => t.contains('tea'));
      }
      if (targetCat == 'seed') {
        return pCat.contains('seed') || p.tags.any((t) => t.contains('seed'));
      }
      if (targetCat == 'tool') {
        return pCat.contains('tool') || p.tags.any((t) => t.contains('tool'));
      }
      return false;
    }).toList();
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
    String? createdId;
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/products'));
      request.headers.addAll(AppConfig.defaultHeaders);
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

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        createdId = data['id'] ?? data['_id'];
      }
    } catch (e) {
      print('Error adding product online: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getStringList('local_seller_products') ?? [];
      final id = createdId ?? 'prod_local_${DateTime.now().millisecondsSinceEpoch}';
      
      final authUser = await _authService.getCurrentUser();
      final sId = (productData['sellerId'] != null && (productData['sellerId'] as String).isNotEmpty)
          ? productData['sellerId']
          : (authUser?.id ?? 's_demo');
      final sName = (productData['sellerName'] != null && (productData['sellerName'] as String).isNotEmpty)
          ? productData['sellerName']
          : (authUser?.businessName ?? authUser?.name ?? 'My Green Shop');
      final sLoc = (productData['sellerLocation'] != null && (productData['sellerLocation'] as String).isNotEmpty)
          ? productData['sellerLocation']
          : (authUser?.location ?? 'Colombo, Sri Lanka');

      String img = productData['imageUrl'] ?? '';
      if (imageBytes != null) {
        img = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
      }

      final newProduct = {
        'id': id,
        'title': productData['title'] ?? 'New Plant',
        'description': productData['description'] ?? '',
        'price': (productData['price'] ?? 0.0) is num ? (productData['price'] as num).toDouble() : 0.0,
        'originalPrice': productData['originalPrice'] != null ? (productData['originalPrice'] as num).toDouble() : null,
        'category': productData['category'] ?? 'indoor',
        'imageUrl': img,
        'emoji': productData['emoji'] ?? '🌿',
        'sellerId': sId,
        'sellerName': sName,
        'sellerLocation': sLoc,
        'rating': 5.0,
        'reviewCount': 1,
        'stock': productData['stock'] ?? 10,
        'isAvailable': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      localJson.insert(0, jsonEncode(newProduct));
      await prefs.setStringList('local_seller_products', localJson);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> updateProduct(String productId, Map<String, dynamic> productData, String token, {Uint8List? imageBytes, String? fileName}) async {
    try {
      final request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/products/$productId'));
      request.headers.addAll(AppConfig.defaultHeaders);
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['title'] = productData['title'] ?? '';
      request.fields['description'] = productData['description'] ?? '';
      request.fields['price'] = (productData['price'] ?? 0).toString();
      request.fields['category'] = productData['category'] ?? '';
      request.fields['emoji'] = productData['emoji'] ?? '🌿';

      if (imageBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: fileName));
      }

      await request.send().timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Error updating product online: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getStringList('local_seller_products') ?? [];
      final updatedList = localJson.map((jsonStr) {
        try {
          final map = jsonDecode(jsonStr);
          if (map['id'] == productId) {
            if (productData['title'] != null) map['title'] = productData['title'];
            if (productData['description'] != null) map['description'] = productData['description'];
            if (productData['price'] != null) map['price'] = (productData['price'] as num).toDouble();
            if (productData['category'] != null) map['category'] = productData['category'];
            if (imageBytes != null) map['imageUrl'] = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
          }
          return jsonEncode(map);
        } catch (_) {
          return jsonStr;
        }
      }).toList();
      await prefs.setStringList('local_seller_products', updatedList);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(String productId, String token) async {
    try {
      await http.delete(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: AppConfig.headers({
          'Authorization': 'Bearer $token',
        }),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Error deleting product online: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getStringList('local_seller_products') ?? [];
      final updatedLocal = localJson.where((str) {
        try {
          final map = jsonDecode(str);
          return map['id'] != productId;
        } catch (_) {
          return true;
        }
      }).toList();
      await prefs.setStringList('local_seller_products', updatedLocal);

      final deletedIds = prefs.getStringList('deleted_product_ids') ?? [];
      if (!deletedIds.contains(productId)) {
        deletedIds.add(productId);
        await prefs.setStringList('deleted_product_ids', deletedIds);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStock(String productId, int newStock, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/products/$productId/stock'),
        headers: AppConfig.headers({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }),
        body: jsonEncode({'stock': newStock}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error updating product stock online: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getStringList('local_seller_products') ?? [];
      final updatedLocal = localJson.map((str) {
        try {
          final map = jsonDecode(str);
          if (map['id'] == productId) {
            map['stock'] = newStock;
            map['isAvailable'] = newStock > 0;
          }
          return jsonEncode(map);
        } catch (_) {
          return str;
        }
      }).toList();
      await prefs.setStringList('local_seller_products', updatedLocal);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ProductModel>> getPopularProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/popular'),
        headers: AppConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 15));
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
      final response = await http.get(
        Uri.parse('$_baseUrl/products/deal-of-day'),
        headers: AppConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 15));
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
