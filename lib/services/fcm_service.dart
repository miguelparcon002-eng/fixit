import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/config/supabase_config.dart';
import '../core/utils/app_logger.dart';

/// Top-level handler — required by Firebase to run in a separate isolate.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  final notification = message.notification;
  if (notification == null) return;

  await plugin.show(
    message.hashCode,
    notification.title ?? 'FixIt',
    notification.body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'fixit_channel',
        'FixIt Notifications',
        channelDescription: 'FixIt app notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

class FCMService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'fixit_channel';
  static const _channelName = 'FixIt Notifications';
  static const _channelDesc = 'FixIt app notifications';

  /// Call once at app startup (after Firebase.initializeApp).
  static Future<void> initialize() async {
    // Set up local notifications
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    // Request permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Show local notification while app is in foreground
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // App opened from a background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    // App opened from a terminated state notification tap
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleMessageOpen(initial);
  }

  /// Save the device FCM token to the user's profile row in Supabase.
  /// Call this after the user has successfully logged in.
  static Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await SupabaseConfig.client
          .from('users')
          .update({'fcm_token': token}).eq('id', userId);

      AppLogger.p('FCMService: token saved for $userId');

      // Keep token fresh if it rotates
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await SupabaseConfig.client
            .from('users')
            .update({'fcm_token': newToken}).eq('id', userId);
        AppLogger.p('FCMService: token refreshed for $userId');
      });
    } catch (e) {
      AppLogger.p('FCMService: failed to save token — $e');
    }
  }

  /// Remove the FCM token when the user logs out so they stop receiving pushes.
  static Future<void> clearTokenForUser(String userId) async {
    try {
      await SupabaseConfig.client
          .from('users')
          .update({'fcm_token': null}).eq('id', userId);
      await FirebaseMessaging.instance.deleteToken();
      AppLogger.p('FCMService: token cleared for $userId');
    } catch (e) {
      AppLogger.p('FCMService: failed to clear token — $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'FixIt',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static void _handleMessageOpen(RemoteMessage message) {
    // You can add navigation logic here using your router,
    // e.g. based on message.data['type'] or message.data['booking_id'].
    AppLogger.p(
        'FCMService: notification tapped — type=${message.data['type']}');
  }
}
