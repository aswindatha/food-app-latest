import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/donation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/volunteer_request.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  
  // Headers for API requests
  static Map<String, String> _getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Register user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        }),
      );

      debugPrint('Register response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data),
          'token': data['token'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      debugPrint('Register error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'emailOrUsername': emailOrUsername,
          'password': password,
        }),
      );

      debugPrint('Login response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data),
          'token': data['token'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Get current user
  static Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(token: token),
      );

      debugPrint('Get current user response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to get user data',
        };
      }
    } catch (e) {
      debugPrint('Get current user error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // ========== UPLOAD APIS ==========

  // Upload an image file and return the URL
  static Future<Map<String, dynamic>> uploadImage({
    required String token,
    required File imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/image'),
      );
      
      // Add auth token
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add image file
      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Upload image response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'imageUrl': data['imageUrl'],
          'filename': data['filename'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to upload image',
        };
      }
    } catch (e) {
      debugPrint('Upload image error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // ========== DONATION APIS ==========

  // Create a new donation
  static Future<Map<String, dynamic>> createDonation({
    required String token,
    required Map<String, dynamic> donationData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/donations'),
        headers: _getHeaders(token: token),
        body: jsonEncode(donationData),
      );

      debugPrint('Create donation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        try {
          return {
            'success': true,
            'donation': Donation.fromJson(data),
          };
        } catch (e) {
          debugPrint('Error parsing donation: $e');
          debugPrint('Response data: $data');
          return {
            'success': false,
            'error': 'Failed to parse donation response: $e',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to create donation',
        };
      }
    } catch (e) {
      debugPrint('Create donation error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Get donor's donations
  static Future<Map<String, dynamic>> getDonorDonations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/donations/my-donations'),
        headers: _getHeaders(token: token),
      );

      debugPrint('Get donor donations response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final donations = <Donation>[];
        
        for (final item in data) {
          try {
            donations.add(Donation.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing donation item: $e');
            debugPrint('Donation data: $item');
            // Continue with other items even if one fails
          }
        }
        
        debugPrint('Successfully parsed ${donations.length} out of ${data.length} donations');
        
        return {
          'success': true,
          'donations': donations,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to get donations',
        };
      }
    } catch (e) {
      debugPrint('Get donor donations error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Update a donation
  static Future<Map<String, dynamic>> updateDonation({
    required String token,
    required int donationId,
    required Map<String, dynamic> donationData,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/donations/$donationId'),
        headers: _getHeaders(token: token),
        body: jsonEncode(donationData),
      );

      debugPrint('Update donation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'donation': Donation.fromJson(data),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to update donation',
        };
      }
    } catch (e) {
      debugPrint('Update donation error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Delete a donation
  static Future<Map<String, dynamic>> deleteDonation({
    required String token,
    required int donationId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/donations/$donationId'),
        headers: _getHeaders(token: token),
      );

      debugPrint('Delete donation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Donation deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to delete donation',
        };
      }
    } catch (e) {
      debugPrint('Delete donation error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // ========== ORGANIZATION DONATION APIS ==========

  static Future<Map<String, dynamic>> getOrganizationAvailableDonations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/organization/donations/available'),
        headers: _getHeaders(token: token),
      );

      debugPrint('Get organization available donations response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final donations = <Donation>[];

        for (final item in data) {
          try {
            donations.add(Donation.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing donation item: $e');
            debugPrint('Donation data: $item');
          }
        }

        return {
          'success': true,
          'donations': donations,
        };
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to get available donations',
      };
    } catch (e) {
      debugPrint('Get organization available donations error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> getOrganizationClaimedDonations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/organization/donations/claimed'),
        headers: _getHeaders(token: token),
      );

      debugPrint('Get organization claimed donations response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final donations = <Donation>[];

        for (final item in data) {
          try {
            donations.add(Donation.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing donation item: $e');
            debugPrint('Donation data: $item');
          }
        }

        return {
          'success': true,
          'donations': donations,
        };
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to get claimed donations',
      };
    } catch (e) {
      debugPrint('Get organization claimed donations error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> claimOrganizationDonation({
    required String token,
    required int donationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/organization/donations/$donationId/claim'),
        headers: _getHeaders(token: token),
      );

      debugPrint('Claim organization donation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final donationJson = data['donation'];
        return {
          'success': true,
          'donation': donationJson != null ? Donation.fromJson(donationJson) : null,
          'conversation': data['conversation'],
        };
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to claim donation',
      };
    } catch (e) {
      debugPrint('Claim organization donation error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> requestVolunteerForDonation({
    required String token,
    required int donationId,
    required int volunteerId,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/organization/donations/$donationId/request-volunteer'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'volunteer_id': volunteerId,
          if (message != null) 'message': message,
        }),
      );

      debugPrint('Request volunteer response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'request': data['request'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to request volunteer',
        };
      }
    } catch (e) {
      debugPrint('Request volunteer error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> requestMultipleVolunteers({
    required String token,
    required int donationId,
    required int volunteerCount,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/organization/donations/$donationId/request-multiple-volunteers'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'volunteerCount': volunteerCount,
          if (message != null) 'message': message,
        }),
      );

      debugPrint('Request multiple volunteers response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final requests = <VolunteerRequest>[];

        if (data['requests'] != null) {
          for (final item in data['requests']) {
            try {
              requests.add(VolunteerRequest.fromJson(item));
            } catch (e) {
              debugPrint('Error parsing volunteer request item: $e');
            }
          }
        }

        return {
          'success': true,
          'requests': requests,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to request volunteers',
        };
      }
    } catch (e) {
      debugPrint('Request multiple volunteers error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> updateOrganizationDonationStatus({
    required String token,
    required int donationId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/organization/donations/$donationId/status'),
        headers: _getHeaders(token: token),
        body: jsonEncode({'status': status}),
      );

      debugPrint('Update organization donation status response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final donationJson = data['donation'];
        return {
          'success': true,
          'donation': donationJson != null ? Donation.fromJson(donationJson) : null,
        };
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to update donation status',
      };
    } catch (e) {
      debugPrint('Update organization donation status error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // ========== VOLUNTEER APIS ==========

  static Future<Map<String, dynamic>> getVolunteerRequests({
    required String token,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/volunteer/requests';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token: token),
      );

      debugPrint('Get volunteer requests response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final requests = <VolunteerRequest>[];

        for (final item in data) {
          try {
            requests.add(VolunteerRequest.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing volunteer request item: $e');
            debugPrint('Volunteer request data: $item');
          }
        }

        return {
          'success': true,
          'requests': requests,
        };
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to get volunteer requests',
      };
    } catch (e) {
      debugPrint('Get volunteer requests error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> respondToVolunteerRequest({
    required String token,
    required int requestId,
    required String status,
    String? message,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/volunteer/requests/$requestId/respond'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'status': status,
          if (message != null) 'message': message,
        }),
      );

      debugPrint('Respond to volunteer request response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'request': data['request'] != null ? VolunteerRequest.fromJson(data['request']) : null,
        };
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to respond to request',
      };
    } catch (e) {
      debugPrint('Respond to volunteer request error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> getVolunteerAssignedDonations({
    required String token,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/volunteer/donations/assigned';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token: token),
      );

      debugPrint('Get volunteer assigned donations response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final donations = <Donation>[];

        for (final item in data) {
          try {
            donations.add(Donation.fromJson(item));
          } catch (e) {
            debugPrint('Error parsing assigned donation item: $e');
            debugPrint('Assigned donation data: $item');
          }
        }

        return {
          'success': true,
          'donations': donations,
        };
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to get assigned donations',
      };
    } catch (e) {
      debugPrint('Get volunteer assigned donations error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> volunteerUpdateDonationStatus({
    required String token,
    required int donationId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/volunteer/donations/$donationId/status'),
        headers: _getHeaders(token: token),
        body: jsonEncode({'status': status}),
      );

      debugPrint('Volunteer update donation status response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'donation': data['donation'] != null ? Donation.fromJson(data['donation']) : null,
        };
      }

      final errorData = jsonDecode(response.body);
      return {
        'success': false,
        'error': errorData['message'] ?? 'Failed to update donation status',
      };
    } catch (e) {
      debugPrint('Volunteer update donation status error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // ========== CONVERSATION APIS ==========

  // Get user conversations
  static Future<Map<String, dynamic>> getUserConversations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations'),
        headers: _getHeaders(token: token),
      );

      debugPrint('Get conversations response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final conversations = data.map((item) => Conversation.fromJson(item)).toList();
        return {
          'success': true,
          'conversations': conversations,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to get conversations',
        };
      }
    } catch (e) {
      debugPrint('Get conversations error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Get conversation details with messages
  static Future<Map<String, dynamic>> getConversationById({
    required String token,
    required int conversationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId'),
        headers: _getHeaders(token: token),
      );

      debugPrint('Get conversation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversation = Conversation.fromJson(data['conversation']);
        final messages = (data['messages'] as List)
            .map((item) => Message.fromJson(item))
            .toList();
        return {
          'success': true,
          'conversation': conversation,
          'messages': messages,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to get conversation',
        };
      }
    } catch (e) {
      debugPrint('Get conversation error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Create a new conversation
  static Future<Map<String, dynamic>> createConversation({
    required String token,
    required int participant2Id,
    required String participant2Type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'participant2_id': participant2Id,
          'participant2_type': participant2Type,
        }),
      );

      debugPrint('Create conversation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'conversation': Conversation.fromJson(data),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to create conversation',
        };
      }
    } catch (e) {
      debugPrint('Create conversation error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Send a message
  static Future<Map<String, dynamic>> sendMessage({
    required String token,
    required int conversationId,
    required String messageText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$conversationId/messages'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          'message_text': messageText,
        }),
      );

      debugPrint('Send message response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': Message.fromJson(data),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      debugPrint('Send message error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Get available users for conversations
  static Future<Map<String, dynamic>> getAvailableUsers({
    required String token,
    String? role,
  }) async {
    try {
      String url = '$baseUrl/conversations/available-users';
      if (role != null) {
        url += '?role=$role';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(token: token),
      );

      debugPrint('Get available users response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final users = data.map((item) => User.fromJson(item)).toList();
        return {
          'success': true,
          'users': users,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to get available users',
        };
      }
    } catch (e) {
      debugPrint('Get available users error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }
}
