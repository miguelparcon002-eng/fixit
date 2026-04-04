import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward.dart';
import '../models/redeemed_voucher.dart';
import '../services/redeemed_voucher_service.dart';
import '../core/config/supabase_config.dart';
import 'auth_provider.dart';
import '../core/utils/app_logger.dart';
final redeemedVoucherServiceProvider = Provider((ref) => RedeemedVoucherService());
final rewardPointsProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return 0;
  try {
    final rows = await SupabaseConfig.client
        .from('bookings')
        .select('final_cost, estimated_cost')
        .eq('customer_id', user.id)
        .eq('status', 'completed');
    int earnedPoints = 0;
    for (final row in rows as List) {
      final amount = (row['final_cost'] as num?)?.toDouble() ??
          (row['estimated_cost'] as num?)?.toDouble() ??
          0.0;
      earnedPoints += (amount / 50).floor();
    }
    final voucherService = ref.watch(redeemedVoucherServiceProvider);
    final redeemedVouchers = await voucherService.getUserRedeemedVouchers(user.id);
    int spentPoints = 0;
    for (final voucher in redeemedVouchers) {
      spentPoints += voucher.pointsCost;
    }
    final remaining = earnedPoints - spentPoints;
    AppLogger.p('RewardPointsProvider: earned=$earnedPoints spent=$spentPoints remaining=$remaining');
    return remaining > 0 ? remaining : 0;
  } catch (e) {
    AppLogger.p('RewardPointsProvider: Error calculating points - $e');
    return 0;
  }
});
final redeemedVouchersProvider = StreamProvider<List<RedeemedVoucher>>((ref) {
  final voucherService = ref.watch(redeemedVoucherServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return voucherService.watchUserRedeemedVouchers(user.id);
});
final unusedVouchersProvider = FutureProvider<List<RedeemedVoucher>>((ref) async {
  final voucherService = ref.watch(redeemedVoucherServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return voucherService.getUnusedVouchers(user.id);
});
final availableVouchersProvider = Provider<List<RewardVoucher>>((ref) {
  return [
    RewardVoucher(
      id: 'v1',
      title: '₱100 OFF',
      description: 'Get ₱100 discount on any repair service',
      pointsCost: 100,
      discountAmount: 100,
      discountType: 'fixed',
    ),
    RewardVoucher(
      id: 'v2',
      title: '₱250 OFF',
      description: 'Get ₱250 discount on repairs above ₱1,000',
      pointsCost: 200,
      discountAmount: 250,
      discountType: 'fixed',
    ),
    RewardVoucher(
      id: 'v3',
      title: '10% OFF',
      description: 'Get 10% discount on any repair service',
      pointsCost: 150,
      discountAmount: 10,
      discountType: 'percentage',
    ),
    RewardVoucher(
      id: 'v4',
      title: '₱500 OFF',
      description: 'Get ₱500 discount on repairs above ₱2,000',
      pointsCost: 300,
      discountAmount: 500,
      discountType: 'fixed',
    ),
    RewardVoucher(
      id: 'v5',
      title: '20% OFF',
      description: 'Get 20% discount on any repair service',
      pointsCost: 400,
      discountAmount: 20,
      discountType: 'percentage',
    ),
  ];
});