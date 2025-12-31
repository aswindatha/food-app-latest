import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/donation.dart';
import '../../models/user.dart';
import '../../utils/app_theme.dart';

class DonationDetailScreen extends StatefulWidget {
  final Donation donation;
  final VoidCallback? onDonationUpdated;

  const DonationDetailScreen({
    super.key,
    required this.donation,
    this.onDonationUpdated,
  });

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Determine which tabs to show based on donation status and volunteer
    _tabController = TabController(length: _getTabCount(), vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTabCount() {
    // If donation is claimed by someone other than current admin, show only details
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (widget.donation.volunteer != null && 
        currentUser != null && 
        widget.donation.volunteer!.id != currentUser.id) {
      return 1; // Only details tab
    }
    
    // Show all tabs for available donations or donations claimed by current admin
    return 3; // Details, Volunteer Requests, Volunteers tabs
  }

  bool _shouldShowVolunteerTabs() {
    return _getTabCount() > 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.donation.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: _buildTabs(),
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: _buildTabLabels(),
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
      ),
    );
  }

  List<Widget> _buildTabs() {
    List<Widget> tabs = [_buildDetailsTab()];
    
    if (_shouldShowVolunteerTabs()) {
      tabs.add(_buildVolunteerRequestsTab());
      tabs.add(_buildVolunteersTab());
    }
    
    return tabs;
  }

  List<Tab> _buildTabLabels() {
    List<Tab> tabs = [const Tab(icon: Icon(Icons.info), text: 'Details')];
    
    if (_shouldShowVolunteerTabs()) {
      tabs.add(const Tab(icon: Icon(Icons.request_page), text: 'Requests'));
      tabs.add(const Tab(icon: Icon(Icons.people), text: 'Volunteers'));
    }
    
    return tabs;
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Donation Image
          if (widget.donation.imageUrl != null && widget.donation.imageUrl!.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(
                    widget.donation.imageUrl!.startsWith('/')
                        ? 'http://localhost:5000${widget.donation.imageUrl}'
                        : widget.donation.imageUrl!,
                  ),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) => {},
                ),
              ),
            ),
          
          // Title and Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.donation.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.donation.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.donation.statusDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.donation.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Donation Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Donation Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Type', widget.donation.typeDisplay),
                  _buildDetailRow('Quantity', '${widget.donation.quantity} ${widget.donation.unit}'),
                  _buildDetailRow('Pickup Address', widget.donation.pickupAddress),
                  _buildDetailRow('Expiry Date', widget.donation.expiryDate.toString().split(' ')[0]),
                  if (widget.donation.pickupTime != null)
                    _buildDetailRow('Pickup Time', widget.donation.pickupTime.toString()),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // People Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'People Involved',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.donation.donor != null)
                    _buildPersonRow('Donor', widget.donation.donor!),
                  if (widget.donation.volunteer != null)
                    _buildPersonRow('Volunteer', widget.donation.volunteer!),
                  if (widget.donation.organization != null)
                    _buildPersonRow('Organization', widget.donation.organization!),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Timestamps
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timestamps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Created', widget.donation.createdAt.toString().split('.')[0]),
                  _buildDetailRow('Updated', widget.donation.updatedAt.toString().split('.')[0]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerRequestsTab() {
    final requests = widget.donation.volunteerRequests ?? [];
    
    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_page, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No volunteer requests yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRequestStatusColor(request.status),
              child: Icon(
                _getRequestStatusIcon(request.status),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(request.volunteer?.username ?? 'Unknown Volunteer'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${request.status}'),
                if (request.message != null && request.message!.isNotEmpty)
                  Text('Message: ${request.message!}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                Text('Requested: ${request.createdAt.toString().split('.')[0]}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view_volunteer',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16),
                      SizedBox(width: 8),
                      Text('View Volunteer'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVolunteersTab() {
    // This would show assigned volunteers
    if (widget.donation.volunteer == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No volunteers assigned yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(widget.donation.volunteer!.username),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${widget.donation.volunteer!.email}'),
              Text('Role: ${widget.donation.volunteer!.roleDisplay}'),
              if (widget.donation.volunteer!.phone != null)
                Text('Phone: ${widget.donation.volunteer!.phone}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow(String role, User person) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              person.username[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  person.username,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  person.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
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
      case 'delivered':
        return Colors.purple;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRequestStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
