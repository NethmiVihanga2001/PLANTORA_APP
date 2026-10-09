import '../config/app_config.dart';

class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category; // plant, flower, herb, fruit, vegetable, tool, seed
  final String imageUrl;
  final String emoji;
  final String sellerId;
  final String sellerName;
  final String sellerLocation;
  final String? sellerAvatar;
  final double rating;
  final int reviewCount;
  final int stock;
  final bool isAvailable;
  final List<String> tags;
  final DateTime createdAt;
  final double? originalPrice;
  final int orderCount;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.emoji,
    required this.sellerId,
    required this.sellerName,
    required this.sellerLocation,
    this.sellerAvatar,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    required this.isAvailable,
    required this.tags,
    required this.createdAt,
    this.originalPrice,
    this.orderCount = 0,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? 'plant',
      imageUrl: _processImageUrl(map['imageUrl']),
      emoji: map['emoji'] ?? '🌿',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerLocation: map['sellerLocation'] ?? '',
      sellerAvatar: map['sellerAvatar'],
      rating: (map['rating'] ?? 4.5).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      stock: map['stock'] ?? 10,
      isAvailable: map['isAvailable'] ?? true,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is String ? DateTime.parse(map['createdAt']) : DateTime.now())
          : DateTime.now(),
      originalPrice: map['originalPrice'] != null ? (map['originalPrice'] as num).toDouble() : null,
      orderCount: map['orderCount'] ?? 0,
    );
  }

  static String _processImageUrl(dynamic url) {
    if (url == null || url.toString().isEmpty) return '';
    String strUrl = url.toString();
    if (strUrl.startsWith('/')) {
      return '${AppConfig.baseUrl}$strUrl';
    }
    return strUrl;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'emoji': emoji,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerLocation': sellerLocation,
      'sellerAvatar': sellerAvatar,
      'rating': rating,
      'reviewCount': reviewCount,
      'stock': stock,
      'isAvailable': isAvailable,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
