import '../core/config/supabase_config.dart';
import '../models/notification_model.dart';

/// System-wide admin notification feed.
///
/// NOTE: The `public.notifications` table schema is per-user (user_id) but the
/// admin feed can still display all notifications (useful for monitoring).
class AdminNotificationsService {
  Future<List<AppNotification>> listFeed({int limit = 50}) async {
    final res = await SupabaseConfig.client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(AppNotification.fromJson).toList();
  }

  Future<void> markAsRead(String id) async {
    await SupabaseConfig.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> deleteNotification(String id) async {
    await SupabaseConfig.client.from('notifications').delete().eq('id', id);
  }
}
