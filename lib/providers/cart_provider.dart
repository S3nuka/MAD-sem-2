import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity.toDouble()));
  }

  // Load cart items
  Future<void> loadCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cartData = await _apiService.getCartItems();
      _items = cartData.map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add item to cart
  Future<void> addToCart(int productId, int quantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Only check by productId since toppings are not used
      CartItem? existing;
      for (final item in _items) {
        if (item.productId == productId) {
          existing = item;
          break;
        }
      }
      if (existing != null) {
        await updateCartItemQuantity(existing.id, existing.quantity + quantity, localOnly: false);
      } else {
        await _apiService.addToCart(productId, quantity); // Do not send toppings
        await loadCart(); // Reload cart after adding item
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(int cartItemId, int quantity, {bool localOnly = false}) async {
    if (localOnly) {
      final index = _items.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        if (quantity < 1) {
          _items.removeAt(index);
        } else {
          _items[index] = CartItem(
            id: _items[index].id,
            name: _items[index].name,
            description: _items[index].description,
            price: _items[index].price,
            imageUrl: _items[index].imageUrl,
            quantity: quantity,
          );
        }
        notifyListeners();
      }
      return;
    }
    try {
      if (quantity < 1) {
        await _apiService.deleteCartItem(cartItemId);
        // Already removed locally
      } else {
        await _apiService.updateCartItem(cartItemId, quantity);
        // Already updated locally
      }
      // Do NOT call loadCart here
      // Optionally, you could update local state with backend response if needed
      // Just notifyListeners to update UI
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(int cartItemId, {bool localOnly = false}) async {
    if (localOnly) {
      _items.removeWhere((item) => item.id == cartItemId);
      notifyListeners();
      return;
    }
    try {
      await _apiService.deleteCartItem(cartItemId);
      // Already removed locally
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.clearCart();
      _items = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 