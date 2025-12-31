import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectionService {
  static const String _baseUrlKey = 'backend_base_url';
  static String _baseUrl = 'http://localhost:5000/api';
  
  static String get baseUrl => _baseUrl;
  
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
      debugPrint('Loaded backend URL: $_baseUrl');
    }
  }
  
  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
    _baseUrl = url;
    debugPrint('Saved backend URL: $_baseUrl');
  }
  
  static Future<ConnectionTestResult> testConnection(String url) async {
    try {
      final testUrl = url.endsWith('/api') ? url : '$url/api';
      final response = await http.get(
        Uri.parse('$testUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return ConnectionTestResult(
          success: true,
          message: 'Connection successful!',
          details: 'Server is running and responding',
        );
      } else {
        return ConnectionTestResult(
          success: false,
          message: 'Server responded with error',
          details: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        message: 'Connection failed',
        details: e.toString(),
      );
    }
  }
  
  static String formatUrl(String url) {
    if (url.isEmpty) return '';
    
    // Remove trailing slash
    url = url.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    // Add http:// if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    
    // Add /api if missing
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    
    return url;
  }
}

class ConnectionTestResult {
  final bool success;
  final String message;
  final String details;
  
  ConnectionTestResult({
    required this.success,
    required this.message,
    required this.details,
  });
}
