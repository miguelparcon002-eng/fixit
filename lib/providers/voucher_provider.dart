import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voucher_service.dart';
import '../models/redeemed_voucher.dart';
import 'auth_provider.dart';
import 'rewards_provider.dart';
final voucherServiceProvider = Provider((ref) => VoucherService());
final profileSetupCompleteProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return false;
  return user.profileSetupComplete ?? false;
});
final validVouchersProvider = FutureProvider<List<RedeemedVoucher>>((ref) async {
  return await ref.watch(unusedVouchersProvider.future);
});