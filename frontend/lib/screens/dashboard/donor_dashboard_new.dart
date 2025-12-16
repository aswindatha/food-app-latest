import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/donation.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'add_donation_screen.dart';
import 'chat_screen.dart';
import 'edit_donation_screen.dart';

class DonorDashboardNew extends StatefulWidget {
  const DonorDashboardNew({Key? key}) : super(key: key);

  @override
  State<DonorDashboardNew> createState() => _DonorDashboardNewState();
}

class _DonorDashboardNewState extends State<DonorDashboardNew> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Donation> _donations = [];
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      // Load donations and conversations in parallel
      final donationsFuture = ApiService.getDonorDonations(token);
      final conversationsFuture = ApiService.getUserConversations(token);

      final results = await Future.wait([donationsFuture, conversationsFuture]);

      final donationsResult = results[0];
      final conversationsResult = results[1];

      if (donationsResult['success'] && conversationsResult['success']) {
        setState(() {
          _donations = donationsResult['donations'] as List<Donation>;
          _conversations = conversationsResult['conversations'] as List<Conversation>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = donationsResult['error'] ?? conversationsResult['error'] ?? 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDonation(Donation donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Donation'),
        content: Text('Are you sure you want to delete "${donation.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;
      
      final result = await ApiService.deleteDonation(
        token: token,
        donationId: donation.id,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation deleted successfully')),
        );
        _loadData(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to delete donation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  Future<void> _editDonation(Donation donation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDonationScreen(donation: donation),
      ),
    );

    if (result == true) {
      _loadData(); // Refresh the list
    }
  }

  void _showDonationPreview(Donation donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(donation.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${donation.typeDisplay}'),
              const SizedBox(height: 8),
              Text('Quantity: ${donation.quantity} ${donation.unit}'),
              const SizedBox(height: 8),
              Text('Status: ${donation.statusDisplay}'),
              const SizedBox(height: 8),
              Text('Expiry: ${donation.expiryDate.day}/${donation.expiryDate.month}/${donation.expiryDate.year}'),
              const SizedBox(height: 8),
              Text('Pickup Address: ${donation.pickupAddress}'),
              if (donation.pickupTime != null) ...[
                const SizedBox(height: 8),
                Text('Pickup Time: ${donation.pickupTime!.hour}:${donation.pickupTime!.minute.toString().padLeft(2, '0')}'),
              ],
              if (donation.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Description: ${donation.description}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Welcome, ${user.firstName}!'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppTheme.primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.list), text: 'My Donations'),
                Tab(icon: Icon(Icons.add_circle), text: 'Add Donation'),
                Tab(icon: Icon(Icons.chat), text: 'Chat'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyDonationsTab(),
                const AddDonationScreen(),
                ChatScreen(onRefresh: _loadData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDonationsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_donations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No donations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Donation" to create your first donation',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Group donations by status
    final currentDonations = _donations.where((d) => d.isCurrent).toList();
    final donatedDonations = _donations.where((d) => d.isDonated).toList();
    final expiredDonations = _donations.where((d) => d.isExpired).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (currentDonations.isNotEmpty) ...[
            _buildSectionHeader('Current Donations', Colors.green),
            ...currentDonations.map((donation) => _buildDonationCard(donation)),
          ],
          if (donatedDonations.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Donated Items', Colors.blue),
            ...donatedDonations.map((donation) => _buildDonationCard(donation)),
          ],
          if (expiredDonations.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Expired Items', Colors.red),
            ...expiredDonations.map((donation) => _buildDonationCard(donation)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildDonationCard(Donation donation) {
    final isEditable = donation.isEditable;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDonationPreview(donation),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      donation.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(donation.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      donation.statusDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${donation.typeDisplay} • ${donation.quantity} ${donation.unit}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Expires: ${donation.expiryDate.day}/${donation.expiryDate.month}/${donation.expiryDate.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              if (isEditable) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editDonation(donation),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteDonation(donation),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'current':
        return Colors.green;
      case 'donated':
        return Colors.blue;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
