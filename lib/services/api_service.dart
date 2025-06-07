import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart' show rootBundle;

class ApiService {
  // Base URL configuration for different platforms
  static const bool useNgrok = false; // Set to true to use ngrok, false for local

  static String get baseUrl {
    if (useNgrok) {
      return 'https://abcd1234.ngrok.io/api'; // <-- your ngrok URL
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000/api';
    } else {
      return 'http://localhost:8000/api';
    }
  }

  // Cache keys
  static const String _menuCacheKey = 'menu_cache';
  static const String _userCacheKey = 'user_cache';
  static const String _cartCacheKey = 'cart_cache';
  static const String _ordersCacheKey = 'orders_cache';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Access-Control-Allow-Origin': '*',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Cache methods
  Future<void> _saveToCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(data));
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  Future<dynamic> getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      return data != null ? json.decode(data) : null;
    } catch (e) {
      debugPrint('Error reading from cache: $e');
      return null;
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_menuCacheKey);
      await prefs.remove(_userCacheKey);
      await prefs.remove(_cartCacheKey);
      await prefs.remove(_ordersCacheKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Get menu items with offline support
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menu'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        await _saveToCache(_menuCacheKey, data);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to load menu items');
    } catch (e) {
      // Try to get cached data if online request fails
      final cachedData = await getCachedData(_menuCacheKey);
      if (cachedData != null) {
        return (cachedData as List).cast<Map<String, dynamic>>();
      }
      // Try to load from local asset as a last resort
      try {
        final localJson = await rootBundle.loadString('assets/data/menu.json');
        final localData = json.decode(localJson) as List;
        return localData.cast<Map<String, dynamic>>();
      } catch (assetError) {
        throw Exception('Failed to load menu items: $e, and failed to load local asset: $assetError');
      }
    }
  }

  // Get user data with offline support
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        await _saveToCache(_userCacheKey, data);
        return data;
      }
      throw Exception('Failed to load user data');
    } catch (e) {
      // Try to get cached data if online request fails
      final cachedData = await getCachedData(_userCacheKey);
      if (cachedData != null) {
        return cachedData as Map<String, dynamic>;
      }
      throw Exception('Failed to load user data: $e');
    }
  }

  // Get cart items with offline support
  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final items = (decoded['data'] != null && decoded['data']['items'] != null)
            ? List<Map<String, dynamic>>.from(decoded['data']['items'])
            : <Map<String, dynamic>>[];
        await _saveToCache(_cartCacheKey, items);
        return items;
      }
      throw Exception('Failed to load cart items');
    } catch (e) {
      // Try to get cached data if online request fails
      final cachedData = await getCachedData(_cartCacheKey);
      if (cachedData != null) {
        return (cachedData as List).cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to load cart items: $e');
    }
  }

  // Get orders with offline support
  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/orders'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          // Handle paginated response: orders are in decoded['data']['data']
          final ordersData = decoded['data'];
          if (ordersData is Map && ordersData.containsKey('data')) {
            return List<Map<String, dynamic>>.from(ordersData['data']);
          }
          // Fallback if not paginated
          return List<Map<String, dynamic>>.from(ordersData);
        }
        throw Exception(decoded['message'] ?? 'Failed to load orders');
      }
      throw Exception('Failed to load orders');
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // First try online login
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache the successful login data
        await _saveToCache('last_login', {
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return data;
      } else {
        // If online login fails, try offline login
        try {
          final offlineData = await _tryOfflineLogin(email, password);
          if (offlineData != null) {
            return offlineData;
          }
        } catch (offlineError) {
          debugPrint('Offline login failed: $offlineError');
        }
        
        // If both online and offline login fail, throw the original error
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to login: ${response.body}');
      }
    } catch (e) {
      // If network error, try offline login
      try {
        final offlineData = await _tryOfflineLogin(email, password);
        if (offlineData != null) {
          return offlineData;
        }
      } catch (offlineError) {
        debugPrint('Offline login failed: $offlineError');
      }
      rethrow;
    }
  }

  // Offline login support
  Future<Map<String, dynamic>?> _tryOfflineLogin(String email, String password) async {
    try {
      // Load offline users from local JSON
      final localJson = await rootBundle.loadString('assets/data/auth.json');
      final authData = json.decode(localJson) as Map<String, dynamic>;
      final offlineUsers = (authData['offline_users'] as List).cast<Map<String, dynamic>>();

      // Find matching user
      final user = offlineUsers.firstWhere(
        (u) => u['email'] == email,
        orElse: () => throw Exception('User not found'),
      );

      // Verify password
      if (user['password'] != password) {
        throw Exception('Invalid password');
      }

      // Return user data in the same format as the API
      return {
        'user': {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'is_admin': user['is_admin'],
        },
        'token': 'offline_token_${user['id']}', // Generate a temporary offline token
        'is_offline': true,
      };
    } catch (e) {
      debugPrint('Error in offline login: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String passwordConfirmation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to logout: ${response.body}');
    }
  }

  // Product endpoints
  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['data']['data'];
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch products: \\${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch product: ${response.body}');
    }
  }

  // Admin product management
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create product: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }

  // Category endpoints
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch categories: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getCategory(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch category: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryProducts(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$id/products'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch category products: ${response.body}');
    }
  }

  // Admin category management
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create category: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update category: ${response.body}');
    }
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }

  // Cart endpoints
  Future<Map<String, dynamic>> addToCart(int productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add to cart: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateCartItem(int cartItemId, int quantity) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cart/$cartItemId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'quantity': quantity,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update cart item: ${response.body}');
    }
  }

  Future<void> deleteCartItem(int cartItemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/$cartItemId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete cart item: ${response.body}');
    }
  }

  Future<void> clearCart() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to clear cart: ${response.body}');
    }
  }

  // Orders endpoints
  Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> cartItems,
    required String address,
    required String phone,
    required String paymentMethod,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'cart_items': cartItems,
        'shipping_address': address,
        'shipping_phone': phone,
        'payment_method': paymentMethod,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to place order: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getOrder(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch order: ${response.body}');
    }
  }

  Future<void> cancelOrder(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$id/cancel'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel order: ${response.body}');
    }
  }

  // Admin order management
  Future<Map<String, dynamic>> updateOrder(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update order: ${response.body}');
    }
  }

  Future<void> deleteOrder(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/orders/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete order: ${response.body}');
    }
  }

  // Activity logs (admin)
  Future<List<Map<String, dynamic>>> getActivityLogs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/activity-logs'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map && data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to fetch activity logs: ${response.body}');
    }
  }

  // User Management
  Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        // Handle paginated response: users are in data['data']['data']
        final usersData = data['data'];
        if (usersData is Map && usersData.containsKey('data')) {
          return usersData['data'];
        }
        // Fallback if not paginated
        return usersData;
      }
      throw Exception(data['message'] ?? 'Failed to load users');
    }
    throw Exception('Failed to load users');
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required bool isAdmin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'is_admin': isAdmin,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create user: ${response.body}');
    }
  }

  Future<void> updateUser({
    required int userId,
    required String name,
    required String email,
    String? password,
    required bool isAdmin,
  }) async {
    final data = {
      'name': name,
      'email': email,
      'is_admin': isAdmin,
    };
    if (password != null) {
      data['password'] = password;
      data['password_confirmation'] = password;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update user: ${response.body}');
    }
  }

  Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete user: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final uri = Uri.parse('$baseUrl/admin/users/search').replace(
      queryParameters: {'query': query},
    );
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to search users: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/role/$role'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to get users by role: ${response.body}');
  }
} 