import 'package:uuid/uuid.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/db_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/technician_verification_guard.dart';
import '../services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  // Optional ref for enforcing technician verification in write operations.
  Ref? _ref;

  BookingService({Ref? ref}) {
    _ref = ref;
  }

  Future<BookingModel> createBooking({
    required String customerId,
    required String technicianId,
    required String serviceId,
    DateTime? scheduledDate,
    String? customerAddress,
    double? customerLatitude,
    double? customerLongitude,
    double? estimatedCost,
    String? paymentMethod,
    String? status,
    String bookingSource = 'booking',
  }) async {
    final bookingId = _uuid.v4();

    final response = await _supabase.from(DBConstants.bookings).insert({
      'id': bookingId,
      'customer_id': customerId,
      'technician_id': technicianId,
      'service_id': serviceId,
      'status': status ?? AppConstants.bookingRequested,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'customer_address': customerAddress,
      'customer_latitude': customerLatitude,
      'customer_longitude': customerLongitude,
      'estimated_cost': estimatedCost,
      'payment_method': paymentMethod,
      'payment_status': 'pending',
      'booking_source': bookingSource,
    }).select().single();

    return BookingModel.fromJson(response);
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? cancellationReason,
    double? cancellationFee,
  }) async {
    if (_ref != null) {
      await TechnicianVerificationGuard.requireVerifiedForWrite(_ref!);
    }

    // Use an RPC function so the WHERE clause is UUID = UUID (no type-cast
    // ambiguity that causes "operator does not exist: uuid = text").
    await _supabase.rpc('set_booking_status', params: {
      'p_booking_id': bookingId,
      'p_status': status,
      'p_cancel_reason': cancellationReason,
      'p_cancel_fee': cancellationFee,
    });

    // Auto-update technician busy status based on active booking count.
    await _syncTechnicianBusy(bookingId, status);
  }

  Future<void> _syncTechnicianBusy(String bookingId, String newStatus) async {
    try {
      // Fetch the technician_id for this booking
      final row = await _supabase
          .from(DBConstants.bookings)
          .select('technician_id')
          .filter('id::text', 'eq', bookingId)
          .maybeSingle();
      if (row == null) return;
      final techUserId = row['technician_id'] as String?;
      if (techUserId == null) return;

      if (newStatus == AppConstants.bookingAccepted ||
          newStatus == AppConstants.bookingEnRoute ||
          newStatus == AppConstants.bookingArrived ||
          newStatus == AppConstants.bookingInProgress) {
        // Technician is now working — mark busy
        await _supabase
            .from(DBConstants.technicianProfiles)
            .update({'is_busy': true})
            .filter('user_id::text', 'eq', techUserId);
      } else if (newStatus == AppConstants.bookingCompleted ||
                 newStatus == AppConstants.bookingPaid ||
                 newStatus == AppConstants.bookingClosed ||
                 newStatus == AppConstants.bookingCancelled ||
                 newStatus == AppConstants.bookingCancellationPending) {
        // Only clear busy if there are no other active bookings
        final active = await _supabase
            .from(DBConstants.bookings)
            .select('id')
            .filter('technician_id::text', 'eq', techUserId)
            .inFilter('status', [
              AppConstants.bookingAccepted,
              AppConstants.bookingInProgress,
            ])
            .filter('id::text', 'neq', bookingId);
        if ((active as List).isEmpty) {
          await _supabase
              .from(DBConstants.technicianProfiles)
              .update({'is_busy': false})
              .filter('user_id::text', 'eq', techUserId);
        }
      }
    } catch (_) {
      // Non-critical — the Supabase trigger handles this server-side too
    }
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
        .filter('id::text', 'eq', bookingId);
  }

  /// Update booking details (notes and price adjustment)
  Future<void> updateBookingDetails({
    required String bookingId,
    String? technicianNotes,
    double? priceAdjustment,
  }) async {
    final updates = <String, dynamic>{};

    if (technicianNotes != null && technicianNotes.isNotEmpty) {
      updates['diagnostic_notes'] = technicianNotes;
    }

    if (priceAdjustment != null) {
      // Get current booking to calculate new final cost
      final booking = await getBookingById(bookingId);
      if (booking != null) {
        final currentCost = booking.estimatedCost ?? 0.0;
        final newFinalCost = currentCost + priceAdjustment;
        updates['final_cost'] = newFinalCost > 0 ? newFinalCost : 0.0;
      }
    }

    if (updates.isNotEmpty) {
      await _supabase
          .from(DBConstants.bookings)
          .update(updates)
          .filter('id::text', 'eq', bookingId);
    }
  }

  /// Add technician notes to existing booking (preserves customer details)
  Future<void> addTechnicianNotes({
    required String bookingId,
    required String technicianNotes,
    double? priceAdjustment,
  }) async {
    // Get current booking
    final booking = await getBookingById(bookingId);
    if (booking == null) return;

    // Get existing diagnostic notes (customer's original booking details)
    String updatedNotes = booking.diagnosticNotes ?? '';

    // Remove old technician notes if they exist
    final parts = updatedNotes.split('---TECHNICIAN NOTES---');
    final customerDetails = parts[0].trim();

    // Append new technician notes with separator
    if (technicianNotes.isNotEmpty) {
      updatedNotes = '$customerDetails\n\n---TECHNICIAN NOTES---\n$technicianNotes';
    } else {
      updatedNotes = customerDetails;
    }

    final updates = <String, dynamic>{
      'diagnostic_notes': updatedNotes,
    };

    // Handle price adjustment if provided - MAINTAIN DISCOUNT
    if (priceAdjustment != null && priceAdjustment != 0) {
      // Check if there's a discount applied
      final promoCode = booking.promoCode;
      final discountAmountStr = booking.discountAmount;
      final originalPriceStr = booking.originalPrice;

      if (promoCode != null && discountAmountStr != null && originalPriceStr != null) {
        // There's a discount - we need to maintain it
        // Parse original price
        final originalPrice = double.tryParse(originalPriceStr.replaceAll('₱', '').replaceAll(',', '').trim()) ?? 0.0;

        // Calculate new original price (before discount)
        final newOriginalPrice = originalPrice + priceAdjustment;

        // Determine if it's a percentage or fixed discount
        if (discountAmountStr.contains('%')) {
          // Percentage discount
          final percentageStr = discountAmountStr.replaceAll('%', '').trim();
          final percentage = double.tryParse(percentageStr) ?? 0.0;

          // Apply percentage to new original price
          final discountAmount = newOriginalPrice * (percentage / 100);
          final newFinalCost = newOriginalPrice - discountAmount;

          updates['final_cost'] = newFinalCost > 0 ? newFinalCost : 0.0;

          // Update the diagnostic notes with new prices
          updatedNotes = updatedNotes.replaceFirst(
            RegExp(r'Original Price: ₱[\d.]+'),
            'Original Price: ₱${newOriginalPrice.toStringAsFixed(2)}'
          );
        } else {
          // Fixed amount discount
          final fixedDiscount = double.tryParse(discountAmountStr.replaceAll('₱', '').replaceAll(',', '').trim()) ?? 0.0;
          final newFinalCost = newOriginalPrice - fixedDiscount;

          updates['final_cost'] = newFinalCost > 0 ? newFinalCost : 0.0;

          // Update the diagnostic notes with new price
          updatedNotes = updatedNotes.replaceFirst(
            RegExp(r'Original Price: ₱[\d.]+'),
            'Original Price: ₱${newOriginalPrice.toStringAsFixed(2)}'
          );
        }

        // Update the notes with the corrected prices
        updates['diagnostic_notes'] = updatedNotes;
      } else {
        // No discount - just add the adjustment
        final currentCost = booking.finalCost ?? booking.estimatedCost ?? 0.0;
        final newFinalCost = currentCost + priceAdjustment;
        updates['final_cost'] = newFinalCost > 0 ? newFinalCost : 0.0;
      }
    }

    await _supabase
        .from(DBConstants.bookings)
        .update(updates)
        .filter('id::text', 'eq', bookingId);

    // Notify customer if price was adjusted
    if (priceAdjustment != null && priceAdjustment != 0) {
      final newCost = (updates['final_cost'] as num?)?.toDouble()
          ?? (booking.finalCost ?? booking.estimatedCost ?? 0.0) + priceAdjustment;
      final direction = priceAdjustment > 0 ? 'increased' : 'decreased';
      await NotificationService().sendNotification(
        userId: booking.customerId,
        type: 'price_updated',
        title: 'Price Updated',
        message: 'Your repair cost has been $direction to ₱${newCost.toStringAsFixed(2)} by the technician.',
        data: {'booking_id': bookingId, 'route': '/booking/$bookingId'},
      );
    }
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
        .filter('id::text', 'eq', bookingId)
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
    }).filter('id::text', 'eq', bookingId);
  }

  Stream<List<BookingModel>> watchCustomerBookings(String customerId) {
    AppLogger.p('🔍 BOOKING SERVICE: Starting stream for customer $customerId');

    return _supabase
        .from(DBConstants.bookings)
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .map((data) {
          AppLogger.p('🔍 BOOKING SERVICE: Received ${data.length} bookings from Supabase for customer');
          final bookings = data.map((e) => BookingModel.fromJson(e)).toList();
          for (var booking in bookings) {
            AppLogger.p('  📋 Customer Booking ${booking.id}: ${booking.status}');
          }
          return bookings;
        });
  }

  Stream<List<BookingModel>> watchTechnicianBookings(String technicianId) {
    AppLogger.p('🔍 BOOKING SERVICE: Starting stream for technician $technicianId');

    return _supabase
        .from(DBConstants.bookings)
        .stream(primaryKey: ['id'])
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false)
        .map((data) {
          AppLogger.p('🔍 BOOKING SERVICE: Received ${data.length} bookings from Supabase');
          final bookings = data.map((e) => BookingModel.fromJson(e)).toList();
          for (var booking in bookings) {
            AppLogger.p('  📋 Booking ${booking.id}: ${booking.status}');
          }
          return bookings;
        });
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
        .filter('id::text', 'eq', bookingId);
  }
}
