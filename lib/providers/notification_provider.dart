import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../services/notification_service.dart';
final notificationServiceProvider = Provider((ref) => NotificationService());
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const <AppNotification>[];
    return;
  }
  final service = ref.watch(notificationServiceProvider);
  yield* service.watchForUser(user.id);
});
final filteredNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final allAsync = ref.watch(notificationsProvider);
  final settingsAsync = ref.watch(notificationSettingsProvider);
  final all = allAsync.valueOrNull ?? [];
  final settings = settingsAsync.valueOrNull;
  if (settings == null) return all;
  return all.where((n) => settings.allows(n.type)).toList();
});
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final filtered = ref.watch(filteredNotificationsProvider);
  return filtered.where((n) => !n.isRead).length;
});