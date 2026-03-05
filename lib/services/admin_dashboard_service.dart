import 'dart:convert';
import '../core/config/supabase_config.dart';
import '../models/admin_dashboard_stats.dart';

class AdminDashboardService {
  Future<AdminDashboardStats> load() async {
    final client = SupabaseConfig.client;

    // NOTE: This project uses a Supabase Dart client version where FetchOptions/CountOption
    // are not available. We count by selecting ids and using list lengths.

    // Pending verifications
    final pendingVerificationsRows = await client
        .from('verification_requests')
        .select('id')
        .eq('status', 'pending');
    final pendingVerifications = (pendingVerificationsRows as List).length;

    // Open support tickets (stored as JSON blob in local_storage)
    int openSupportTickets = 0;
    try {
      final ticketsRow = await client
          .from('local_storage')
          .select('value')
          .eq('key', 'support_tickets')
          .maybeSingle();
      if (ticketsRow != null && ticketsRow['value'] != null) {
        final List<dynamic> ticketsList = json.decode(ticketsRow['value'] as String);
        openSupportTickets = ticketsList.where((t) {
          final status = t['status'] as String?;
          return status == 'open' || status == 'in_progress';
        }).length;
      }
    } catch (_) {}

    // Total bookings
    final totalBookingsRows = await client.from('bookings').select('id');
    final totalBookings = (totalBookingsRows as List).length;

    // Pending payments: submitted by customer, awaiting admin verification
    final pendingPaymentsRows = await client
        .from('payments')
        .select('id')
        .eq('status', 'pending_verification');
    final pendingPayments = (pendingPaymentsRows as List).length;

    // Bookings today
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final bookingsTodayRows = await client
        .from('bookings')
        .select('id')
        .gte('created_at', startOfDay.toIso8601String())
        .lte('created_at', endOfDay.toIso8601String());
    final bookingsToday = (bookingsTodayRows as List).length;

    // Users totals by role
    final customersRows =
        await client.from('users').select('id').eq('role', 'customer');
    final totalCustomers = (customersRows as List).length;

    final techsRows =
        await client.from('users').select('id').eq('role', 'technician');
    final totalTechnicians = (techsRows as List).length;

    return AdminDashboardStats(
      pendingVerifications: pendingVerifications,
      openSupportTickets: openSupportTickets,
      totalBookings: totalBookings,
      bookingsToday: bookingsToday,
      totalCustomers: totalCustomers,
      totalTechnicians: totalTechnicians,
      pendingPayments: pendingPayments,
    );
  }
}
