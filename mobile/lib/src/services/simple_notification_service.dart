import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Simple notification service that shows local notifications
/// This replaces Firebase Cloud Messaging for in-app notifications
class SimpleNotificationService {
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'default_channel',
    'General Notifications',
    description: 'Default channel for general notifications',
    importance: Importance.high,
  );

  /// Initialize local notifications only (no Firebase)
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _local.initialize(initSettings);

      // Create notification channel
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_defaultChannel);

      print('✅ Local notifications initialized');
    } catch (e) {
      print('⚠️ Notification initialization failed: $e');
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
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
        payload: data?.toString(),
      );
    } catch (e) {
      print('⚠️ Failed to show notification: $e');
    }
  }
}
