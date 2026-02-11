import '../core/config/supabase_config.dart';

class AdminCustomerActionsService {
  Future<void> setSuspended({required String customerId, required bool suspended}) async {
    await SupabaseConfig.client
        .from('users')
        .update({'is_suspended': suspended})
        .eq('id', customerId);
  }
}
