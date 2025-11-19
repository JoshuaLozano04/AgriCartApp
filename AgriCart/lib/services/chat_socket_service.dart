import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'token_storage_service.dart';
import 'api_service.dart';

/// WebSocket service for real-time chat messaging
/// Handles connection, reconnection, and message streaming per conversation
class ChatSocketService {
  WebSocketChannel? _channel;
  final String conversationId;
  final TokenStorageService _tokenStorage = TokenStorageService();

  // Stream controllers
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _disposed = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectBaseDelay = Duration(seconds: 2);

  ChatSocketService({required this.conversationId});

  /// Stream of incoming messages and events
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Stream of connection status
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Check if currently connected
  bool get isConnected => _isConnected;

  /// Get WebSocket URL based on API base URL
  String get _webSocketUrl {
    final baseUrl = ApiService.baseUrl;

    // Convert HTTP(S) URL to WS(S) URL
    String wsUrl;
    if (baseUrl.startsWith('https://')) {
      wsUrl = baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      wsUrl = baseUrl.replaceFirst('http://', 'ws://');
    } else {
      wsUrl = 'ws://$baseUrl';
    }

    // Remove /api suffix if present
    wsUrl = wsUrl.replaceAll('/api', '');

    return wsUrl;
  }

  /// Connect to WebSocket with JWT authentication
  Future<void> connect() async {
    if (_isConnected || _isConnecting || _disposed) {
      return;
    }

    _isConnecting = true;

    try {
      // Get JWT token
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('ChatSocket: No token available');
        _connectionController.add(false);
        _isConnecting = false;
        return;
      }

      // Build WebSocket URL with token
      final url = '$_webSocketUrl/ws/chat/$conversationId/?token=$token';
      debugPrint('ChatSocket: Connecting to $url');

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Listen to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _connectionController.add(true);

      debugPrint('ChatSocket: Connected to conversation $conversationId');
    } catch (e) {
      debugPrint('ChatSocket: Connection error: $e');
      _isConnected = false;
      _isConnecting = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      debugPrint('ChatSocket: Received message type: ${data['type']}');

      // Emit message to stream
      _messageController.add(data);
    } catch (e) {
      debugPrint('ChatSocket: Error parsing message: $e');
    }
  }

  /// Handle WebSocket errors
  void _onError(error) {
    debugPrint('ChatSocket: Stream error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  /// Handle WebSocket connection closed
  void _onDone() {
    debugPrint('ChatSocket: Connection closed');
    _isConnected = false;
    _connectionController.add(false);
    if (!_disposed) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_disposed || _reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('ChatSocket: Max reconnect attempts reached or disposed');
      return;
    }

    _reconnectTimer?.cancel();

    final delay =
        _reconnectBaseDelay * (1 << _reconnectAttempts); // Exponential backoff
    _reconnectAttempts++;

    debugPrint(
        'ChatSocket: Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      if (!_disposed) {
        connect();
      }
    });
  }

  /// Send a chat message
  void sendMessage(String message, String receiverId, {String? tempId}) {
    if (!_isConnected || _channel == null) {
      debugPrint('ChatSocket: Cannot send message - not connected');
      return;
    }

    final data = {
      'type': 'chat_message',
      'message': message,
      'receiver_id': receiverId,
      if (tempId != null) 'temp_id': tempId,
    };

    try {
      _channel!.sink.add(jsonEncode(data));
      debugPrint('ChatSocket: Sent message');
    } catch (e) {
      debugPrint('ChatSocket: Error sending message: $e');
    }
  }

  /// Send typing indicator
  void sendTyping(bool isTyping) {
    if (!_isConnected || _channel == null) {
      return;
    }

    final data = {
      'type': 'typing',
      'is_typing': isTyping,
    };

    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('ChatSocket: Error sending typing indicator: $e');
    }
  }

  /// Send read receipt for a message
  void sendReadReceipt(String messageId) {
    if (!_isConnected || _channel == null) {
      return;
    }

    final data = {
      'type': 'read_receipt',
      'message_id': messageId,
    };

    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('ChatSocket: Error sending read receipt: $e');
    }
  }

  /// Disconnect and clean up
  Future<void> disconnect() async {
    debugPrint('ChatSocket: Disconnecting');
    _disposed = true;
    _reconnectTimer?.cancel();

    try {
      await _channel?.sink.close(status.goingAway);
    } catch (e) {
      debugPrint('ChatSocket: Error closing channel: $e');
    }

    _isConnected = false;
    _connectionController.add(false);
  }

  /// Dispose and close all streams
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}
