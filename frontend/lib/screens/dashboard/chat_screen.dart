import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import 'conversation_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const ChatScreen({super.key, this.onRefresh});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Conversation> _conversations = [];
  List<User> _availableUsers = [];
  bool _isLoading = false;
  String? _error;
  String _selectedRole = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      // Load conversations and available users in parallel
      final conversationsFuture = ApiService.getUserConversations(token);
      final usersFuture = _selectedRole == 'all' 
          ? ApiService.getAvailableUsers(token: token)
          : ApiService.getAvailableUsers(token: token, role: _selectedRole);

      final results = await Future.wait([conversationsFuture, usersFuture]);

      final conversationsResult = results[0];
      final usersResult = results[1];

      if (conversationsResult['success'] && usersResult['success']) {
        setState(() {
          _conversations = conversationsResult['conversations'] as List<Conversation>;
          _availableUsers = usersResult['users'] as List<User>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = conversationsResult['error'] ?? usersResult['error'] ?? 'Failed to load data';
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

  Future<void> _startNewConversation(User user) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token!;

      final result = await ApiService.createConversation(
        token: token,
        participant2Id: user.id,
        participant2Type: user.role,
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

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Start New Conversation'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                // Role filter
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'volunteer', child: Text('Volunteers')),
                    DropdownMenuItem(value: 'organization', child: Text('Organizations')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                    _loadData();
                  },
                ),
                const SizedBox(height: 16),
                // Available users list
                Expanded(
                  child: _availableUsers.isEmpty
                      ? const Center(child: Text('No users available'))
                      : ListView.builder(
                          itemCount: _availableUsers.length,
                          itemBuilder: (context, index) {
                            final user = _availableUsers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor,
                                child: Text(
                                  '${user.firstName[0]}${user.lastName[0]}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text('${user.firstName} ${user.lastName}'),
                              subtitle: Text(user.roleDisplay),
                              onTap: () {
                                Navigator.pop(context);
                                _startNewConversation(user);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor,
            child: Row(
              children: [
                const Icon(Icons.chat, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
                IconButton(
                  onPressed: _showNewConversationDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to start a new conversation',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showNewConversationDialog,
              icon: const Icon(Icons.add),
              label: const Text('Start Conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationCard(conversation);
        },
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            '${conversation.participant2.firstName[0]}${conversation.participant2.lastName[0]}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          conversation.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conversation.participant2TypeDisplay),
            const SizedBox(height: 4),
            Text(
              conversation.lastMessageDisplay,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.lastMessageAt != null)
              Text(
                _formatTime(conversation.lastMessageAt!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationDetailScreen(
                conversation: conversation,
                onMessageSent: _loadData,
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn().slideX();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
