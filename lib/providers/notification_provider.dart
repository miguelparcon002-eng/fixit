import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

/// Realtime stream of ALL the current user's notifications (unfiltered).
/// Updates instantly whenever the DB changes — no manual refresh needed.
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const <AppNotification>[];
    return;
  }

  final service = ref.watch(notificationServiceProvider);
  yield* service.watchForUser(user.id);
});

/// Filtered view — respects the user's notification settings toggles.
/// Use this in all notification list screens.
final filteredNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final allAsync = ref.watch(notificationsProvider);
  final settingsAsync = ref.watch(notificationSettingsProvider);

  final all = allAsync.valueOrNull ?? [];
  final settings = settingsAsync.valueOrNull;

  // If settings haven't loaded yet, show everything
  if (settings == null) return all;

  return all.where((n) => settings.allows(n.type)).toList();
});

/// Unread count based on the filtered list.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final filtered = ref.watch(filteredNotificationsProvider);
  return filtered.where((n) => !n.isRead).length;
});
