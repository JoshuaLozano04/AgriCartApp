import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    if (token != null && token.isNotEmpty) {
      try {
        await ApiService().registerFcmToken(token);
      } catch (e) {
        print('Failed to register FCM token: $e');
      }
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      // Send token to backend
      if (newToken.isNotEmpty) {
        ApiService().registerFcmToken(newToken).catchError((e) {
          print('Failed to register refreshed token: $e');
          return <String, dynamic>{};
        });
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (must be top-level function)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
    final payload = response.payload;
    if (payload == null) return;
    // payload is a stringified map from message.data
    // Basic parse to route by type
    try {
      final dataString = payload.replaceAll(RegExp(r'^{|}$'), '');
      final parts = dataString.split(',');
      final Map<String, String> data = {};
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length >= 2) {
          final key = kv[0].trim().replaceAll("'", '').replaceAll('"', '');
          final value = kv.sublist(1).join(':').trim().replaceAll("'", '').replaceAll('"', '');
          data[key] = value;
        }
      }
      final type = data['type'];
      if (type == 'order_update' && data['order_id'] != null) {
        // Future: navigate to order detail screen using a global navigator key
        print('Navigate to order: ${data['order_id']}');
      } else if (type == 'chat_message' && data['thread_id'] != null) {
        print('Navigate to chat thread: ${data['thread_id']}');
      }
    } catch (e) {
      print('Failed to parse notification payload: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');

    // Show local notification
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'agricart_channel',
      'AgriCart Notifications',
      channelDescription: 'Notifications for orders, messages, and updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'AgriCart',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  void _handleBackgroundMessageTap(RemoteMessage message) {
    print('Background message tapped: ${message.notification?.title}');
    // Navigate to appropriate screen based on message data
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

