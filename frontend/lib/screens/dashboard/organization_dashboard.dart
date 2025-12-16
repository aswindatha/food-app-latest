import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class OrganizationDashboard extends StatelessWidget {
  const OrganizationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Organization Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthProvider>().logout();
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.business),
                    SizedBox(width: 8),
                    Text('Organization Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
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
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(
                              Icons.business,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Organization Portal',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  authProvider.user?.fullName ?? 'Organization',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Managing food distribution and coordinating efforts to serve our community better.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.3, duration: 600.ms).fadeIn(),
                
                const SizedBox(height: 30),
                
                // Impact Stats
                Text(
                  'Organization Impact',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildImpactCard(
                      context,
                      'Total Donations',
                      '1,234',
                      Icons.inventory,
                      AppTheme.primaryColor,
                    ).animate().scale(duration: 600.ms, delay: 300.ms),
                    _buildImpactCard(
                      context,
                      'Families Helped',
                      '567',
                      Icons.family_restroom,
                      AppTheme.secondaryColor,
                    ).animate().scale(duration: 600.ms, delay: 400.ms),
                    _buildImpactCard(
                      context,
                      'Active Volunteers',
                      '89',
                      Icons.people,
                      AppTheme.accentColor,
                    ).animate().scale(duration: 600.ms, delay: 500.ms),
                    _buildImpactCard(
                      context,
                      'Partner Organizations',
                      '23',
                      Icons.handshake,
                      Colors.purple,
                    ).animate().scale(duration: 600.ms, delay: 600.ms),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Management Tools
                Text(
                  'Management Tools',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
                
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildToolCard(
                      context,
                      'Donation Management',
                      Icons.inventory_2,
                      AppTheme.primaryColor,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Donation management coming soon!')),
                        );
                      },
                    ).animate().scale(duration: 600.ms, delay: 800.ms),
                    _buildToolCard(
                      context,
                      'Volunteer Coordination',
                      Icons.group_work,
                      AppTheme.accentColor,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Volunteer coordination coming soon!')),
                        );
                      },
                    ).animate().scale(duration: 600.ms, delay: 900.ms),
                    _buildToolCard(
                      context,
                      'Distribution Tracking',
                      Icons.local_shipping,
                      AppTheme.secondaryColor,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Distribution tracking coming soon!')),
                        );
                      },
                    ).animate().scale(duration: 600.ms, delay: 1000.ms),
                    _buildToolCard(
                      context,
                      'Reports & Analytics',
                      Icons.analytics,
                      Colors.purple,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reports & analytics coming soon!')),
                        );
                      },
                    ).animate().scale(duration: 600.ms, delay: 1100.ms),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Recent Activities
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(duration: 600.ms, delay: 1200.ms),
                
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildActivityItem(
                          'New Donation Received',
                          'Fresh produce from local farm',
                          '1 hour ago',
                          Icons.inventory,
                          AppTheme.primaryColor,
                        ),
                        const Divider(),
                        _buildActivityItem(
                          'Volunteer Assignment',
                          '12 volunteers assigned for weekend pickup',
                          '3 hours ago',
                          Icons.people,
                          AppTheme.accentColor,
                        ),
                        const Divider(),
                        _buildActivityItem(
                          'Distribution Complete',
                          'Food delivered to 45 families',
                          '1 day ago',
                          Icons.check_circle,
                          AppTheme.successColor,
                        ),
                        const Divider(),
                        _buildActivityItem(
                          'Partner Meeting',
                          'Meeting with local supermarket chain',
                          '2 days ago',
                          Icons.handshake,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 1300.ms),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImpactCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
