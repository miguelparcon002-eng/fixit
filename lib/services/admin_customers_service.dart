import '../core/config/supabase_config.dart';
import '../models/admin_customer_user.dart';

class AdminCustomersService {
  Future<List<AdminCustomerUser>> listCustomers() async {
    final client = SupabaseConfig.client;

    // Load customers
    final rows = await client
        .from('users')
        .select('id, full_name, email, contact_number, address, city, verified, is_suspended, profile_picture, created_at')
        .eq('role', 'customer')
        .order('created_at', ascending: false);

    // Determine activity: "Active" = has any booking created within last 7 days.
    final since = DateTime.now().toUtc().subtract(const Duration(days: 7));
    final recentBookings = await client
        .from('bookings')
        .select('customer_id, created_at')
        .gte('created_at', since.toIso8601String());

    final lastBookingByCustomer = <String, DateTime>{};
    for (final r in (recentBookings as List).cast<Map<String, dynamic>>()) {
      final cid = r['customer_id'] as String?;
      final created = r['created_at'] as String?;
      if (cid == null || created == null) continue;
      final dt = DateTime.tryParse(created);
      if (dt == null) continue;
      final existing = lastBookingByCustomer[cid];
      if (existing == null || dt.isAfter(existing)) {
        lastBookingByCustomer[cid] = dt;
      }
    }

    return (rows as List).cast<Map<String, dynamic>>().map((u) {
      final id = u['id'] as String;
      return AdminCustomerUser.fromJson({
        ...u,
        'last_booking_at': lastBookingByCustomer[id]?.toIso8601String(),
      });
    }).toList();
  }

  Future<AdminCustomerUser?> getCustomer(String customerId) async {
    final client = SupabaseConfig.client;

    final row = await client
        .from('users')
        .select('id, full_name, email, contact_number, address, city, verified, is_suspended, profile_picture, created_at')
        .eq('id', customerId)
        .maybeSingle();

    if (row == null) return null;

    // Last booking within last 7 days (for active/inactive display)
    final since = DateTime.now().toUtc().subtract(const Duration(days: 7));
    final recent = await client
        .from('bookings')
        .select('created_at')
        .eq('customer_id', customerId)
        .gte('created_at', since.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return AdminCustomerUser.fromJson({
      ...row,
      'last_booking_at': recent?['created_at'],
    });
  }
}
