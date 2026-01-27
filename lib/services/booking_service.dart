import 'package:uuid/uuid.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/db_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/booking_model.dart';

class BookingService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  Future<BookingModel> createBooking({
    required String customerId,
    required String technicianId,
    required String serviceId,
    DateTime? scheduledDate,
    String? customerAddress,
    double? customerLatitude,
    double? customerLongitude,
    double? estimatedCost,
  }) async {
    final bookingId = _uuid.v4();

    final response = await _supabase.from(DBConstants.bookings).insert({
      'id': bookingId,
      'customer_id': customerId,
      'technician_id': technicianId,
      'service_id': serviceId,
      'status': AppConstants.bookingRequested,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'customer_address': customerAddress,
      'customer_latitude': customerLatitude,
      'customer_longitude': customerLongitude,
      'estimated_cost': estimatedCost,
      'payment_status': 'pending',
    }).select().single();

    return BookingModel.fromJson(response);
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? cancellationReason,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
    };

    if (status == AppConstants.bookingAccepted) {
      updates['accepted_at'] = DateTime.now().toIso8601String();
    } else if (status == AppConstants.bookingCompleted) {
      updates['completed_at'] = DateTime.now().toIso8601String();
    } else if (status == AppConstants.bookingCancelled) {
      updates['cancelled_at'] = DateTime.now().toIso8601String();
      if (cancellationReason != null) {
        updates['cancellation_reason'] = cancellationReason;
      }
    }

    await _supabase
        .from(DBConstants.bookings)
        .update(updates)
        .eq('id', bookingId);
  }

  Future<void> updateDiagnosticNotes({
    required String bookingId,
    required String notes,
    List<String>? partsList,
    double? finalCost,
  }) async {
    final updates = <String, dynamic>{
      'diagnostic_notes': notes,
    };

    if (partsList != null) updates['parts_list'] = partsList;
    if (finalCost != null) updates['final_cost'] = finalCost;

    await _supabase
        .from(DBConstants.bookings)
        .update(updates)
        .eq('id', bookingId);
  }

  Future<List<BookingModel>> getCustomerBookings(String customerId) async {
    final response = await _supabase
        .from(DBConstants.bookings)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => BookingModel.fromJson(e)).toList();
  }

  Future<List<BookingModel>> getTechnicianBookings(String technicianId) async {
    final response = await _supabase
        .from(DBConstants.bookings)
        .select()
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => BookingModel.fromJson(e)).toList();
  }

  Future<List<BookingModel>> getBookingsByStatus({
    required String userId,
    required String status,
    bool isTechnician = false,
  }) async {
    final field = isTechnician ? 'technician_id' : 'customer_id';

    final response = await _supabase
        .from(DBConstants.bookings)
        .select()
        .eq(field, userId)
        .eq('status', status)
        .order('created_at', ascending: false);

    return (response as List).map((e) => BookingModel.fromJson(e)).toList();
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    final response = await _supabase
        .from(DBConstants.bookings)
        .select()
        .eq('id', bookingId)
        .single();

    return BookingModel.fromJson(response);
  }

  Future<void> rateBooking({
    required String bookingId,
    required int rating,
    String? review,
  }) async {
    await _supabase.from(DBConstants.bookings).update({
      'rating': rating,
      'review': review,
    }).eq('id', bookingId);
  }

  Stream<List<BookingModel>> watchCustomerBookings(String customerId) {
    return _supabase
        .from(DBConstants.bookings)
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => BookingModel.fromJson(e)).toList());
  }

  Stream<List<BookingModel>> watchTechnicianBookings(String technicianId) {
    return _supabase
        .from(DBConstants.bookings)
        .stream(primaryKey: ['id'])
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => BookingModel.fromJson(e)).toList());
  }

  Future<void> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
    String? paymentMethod,
  }) async {
    final updates = <String, dynamic>{
      'payment_status': paymentStatus,
    };

    if (paymentMethod != null) {
      updates['payment_method'] = paymentMethod;
    }

    await _supabase
        .from(DBConstants.bookings)
        .update(updates)
        .eq('id', bookingId);
  }
}
