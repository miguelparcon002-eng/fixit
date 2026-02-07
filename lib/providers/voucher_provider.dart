import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voucher_service.dart';
import '../models/redeemed_voucher.dart';
import 'auth_provider.dart';
import 'rewards_provider.dart';

final voucherServiceProvider = Provider((ref) => VoucherService());

// Provider to check if profile setup is complete
final profileSetupCompleteProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return false;

  // Check if user has profile_setup_complete flag set
  return user.profileSetupComplete ?? false;
});

// Alias for backwards compatibility - use unusedVouchersProvider from rewards_provider
final validVouchersProvider = FutureProvider<List<RedeemedVoucher>>((ref) async {
  return await ref.watch(unusedVouchersProvider.future);
});
