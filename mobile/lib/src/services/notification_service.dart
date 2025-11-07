import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Background message handler - MUST be top-level function
/// This runs even when the app is closed/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background notification received: ${message.notification?.title}');
  print('   Message: ${message.notification?.body}');
  print('   Data: ${message.data}');
  // Notification automatically shows in system tray by FCM
}

/// Handles Firebase Cloud Messaging: token registration, foreground/background notifications.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _api;
  String? _fcmToken;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'default_channel',
    'General Notifications',
    description: 'Default channel for general notifications',
    importance: Importance.high,
  );

  NotificationService(this._api);

  /// Initialize FCM, request permission, and get token.
  Future<void> initialize() async {
    try {
      // Initialize local notifications (needed to show notifications in foreground on Android)
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _local.initialize(initSettings);
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_defaultChannel);

      // Register background message handler FIRST
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request permission for iOS and Android 13+
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM permission granted');
      } else {
        print('⚠️ FCM permission denied');
        return;
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: $_fcmToken');
        await _registerToken(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');
        _registerToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('📩 Foreground notification: ${message.notification?.title}');
        _handleMessage(message);
        // Explicitly show a local notification when app is in foreground
        final title = message.notification?.title ?? 'Notification';
        final body = message.notification?.body ?? '';
        final androidDetails = AndroidNotificationDetails(
          _defaultChannel.id,
          _defaultChannel.name,
          channelDescription: _defaultChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );
        await _local.show(
          DateTime.now().millisecondsSinceEpoch % 100000,
          title,
          body,
          NotificationDetails(android: androidDetails),
          payload: message.data.isNotEmpty ? message.data.toString() : null,
        );
      });

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
            '📬 Notification tapped (background): ${message.notification?.title}');
        _handleMessage(message);
      });

      // Check if app was opened from a terminated state notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print(
            '📭 Notification tapped (terminated): ${initialMessage.notification?.title}');
        _handleMessage(initialMessage);
      }
    } catch (e) {
      print('❌ FCM initialization error: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.dio.put('/api/users/fcm-token', data: {'token': token});
      print('✅ FCM token registered with backend');
    } catch (e) {
      print('❌ Failed to register FCM token: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    // You can navigate to specific screens based on message.data
    final data = message.data;
    print('Notification data: $data');

    // Example routing:
    // if (data['type'] == 'new_post') {
    //   navigatorKey.currentState?.pushNamed('/posts');
    // } else if (data['type'] == 'chat_message') {
    //   navigatorKey.currentState?.pushNamed('/chat', arguments: data['roomId']);
    // }
  }

  String? get fcmToken => _fcmToken;
}
