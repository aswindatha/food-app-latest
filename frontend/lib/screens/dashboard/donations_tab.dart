import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../models/donation.dart';
import 'donation_detail_screen.dart';

class DonationsTab extends StatefulWidget {
  final List<Donation> donations;
  final VoidCallback? onDonationUpdated;

  const DonationsTab({
    super.key,
    required this.donations,
    this.onDonationUpdated,
  });

  @override
  State<DonationsTab> createState() => _DonationsTabState();
}

class _DonationsTabState extends State<DonationsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _sortField = 'created_at';
  String _sortOrder = 'DESC';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  List<Donation> _filteredDonations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredDonations = List.from(widget.donations);
    _searchController.addListener(_filterDonations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDonations() {
    setState(() {
      _filteredDonations = widget.donations.where((donation) {
        final matchesSearch = _searchController.text.isEmpty ||
            donation.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            donation.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            donation.donationType.toLowerCase().contains(_searchController.text.toLowerCase());

        final matchesStatus = _selectedStatus == 'all' || donation.status == _selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showDonationDialog(Donation donation) {
    final TextEditingController titleController = TextEditingController(text: donation.title);
    final TextEditingController descriptionController = TextEditingController(text: donation.description);
    final TextEditingController typeController = TextEditingController(text: donation.donationType);
    final TextEditingController quantityController = TextEditingController(text: donation.quantity.toString());
    final TextEditingController unitController = TextEditingController(text: donation.unit);
    final TextEditingController expiryDateController = TextEditingController(text: donation.expiryDate.toString().split(' ')[0]);
    final TextEditingController pickupAddressController = TextEditingController(text: donation.pickupAddress);
    final TextEditingController statusController = TextEditingController(text: donation.status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Donation: ${donation.title}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: typeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'FOOD', child: Text('Food')),
                    DropdownMenuItem(value: 'CLOTHES', child: Text('Clothes')),
                    DropdownMenuItem(value: 'MEDICINE', child: Text('Medicine')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    typeController.text = value!;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: expiryDateController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pickupAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: statusController.text,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'available', child: Text('Available')),
                    DropdownMenuItem(value: 'claiming', child: Text('Claiming')),
                    DropdownMenuItem(value: 'in_transit', child: Text('In Transit')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                  ],
                  onChanged: (value) {
                    statusController.text = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final token = authProvider.token;

              if (token != null) {
                final donationData = {
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'donation_type': typeController.text,
                  'quantity': int.tryParse(quantityController.text) ?? donation.quantity,
                  'unit': unitController.text,
                  'expiry_date': expiryDateController.text,
                  'pickup_address': pickupAddressController.text,
                  'status': statusController.text,
                };

                final result = await ApiService.updateDonation(
                  token: token,
                  donationId: donation.id,
                  donationData: donationData,
                );

                if (result['success'] == true) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Donation updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  widget.onDonationUpdated?.call();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['error'] ?? 'Failed to update donation'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDonation(Donation donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Donation'),
        content: Text('Are you sure you want to delete ${donation.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final result = await ApiService.deleteDonation(
          token: token,
          donationId: donation.id,
        );

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Donation deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onDonationUpdated?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete donation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DonationsTab build called. Donations count: ${widget.donations.length}');
    if (widget.donations.isEmpty) {
      return const Center(
        child: Text('No donations available'),
      );
    }
    
    // Simplified version to avoid layout issues
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donation Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text('Total donations: ${widget.donations.length}'),
          const SizedBox(height: 16),
          ...widget.donations.map((donation) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('${donation.title} - ${donation.status}'),
          )).toList(),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'claiming':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.inventory_2;
      case 'claiming':
        return Icons.pending;
      case 'in_transit':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }
}
