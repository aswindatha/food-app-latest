import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/donation.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'add_donation_screen.dart';
import 'chat_screen.dart';
import 'edit_donation_screen.dart';
import 'conversation_detail_screen.dart';

class DonorDashboardNew extends StatefulWidget {
  const DonorDashboardNew({super.key});

  @override
  State<DonorDashboardNew> createState() => _DonorDashboardNewState();
}

class _DonorDashboardNewState extends State<DonorDashboardNew> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Donation> _donations = [];
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _error;

  Widget _buildDonationImage(String? imageUrl) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    // If it's a relative URL (starts with /assets), prepend server base URL
    final fullUrl = url.startsWith('/') 
        ? 'http://localhost:5000$url'
        : url;

    final Widget image = (fullUrl.startsWith('http://') || fullUrl.startsWith('https://'))
        ? Image.network(
            fullUrl,
            height: 180,
            width: 300,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          )
        : Image.file(
            File(fullUrl),
            height: 180,
            width: 300,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image,
    );
  }

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
              _buildDonationImage(donation.imageUrl),
              if ((donation.imageUrl ?? '').trim().isNotEmpty) const SizedBox(height: 12),
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

  void _showProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileItem('Username', user.username),
              _buildProfileItem('Email', user.email),
              _buildProfileItem('Phone', user.phone ?? 'Not provided'),
              _buildProfileItem('Address', user.address ?? 'Not provided'),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock),
                  label: const Text('Change Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
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

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    Navigator.pop(context); // Close profile dialog
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm new password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  
                  try {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final result = await authProvider.changePassword(
                      _currentPasswordController.text,
                      _newPasswordController.text,
                    );
                    
                    Navigator.pop(context);
                    
                    if (result['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password changed successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? 'Failed to change password')),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('An error occurred')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Change Password'),
            ),
          ],
        ),
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
            icon: const Icon(Icons.person),
            onPressed: _showProfileDialog,
            tooltip: 'Profile',
          ),
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
    final donatedDonations = _donations.where((d) => d.isDelivered || d.status == 'in_transit').toList();
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
              if (donation.status == 'in_transit') ...[
                const SizedBox(height: 12),
                _buildInTransitButtons(donation),
              ],
         ] ),
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildInTransitButtons(Donation donation) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Chat with Organization button
        if (donation.organization != null)
          ElevatedButton.icon(
            onPressed: () => _startChat(donation.organization!, 'organization'),
            icon: const Icon(Icons.chat, size: 16),
            label: const Text('Chat Org'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        if (donation.organization != null) const SizedBox(width: 8),
        
        // Chat with Volunteer button/dropdown
        if (donation.volunteerRequests != null && donation.volunteerRequests!.isNotEmpty)
          _buildVolunteerChatDropdown(donation)
        else if (donation.volunteer != null)
          ElevatedButton.icon(
            onPressed: () => _startChat(donation.volunteer!, 'volunteer'),
            icon: const Icon(Icons.chat, size: 16),
            label: const Text('Chat Volunteer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: null, // Disabled when no volunteer
            icon: const Icon(Icons.chat, size: 16),
            label: const Text('No Volunteer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white70,
            ),
          ),
      ],
    );
  }

  Widget _buildVolunteerChatDropdown(Donation donation) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        hint: const Text('Chat Volunteer'),
        value: null,
        isExpanded: false,
        underline: const SizedBox(),
        items: donation.volunteerRequests!.map((request) {
          if (request.volunteer != null) {
            return DropdownMenuItem<String>(
              value: request.volunteer!.id.toString(),
              child: Row(
                children: [
                  const Icon(Icons.chat, size: 16),
                  const SizedBox(width: 8),
                  Text('Chat ${request.volunteer!.firstName}'),
                ],
              ),
            );
          }
          return null;
        }).where((item) => item != null).cast<DropdownMenuItem<String>>().toList(),
        onChanged: (value) {
          if (value != null) {
            final volunteerId = int.parse(value);
            final volunteer = donation.volunteerRequests!
                .firstWhere((req) => req.volunteer?.id == volunteerId)
                .volunteer;
            if (volunteer != null) {
              _startChat(volunteer, 'volunteer');
            }
          }
        },
      ),
    );
  }

  Future<void> _startChat(User user, String userType) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      final result = await ApiService.createConversation(
        token: token,
        participant2Id: user.id,
        participant2Type: userType,
      );

      if (result['success']) {
        // Navigate to conversation detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversation: result['conversation'],
              onMessageSent: _loadData,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to start conversation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
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
