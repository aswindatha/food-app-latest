import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/donation.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class EditDonationScreen extends StatefulWidget {
  final Donation donation;

  const EditDonationScreen({Key? key, required this.donation}) : super(key: key);

  @override
  State<EditDonationScreen> createState() => _EditDonationScreenState();
}

class _EditDonationScreenState extends State<EditDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _pickupAddressController;
  
  late String _selectedType;
  late String _selectedUnit;
  late DateTime _expiryDate;
  DateTime? _pickupTime;
  String? _imageUrl;
  bool _isLoading = false;

  final List<String> _donationTypes = ['FOOD', 'CLOTHES', 'MEDICINE', 'OTHER'];
  final List<String> _units = ['kg', 'pieces', 'liters', 'boxes', 'cans', 'items'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.donation.title);
    _descriptionController = TextEditingController(text: widget.donation.description);
    _quantityController = TextEditingController(text: widget.donation.quantity.toString());
    _pickupAddressController = TextEditingController(text: widget.donation.pickupAddress);
    
    _selectedType = widget.donation.donationType;
    _selectedUnit = widget.donation.unit;
    _expiryDate = widget.donation.expiryDate;
    _pickupTime = widget.donation.pickupTime;
    _imageUrl = widget.donation.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _pickupAddressController.dispose();
    super.dispose();
  }

  Future<void> _updateDonation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getToken();
      
      final donationData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'donation_type': _selectedType,
        'quantity': int.parse(_quantityController.text),
        'unit': _selectedUnit,
        'expiry_date': _expiryDate.toIso8601String(),
        'pickup_address': _pickupAddressController.text.trim(),
        'pickup_time': _pickupTime?.toIso8601String(),
        'image_url': _imageUrl,
      };

      final result = await ApiService.updateDonation(
        token: token,
        donationId: widget.donation.id,
        donationData: donationData,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation updated successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to update donation')),
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

  Future<String> _getToken() async {
    // This should come from your auth provider
    // For now, returning a placeholder - replace with actual implementation
    return 'your_token_here';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Donation'),
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
      value: _selectedType,
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
      value: _selectedUnit,
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
        final date = await showDatePicker(
          context: context,
          initialDate: _pickupTime ?? DateTime.now().add(const Duration(hours: 2)),
          firstDate: DateTime.now(),
          lastDate: _expiryDate,
        );
        if (date != null) {
          final timeOfDay = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(date),
          );
          if (timeOfDay != null) {
            setState(() {
              _pickupTime = DateTime(
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
        onPressed: _isLoading ? null : _updateDonation,
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
                'Update Donation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    ).animate().fadeIn().scale();
  }
}
