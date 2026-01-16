import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'notification_router.dart';

class PushNotificationService {
  static final _fcm = FirebaseMessaging.instance;

  /// Call from main()
  static Future<void> init(BuildContext context) async {
    await _fcm.requestPermission();

    // 🔔 App opened from TERMINATED state
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(context, initialMessage);
    }

    // 🔔 App opened from BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleMessage(context, message),
    );
  }

  static void _handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data.isNotEmpty) {
      NotificationRouter.handle(context, message.data);
    }
  }
}
