import '../core/config/supabase_config.dart';
import '../models/notification_model.dart';
import '../core/utils/app_logger.dart';

class NotificationService {
  /// Realtime stream — emits a new list whenever any notification
  /// for [userId] is inserted, updated, or deleted.
  Stream<List<AppNotification>> watchForUser(String userId) {
    return SupabaseConfig.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(AppNotification.fromJson).toList());
  }

  Future<List<AppNotification>> listForUser(String userId) async {
    final res = await SupabaseConfig.client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(AppNotification.fromJson).toList();
  }

  Future<void> markAsRead(String id) async {
    await SupabaseConfig.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead(String userId) async {
    await SupabaseConfig.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  Future<void> deleteNotification(String id) async {
    await SupabaseConfig.client.from('notifications').delete().eq('id', id);
  }

  /// Send a verification status email to the technician via Edge Function.
  Future<void> sendVerificationEmail({
    required String toEmail,
    required String technicianName,
    required String action, // 'approved' | 'rejected' | 'resubmit'
    String? adminNotes,
  }) async {
    final response = await SupabaseConfig.client.functions.invoke(
      'send-verification-email',
      body: {
        'to': toEmail,
        'technicianName': technicianName,
        'action': action,
        'adminNotes': adminNotes ?? '',
      },
    );
    AppLogger.p('📧 Email function response: status=${response.status} data=${response.data}');
    // Surface any error from the edge function
    if (response.status != 200) {
      throw Exception('Email send failed (status ${response.status}): ${response.data}');
    }
  }

  /// Manually send a notification (for client-side events not covered by DB triggers).
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await SupabaseConfig.client.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      if (data != null) 'data': data,
    });
  }
}
