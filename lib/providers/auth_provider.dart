import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _userProfile;

  // Instance ApiService untuk komunikasi ke backend
  late ApiService _apiService;

  // Instance CookieRequest dari pbp_django_auth
  final CookieRequest request;

  // Constructor: Menerima request dari main.dart
  AuthProvider(this.request) {
    // Inisialisasi ApiService dengan request yang diberikan
    _apiService = ApiService(request);
    _checkLoginStatus();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfile? get userProfile => _userProfile;

  /// Cek status login saat aplikasi dimulai
  Future<void> _checkLoginStatus() async {
    // CookieRequest menyimpan status login (cookies) secara otomatis.
    // Jika loggedIn bernilai true, kita coba ambil data profil untuk memastikan session valid.
    if (request.loggedIn) {
      try {
        await loadProfile();
        _isAuthenticated = true;
      } catch (e) {
        // Jika gagal ambil profil (misal session expired), anggap belum login
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  /// Fungsi Login
  Future<void> login(String username, String password) async {
    _apiService ??= await ApiService.instance();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Panggil fungsi login dari ApiService
      final response = await _apiService.login(username, password);

      // Cek status dari response JSON Django
      if (response['status'] == true) {
        _isAuthenticated = true;
        // Setelah login sukses, langsung ambil data profil user
        await loadProfile();
        print('[AUTH] Login success: $username');
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
      final response = await _apiService.register(username, password);

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
    _apiService ??= await ApiService.instance();
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
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
    _apiService ??= await ApiService.instance();
    try {
      _userProfile = await _apiService.getProfile();
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
    _apiService ??= await ApiService.instance();
    try {
      _userProfile = await _apiService.updateProfile(profileData);
      notifyListeners();
    } catch (e) {
      print('[AUTH] Failed to update profile: $e');
      throw e;
    }
  }
}
