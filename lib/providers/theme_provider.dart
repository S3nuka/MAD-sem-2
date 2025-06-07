import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _systemThemeKey = 'use_system_theme';
  bool _isDarkMode = false;
  bool _useSystemTheme = true;
  bool _isLoading = false;
  String? _error;

  bool get isDarkMode => _isDarkMode;
  bool get useSystemTheme => _useSystemTheme;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      _useSystemTheme = prefs.getBool(_systemThemeKey) ?? true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isDarkMode = !_isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      _error = e.toString();
      _isDarkMode = !_isDarkMode; // Revert the change if saving fails
    } finally {
      _isLoading = false;
    notifyListeners();
    }
  }

  Future<void> toggleSystemTheme() async {
    _isLoading = true;
    notifyListeners();
    try {
    _useSystemTheme = !_useSystemTheme;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_systemThemeKey, _useSystemTheme);
    } catch (e) {
      _error = e.toString();
      _useSystemTheme = !_useSystemTheme; // Revert if saving fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(bool isDarkMode) async {
    if (_isDarkMode == isDarkMode) return;

    _isLoading = true;
    notifyListeners();

    try {
      _isDarkMode = isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      _error = e.toString();
      _isDarkMode = !isDarkMode; // Revert the change if saving fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
