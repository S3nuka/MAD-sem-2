import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  String? _token;
  bool _isOfflineMode = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _user?['is_admin'] == true || _user?['is_admin'] == 1;
  String? get token => _token;
  bool get isOfflineMode => _isOfflineMode;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      _token = response['token'] as String;
      _isAuthenticated = true;
      _isOfflineMode = response['is_offline'] == true;

      // Store token and offline status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setBool('is_offline_mode', _isOfflineMode);

      // Get user details
      _user = response['user'] as Map<String, dynamic>;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _token = null;
      _isOfflineMode = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password, String passwordConfirmation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(name, email, password, passwordConfirmation);
      _token = response['token'] as String;
      _isAuthenticated = true;

      // Store token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      // Get user details
      await _getCurrentUser();
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _token = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      // Even if logout fails, clear local data
      debugPrint('Logout error: $e');
    } finally {
      // Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      
      _token = null;
      _user = null;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _getCurrentUser() async {
    try {
      _user = await _apiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _user = null;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _isOfflineMode = prefs.getBool('is_offline_mode') ?? false;

      if (_token != null) {
        _isAuthenticated = true;
        if (!_isOfflineMode) {
          // Only try to get user details from API if not in offline mode
          await _getCurrentUser();
        } else {
          // In offline mode, try to get user from cache
          final cachedUser = await _apiService.getCachedData('user_cache');
          if (cachedUser != null) {
            _user = cachedUser as Map<String, dynamic>;
          }
        }
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 