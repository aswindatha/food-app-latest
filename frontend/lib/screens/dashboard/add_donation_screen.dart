import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

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
  DateTime? _pickupTime;
  String? _imageUrl;
  bool _isLoading = false;

  final List<String> _donationTypes = ['FOOD', 'CLOTHES', 'MEDICINE', 'OTHER'];
  final List<String> _units = ['kg', 'pieces', 'liters', 'boxes', 'cans', 'items'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _pickupAddressController.dispose();
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

      // Upload image first if selected
      String? uploadedImageUrl;
      if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        final imageFile = File(_imageUrl!);
        if (await imageFile.exists()) {
          final uploadResult = await ApiService.uploadImage(
            token: token,
            imageFile: imageFile,
          );
          if (uploadResult['success'] == true) {
            uploadedImageUrl = uploadResult['imageUrl'] as String;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: ${uploadResult['error']}')),
            );
            // Continue without image rather than blocking
          }
        }
      }

      final donationData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'donation_type': _selectedType,
        'quantity': int.parse(_quantityController.text),
        'unit': _selectedUnit,
        'expiry_date': _expiryDate.toIso8601String(),
        'pickup_address': _pickupAddressController.text.trim(),
        'pickup_time': _pickupTime?.toIso8601String(),
        'image_url': uploadedImageUrl,
      };

      final result = await ApiService.createDonation(
        token: token,
        donationData: donationData,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation created successfully!')),
        );
        
        // Clear the form
        _formKey.currentState!.reset();
        setState(() {
          _titleController.clear();
          _descriptionController.clear();
          _quantityController.clear();
          _pickupAddressController.clear();
          _selectedType = 'FOOD';
          _selectedUnit = 'kg';
          _expiryDate = DateTime.now().add(const Duration(hours: 6));
          _pickupTime = null;
          _imageUrl = null;
        });

        // Navigate back to donations tab
        DefaultTabController.of(context).animateTo(0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to create donation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
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
              _buildExpiryDatePicker(),
              const SizedBox(height: 16),
              _buildPickupTimePicker(),
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
                  child: Image.file(
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
          setState(() {
            _expiryDate = date;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Expiry Date *',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}',
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildPickupTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showDatePicker(
          context: context,
          initialDate: _pickupTime ?? DateTime.now().add(const Duration(hours: 2)),
          firstDate: DateTime.now(),
          lastDate: _expiryDate,
        );
        if (time != null) {
          final timeOfDay = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(time),
          );
          if (timeOfDay != null) {
            setState(() {
              _pickupTime = DateTime(
                time.year,
                time.month,
                time.day,
                timeOfDay.hour,
                timeOfDay.minute,
              );
            });
          }
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Preferred Pickup Time',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.schedule),
          hintText: 'Select pickup time (optional)',
        ),
        child: Text(
          _pickupTime != null
              ? '${_pickupTime!.day}/${_pickupTime!.month}/${_pickupTime!.year} ${_pickupTime!.hour}:${_pickupTime!.minute.toString().padLeft(2, '0')}'
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
