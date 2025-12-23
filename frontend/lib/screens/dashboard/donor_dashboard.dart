import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class DonorDashboard extends StatelessWidget {
  const DonorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Donor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
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
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
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
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
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
                              Icons.person,
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
                                  'Welcome back,',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  authProvider.user?.fullName ?? 'Donor',
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
                        'Thank you for your generosity! Together we can make a difference in our community.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.3, duration: 600.ms).fadeIn(),
                
                const SizedBox(height: 30),
                
                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildActionCard(
                      context,
                      'Donate Food',
                      Icons.volunteer_activism,
                      AppTheme.primaryColor,
                      () {
                        // TODO: Navigate to donation form
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Donation form coming soon!')),
                        );
                      },
                    ).animate().scale(duration: 600.ms, delay: 300.ms),
                    _buildActionCard(
                      context,
                      'My Donations',
                      Icons.history,
                      AppTheme.secondaryColor,
                      () {
                        // TODO: Navigate to donation history
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Donation history coming soon!')),
                        );
                      },
                    ).animate().scale(duration: 600.ms, delay: 400.ms),
                    _buildActionCard(
                      context,
                      'Find Volunteers',
                      Icons.people,
                      AppTheme.accentColor,
                      () {
                        // TODO: Navigate to volunteers list
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Volunteers list coming soon!')),
                        );
                      },
                    ).animate().scale(duration: 600.ms, delay: 500.ms),
                    _buildActionCard(
                      context,
                      'Impact Stats',
                      Icons.bar_chart,
                      Colors.purple,
                      () {
                        // TODO: Navigate to impact statistics
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Impact statistics coming soon!')),
                        );
                      },
                    ).animate().scale(duration: 600.ms, delay: 600.ms),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Recent Activity
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
                
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildActivityItem(
                          'Donation Posted',
                          'Fresh vegetables - 5kg',
                          '2 hours ago',
                          Icons.volunteer_activism,
                          AppTheme.primaryColor,
                        ),
                        const Divider(),
                        _buildActivityItem(
                          'Volunteer Assigned',
                          'John Smith accepted pickup',
                          '5 hours ago',
                          Icons.people,
                          AppTheme.accentColor,
                        ),
                        const Divider(),
                        _buildActivityItem(
                          'Donation Completed',
                          'Canned goods delivered',
                          '1 day ago',
                          Icons.check_circle,
                          AppTheme.successColor,
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 800.ms),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to quick donation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quick donation coming soon!')),
          );
        },
        label: const Text('Quick Donate'),
        icon: const Icon(Icons.add),
      ).animate().scale(duration: 600.ms, delay: 900.ms),
    );
  }

  Widget _buildActionCard(
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
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
