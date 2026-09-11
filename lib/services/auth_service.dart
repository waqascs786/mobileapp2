import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _error;

  AuthService({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String? get token => _storageService.getString('auth_token');

  String get userName => _user?['name'] as String? ?? '';
  String get userEmail => _user?['email'] as String? ?? '';
  String get userAvatar => _user?['avatar'] as String? ?? '';
  int get userId => _user?['id'] as int? ?? 0;

  Future<void> autoLogin() async {
    final savedToken = _storageService.getString('auth_token');
    if (savedToken == null || savedToken.isEmpty) {
      _isAuthenticated = false;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final userData = await _apiService.getProfile();
      _user = userData;
      _isAuthenticated = true;

      await _storageService.saveString('user_data', userData.toString());
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      await _storageService.remove('auth_token');
      await _storageService.remove('user_data');
      _log('Auto-login failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _apiService.login(email, password);
      _user = result['user'] as Map<String, dynamic>?;
      _isAuthenticated = true;

      await _storageService.saveString(
        'user_data',
        _user.toString(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _log('Login failed: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _apiService.register(name, email, password);
      _user = result['user'] as Map<String, dynamic>?;
      _isAuthenticated = true;

      await _storageService.saveString(
        'user_data',
        _user.toString(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _log('Registration failed: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;
    _error = null;

    await _storageService.remove('auth_token');
    await _storageService.remove('user_data');

    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (!_isAuthenticated) return;

    try {
      final userData = await _apiService.getProfile();
      _user = userData;
      await _storageService.saveString('user_data', userData.toString());
      notifyListeners();
    } catch (e) {
      _log('Profile refresh failed: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _log(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'AuthService');
    }
  }
}
