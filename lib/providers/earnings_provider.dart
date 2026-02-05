import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/earnings_service.dart';
import 'booking_provider.dart';
import 'auth_provider.dart';

final earningsServiceProvider = Provider((ref) => EarningsService());

// Provider for total earnings calculated from Supabase bookings
final totalEarningsProvider = FutureProvider<double>((ref) async {
  final bookingsAsync = await ref.watch(technicianBookingsProvider.future);

  double total = 0.0;
  for (final booking in bookingsAsync) {
    if (booking.status == 'completed') {
      total += (booking.finalCost ?? booking.estimatedCost ?? 0.0);
    }
  }

  print('TotalEarningsProvider: Calculated ₱$total from Supabase completed bookings');
  return total;
});

// Provider for today's earnings calculated from Supabase bookings
final todayEarningsProvider = FutureProvider<double>((ref) async {
  final bookingsAsync = await ref.watch(technicianBookingsProvider.future);
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  double total = 0.0;
  for (final booking in bookingsAsync) {
    if (booking.status == 'completed' && booking.completedAt != null) {
      final completedDate = booking.completedAt!;
      if (completedDate.isAfter(todayStart) && completedDate.isBefore(todayEnd)) {
        total += (booking.finalCost ?? booking.estimatedCost ?? 0.0);
      }
    }
  }

  print('TodayEarningsProvider: Calculated ₱$total for today from Supabase');
  return total;
});

// Provider for this week's earnings calculated from Supabase bookings
final weekEarningsProvider = FutureProvider<double>((ref) async {
  final bookingsAsync = await ref.watch(technicianBookingsProvider.future);
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

  double total = 0.0;
  for (final booking in bookingsAsync) {
    if (booking.status == 'completed' && booking.completedAt != null) {
      if (!booking.completedAt!.isBefore(startOfWeekDate)) {
        total += (booking.finalCost ?? booking.estimatedCost ?? 0.0);
      }
    }
  }

  print('WeekEarningsProvider: Calculated ₱$total for this week from Supabase');
  return total;
});

// Provider for this month's earnings calculated from Supabase bookings
final monthEarningsProvider = FutureProvider<double>((ref) async {
  final bookingsAsync = await ref.watch(technicianBookingsProvider.future);
  final now = DateTime.now();

  double total = 0.0;
  for (final booking in bookingsAsync) {
    if (booking.status == 'completed' && booking.completedAt != null) {
      final completedDate = booking.completedAt!;
      if (completedDate.year == now.year && completedDate.month == now.month) {
        total += (booking.finalCost ?? booking.estimatedCost ?? 0.0);
      }
    }
  }

  print('MonthEarningsProvider: Calculated ₱$total for this month from Supabase');
  return total;
});

// Provider for transactions list from Supabase bookings
final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final bookingsAsync = await ref.watch(technicianBookingsProvider.future);

  final transactions = <Map<String, dynamic>>[];
  for (final booking in bookingsAsync) {
    if (booking.status == 'completed') {
      transactions.add({
        'id': booking.id,
        'customer_name': 'Customer', // BookingModel doesn't have customer name, would need to fetch
        'service': booking.serviceId,
        'job_id': booking.id,
        'amount': (booking.finalCost ?? booking.estimatedCost ?? 0.0),
        'created_at': (booking.completedAt ?? booking.createdAt).toIso8601String(),
      });
    }
  }

  // Sort by date descending
  transactions.sort((a, b) {
    final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
    final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
    return dateB.compareTo(dateA);
  });

  print('TransactionsProvider: Found ${transactions.length} transactions from Supabase');
  return transactions;
});

// Provider for jobs completed count from Supabase bookings
final jobsCompletedProvider = FutureProvider<int>((ref) async {
  final bookingsAsync = await ref.watch(technicianBookingsProvider.future);

  int count = 0;
  for (final booking in bookingsAsync) {
    if (booking.status == 'completed') {
      count++;
    }
  }

  print('JobsCompletedProvider: Found $count completed jobs from Supabase');
  return count;
});
