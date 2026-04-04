import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/config/supabase_config.dart';
import '../core/utils/app_logger.dart';
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
  static Future<void> initialize() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
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
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleMessageOpen(initial);
  }
  static Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await SupabaseConfig.client
          .from('users')
          .update({'fcm_token': token}).eq('id', userId);
      AppLogger.p('FCMService: token saved for $userId');
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
    AppLogger.p(
        'FCMService: notification tapped — type=${message.data['type']}');
  }
}