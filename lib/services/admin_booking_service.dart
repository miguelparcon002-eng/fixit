import '../core/config/supabase_config.dart';
import '../models/admin_booking_view.dart';
import '../models/booking_model.dart';

class AdminBookingService {
  Future<List<AdminBookingView>> listBookings() async {
    final client = SupabaseConfig.client;

    final rows = await client
        .from('bookings')
        .select('*, '
            'customer:users!bookings_customer_id_fkey(full_name, contact_number), '
            'technician:users!bookings_technician_id_fkey(full_name, contact_number), '
            'service:services!bookings_service_id_fkey(service_name)')
        .order('created_at', ascending: false);

    final list = (rows as List).cast<Map<String, dynamic>>();

    return list.map(_mapRow).toList();
  }

  Future<List<AdminBookingView>> listBookingsForCustomer(String customerId) async {
    final client = SupabaseConfig.client;

    final rows = await client
        .from('bookings')
        .select('*, '
            'customer:users!bookings_customer_id_fkey(full_name, contact_number), '
            'technician:users!bookings_technician_id_fkey(full_name, contact_number), '
            'service:services!bookings_service_id_fkey(service_name)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.map(_mapRow).toList();
  }

  Future<List<AdminBookingView>> listBookingsForTechnician(String technicianId) async {
    final client = SupabaseConfig.client;

    final rows = await client
        .from('bookings')
        .select('*, '
            'customer:users!bookings_customer_id_fkey(full_name, contact_number), '
            'technician:users!bookings_technician_id_fkey(full_name, contact_number), '
            'service:services!bookings_service_id_fkey(service_name)')
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false);

    final list = (rows as List).cast<Map<String, dynamic>>();
    return list.map(_mapRow).toList();
  }

  AdminBookingView _mapRow(Map<String, dynamic> r) {
    final booking = BookingModel.fromJson(r);
    final customer = (r['customer'] as Map?)?.cast<String, dynamic>();
    final technician = (r['technician'] as Map?)?.cast<String, dynamic>();
    final service = (r['service'] as Map?)?.cast<String, dynamic>();

    return AdminBookingView(
      booking: booking,
      customerName: (customer?['full_name'] as String?) ?? booking.customerId,
      technicianName:
          (technician?['full_name'] as String?) ?? booking.technicianId,
      serviceName: (service?['service_name'] as String?) ?? booking.serviceId,
    );
  }
}
