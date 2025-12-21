import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _userProfile;

  // Instance CookieRequest dari pbp_django_auth
  final CookieRequest request;

  // Constructor: Menerima request dari main.dart
  AuthProvider(this.request) {
    ApiService.initialize(request);
    _checkLoginStatus();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfile? get userProfile => _userProfile;

  /// Cek status login saat aplikasi dimulai
  /// Cek status login saat aplikasi dimulai
  Future<void> _checkLoginStatus() async {
    try {
      _userProfile = await ApiService.instance.tryGetProfile();
      _isAuthenticated = _userProfile != null;
    } catch (_) {
      _isAuthenticated = false;
      _userProfile = null;
    }
    notifyListeners();
  }

  /// Fungsi Login
  Future<void> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Panggil fungsi login dari ApiService
      final response = await ApiService.instance.login(username, password);

      // Cek status dari response JSON Django
      if (response['status'] == true) {
        // In dummy mode, build a profile from the login payload and skip the extra fetch
        if (DummyDataService.USE_DUMMY_DATA && response['user'] != null) {
          final user = response['user'] as Map<String, dynamic>;
          _userProfile = UserProfile(
            id: user['id'] ?? 0,
            username: user['username'] ?? username,
            displayName: user['display_name'] ?? user['username'] ?? username,
            bio: null,
            city: null,
            country: null,
            avatarUrl: null,
            favoriteDistance: null,
            emergencyContactName: null,
            emergencyContactPhone: null,
            website: null,
            instagramHandle: null,
            stravaProfile: null,
            birthDate: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            history: const [],
            achievements: const [],
            isSuperuser: user['is_superuser'] == true,
            isStaff: user['is_staff'] == true,
          );
          _isAuthenticated = true;
          print('[AUTH] Dummy login success: $username');
        } else {
          _isAuthenticated = true;
          // Setelah login sukses, langsung ambil data profil user
          await loadProfile();
          print('[AUTH] Login success: $username');
        }
      } else {
        _isAuthenticated = false;
        _errorMessage = response['message'] ?? 'Login failed';
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      print('[AUTH] Login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fungsi Register
  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.instance.register(username, password);

      if (response['status'] == true) {
        // Register sukses!
        // Opsional: Bisa langsung login otomatis atau minta user login manual.
        // Di sini kita return true agar UI tahu proses sukses.
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fungsi Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.instance.logout();
    } catch (e) {
      // Abaikan error saat logout (misal koneksi putus), tetap hapus state lokal
      print('[AUTH] Logout warning: $e');
    } finally {
      _isAuthenticated = false;
      _userProfile = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil data profil user dari backend
  Future<void> loadProfile() async {
    // In dummy mode, use the in-memory profile set at login to avoid auto-admin profile.
    if (DummyDataService.USE_DUMMY_DATA) {
      if (_userProfile != null) {
        notifyListeners();
        return;
      }
      _isAuthenticated = false;
      _userProfile = null;
      notifyListeners();
      return;
    }

    try {
      _userProfile = await ApiService.instance.getProfile();
      notifyListeners();
    } catch (e) {
      print('[AUTH] Failed to load profile: $e');
      // Jika error loading profile, kemungkinan session habis
      // Kita set authenticated false agar user diarahkan ke login screen
      _isAuthenticated = false;
      _userProfile = null;
      notifyListeners();
      // Opsional: throw e; jika ingin menangani error di UI
    }
  }

  /// Update profil user
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      _userProfile = await ApiService.instance.updateProfile(profileData);
      notifyListeners();
    } catch (e) {
      print('[AUTH] Failed to update profile: $e');
      throw e;
    }
  }
}
