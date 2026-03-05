import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking_model.dart';
import 'booking_provider.dart';

/// Range selection for transaction filtering in the technician earnings screen.
enum EarningsRange { week, month, all }

/// UI state for selected range.
final selectedEarningsRangeProvider = StateProvider<EarningsRange>((ref) {
  return EarningsRange.week;
});

/// Advanced filter state for transaction history.
class EarningsFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? minAmount;
  final double? maxAmount;
  final bool? emergencyOnly; // null = both, true = emergency only, false = regular only
  final EarningsSortOrder sort;

  const EarningsFilter({
    this.fromDate,
    this.toDate,
    this.minAmount,
    this.maxAmount,
    this.emergencyOnly,
    this.sort = EarningsSortOrder.newest,
  });

  bool get isActive =>
      fromDate != null ||
      toDate != null ||
      minAmount != null ||
      maxAmount != null ||
      emergencyOnly != null ||
      sort != EarningsSortOrder.newest;

  EarningsFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
    bool? emergencyOnly,
    EarningsSortOrder? sort,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearMin = false,
    bool clearMax = false,
    bool clearEmergency = false,
  }) {
    return EarningsFilter(
      fromDate: clearFrom ? null : (fromDate ?? this.fromDate),
      toDate: clearTo ? null : (toDate ?? this.toDate),
      minAmount: clearMin ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMax ? null : (maxAmount ?? this.maxAmount),
      emergencyOnly: clearEmergency ? null : (emergencyOnly ?? this.emergencyOnly),
      sort: sort ?? this.sort,
    );
  }
}

enum EarningsSortOrder { newest, oldest, highest, lowest }

final earningsFilterProvider = StateProvider<EarningsFilter>((ref) => const EarningsFilter());

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

/// Returns the most relevant date for a completed booking (completed > scheduled > created).
DateTime _transactionDate(BookingModel b) =>
    b.completedAt ?? b.scheduledDate ?? b.createdAt;

/// Filters transactions by [selectedEarningsRangeProvider] (quick tabs).
/// If the advanced filter has a custom date range set, it overrides the tab cutoff.
final filteredTransactionsProvider = FutureProvider<List<BookingModel>>((ref) async {
  final range = ref.watch(selectedEarningsRangeProvider);
  final filter = ref.watch(earningsFilterProvider);
  final transactions = await ref.watch(transactionsProvider.future);

  final now = DateTime.now();

  var result = transactions.toList();

  // If no custom date filter, apply the tab cutoff
  if (filter.fromDate == null && filter.toDate == null && range != EarningsRange.all) {
    final DateTime cutoff = switch (range) {
      EarningsRange.week => now.subtract(const Duration(days: 7)),
      EarningsRange.month => DateTime(now.year, now.month, 1),
      EarningsRange.all => now, // unreachable due to guard above
    };
    result = result.where((b) => _transactionDate(b).isAfter(cutoff)).toList();
  }

  // Apply advanced filters — custom date range overrides tab
  if (filter.fromDate != null) {
    final from = DateTime(filter.fromDate!.year, filter.fromDate!.month, filter.fromDate!.day);
    result = result.where((b) => !_transactionDate(b).isBefore(from)).toList();
  }
  if (filter.toDate != null) {
    final to = DateTime(filter.toDate!.year, filter.toDate!.month, filter.toDate!.day, 23, 59, 59);
    result = result.where((b) => !_transactionDate(b).isAfter(to)).toList();
  }
  if (filter.minAmount != null) {
    result = result.where((b) => _bookingAmount(b) >= filter.minAmount!).toList();
  }
  if (filter.maxAmount != null) {
    result = result.where((b) => _bookingAmount(b) <= filter.maxAmount!).toList();
  }
  if (filter.emergencyOnly != null) {
    result = result.where((b) => b.isEmergency == filter.emergencyOnly).toList();
  }

  // Sort
  result.sort((a, b) {
    switch (filter.sort) {
      case EarningsSortOrder.oldest:
        return _transactionDate(a).compareTo(_transactionDate(b));
      case EarningsSortOrder.highest:
        return _bookingAmount(b).compareTo(_bookingAmount(a));
      case EarningsSortOrder.lowest:
        return _bookingAmount(a).compareTo(_bookingAmount(b));
      case EarningsSortOrder.newest:
        return _transactionDate(b).compareTo(_transactionDate(a));
    }
  });

  return result;
});

final totalEarningsProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  return transactions.fold<double>(0.0, (sum, b) => sum + _bookingAmount(b));
});

final todayEarningsProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final now = DateTime.now();

  final todayTx = transactions.where((b) => _isSameDay(_transactionDate(b), now));
  return todayTx.fold<double>(0.0, (sum, b) => sum + _bookingAmount(b));
});

final weekEarningsProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  final weekTx = transactions.where((b) => _transactionDate(b).isAfter(weekAgo));
  return weekTx.fold<double>(0.0, (sum, b) => sum + _bookingAmount(b));
});

final monthEarningsProvider = FutureProvider<double>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);

  final monthTx = transactions.where((b) => _transactionDate(b).isAfter(monthStart));
  return monthTx.fold<double>(0.0, (sum, b) => sum + _bookingAmount(b));
});
