import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voucher_service.dart';

final voucherServiceProvider = Provider((ref) => VoucherService());

// Provider to check if profile setup is complete
final profileSetupCompleteProvider = FutureProvider<bool>((ref) async {
  final voucherService = ref.watch(voucherServiceProvider);
  return await voucherService.isProfileSetupComplete();
});

// Provider for all vouchers
final vouchersProvider = FutureProvider<List<Voucher>>((ref) async {
  final voucherService = ref.watch(voucherServiceProvider);
  return await voucherService.getVouchers();
});

// Provider for valid vouchers only
final validVouchersProvider = FutureProvider<List<Voucher>>((ref) async {
  final voucherService = ref.watch(voucherServiceProvider);
  return await voucherService.getValidVouchers();
});

// StateNotifier for managing voucher state with actions
class VoucherNotifier extends StateNotifier<AsyncValue<List<Voucher>>> {
  final VoucherService _voucherService;

  VoucherNotifier(this._voucherService) : super(const AsyncValue.loading()) {
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      final vouchers = await _voucherService.getVouchers();
      state = AsyncValue.data(vouchers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    await _loadVouchers();
  }

  Future<Voucher> createWelcomeVoucher() async {
    final voucher = await _voucherService.createWelcomeVoucher();
    await _loadVouchers();
    return voucher;
  }

  Future<void> useVoucher(String voucherId) async {
    await _voucherService.useVoucher(voucherId);
    await _loadVouchers();
  }
}

final voucherNotifierProvider = StateNotifierProvider<VoucherNotifier, AsyncValue<List<Voucher>>>((ref) {
  final voucherService = ref.watch(voucherServiceProvider);
  return VoucherNotifier(voucherService);
});
