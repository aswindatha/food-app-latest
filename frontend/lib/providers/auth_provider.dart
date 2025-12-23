import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _token;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  bool get isAuthenticated => _user != null;

  // Initialize auth state
  Future<void> initializeAuth() async {
    _setLoading(true);
    try {
      final isValid = await AuthService.validateToken();
      if (isValid) {
        _user = await AuthService.getUser();
        _token = await AuthService.getToken();
        // Schedule notification after build cycle
        Future.microtask(() => notifyListeners());
      }
    } catch (e) {
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }

  // Register user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );

      if (result['success']) {
        _user = result['user'];
        _token = result['token'];
        notifyListeners();
        return true;
      } else {
        _setError(result['error'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );

      if (result['success']) {
        _user = result['user'];
        _token = result['token'];
        notifyListeners();
        return true;
      } else {
        _setError(result['error'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await AuthService.logout();
      _user = null;
      _token = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _clearError();
    Future.microtask(() => notifyListeners());
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    Future.microtask(() => notifyListeners());
  }

  void _setError(String error) {
    _error = error;
    Future.microtask(() => notifyListeners());
  }

  void _clearError() {
    _error = null;
  }
}
