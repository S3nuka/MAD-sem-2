import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class MenuProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get products => List.unmodifiable(_products);
  List<Map<String, dynamic>> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load products
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final productsData = await _apiService.getProducts();
      // Ensure price is always a double
      _products = productsData.map<Map<String, dynamic>>((item) {
        final price = item['price'];
        return {
          ...item,
          'price': price is String ? double.tryParse(price) ?? 0.0 : (price is num ? price.toDouble() : 0.0),
        };
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load categories
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final categoriesData = await _apiService.getCategories();
      _categories = categoriesData;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(int categoryId) async {
    try {
      return await _apiService.getCategoryProducts(categoryId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Admin: Create product
  Future<void> createProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createProduct(productData);
      await loadProducts(); // Reload products after creation
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin: Update product
  Future<void> updateProduct(int id, Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateProduct(id, productData);
      await loadProducts(); // Reload products after update
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin: Delete product
  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteProduct(id);
      await loadProducts(); // Reload products after deletion
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin: Create category
  Future<void> createCategory(Map<String, dynamic> categoryData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createCategory(categoryData);
      await loadCategories(); // Reload categories after creation
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin: Update category
  Future<void> updateCategory(int id, Map<String, dynamic> categoryData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateCategory(id, categoryData);
      await loadCategories(); // Reload categories after update
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin: Delete category
  Future<void> deleteCategory(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteCategory(id);
      await loadCategories(); // Reload categories after deletion
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 