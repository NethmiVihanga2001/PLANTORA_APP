import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<ProductModel> _items = [];

  List<ProductModel> get items => List.unmodifiable(_items);

  int get count => _items.length;

  bool isFavorite(String productId) => _items.any((p) => p.id == productId);

  void toggle(ProductModel product) {
    final idx = _items.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _items.removeAt(idx);
    } else {
      _items.add(product);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((p) => p.id == productId);
    notifyListeners();
  }
}
