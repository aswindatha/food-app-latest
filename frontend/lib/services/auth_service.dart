import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Save authentication data
  static Future<void> saveAuthData(User user, String token) async {
    try {
      // Save token securely
      await _secureStorage.write(key: _tokenKey, value: token);
      
      // Save user data to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      
      print('Auth data saved successfully');
    } catch (e) {
      print('Error saving auth data: $e');
      rethrow;
    }
  }

  // Get stored token
  static Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get stored user data
  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Clear all authentication data
  static Future<void> clearAuthData() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      print('Auth data cleared successfully');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Validate token by fetching current user
  static Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final result = await ApiService.getCurrentUser(token);
      if (result['success'] && result['user'] != null) {
        // Update stored user data
        final user = result['user'] as User;
        await saveAuthData(user, token);
        return true;
      } else {
        // Token is invalid, clear auth data
        await clearAuthData();
        return false;
      }
    } catch (e) {
      print('Error validating token: $e');
      await clearAuthData();
      return false;
    }
  }

  // Register new user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final result = await ApiService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );

      if (result['success'] && result['user'] != null && result['token'] != null) {
        await saveAuthData(result['user'], result['token']);
      }

      return result;
    } catch (e) {
      print('Register service error: $e');
      return {
        'success': false,
        'error': 'Registration service error',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final result = await ApiService.login(
        emailOrUsername: emailOrUsername,
        password: password,
      );

      if (result['success'] && result['user'] != null && result['token'] != null) {
        await saveAuthData(result['user'], result['token']);
      }

      return result;
    } catch (e) {
      print('Login service error: $e');
      return {
        'success': false,
        'error': 'Login service error',
      };
    }
  }

  // Logout user
  static Future<void> logout() async {
    await clearAuthData();
  }
}
