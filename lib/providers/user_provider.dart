import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all users
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = List<Map<String, dynamic>>.from(await _apiService.getUsers());
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new user
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createUser(
        name: name,
        email: email,
        password: password,
        isAdmin: role == 'admin',
      );
      await loadUsers(); // Reload users after creating
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user
  Future<void> updateUser({
    required int userId,
    required String name,
    required String email,
    String? password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateUser(
        userId: userId,
        name: name,
        email: email,
        password: password,
        isAdmin: role == 'admin',
      );
      await loadUsers(); // Reload users after updating
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete user
  Future<void> deleteUser(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteUser(userId);
      await loadUsers(); // Reload users after deletion
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search users by query
  Future<void> searchUsers(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final usersData = await _apiService.searchUsers(query);
      _users = usersData;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get users by role
  Future<void> getUsersByRole(String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final usersData = await _apiService.getUsersByRole(role);
      _users = usersData;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 