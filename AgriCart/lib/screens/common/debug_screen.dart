import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/notification_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String? _token;
  final _notif = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final t = await FirebaseMessaging.instance.getToken();
    setState(() => _token = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FCM Token:'),
            SelectableText(_token ?? 'Loading...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _notif.initialize();
                await _notif.subscribeToTopic('promos');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscribed to promos')),
                  );
                }
              },
              child: const Text('Subscribe to promos'),
            ),
          ],
        ),
      ),
    );
  }
}



