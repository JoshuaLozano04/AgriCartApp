import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../services/api_service.dart';
import '../../services/chat_socket_service.dart';
import '../../theme/app_theme.dart';
import '../../bloc/chat_image/chat_image_bloc.dart';
import '../../bloc/chat_image/chat_image_event.dart';
import '../../bloc/chat_image/chat_image_state.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ApiService _apiService = ApiService();
  ChatSocketService? _socketService;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatImageBloc _chatImageBloc;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isConnected = false;
  String? _error;
  Timer? _typingTimer;
  bool _isTyping = false;
  String? _otherUserTyping;

  // Map to track pending messages by temp_id
  final Map<String, Map<String, dynamic>> _pendingMessages = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initializeSocket();
    _chatImageBloc = ChatImageBloc(apiService: _apiService);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _socketService?.dispose();
    _chatImageBloc.close();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await _apiService.getConversationMessages(widget.conversationId);

      if (response['success'] == true) {
        setState(() {
          _messages =
              List<Map<String, dynamic>>.from(response['messages'] ?? []);
          _isLoading = false;
        });

        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // Mark conversation as read
        _apiService.markConversationRead(widget.conversationId);
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load messages';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading messages: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeSocket() {
    _socketService = ChatSocketService(conversationId: widget.conversationId);

    // Listen to connection status
    _socketService!.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    // Listen to messages
    _socketService!.messageStream.listen(_handleSocketMessage);

    // Connect
    _socketService!.connect();
  }

  void _handleSocketMessage(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'connection':
        debugPrint('Chat: Connected to conversation');
        break;

      case 'chat_message':
        final message = data['message'] as Map<String, dynamic>?;
        if (message != null && mounted) {
          setState(() {
            // Remove from pending if it's our own message
            final messageId = message['message_id'];
            _pendingMessages
                .removeWhere((key, value) => value['message_id'] == messageId);

            // Add to messages list if not already present
            if (!_messages.any((m) => m['message_id'] == messageId)) {
              _messages.add(message);
            }
          });
          _scrollToBottom();

          // Send read receipt if message is for us
          final currentUserId = _getCurrentUserId();
          if (message['receiver_id'] == currentUserId) {
            _socketService?.sendReadReceipt(message['message_id']);
          }
        }
        break;

      case 'message_sent':
        // Acknowledgement from server
        final messageId = data['message_id'];
        final tempId = data['temp_id'];

        if (tempId != null && _pendingMessages.containsKey(tempId)) {
          setState(() {
            // Update pending message with server message_id
            final pending = _pendingMessages[tempId]!;
            pending['message_id'] = messageId;
            pending['created_at'] = data['timestamp'];
            pending['status'] = 'sent';
            _pendingMessages.remove(tempId);
          });
        }
        break;

      case 'typing':
        final userId = data['user_id'];
        final isTyping = data['is_typing'] == true;

        if (userId != _getCurrentUserId()) {
          setState(() {
            _otherUserTyping = isTyping ? widget.otherUserName : null;
          });
        }
        break;

      case 'read_receipt':
        final messageId = data['message_id'];
        if (mounted) {
          setState(() {
            final index =
                _messages.indexWhere((m) => m['message_id'] == messageId);
            if (index != -1) {
              _messages[index]['is_read'] = true;
            }
          });
        }
        break;

      case 'error':
        debugPrint('Chat error: ${data['message']}');
        break;
    }
  }

  String _getCurrentUserId() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      return state.user.userId;
    }
    return '';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onMessageChanged(String text) {
    // Trigger rebuild to update send button state
    setState(() {});

    // Send typing indicator
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _socketService?.sendTyping(true);
    }

    // Cancel previous timer
    _typingTimer?.cancel();

    // Set new timer to stop typing indicator
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _socketService?.sendTyping(false);
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final currentUserId = _getCurrentUserId();
    if (currentUserId.isEmpty) {
      return;
    }

    // Generate temp_id for optimistic UI
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Create optimistic message
    final optimisticMessage = {
      'message_id': tempId,
      'temp_id': tempId,
      'conversation_id': widget.conversationId,
      'sender_id': currentUserId,
      'receiver_id': widget.otherUserId,
      'message': text,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
      'status': 'sending',
    };

    setState(() {
      _messages.add(optimisticMessage);
      _pendingMessages[tempId] = optimisticMessage;
    });

    _messageController.clear();
    _scrollToBottom();

    // Stop typing indicator
    if (_isTyping) {
      _isTyping = false;
      _socketService?.sendTyping(false);
    }

    // Send via WebSocket if connected, otherwise use REST API fallback
    if (_isConnected) {
      _socketService?.sendMessage(text, widget.otherUserId, tempId: tempId);
    } else {
      // Fallback to REST API if WebSocket not connected
      debugPrint('Chat: WebSocket not connected, using REST API fallback');
      try {
        final response = await _apiService.sendMessage(
          widget.otherUserId,
          text,
        );

        if (response['success'] == true && mounted) {
          final message = response['message'];
          setState(() {
            _pendingMessages.remove(tempId);
            // Replace optimistic message with server response
            final index = _messages.indexWhere((m) => m['temp_id'] == tempId);
            if (index != -1) {
              _messages[index] = message;
            }
          });
        } else {
          // Mark message as failed
          if (mounted) {
            setState(() {
              final index = _messages.indexWhere((m) => m['temp_id'] == tempId);
              if (index != -1) {
                _messages[index]['status'] = 'failed';
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Chat: Error sending message via REST: $e');
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m['temp_id'] == tempId);
            if (index != -1) {
              _messages[index]['status'] = 'failed';
            }
          });
        }
      }
    }
  }

  // Image picking/uploading is handled by ChatImageBloc now.

  void _addSentImageMessage({required String imageUrl, String? messageId}) {
    final currentUserId = _getCurrentUserId();
    final imageMessage = {
      'message_id': messageId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'conversation_id': widget.conversationId,
      'sender_id': currentUserId,
      'receiver_id': widget.otherUserId,
      'message': '📷 Image',
      'message_type': 'image',
      'metadata': {'type': 'image', 'image_url': imageUrl},
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
      'status': 'sent',
    };
    setState(() {
      _messages.add(imageMessage);
    });
    _scrollToBottom();
  }

  void _addFailedImageMessage({required String localPath, String? imageUrl, String? reason}) {
    final currentUserId = _getCurrentUserId();
    final failedMessage = {
      'message_id': 'fail_${DateTime.now().millisecondsSinceEpoch}',
      'conversation_id': widget.conversationId,
      'sender_id': currentUserId,
      'receiver_id': widget.otherUserId,
      'message': 'Image failed',
      'message_type': 'image',
      'metadata': {
        'type': 'image',
        if (imageUrl != null) 'image_url': imageUrl,
        'local_path': localPath,
        'error': reason ?? 'Unknown error',
      },
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
      'status': 'failed',
    };
    setState(() => _messages.add(failedMessage));
    _scrollToBottom();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image failed: ${reason ?? 'Unknown'}'), backgroundColor: Colors.red),
      );
    }
  }

  // Retry handled by ChatImageBloc; UI dispatches a ChatImageRetryRequested event.

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return '';
      }

      return DateFormat.jm().format(dateTime.toLocal());
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

        return BlocProvider.value(
          value: _chatImageBloc,
          child: BlocListener<ChatImageBloc, ChatImageState>(
            listener: (context, state) {
              if (state is ChatImageUploadSuccess) {
                _addSentImageMessage(imageUrl: state.imageUrl);
              } else if (state is ChatImageUploadFailure) {
                _addFailedImageMessage(localPath: state.localPath, reason: state.error);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Image upload failed: ${state.error}'), backgroundColor: Colors.red),
                );
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(widget.otherUserName),
                actions: [
                  if (!_isConnected)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Icon(Icons.cloud_off, size: 20),
                    ),
                ],
              ),
              body: Column(
                children: [
                  if (!_isConnected && !_isLoading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.orange,
                      child: const Text(
                        'Reconnecting...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  Expanded(child: _buildMessagesList(currentUserId)),
                  _buildInputArea(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesList(String currentUserId) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
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
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
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
              'No messages yet',
              style: AppTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['sender_id'] == currentUserId;
        final status = message['status'] as String?;

        return _buildMessageBubble(message, isMe, status);
      },
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isMe,
    String? status,
  ) {
    final text = message['message'] ?? '';
    final messageType = message['message_type'] ?? message['metadata']?['type'];
    final imageUrl = (messageType == 'image')
        ? (message['metadata'] is Map ? message['metadata']['image_url'] : null)
        : null;
    final timestamp = message['created_at'];
    final isRead = message['is_read'] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryGreen : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null) ...[
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      insetPadding: const EdgeInsets.all(16),
                      child: InteractiveViewer(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          placeholder: (c, _) => const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (c, _, __) => const Icon(Icons.broken_image, size: 64),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (c, _) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.black12,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (c, _, __) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.black12,
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                    if (status == 'failed') Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () {
                          final localPath = message['metadata'] is Map ? message['metadata']['local_path'] : null;
                          if (localPath != null) {
                            context.read<ChatImageBloc>().add(ChatImageRetryRequested(localPath: localPath, receiverId: widget.otherUserId));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Local file not available for retry'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.refresh, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    if (status == 'retrying') Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                          child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (text.isNotEmpty && text != '📷 Image')
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
            ] else ...[
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    status == 'sending'
                        ? Icons.access_time
                        : isRead
                            ? Icons.done_all
                            : Icons.done,
                    size: 14,
                    color: isRead ? Colors.blue : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Typing indicator
          if (_otherUserTyping != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                '$_otherUserTyping is typing...',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          // Input row
          Row(
            children: [
              // Image picker button (uses ChatImageBloc)
              PopupMenuButton<String>(
                tooltip: 'Attach',
                icon: BlocBuilder<ChatImageBloc, ChatImageState>(
                  builder: (context, state) {
                    if (state is ChatImageUploading) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return const Icon(Icons.add_photo_alternate, color: Colors.blueGrey);
                  },
                ),
                onSelected: (value) {
                  final bloc = context.read<ChatImageBloc>();
                  if (bloc.state is ChatImageUploading) return;
                  if (value == 'gallery') {
                    bloc.add(ChatImagePickRequested(source: ImageSource.gallery, receiverId: widget.otherUserId));
                  } else if (value == 'camera') {
                    bloc.add(ChatImagePickRequested(source: ImageSource.camera, receiverId: widget.otherUserId));
                  }
                },
                itemBuilder: (c) => [
                  const PopupMenuItem(value: 'camera', child: ListTile(leading: Icon(Icons.photo_camera), title: Text('Camera'))),
                  const PopupMenuItem(value: 'gallery', child: ListTile(leading: Icon(Icons.photo_library), title: Text('Gallery'))),
                ],
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  onChanged: _onMessageChanged,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppTheme.textGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: _messageController.text.trim().isEmpty
                    ? Colors.grey
                    : AppTheme.primaryGreen,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _messageController.text.trim().isEmpty
                      ? null
                      : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
