import '../services/connection_service.dart';

class ImageUrlHelper {
  static String formatImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }
    
    // If it's already a full URL, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If it's a relative URL, prepend the backend base URL
    final baseUrl = ConnectionService.baseUrl;
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    } else {
      return '$baseUrl/$url';
    }
  }
}
