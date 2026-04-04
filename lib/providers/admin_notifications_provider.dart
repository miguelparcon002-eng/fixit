import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/admin_notifications_service.dart';
final adminNotificationsServiceProvider =
    Provider((ref) => AdminNotificationsService());
final adminNotificationsFeedProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final svc = ref.watch(adminNotificationsServiceProvider);
  return svc.watchFeed(limit: 50);
});
final adminUnreadNotificationsCountProvider = Provider<int>((ref) {
  final async = ref.watch(adminNotificationsFeedProvider);
  return async.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});