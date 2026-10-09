import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  double _discountPercentage = 0.0;
  bool _hasFreeDeliveryReward = false;
  String? _activeRewardTitle;

  CartProvider() {
    loadSavedReward();
  }

  List<CartItem> get items => List.unmodifiable(_items);
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  double get discountPercentage => _discountPercentage;
  bool get hasFreeDeliveryReward => _hasFreeDeliveryReward;
  String? get activeRewardTitle => _activeRewardTitle;

  double get discountAmount => (totalPrice * (_discountPercentage / 100.0));
  double get finalSubtotal => (totalPrice - discountAmount).clamp(0.0, double.infinity);

  Future<void> loadSavedReward() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _activeRewardTitle = prefs.getString('active_reward_title');
      _discountPercentage = prefs.getDouble('active_reward_discount_pct') ?? 0.0;
      _hasFreeDeliveryReward = prefs.getBool('active_reward_free_delivery') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> applyReward({
    required String title,
    required double percentage,
    bool freeDelivery = false,
  }) async {
    _activeRewardTitle = title;
    _discountPercentage = percentage;
    _hasFreeDeliveryReward = freeDelivery;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_reward_title', title);
      await prefs.setDouble('active_reward_discount_pct', percentage);
      await prefs.setBool('active_reward_free_delivery', freeDelivery);
    } catch (_) {}
  }

  Future<void> clearReward() async {
    _activeRewardTitle = null;
    _discountPercentage = 0.0;
    _hasFreeDeliveryReward = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_reward_title');
      await prefs.remove('active_reward_discount_pct');
      await prefs.remove('active_reward_free_delivery');
    } catch (_) {}
  }

  void addItem(CartItem item) {
    final idx = _items.indexWhere((i) => i.productId == item.productId);
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      _items[idx].quantity++;
      notifyListeners();
    }
  }

  void decreaseQuantity(String productId) {
    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
      notifyListeners();
    }
  }

  bool isInCart(String productId) {
    return _items.any((i) => i.productId == productId);
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

