import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getUserConversations();

      if (response['success'] == true) {
        setState(() {
          _conversations =
              List<Map<String, dynamic>>.from(response['conversations'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load conversations';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading conversations: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp == '') return '';

    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        // Today - show time
        return DateFormat.jm().format(dateTime);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat.E().format(dateTime); // Day of week
      } else {
        return DateFormat.MMMd().format(dateTime); // Month and day
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final currentUserId =
            state is AuthAuthenticated ? state.user.userId : '';

        return Scaffold(
          body: _buildBody(currentUserId),
        );
      },
    );
  }

  Widget _buildBody(String currentUserId) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textGray,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadConversations,
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
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.textGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: AppTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting with sellers',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final otherUser = conversation['other_user'] as Map<String, dynamic>?;
          final unreadCount = conversation['unread_count'] ?? 0;
          final lastMessage = conversation['last_message'] ?? '';
          final lastMessageAt = conversation['last_message_at'];

          return _buildConversationCard(
            conversation: conversation,
            otherUser: otherUser,
            unreadCount: unreadCount,
            lastMessage: lastMessage,
            lastMessageAt: lastMessageAt,
            currentUserId: currentUserId,
          );
        },
      ),
    );
  }

  Widget _buildConversationCard({
    required Map<String, dynamic> conversation,
    required Map<String, dynamic>? otherUser,
    required int unreadCount,
    required String lastMessage,
    required dynamic lastMessageAt,
    required String currentUserId,
  }) {
    final conversationId = conversation['conversation_id'];
    final otherUserName = otherUser?['full_name'] ?? 'Unknown User';
    final otherUserId = otherUser?['user_id'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.lightGreen,
              child: Text(
                otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          otherUserName,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          lastMessage.isEmpty ? 'No messages yet' : lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textGray,
            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: Text(
          _formatTimestamp(lastMessageAt),
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textGray,
            fontSize: 12,
          ),
        ),
        onTap: () async {
          // Navigate to chat detail screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                conversationId: conversationId,
                otherUserId: otherUserId,
                otherUserName: otherUserName,
              ),
            ),
          );

          // Refresh list if returning from chat
          if (result == true) {
            _loadConversations();
          }
        },
      ),
    );
  }
}
