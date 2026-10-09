// lib/models/cart_item_model.dart

class CartItem {
  final String productId;
  final String title;
  final double price;
  final String imageUrl;
  final String emoji;
  final String sellerId;
  int quantity;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.sellerId,
    this.imageUrl = '',
    this.emoji = '🌿',
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}
