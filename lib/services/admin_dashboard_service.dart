import '../core/config/supabase_config.dart';
import '../models/admin_dashboard_stats.dart';
class AdminDashboardService {
  Future<AdminDashboardStats> load() async {
    final client = SupabaseConfig.client;
    final pendingVerificationsRows = await client
        .from('verification_requests')
        .select('id')
        .eq('status', 'pending');
    final pendingVerifications = (pendingVerificationsRows as List).length;
    int openSupportTickets = 0;
    try {
      final openTicketsRows = await client
          .from('support_tickets')
          .select('id')
          .or('status.eq.open,status.eq.in_progress');
      openSupportTickets = (openTicketsRows as List).length;
    } catch (_) {}
    final totalBookingsRows = await client.from('bookings').select('id');
    final totalBookings = (totalBookingsRows as List).length;
    final pendingPaymentsRows = await client
        .from('payments')
        .select('id')
        .eq('status', 'pending_verification');
    final pendingPayments = (pendingPaymentsRows as List).length;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final bookingsTodayRows = await client
        .from('bookings')
        .select('id')
        .gte('created_at', startOfDay.toIso8601String())
        .lte('created_at', endOfDay.toIso8601String());
    final bookingsToday = (bookingsTodayRows as List).length;
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