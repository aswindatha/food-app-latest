import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/donation.dart';
import '../../providers/auth_provider.dart';

import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';
import 'conversation_detail_screen.dart';

class OrganizationDashboard extends StatefulWidget {
  const OrganizationDashboard({super.key});

  @override
  State<OrganizationDashboard> createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Donation> _availableDonations = [];
  List<Donation> _claimedDonations = [];
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
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
        return;
      }

      final results = await Future.wait([
        ApiService.getOrganizationAvailableDonations(token),
        ApiService.getOrganizationClaimedDonations(token),
      ]);

      final availableResult = results[0];
      final claimedResult = results[1];

      if (availableResult['success'] == true && claimedResult['success'] == true) {
        setState(() {
          // Filter out expired donations on client side as extra protection
          _availableDonations = (availableResult['donations'] as List<Donation>)
              .where((donation) => !donation.isExpired)
              .toList();
          _claimedDonations = (claimedResult['donations'] as List<Donation>);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = availableResult['error'] ?? claimedResult['error'] ?? 'Failed to load data';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An unexpected error occurred';
      });
    }
  }

  Future<void> _claimDonation(Donation donation) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Claim Donation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Do you want to claim "${donation.title}"?'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: const Text('Claim'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmed != true) return;

      final result = await ApiService.claimOrganizationDonation(
        token: token,
        donationId: donation.id,
      );

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation claimed successfully')),
        );
        await _loadData();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to claim donation')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
      }
    }
  }

  Future<void> _requestMultipleVolunteers(Donation donation, int volunteerCount) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request Volunteers'),
          content: Text('Do you want to request $volunteerCount volunteer${volunteerCount > 1 ? 's' : ''} for "${donation.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Request'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final result = await ApiService.requestMultipleVolunteers(
        token: token,
        donationId: donation.id,
        volunteerCount: volunteerCount,
        message: 'Volunteers needed for donation: ${donation.title}',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$volunteerCount volunteer request${volunteerCount > 1 ? 's' : ''} sent successfully')),
        );
        Navigator.pop(context);
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to request volunteers')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
      }
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
            Text('Welcome, ${user?.firstName ?? 'Organization'}!'),
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
                Tab(icon: Icon(Icons.list), text: 'Available Donations'),
                Tab(icon: Icon(Icons.inventory), text: 'Claimed Donations'),
                Tab(icon: Icon(Icons.chat), text: 'Chat'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableDonationsTab(),
                _buildClaimedDonationsTab(),
                ChatScreen(onRefresh: _loadData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableDonationsTab() {
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: _availableDonations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No available donations',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableDonations.length,
              itemBuilder: (context, index) {
                final donation = _availableDonations[index];
                return _buildDonationCard(
                  donation,
                  isClaimed: false,
                  onClaim: () => _claimDonation(donation),
                );
              },
            ),
    );
  }

  Widget _buildClaimedDonationsTab() {
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: _claimedDonations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No claimed donations',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _buildClaimedGroupedList(),
    );
  }

  Widget _buildClaimedGroupedList() {
    final transporting = _claimedDonations.where((d) => d.status == 'in_transit').toList();
    final others = _claimedDonations.where((d) => d.status != 'in_transit').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (transporting.isNotEmpty) ...[
          _buildSectionHeader('Currently Transporting', Colors.orange),
          const SizedBox(height: 12),
          ...transporting.map((d) => _buildClaimedDonationCard(d, isTransporting: true)),
          const SizedBox(height: 24),
        ],
        if (others.isNotEmpty) ...[
          _buildSectionHeader('Other Claimed Donations', Colors.green.shade800),
          const SizedBox(height: 12),
          ...others.map((d) => _buildClaimedDonationCard(d, isTransporting: false)),
        ],
      ],
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

  Widget _buildClaimedDonationCard(Donation donation, {required bool isTransporting}) {
    final borderColor = isTransporting ? Colors.orange : Colors.green.shade800;
    final tintColor = isTransporting ? Colors.orange.withOpacity(0.06) : Colors.green.shade900.withOpacity(0.06);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor.withOpacity(0.6), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showClaimedDonationDialog(donation, isTransporting: isTransporting),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: tintColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      donation.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      donation.status,
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
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  void _showClaimedDonationDialog(Donation donation, {required bool isTransporting}) {
    showDialog(
      context: context,
      builder: (context) {
        return VolunteerRequestDialog(
          donation: donation,
          isTransporting: isTransporting,
          onRequestVolunteers: (volunteerCount) => _requestMultipleVolunteers(donation, volunteerCount),
        );
      },
    );
  }

  Widget _buildDonationCard(
    Donation donation, {
    required bool isClaimed,
    VoidCallback? onClaim,
    VoidCallback? onRequestVolunteer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClaimed
                        ? Colors.green.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    donation.typeDisplay,
                    style: TextStyle(
                      color: isClaimed ? Colors.green : AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  donation.quantity.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  donation.unit,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              donation.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              donation.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${donation.expiryDate.day}/${donation.expiryDate.month}/${donation.expiryDate.year}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    donation.pickupAddress,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (!isClaimed && onClaim != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Claim Donation'),
                ),
              ),
            ],
            if (isClaimed && onRequestVolunteer != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onRequestVolunteer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: const Text('Request Volunteer'),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().slideX(begin: 0.1, duration: 300.ms).fadeIn();
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

class VolunteerRequestDialog extends StatefulWidget {
  final Donation donation;
  final bool isTransporting;
  final Function(int) onRequestVolunteers;

  const VolunteerRequestDialog({
    super.key,
    required this.donation,
    required this.isTransporting,
    required this.onRequestVolunteers,
  });

  @override
  State<VolunteerRequestDialog> createState() => _VolunteerRequestDialogState();
}

class _VolunteerRequestDialogState extends State<VolunteerRequestDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.6,
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.donation.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Details'),
                        Tab(text: 'Request Volunteers'),
                        Tab(text: 'Volunteers'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildDetailsTab(context),
                    VolunteerRequestDialogContent(
                      donation: widget.donation,
                      onRequestVolunteers: widget.onRequestVolunteers,
                    ),
                    _buildVolunteersListTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.donation.imageUrl != null && widget.donation.imageUrl!.isNotEmpty)
            Center(
              child: _buildDonationImage(widget.donation.imageUrl),
            ),
          const SizedBox(height: 16),
          _buildDetailRow('Type', widget.donation.typeDisplay),
          _buildDetailRow('Quantity', '${widget.donation.quantity} ${widget.donation.unit}'),
          _buildDetailRow('Expiry', 
            '${widget.donation.expiryDate.day}/${widget.donation.expiryDate.month}/${widget.donation.expiryDate.year}'),
          _buildDetailRow('Pickup Address', widget.donation.pickupAddress),
          _buildDetailRow('Pickup Time', 
            widget.donation.pickupTime != null 
              ? '${widget.donation.pickupTime!.hour}:${widget.donation.pickupTime!.minute.toString().padLeft(2, '0')}'
              : 'Not specified'),
          _buildDetailRow('Status', widget.donation.status),
          const SizedBox(height: 24),
          if (widget.isTransporting)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.donation.volunteerId != null) {
                    // Chat functionality would go here
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Volunteer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVolunteersListTab() {
    final volunteers = widget.donation.volunteerRequests
        ?.where((r) => r.status == 'accepted')
        .map((r) => r.volunteer)
        .toList() ?? [];

    return volunteers.isEmpty
        ? const Center(
            child: Text('No volunteers have accepted yet'),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: volunteers.length,
            itemBuilder: (context, index) {
              final volunteer = volunteers[index];
              if (volunteer == null) return const SizedBox.shrink();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      '${volunteer.firstName[0]}${volunteer.lastName[0]}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('${volunteer.firstName} ${volunteer.lastName}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () => _startVolunteerChat(volunteer),
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            },
          );
  }

  Widget _buildDonationImage(String? imageUrl) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

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

  Widget _buildDetailRow(String label, String value) {
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startVolunteerChat(dynamic volunteer) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      final result = await ApiService.createConversation(
        token: token,
        participant2Id: volunteer.id,
        participant2Type: 'volunteer',
      );

      if (result['success'] == true) {
        if (!mounted) return;
        
        Navigator.pop(context); // Close the dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailScreen(
              conversation: result['conversation'],
              onMessageSent: () {},
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Failed to start chat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred while starting chat')),
        );
      }
    }
  }
}

class VolunteerRequestDialogContent extends StatefulWidget {
  final Donation donation;
  final Function(int) onRequestVolunteers;

  const VolunteerRequestDialogContent({
    super.key,
    required this.donation,
    required this.onRequestVolunteers,
  });

  @override
  State<VolunteerRequestDialogContent> createState() => _VolunteerRequestDialogContentState();
}

class _VolunteerRequestDialogContentState extends State<VolunteerRequestDialogContent> {
  int _volunteerCount = 1;

  void _incrementVolunteerCount() {
    setState(() {
      if (_volunteerCount < 10) {
        _volunteerCount++;
      }
    });
  }

  void _decrementVolunteerCount() {
    setState(() {
      if (_volunteerCount > 1) {
        _volunteerCount--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How many volunteers do you need?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _decrementVolunteerCount,
                icon: const Icon(Icons.remove_circle_outline, size: 32),
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              Text(
                '$_volunteerCount',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _incrementVolunteerCount,
                icon: const Icon(Icons.add_circle_outline, size: 32),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onRequestVolunteers(_volunteerCount),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Request Volunteers',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}