import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

/// Authentication Provider
class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _error;

  // OTP flow state
  String? _phone;
  bool _isNewUser = false;
  String? _registrationToken;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get phone => _phone;
  bool get isNewUser => _isNewUser;

  bool get isMale => _user?.isMale ?? false;
  bool get isFemale => _user?.isFemale ?? false;

  /// Initialize - check if user is logged in
  Future<void> init() async {
    if (_isInitialized) return;
    
    _isLoading = true;

    try {
      final token = await _storage.read(key: AppConfig.tokenKey);
      final userData = await _storage.read(key: AppConfig.userKey);

      if (token != null && userData != null) {
        try {
          _user = User.fromJson(jsonDecode(userData));
          _isLoggedIn = true;
        } catch (e) {
          await _storage.deleteAll();
        }
      }
    } catch (e) {
      // Storage error - ignore on web
      debugPrint('Storage init error: $e');
    }

    _isLoading = false;
    _isInitialized = true;
  }

  /// Send OTP to phone (via Backend API with 2Factor.in)
  Future<bool> sendOtp(String phone) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('Sending OTP to: $phone via backend (2Factor.in)');
      
      final response = await _api.sendOtp(phone);
      
      if (response.success) {
        _phone = phone;
        debugPrint('OTP sent successfully!');
        _setLoading(false);
        return true;
      } else {
        final errorMsg = response.message ?? 'Failed to send OTP';
        _setError(errorMsg);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('Send OTP Exception: $e');
      _setError('Error sending OTP: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Verify OTP entered by user
  Future<bool> verifyOtp(String otp) async {
    if (_phone == null) {
      _setError('Phone number not set');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _api.verifyOtp(phone: _phone!, otp: otp);

      if (response.success) {
        final data = response.data;
        _isNewUser = data['is_new_user'] ?? false;

        if (_isNewUser) {
          // Need to register
          _registrationToken = data['registration_token'];
          _setLoading(false);
          return true;
        } else {
          // Existing user - logged in
          await _handleLogin(data);
          _setLoading(false);
          return true;
        }
      } else {
        _setError(response.message ?? 'Invalid OTP');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      _setError('Verification failed');
      _setLoading(false);
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String userType,
    String? name,
    int? age,
    String? bio,
    File? avatar,
    String? avatarUrl,
    File? voiceVerification,
  }) async {
    if (_registrationToken == null) {
      _setError('Registration token expired');
      return false;
    }

    _setLoading(true);
    _clearError();

    final response = await _api.register(
      registrationToken: _registrationToken!,
      userType: userType,
      name: name,
      age: age,
      bio: bio,
      avatar: avatar,
      avatarUrl: avatarUrl,
      voiceVerification: voiceVerification,
    );

    if (response.success) {
      await _handleLogin(response.data);
      _setLoading(false);
      return true;
    } else {
      _setError(response.message ?? 'Registration failed');
      _setLoading(false);
      return false;
    }
  }

  /// Handle login after OTP verify or register
  Future<void> _handleLogin(Map<String, dynamic> data) async {
    final token = data['token'];
    final userData = data['user'];

    if (token != null) {
      await _api.saveToken(token);
    }

    if (userData != null) {
      _user = User.fromJson(userData);
      await _storage.write(
        key: AppConfig.userKey,
        value: jsonEncode(userData),
      );
      await _storage.write(
        key: AppConfig.userTypeKey,
        value: _user!.userType,
      );
    }

    _isLoggedIn = true;
    _isNewUser = false;
    _registrationToken = null;
    notifyListeners();
  }

  /// Refresh user profile from server
  Future<void> refreshProfile() async {
    final response = await _api.getProfile();

    if (response.success && response.data['user'] != null) {
      _user = User.fromJson(response.data['user']);
      await _storage.write(
        key: AppConfig.userKey,
        value: jsonEncode(response.data['user']),
      );
      notifyListeners();
    }
  }

  /// Update profile
  Future<bool> updateProfile({
    String? name,
    int? age,
    String? bio,
    String? location,
    File? avatar,
  }) async {
    _setLoading(true);
    _clearError();

    final response = await _api.updateProfile(
      name: name,
      age: age,
      bio: bio,
      location: location,
      avatar: avatar,
    );

    if (response.success) {
      if (response.data['user'] != null) {
        _user = User.fromJson(response.data['user']);
        await _storage.write(
          key: AppConfig.userKey,
          value: jsonEncode(response.data['user']),
        );
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setError(response.message ?? 'Update failed');
      _setLoading(false);
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading(true);

    await _api.logout();
    await _storage.deleteAll();

    _user = null;
    _isLoggedIn = false;
    _phone = null;
    _isNewUser = false;
    _registrationToken = null;

    _setLoading(false);
    notifyListeners();
  }

  /// Reset auth flow state
  void resetAuthFlow() {
    _phone = null;
    _isNewUser = false;
    _registrationToken = null;
    _clearError();
    notifyListeners();
  }

  // ========== HELPER METHODS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
