import '../core/config/supabase_config.dart';
import '../models/notification_model.dart';
class AdminNotificationsService {
  Stream<List<AppNotification>> watchFeed({int limit = 50}) {
    return SupabaseConfig.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .take(limit)
            .map(AppNotification.fromJson)
            .toList());
  }
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