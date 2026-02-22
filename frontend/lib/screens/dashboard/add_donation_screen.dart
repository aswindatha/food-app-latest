import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../models/donation.dart';

class AddDonationScreen extends StatefulWidget {
  const AddDonationScreen({super.key});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  
  String _selectedType = 'FOOD';
  String _selectedUnit = 'kg';
  DateTime _expiryDate = DateTime.now().add(const Duration(hours: 6));
  DateTime? _cookingTime; // For food items
  String? _imageUrl;
  bool _isLoading = false;

  final List<String> _donationTypes = ['FOOD', 'CLOTHES', 'MEDICINE', 'OTHER'];
  final List<String> _units = ['kg', 'pieces', 'liters', 'boxes', 'cans', 'items'];
  final TextEditingController _customTypeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _pickupAddressController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // For now, we'll just store the local path
        // In a real app, you'd upload this to a server
        setState(() {
          _imageUrl = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      // Simple payload without image upload for now
      final donationData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'donation_type': _selectedType == 'OTHER' ? _customTypeController.text.trim() : _selectedType,
        'quantity': int.parse(_quantityController.text),
        'unit': _selectedUnit,
        'pickup_address': _pickupAddressController.text.trim(),
        'pickup_time': DateTime.now().toIso8601String(),
        'image_url': null,
      };

      // Handle expiry date based on donation type
      if (_selectedType == 'FOOD' && _cookingTime != null) {
        // For food items, expiry_date is cooking_time + 1 hour
        donationData['expiry_date'] = _cookingTime!.add(const Duration(hours: 1)).toIso8601String();
        donationData['cooking_time'] = _cookingTime!.toIso8601String();
      } else {
        // For non-food items, use the editable expiry_date
        donationData['expiry_date'] = _expiryDate.toIso8601String();
      }

      print('🚀 Simple donation payload:');
      print(donationData);

      final result = await ApiService.createDonation(
        token: token,
        donationData: donationData,
      );

      if (result['success']) {
        print('✅ Donation created successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation created successfully!')),
        );
        
        // Navigate back to donations tab
        if (mounted) {
          // Simple navigation to dashboard
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard',
            (route) => false,
          );
        }
      } else {
        print('❌ Donation creation failed!');
        print('Error: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to create donation')),
        );
      }
    } catch (e) {
      print('💥 Simple error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Donation'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Section
              _buildImageSection(),
              const SizedBox(height: 24),
              
              // Basic Information
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              
              // Donation Details
              _buildSectionHeader('Donation Details'),
              const SizedBox(height: 16),
              _buildTypeDropdown(),
              const SizedBox(height: 16),
              if (_selectedType == 'OTHER') ...[
                _buildCustomTypeField(),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(child: _buildQuantityField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUnitDropdown()),
                ],
              ),
              const SizedBox(height: 24),
              
              // Timing Information
              _buildSectionHeader('Timing Information'),
              const SizedBox(height: 16),
              
              // Show cooking time for food items, expiry date picker for others
              if (_selectedType == 'FOOD') ...[
                _buildCookingTimePicker(),
                const SizedBox(height: 16),
              ],
              
              // Show editable expiry date for non-food items
              if (_selectedType != 'FOOD') ...[
                _buildExpiryDatePicker(),
                const SizedBox(height: 16),
              ],
              
              // Show expiry time (non-editable) and remove pickup time picker
              _buildExpiryTimeDisplay(),
              const SizedBox(height: 24),
              
              // Pickup Location
              _buildSectionHeader('Pickup Location'),
              const SizedBox(height: 16),
              _buildPickupAddressField(),
              const SizedBox(height: 32),
              
              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildImageSection() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: _imageUrl != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, _) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(_imageUrl!),
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => setState(() => _imageUrl = null),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
    ).animate().fadeIn().scale();
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title *',
        hintText: 'Enter donation title',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    ).animate().fadeIn().slideX();
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Enter donation description (optional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    ).animate().fadeIn().slideX();
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedType,
      decoration: const InputDecoration(
        labelText: 'Donation Type *',
        border: OutlineInputBorder(),
      ),
      items: _donationTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedType = value!;
          // Reset cooking time when type changes
          if (_selectedType != 'FOOD') {
            _cookingTime = null;
          }
        });
      },
    ).animate().fadeIn().slideX();
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(
        labelText: 'Quantity *',
        hintText: 'Enter quantity',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a quantity';
        }
        final number = int.tryParse(value);
        if (number == null || number <= 0) {
          return 'Please enter a valid quantity';
        }
        return null;
      },
    ).animate().fadeIn().slideX();
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedUnit,
      decoration: const InputDecoration(
        labelText: 'Unit *',
        border: OutlineInputBorder(),
      ),
      items: _units.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(unit),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedUnit = value!;
        });
      },
    ).animate().fadeIn().slideX();
  }

  Widget _buildExpiryTimeDisplay() {
    String expiryDisplay;
    
    if (_selectedType == 'FOOD' && _cookingTime != null) {
      // For food items, expiry is 1 hour after cooking time
      final expiryTime = _cookingTime!.add(const Duration(hours: 1));
      expiryDisplay = '${expiryTime.day}/${expiryTime.month}/${expiryTime.year} ${expiryTime.hour}:${expiryTime.minute.toString().padLeft(2, '0')}';
    } else {
      // For non-food items, show current expiry date
      expiryDisplay = '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedType == 'FOOD' ? 'Expiry Time (1 hour after cooking)' : 'Expiry Date',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            expiryDisplay,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildCookingTimePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _cookingTime ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          final timeOfDay = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(date),
          );
          if (timeOfDay != null) {
            setState(() {
              _cookingTime = DateTime(
                date.year,
                date.month,
                date.day,
                timeOfDay.hour,
                timeOfDay.minute,
              );
              // Auto-update expiry date to 1 hour after cooking time
              _expiryDate = _cookingTime!.add(const Duration(hours: 1));
            });
          }
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Cooking Time *',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.access_time),
          hintText: 'Select cooking time',
        ),
        child: Text(
          _cookingTime != null
              ? '${_cookingTime!.day}/${_cookingTime!.month}/${_cookingTime!.year} ${_cookingTime!.hour}:${_cookingTime!.minute.toString().padLeft(2, '0')}'
              : 'Not specified',
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildPickupAddressField() {
    return TextFormField(
      controller: _pickupAddressController,
      decoration: const InputDecoration(
        labelText: 'Pickup Address *',
        hintText: 'Enter pickup address',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a pickup address';
        }
        return null;
      },
    ).animate().fadeIn().slideX();
  }

  Widget _buildCustomTypeField() {
    return TextFormField(
      controller: _customTypeController,
      decoration: const InputDecoration(
        labelText: 'Custom Type *',
        hintText: 'Enter donation type',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (_selectedType == 'OTHER' && (value == null || value.trim().isEmpty)) {
          return 'Please enter a custom type';
        }
        return null;
      },
    ).animate().fadeIn().slideX();
  }

  Widget _buildExpiryDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _expiryDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          final timeOfDay = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(date),
          );
          if (timeOfDay != null) {
            setState(() {
              _expiryDate = DateTime(
                date.year,
                date.month,
                date.day,
                timeOfDay.hour,
                timeOfDay.minute,
              );
            });
          }
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Expiry Date & Time *',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
          hintText: 'Select expiry date and time',
        ),
        child: Text(
          '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year} ${_expiryDate.hour}:${_expiryDate.minute.toString().padLeft(2, '0')}',
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Create Donation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    ).animate().fadeIn().scale();
  }
}
