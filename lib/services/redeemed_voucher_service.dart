import '../core/config/supabase_config.dart';
import '../models/redeemed_voucher.dart';
import '../models/reward.dart';

class RedeemedVoucherService {
  final _supabase = SupabaseConfig.client;

  /// Get all redeemed vouchers for the current user
  Future<List<RedeemedVoucher>> getUserRedeemedVouchers(String userId) async {
    try {
      final response = await _supabase
          .from('user_redeemed_vouchers')
          .select()
          .eq('user_id', userId)
          .order('redeemed_at', ascending: false);

      return (response as List)
          .map((json) => RedeemedVoucher.fromJson(json))
          .toList();
    } catch (e) {
      print('RedeemedVoucherService: Error loading redeemed vouchers - $e');
      return [];
    }
  }

  /// Redeem a voucher
  Future<RedeemedVoucher?> redeemVoucher({
    required String userId,
    required RewardVoucher voucher,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await _supabase
          .from('user_redeemed_vouchers')
          .insert({
            'user_id': userId,
            'voucher_id': voucher.id,
            'voucher_title': voucher.title,
            'voucher_description': voucher.description,
            'points_cost': voucher.pointsCost,
            'discount_amount': voucher.discountAmount,
            'discount_type': voucher.discountType,
            'is_used': false,
            'expires_at': expiresAt?.toIso8601String(),
          })
          .select()
          .single();

      print('RedeemedVoucherService: Voucher redeemed successfully');
      return RedeemedVoucher.fromJson(response);
    } catch (e) {
      print('RedeemedVoucherService: Error redeeming voucher - $e');
      return null;
    }
  }

  /// Mark a voucher as used (when applied to a booking)
  Future<bool> markVoucherAsUsed({
    required String voucherId,
    String? bookingId,
  }) async {
    try {
      await _supabase
          .from('user_redeemed_vouchers')
          .update({
            'is_used': true,
            'used_at': DateTime.now().toIso8601String(),
            if (bookingId != null) 'booking_id': bookingId,
          })
          .eq('id', voucherId);

      print('RedeemedVoucherService: Voucher marked as used');
      return true;
    } catch (e) {
      print('RedeemedVoucherService: Error marking voucher as used - $e');
      return false;
    }
  }

  /// Get unused vouchers for a user
  Future<List<RedeemedVoucher>> getUnusedVouchers(String userId) async {
    try {
      final response = await _supabase
          .from('user_redeemed_vouchers')
          .select()
          .eq('user_id', userId)
          .eq('is_used', false)
          .order('redeemed_at', ascending: false);

      return (response as List)
          .map((json) => RedeemedVoucher.fromJson(json))
          .toList();
    } catch (e) {
      print('RedeemedVoucherService: Error loading unused vouchers - $e');
      return [];
    }
  }

  /// Delete a redeemed voucher (if allowed)
  Future<bool> deleteRedeemedVoucher(String voucherId) async {
    try {
      await _supabase
          .from('user_redeemed_vouchers')
          .delete()
          .eq('id', voucherId);

      print('RedeemedVoucherService: Redeemed voucher deleted');
      return true;
    } catch (e) {
      print('RedeemedVoucherService: Error deleting redeemed voucher - $e');
      return false;
    }
  }

  /// Stream redeemed vouchers for real-time updates
  Stream<List<RedeemedVoucher>> watchUserRedeemedVouchers(String userId) {
    return _supabase
        .from('user_redeemed_vouchers')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('redeemed_at', ascending: false)
        .map((data) => data.map((json) => RedeemedVoucher.fromJson(json)).toList());
  }
}
