import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/notification_settings_service.dart';

final notificationSettingsServiceProvider =
    Provider((ref) => NotificationSettingsService());

/// Loads settings from Supabase for the current user.
/// Async notifier so we can update individual toggles and auto-save.
class NotificationSettingsNotifier
    extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) return const NotificationSettings(userId: '');

    final service = ref.read(notificationSettingsServiceProvider);
    return service.getSettings(user.id);
  }

  /// Toggle a single field and persist to Supabase immediately.
  Future<void> save(NotificationSettings updated) async {
    state = AsyncData(updated);
    final service = ref.read(notificationSettingsServiceProvider);
    await service.saveSettings(updated);
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);
