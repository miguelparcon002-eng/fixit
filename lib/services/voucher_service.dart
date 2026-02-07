import '../core/config/supabase_config.dart';
import '../core/constants/db_constants.dart';

class VoucherService {
  final _supabase = SupabaseConfig.client;

  Future<bool> isProfileSetupComplete(String userId) async {
    try {
      final response = await _supabase
          .from(DBConstants.users)
          .select('profile_setup_complete')
          .eq('id', userId)
          .single();
      return response['profile_setup_complete'] ?? false;
    } catch (e) {
      print('VoucherService: Error loading profile_setup_complete - $e');
      return false;
    }
  }

  Future<void> markProfileSetupComplete(String userId) async {
    try {
      await _supabase
          .from(DBConstants.users)
          .update({'profile_setup_complete': true})
          .eq('id', userId);
    } catch (e) {
      print('VoucherService: Error marking profile setup complete - $e');
      rethrow;
    }
  }
}
