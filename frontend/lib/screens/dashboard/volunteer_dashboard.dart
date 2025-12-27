import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/donation.dart';
import '../../models/volunteer_request.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';
import 'conversation_detail_screen.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          )
        : Image.file(
            File(fullUrl),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image,
    );
  }

  List<VolunteerRequest> _pendingRequests = [];
  List<Donation> _assignedInTransit = [];
  List<Donation> _assignedCompleted = [];

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
      final token = authProvider.token;
      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
        return;
      }

      final results = await Future.wait([
        ApiService.getVolunteerRequests(token: token, status: 'pending'),
        ApiService.getVolunteerAssignedDonations(token: token),
      ]);

      final requestsResult = results[0];
      final assignedResult = results[1];

      if (requestsResult['success'] == true && assignedResult['success'] == true) {
        final requests = (requestsResult['requests'] as List<VolunteerRequest>);
        final assigned = (assignedResult['donations'] as List<Donation>);

        setState(() {
          _pendingRequests = requests;
          _assignedInTransit = assigned.where((d) => d.status == 'in_transit').toList();
          _assignedCompleted = assigned.where((d) => d.status == 'completed').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = requestsResult['error'] ?? assignedResult['error'] ?? 'Failed to load data';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An unexpected error occurred';
      });
    }
  }

  Future<void> _respondToRequest(VolunteerRequest request, String status) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    final result = await ApiService.respondToVolunteerRequest(
      token: token,
      requestId: request.id,
      status: status,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'accepted' ? 'Request accepted' : 'Request rejected')),
      );
      await _loadData();
      if (status == 'accepted') {
        _tabController.animateTo(1);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to respond')),
      );
    }
  }

  Future<void> _chatWithUser({required int userId, required String userType}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    final result = await ApiService.createConversation(
      token: token,
      participant2Id: userId,
      participant2Type: userType,
    );

    if (!mounted) return;

    if (result['success'] == true) {
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
        SnackBar(content: Text(result['error'] ?? 'Failed to start chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('Welcome, ${user?.firstName ?? 'Volunteer'}!'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showProfileDialog(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                _showProfileDialog(context);
              } else if (value == 'logout') {
                authProvider.logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.inbox), text: 'Requests'),
                Tab(icon: Icon(Icons.local_shipping), text: 'Deliveries'),
                Tab(icon: Icon(Icons.chat), text: 'Chat'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildDeliveriesTab(),
                ChatScreen(onRefresh: _loadData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No requests right now',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final req = _pendingRequests[index];
          final donation = req.donation;
          final orgName = req.organization?.fullName ?? 'Organization';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.handshake, color: Colors.white),
              ),
              title: Text(donation?.title ?? 'Donation'),
              subtitle: Text('From: $orgName'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRequestDialog(req),
            ),
          ).animate().fadeIn().slideX();
        },
      ),
    );
  }

  Widget _buildDeliveriesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final current = _assignedInTransit.isNotEmpty ? _assignedInTransit.first : null;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (current != null) ...[
            _buildSectionHeader('Active Delivery', Colors.orange),
            const SizedBox(height: 12),
            _buildActiveDeliveryCard(current),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader('Completed Deliveries', Colors.green.shade800),
          const SizedBox(height: 12),
          if (_assignedCompleted.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'No completed deliveries yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            )
          else
            ..._assignedCompleted.map((d) => _buildCompletedDeliveryCard(d)),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard(Donation donation) {
    final orgId = donation.organizationId;
    final donorId = donation.donorId;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.orange.withOpacity(0.6), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'IN PROGRESS',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${donation.typeDisplay} • ${donation.quantity} ${donation.unit}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              donation.pickupAddress,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: orgId == null
                        ? null
                        : () => _chatWithUser(userId: orgId, userType: 'organization'),
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat Org'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _chatWithUser(userId: donorId, userType: 'donor'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat Donor'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildCompletedDeliveryCard(Donation donation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.green.shade800.withOpacity(0.6), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          donation.title,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900),
        ),
        subtitle: Text('${donation.typeDisplay} • ${donation.quantity} ${donation.unit}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showCompletedDonationDialog(donation),
      ),
    ).animate().fadeIn().slideY();
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(_error ?? 'Something went wrong', style: const TextStyle(fontSize: 16)),
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

  void _showRequestDialog(VolunteerRequest request) {
    final donation = request.donation;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(donation?.title ?? 'Request'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (donation != null) ...[
                _buildDonationImage(donation.imageUrl),
                if ((donation.imageUrl ?? '').trim().isNotEmpty) const SizedBox(height: 12),
                Text('Type: ${donation.typeDisplay}'),
                const SizedBox(height: 8),
                Text('Quantity: ${donation.quantity} ${donation.unit}'),
                const SizedBox(height: 8),
                Text('Pickup Address: ${donation.pickupAddress}'),
                const SizedBox(height: 8),
                if (donation.description.isNotEmpty) Text('Details: ${donation.description}'),
              ] else ...[
                const Text('Donation details not available.'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _respondToRequest(request, 'rejected');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _respondToRequest(request, 'accepted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showCompletedDonationDialog(Donation donation) {
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
              Text('Status: ${donation.status}'),
              const SizedBox(height: 8),
              Text('Pickup Address: ${donation.pickupAddress}'),
              const SizedBox(height: 8),
              Text('Expires: ${donation.expiryDate.day}/${donation.expiryDate.month}/${donation.expiryDate.year}'),
              if (donation.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Details: ${donation.description}'),
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

  void _showProfileDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: AppTheme.primaryColor,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Profile Information
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildProfileInfoRow('Username', user.username),
              _buildProfileInfoRow('Email', user.email),
              if (user.phone != null) 
                _buildProfileInfoRow('Phone', user.phone!),
              _buildProfileInfoRow('Member Since', 
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings coming soon!')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('Settings'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showChangePasswordDialog(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('Change Password'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        authProvider.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryColor),
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (newPasswordController.text != confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Passwords do not match')),
                              );
                              return;
                            }
                            
                            setState(() => isLoading = true);
                            
                            // TODO: Implement password change API call
                            await Future.delayed(const Duration(seconds: 2));
                            
                            setState(() => isLoading = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password changed successfully')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Change Password'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
