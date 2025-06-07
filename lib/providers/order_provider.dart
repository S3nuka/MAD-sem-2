import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load orders
  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ordersData = await _apiService.getOrders();
      _orders = ordersData;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new order
  Future<void> createOrder({
    required List<Map<String, dynamic>> cartItems,
    required String address,
    required String phone,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.placeOrder(
        cartItems: cartItems,
        address: address,
        phone: phone,
        paymentMethod: paymentMethod,
      );
      await loadOrders(); // Reload orders after creation
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update order status
  Future<void> updateOrderStatus(int orderId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateOrder(orderId, {'status': status});
      await loadOrders(); // Reload orders after update
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel order
  Future<void> cancelOrder(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.cancelOrder(orderId);
      await loadOrders(); // Reload orders after cancellation
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get order details
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orderDetails = await _apiService.getOrder(orderId);
      return orderDetails;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin: Update order
  Future<void> updateOrder(int orderId, Map<String, dynamic> orderData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateOrder(orderId, orderData);
      await loadOrders(); // Reload orders after update
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin: Delete order
  Future<void> deleteOrder(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteOrder(orderId);
      await loadOrders(); // Reload orders after deletion
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter orders by status
  List<Map<String, dynamic>> getOrdersByStatus(String status) {
    return _orders.where((order) => order['status'] == status).toList();
  }
} 