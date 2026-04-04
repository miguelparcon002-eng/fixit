import '../core/config/supabase_config.dart';
import '../models/notification_model.dart';
import '../core/utils/app_logger.dart';
class NotificationService {
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
    if (response.status != 200) {
      throw Exception('Email send failed (status ${response.status}): ${response.data}');
    }
  }
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
    try {
      await SupabaseConfig.client.functions.invoke(
        'send-push-notification',
        body: {
          'userId': userId,
          'title': title,
          'body': message,
          'data': {'type': type, ...?data},
        },
      );
    } catch (e) {
      AppLogger.p('NotificationService: FCM push failed (non-fatal) — $e');
    }
  }
}