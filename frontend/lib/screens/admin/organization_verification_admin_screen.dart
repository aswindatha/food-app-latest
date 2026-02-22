import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class OrganizationVerificationAdminScreen extends StatefulWidget {
  const OrganizationVerificationAdminScreen({super.key});

  @override
  State<OrganizationVerificationAdminScreen> createState() => _OrganizationVerificationAdminScreenState();
}

class _OrganizationVerificationAdminScreenState extends State<OrganizationVerificationAdminScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _pendingOrganizations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingOrganizations();
  }

  Future<void> _loadPendingOrganizations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual API call when backend is ready
      // For now, using mock data
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _pendingOrganizations = [
          {
            'id': 1,
            'username': '#john_doe',
            'email': 'john@charity.org',
            'organizationName': 'Helping Hands Charity',
            'description': 'A non-profit organization focused on helping local communities with food distribution and educational programs.',
            'phone': '+1 (555) 123-4567',
            'address': '123 Main St, Anytown, USA',
            'documentUrl': 'https://example.com/docs/charity-docs.pdf',
            'submittedAt': '2026-02-22T10:30:00Z',
            'status': 'pending'
          },
          {
            'id': 2,
            'username': '#jane_smith',
            'email': 'jane@community.org',
            'organizationName': 'Community Food Bank',
            'description': 'Local food bank serving families in need with emergency food supplies and weekly distributions.',
            'phone': '+1 (555) 987-6543',
            'address': '456 Oak Ave, Hometown, USA',
            'documentUrl': 'https://example.com/docs/foodbank-license.pdf',
            'submittedAt': '2026-02-22T09:15:00Z',
            'status': 'pending'
          },
          {
            'id': 3,
            'username': '#green_earth',
            'email': 'contact@greenearth.org',
            'organizationName': 'Green Earth Initiative',
            'description': 'Environmental organization focused on sustainable food systems and community gardens.',
            'phone': '+1 (555) 246-8135',
            'address': '789 Pine St, Greenville, USA',
            'documentUrl': 'https://example.com/docs/green-earth-cert.pdf',
            'submittedAt': '2026-02-22T08:45:00Z',
            'status': 'pending'
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load pending organizations';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveOrganization(int orgId, String username) async {
    try {
      setState(() => _isLoading = true);
      
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Remove # from username for approved organizations
      final cleanUsername = username.replaceFirst('#', '');
      
      setState(() {
        _pendingOrganizations = _pendingOrganizations
            .where((org) => org['id'] != orgId)
            .toList();
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Approved organization: $orgId'),
          backgroundColor: Colors.green,
        ),
      );
      
      print('✅ Approved organization: $orgId - Username updated: #$username → $cleanUsername');
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve organization'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrganization(int orgId, String username) async {
    try {
      setState(() => _isLoading = true);
      
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _pendingOrganizations = _pendingOrganizations
            .where((org) => org['id'] != orgId)
            .toList();
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Rejected organization: $orgId'),
          backgroundColor: Colors.red,
        ),
      );
      
      print('❌ Rejected organization: $orgId - Deleted user: $username');
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject organization'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Organization Verification'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingOrganizations,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingOrganizations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No pending organizations',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All organizations have been reviewed',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingOrganizations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingOrganizations.length,
                        itemBuilder: (context, index) {
                          final org = _pendingOrganizations[index];
                          return _buildOrganizationCard(org);
                        },
                      ),
                    ),
    );
  }

  Widget _buildOrganizationCard(Map<String, dynamic> org) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrganizationDetails(org),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with username and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          org['organizationName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                org['username'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.pending,
                              size: 16,
                              color: Colors.orange[600],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(org['status']),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      org['status'].toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                org['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Contact info
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      org['email'],
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      org['phone'],
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      org['address'],
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Documents
              if (org['documentUrl'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Open document
                          print('Opening document: ${org['documentUrl']}');
                        },
                        child: Text(
                          'View Documents',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectOrganization(org['id'], org['username']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveOrganization(org['id'], org['username']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(
      duration: const Duration(milliseconds: 300),
      begin: 0.1,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showOrganizationDetails(Map<String, dynamic> org) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Organization Details',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Organization Name', org['organizationName']),
                      _buildDetailRow('Username', org['username']),
                      _buildDetailRow('Email', org['email']),
                      _buildDetailRow('Phone', org['phone']),
                      _buildDetailRow('Address', org['address']),
                      _buildDetailRow('Submitted', org['submittedAt']),
                      _buildDetailRow('Status', org['status']),
                      if (org['documentUrl'] != null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Documents:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            print('Opening document: ${org['documentUrl']}');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.description, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'View Verification Documents',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
