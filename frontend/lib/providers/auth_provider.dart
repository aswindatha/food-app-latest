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

  // Login method
  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );

      if (response['success'] == true) {
        _user = await AuthService.getUser();
        _token = response['token'];
        await AuthService.saveToken(response['token']);
        // Schedule notification after build cycle
        Future.microtask(() => notifyListeners());
        return true;
      } else {
        _setError(response['error'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout method
  Future<void> logout() async {
    _setLoading(true);
    try {
      await AuthService.logout();
      _user = null;
      _token = null;
      await AuthService.removeToken();
      // Schedule notification after build cycle
      Future.microtask(() => notifyListeners());
    } catch (e) {
      _setError('Failed to logout');
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
    String? address,
    String? phone,
    String? documentPath,
    double? latitude,
    double? longitude,
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
        address: address,
        phone: phone,
        documentPath: documentPath,
        latitude: latitude,
        longitude: longitude,
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

  // Change password
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result['success']) {
        return {'success': true};
      } else {
        _setError(result['error'] ?? 'Password change failed');
        return {'success': false, 'message': result['error'] ?? 'Password change failed'};
      }
    } catch (e) {
      _setError('Password change failed: $e');
      return {'success': false, 'message': 'Password change failed: $e'};
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
