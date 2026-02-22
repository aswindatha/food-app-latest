import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/connection_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = 'donor';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedDocument;
  PlatformFile? _selectedFile;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result != null) {
        setState(() {
          _selectedDocument = result.files.single.name;
          // Store the file object for upload during registration
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking document: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<String?> _uploadOrganizationDocument() async {
    if (_selectedFile == null) return null;

    try {
      // Get base URL without /api and construct the correct endpoint
      final baseUrl = ConnectionService.baseUrl.replaceAll('/api', '');
      final uploadUrl = '$baseUrl/api/upload/registration-document';
      
      // Create multipart request for unauthenticated registration upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(uploadUrl),
      );
      
      // Add file
      if (kIsWeb && _selectedFile!.bytes != null) {
        // For web, use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'document',
            _selectedFile!.bytes!,
            filename: _selectedFile!.name,
          ),
        );
      } else if (_selectedFile!.path != null) {
        // For mobile/desktop, use file path
        final file = File(_selectedFile!.path!);
        request.files.add(
          await http.MultipartFile.fromPath(
            'document',
            file.path,
            filename: _selectedFile!.name,
          ),
        );
      }

      print('Uploading document to: $uploadUrl');
      print('File name: ${_selectedFile!.name}');

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('Upload response status: ${response.statusCode}');
      print('Upload response body: $responseBody');

      if (response.statusCode == 201) {
        try {
          final responseData = jsonDecode(responseBody);
          if (responseData['success'] == true) {
            return responseData['documentUrl'] as String;
          } else {
            throw Exception(responseData['message'] ?? 'Upload failed');
          }
        } catch (e) {
          print('Error parsing response: $e');
          print('Response body was: $responseBody');
          throw Exception('Invalid response from server');
        }
      } else {
        print('Upload failed with status: ${response.statusCode}');
        print('Response body: $responseBody');
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading document: $e');
      return null;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location captured successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Validate organization-specific fields
    if (_selectedRole == 'organization') {
      if (_addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your organization address'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      if (_phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your phone number'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a verification document'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please capture your organization location'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    }

    final authProvider = context.read<AuthProvider>();
    
    // For organizations, upload document first
    String? documentPath;
    if (_selectedRole == 'organization' && _selectedFile != null) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading document...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      documentPath = await _uploadOrganizationDocument();
      if (documentPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload document'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    }
    
    final success = await authProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      role: _selectedRole,
      address: _selectedRole == 'organization' ? _addressController.text.trim() : null,
      phone: _selectedRole == 'organization' ? _phoneController.text.trim() : null,
      documentPath: documentPath,
      latitude: _selectedRole == 'organization' ? _latitude : null,
      longitude: _selectedRole == 'organization' ? _longitude : null,
    );

    if (success) {
      final user = authProvider.user;
      print('✅ Registration successful!');
      print('🔍 User role: ${user?.role}');
      print('🔍 Username: ${user?.username}');
      print('🔍 Username starts with #: ${user?.username?.startsWith('#')}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Direct redirect based on role and verification status
      if (user?.role == 'organization' && user?.username?.startsWith('#') == true) {
        print('🔍 Redirecting to verification screen');
        context.go('/organization-verification');
      } else {
        print('🔍 Redirecting to dashboard');
        context.go('/dashboard');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                IconButton(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back),
                ).animate().fadeIn(duration: 300.ms),
                
                const SizedBox(height: 20),
                
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displayLarge,
                ).animate().fadeIn(duration: 400.ms),
                
                const SizedBox(height: 8),
                
                Text(
                  'Join us in making a difference',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ).animate().fadeIn(duration: 500.ms),
                
                const SizedBox(height: 40),
                
                // Name fields
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          hintText: 'John',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ).animate().slideX(begin: -0.2, duration: 600.ms).fadeIn(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          hintText: 'Doe',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ).animate().slideX(begin: 0.2, duration: 600.ms).fadeIn(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'johndoe',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 100.ms).fadeIn(),
                
                const SizedBox(height: 20),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'john@example.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 200.ms).fadeIn(),
                
                const SizedBox(height: 20),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 300.ms).fadeIn(),
                
                const SizedBox(height: 20),
                
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    return null;
                  },
                ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 400.ms).fadeIn(),
                
                const SizedBox(height: 20),
                
                // Role selection with toggle
                Text(
                  'I want to register as:',
                  style: Theme.of(context).textTheme.titleMedium,
                ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 500.ms).fadeIn(),
                
                const SizedBox(height: 12),
                
                // Toggle buttons for role selection
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'donor';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'donor' 
                                  ? AppTheme.primaryColor 
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Donor',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole == 'donor' 
                                    ? Colors.white 
                                    : AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'organization';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'organization' 
                                  ? AppTheme.primaryColor 
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Organization',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedRole == 'organization' 
                                    ? Colors.white 
                                    : AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 600.ms).fadeIn(),
                
                // Organization-specific fields
                if (_selectedRole == 'organization') ...[
                  const SizedBox(height: 20),
                  
                  // Address field
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Organization Address',
                      hintText: 'Enter your organization address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (_selectedRole == 'organization' && (value == null || value.isEmpty)) {
                        return 'Please enter your organization address';
                      }
                      return null;
                    },
                  ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 650.ms).fadeIn(),
                  
                  const SizedBox(height: 20),
                  
                  // Phone field
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (_selectedRole == 'organization' && (value == null || value.isEmpty)) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 700.ms).fadeIn(),
                  
                  const SizedBox(height: 20),
                  
                  // Document upload
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification Document',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_selectedDocument != null) ...[
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.description, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedDocument!,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _selectedDocument = null;
                                          _selectedFile = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                            TextButton.icon(
                              onPressed: _pickDocument,
                              icon: const Icon(Icons.upload_file),
                              label: Text(_selectedDocument == null 
                                  ? 'Upload Document' 
                                  : 'Change Document'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 750.ms).fadeIn(),
                  
                  const SizedBox(height: 20),
                  
                  // Location capture
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organization Location',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_latitude != null && _longitude != null) ...[
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: AppTheme.successColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Location captured: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.successColor),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed: _getCurrentLocation,
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                            TextButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.location_on),
                              label: Text(_latitude == null 
                                  ? 'Capture Location' 
                                  : 'Update Location'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 800.ms).fadeIn(),
                ],
                
                const SizedBox(height: 40),
                
                // Register button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _register,
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 700.ms).fadeIn();
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ).animate().fadeIn(duration: 800.ms, delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
