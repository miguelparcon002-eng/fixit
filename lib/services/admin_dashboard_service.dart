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

    // Open support tickets
    final openTicketsRows = await client
        .from('support_tickets')
        .select('id')
        .inFilter('status', ['open', 'in_progress']);
    final openSupportTickets = (openTicketsRows as List).length;

    // Total bookings
    final totalBookingsRows = await client.from('bookings').select('id');
    final totalBookings = (totalBookingsRows as List).length;

    // Bookings today
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final bookingsTodayRows = await client
        .from('bookings')
        .select('id')
        .gte('created_at', startOfDay.toIso8601String());
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
    );
  }
}
