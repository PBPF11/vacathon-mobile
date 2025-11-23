import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/models.dart';

/// Authentication provider
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _userProfile;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfile? get userProfile => _userProfile;

  ApiService? _apiService;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs);
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
      // Try to load profile
      try {
        await loadProfile();
      } catch (e) {
        // Token might be invalid, logout
        await logout();
      }
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Dummy login for testing
      if (username == 'aaa' && password == '123') {
        _isAuthenticated = true;
        _userProfile = UserProfile(
          id: 1,
          username: 'aaa',
          displayName: 'Test Runner',
          bio: 'A passionate runner ready for adventure!',
          city: 'Jakarta',
          country: 'Indonesia',
          avatarUrl: null,
          favoriteDistance: '21K',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          history: [],
          achievements: [],
        );
        _apiService!.setToken('dummy_token');
      } else {
        final response = await _apiService!.login(username, password);
        _isAuthenticated = true;
        await loadProfile();
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService!.logout();
    } catch (e) {
      // Ignore logout errors
      print('Logout error: $e');
    } finally {
      _apiService!.clearToken();
      _isAuthenticated = false;
      _userProfile = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    try {
      _userProfile = await _apiService!.getProfile();
      notifyListeners();
    } catch (e) {
      print('Failed to load profile: $e');
      throw e;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      _userProfile = await _apiService!.updateProfile(profileData);
      notifyListeners();
    } catch (e) {
      print('Failed to update profile: $e');
      throw e;
    }
  }
}