import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool _isLoading = false;
  String? _error;

  File? get profileImage => _profileImage;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProfileProvider() {
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_path');
      if (imagePath != null) {
        _profileImage = File(imagePath);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        _isLoading = true;
        _error = null;
        notifyListeners();

        final imageFile = File(photo.path);
        
        // Save image path locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', photo.path);

        // TODO: Upload image to server if needed
        // await _apiService.uploadProfileImage(imageFile);

        _profileImage = imageFile;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        _isLoading = true;
        _error = null;
        notifyListeners();

        final imageFile = File(image.path);
        
        // Save image path locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', image.path);

        // TODO: Upload image to server if needed
        // await _apiService.uploadProfileImage(imageFile);

        _profileImage = imageFile;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeProfileImage() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Remove image path from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_path');

      // TODO: Remove image from server if needed
      // await _apiService.removeProfileImage();

      _profileImage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
} 