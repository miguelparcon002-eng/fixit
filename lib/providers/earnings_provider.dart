import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/earnings_service.dart';

final earningsServiceProvider = Provider((ref) => EarningsService());

// Use StateNotifier to hold earnings state that can be refreshed
class TodayEarningsNotifier extends StateNotifier<AsyncValue<double>> {
  final EarningsService _earningsService;

  TodayEarningsNotifier(this._earningsService) : super(const AsyncValue.loading()) {
    loadEarnings();
  }

  Future<void> loadEarnings() async {
    state = const AsyncValue.loading();
    try {
      final earnings = await _earningsService.getTodayEarnings();
      state = AsyncValue.data(earnings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reload earnings data (called when user changes)
  Future<void> reload() async {
    state = const AsyncValue.loading();
    await loadEarnings();
  }

  Future<void> addEarning(double amount, String customerName, String service, String jobId) async {
    try {
      await _earningsService.addEarning(amount, customerName, service, jobId);
      await loadEarnings(); // Reload after adding
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final todayEarningsProvider = StateNotifierProvider<TodayEarningsNotifier, AsyncValue<double>>((ref) {
  final earningsService = ref.watch(earningsServiceProvider);
  return TodayEarningsNotifier(earningsService);
});

final totalEarningsProvider = FutureProvider<double>((ref) async {
  final earningsService = ref.watch(earningsServiceProvider);
  return await earningsService.getTotalEarnings();
});

final weekEarningsProvider = FutureProvider<double>((ref) async {
  final earningsService = ref.watch(earningsServiceProvider);
  return await earningsService.getWeekEarnings();
});

final monthEarningsProvider = FutureProvider<double>((ref) async {
  final earningsService = ref.watch(earningsServiceProvider);
  return await earningsService.getMonthEarnings();
});

final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final earningsService = ref.watch(earningsServiceProvider);
  return await earningsService.getTransactions();
});
