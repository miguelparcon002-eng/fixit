import '../core/config/supabase_config.dart';

class AdminTechnicianActionsService {
  Future<void> setSuspended({required String technicianId, required bool suspended}) async {
    await SupabaseConfig.client
        .from('users')
        .update({'is_suspended': suspended})
        .eq('id', technicianId);
  }
}
