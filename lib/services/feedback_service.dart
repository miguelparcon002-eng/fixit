import '../core/config/supabase_config.dart';

class FeedbackService {
  static Future<void> submitFeedback({
    required String userId,
    required String userName,
    required String type, // 'feedback' or 'bug_report'
    required String message,
    int? rating,
  }) async {
    await SupabaseConfig.client.from('user_feedback').insert({
      'user_id': userId,
      'user_name': userName,
      'type': type,
      'message': message,
      'rating': rating,
      'status': 'new',
    });
  }

  static Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final response = await SupabaseConfig.client
        .from('user_feedback')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> updateFeedbackStatus({
    required String feedbackId,
    required String status,
    String? adminNote,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'reviewed_at': DateTime.now().toIso8601String(),
    };
    if (adminNote != null) {
      updates['admin_note'] = adminNote;
    }
    await SupabaseConfig.client
        .from('user_feedback')
        .update(updates)
        .eq('id', feedbackId);
  }
}
