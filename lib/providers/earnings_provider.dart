import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_model.dart';
import 'booking_provider.dart';

/// Range selection for transaction filtering in the technician earnings screen.
enum EarningsRange { week, month }

/// UI state for selected range.
final selectedEarningsRangeProvider = StateProvider<EarningsRange>((ref) {
  return EarningsRange.week;
});

bool _isCompleted(BookingModel b) {
  return b.status.toLowerCase() == 'completed';
}

double _bookingAmount(BookingModel b) {
  // Prefer final cost; fallback to estimated.
  final finalCost = b.finalCost;
  if (finalCost != null) return finalCost.toDouble();
  final estimated = b.estimatedCost;
  if (estimated != null) return estimated.toDouble();
  return 0.0;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Completed bookings (transactions) for the current technician.
///
/// Kept as a FutureProvider so UI can use `.when(...)`.
final transactionsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final bookings = await ref.watch(technicianBookingsProvider.future);
  return bookings.where(_isCompleted).toList();
});

/// Filters transactions by [selectedEarningsRangeProvider].
final filteredTransactionsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final range = ref.watch(selectedEarningsRangeProvider);
  final transactions = await ref.watch(transactionsProvider.future);

  final now = DateTime.now();
  final DateTime cutoff = switch (range) {
    EarningsRange.week => now.subtract(const Duration(days: 7)),
    EarningsRange.month => DateTime(now.year, now.month, 1),
  };

  return transactions.where((b) {
    return b.createdAt.isAfter(cutoff);
  }).toList();
});

final totalEarningsProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  return transactions.fold<double>(0.0, (sum, b) => sum + _bookingAmount(b));
});

final todayEarningsProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final now = DateTime.now();

  final todayTx = transactions.where((b) {
    return _isSameDay(b.createdAt, now);
  });

  return todayTx.fold<double>(0.0, (sum, b) => sum + _bookingAmount(b));
});

final weekEarningsProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  final weekTx = transactions.where((b) {
    return b.createdAt.isAfter(weekAgo);
  });

  return weekTx.fold<double>(0.0, (sum, b) => sum + _bookingAmount(b));
});

final monthEarningsProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);

  final monthTx = transactions.where((b) {
    return b.createdAt.isAfter(monthStart);
  });

  return monthTx.fold<double>(0.0, (sum, b) => sum + _bookingAmount(b));
});
