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
    await _supabase.rpc('set_booking_status', params: {
      'p_booking_id': bookingId,
      'p_status': status,
      'p_cancel_reason': cancellationReason,
      'p_cancel_fee': cancellationFee,
    });
    await _syncTechnicianBusy(bookingId, status);
    await _syncJobRequestStatus(bookingId, status);
  }
  Future<void> _syncTechnicianBusy(String bookingId, String newStatus) async {
    try {
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
        await _supabase
            .from(DBConstants.technicianProfiles)
            .update({'is_busy': true})
            .filter('user_id::text', 'eq', techUserId);
      } else if (newStatus == AppConstants.bookingCompleted ||
                 newStatus == AppConstants.bookingPaid ||
                 newStatus == AppConstants.bookingClosed ||
                 newStatus == AppConstants.bookingCancelled ||
                 newStatus == AppConstants.bookingCancellationPending) {
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
    }
  }
  Future<void> _syncJobRequestStatus(String bookingId, String newStatus) async {
    try {
      final isTerminal = newStatus == AppConstants.bookingCompleted ||
          newStatus == AppConstants.bookingPaid ||
          newStatus == AppConstants.bookingClosed;
      final isCancelled = newStatus == AppConstants.bookingCancelled;
      if (!isTerminal && !isCancelled) return;
      final row = await _supabase
          .from(DBConstants.bookings)
          .select('customer_id, technician_id, booking_source')
          .filter('id::text', 'eq', bookingId)
          .maybeSingle();
      if (row == null || row['booking_source'] != 'post_problem') return;
      final customerId = row['customer_id'] as String?;
      final technicianId = row['technician_id'] as String?;
      if (customerId == null || technicianId == null) return;
      await _supabase
          .from('job_requests')
          .update({'status': isTerminal ? 'completed' : 'cancelled'})
          .eq('customer_id', customerId)
          .eq('technician_id', technicianId)
          .eq('status', 'accepted');
    } catch (_) {
    }
  }
  Future<void> updateDiagnosticNotes({
    required String bookingId,
    required String notes,
    List<String>? partsList,
    double? finalCost,
  }) async {
    String updatedNotes = notes;
    final updates = <String, dynamic>{};
    if (partsList != null) updates['parts_list'] = partsList;
    if (finalCost != null) {
      final booking = await getBookingById(bookingId);
      final discountStr = booking?.discountAmount;
      if (discountStr != null) {
        double effectiveCost;
        if (discountStr.endsWith('%')) {
          final pct = double.tryParse(discountStr.replaceAll('%', '').trim()) ?? 0.0;
          effectiveCost = finalCost * (1 - pct / 100);
        } else {
          final fixed = double.tryParse(
                  discountStr.replaceAll('₱', '').replaceAll(',', '').trim()) ??
              0.0;
          effectiveCost = (finalCost - fixed).clamp(0.0, double.infinity);
        }
        updatedNotes = updatedNotes.replaceFirst(
          RegExp(r'Original Price: ₱[\d.]+'),
          'Original Price: ₱${finalCost.toStringAsFixed(2)}',
        );
        updates['final_cost'] = effectiveCost;
      } else {
        updates['final_cost'] = finalCost;
      }
    }
    updates['diagnostic_notes'] = updatedNotes;
    await _supabase
        .from(DBConstants.bookings)
        .update(updates)
        .filter('id::text', 'eq', bookingId);
  }
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
  Future<void> addTechnicianNotes({
    required String bookingId,
    required String technicianNotes,
    double? priceAdjustment,
  }) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) return;
    String updatedNotes = booking.diagnosticNotes ?? '';
    final parts = updatedNotes.split('---TECHNICIAN NOTES---');
    final customerDetails = parts[0].trim();
    final existingTechNotes = parts.length > 1 ? parts[1].trim() : '';
    if (technicianNotes.isNotEmpty) {
      final combined = existingTechNotes.isNotEmpty
          ? '$existingTechNotes\n$technicianNotes'
          : technicianNotes;
      updatedNotes = '$customerDetails\n\n---TECHNICIAN NOTES---\n$combined';
    } else {
      updatedNotes = existingTechNotes.isNotEmpty
          ? '$customerDetails\n\n---TECHNICIAN NOTES---\n$existingTechNotes'
          : customerDetails;
    }
    final updates = <String, dynamic>{
      'diagnostic_notes': updatedNotes,
    };
    if (priceAdjustment != null && priceAdjustment != 0) {
      final promoCode = booking.promoCode;
      final discountAmountStr = booking.discountAmount;
      final originalPriceStr = booking.originalPrice;
      if (promoCode != null && discountAmountStr != null && originalPriceStr != null) {
        final originalPrice = double.tryParse(originalPriceStr.replaceAll('₱', '').replaceAll(',', '').trim()) ?? 0.0;
        final newOriginalPrice = originalPrice + priceAdjustment;
        if (discountAmountStr.contains('%')) {
          final percentageStr = discountAmountStr.replaceAll('%', '').trim();
          final percentage = double.tryParse(percentageStr) ?? 0.0;
          final discountAmount = newOriginalPrice * (percentage / 100);
          final newFinalCost = newOriginalPrice - discountAmount;
          updates['final_cost'] = newFinalCost > 0 ? newFinalCost : 0.0;
          updatedNotes = updatedNotes.replaceFirst(
            RegExp(r'Original Price: ₱[\d.]+'),
            'Original Price: ₱${newOriginalPrice.toStringAsFixed(2)}'
          );
        } else {
          final fixedDiscount = double.tryParse(discountAmountStr.replaceAll('₱', '').replaceAll(',', '').trim()) ?? 0.0;
          final newFinalCost = newOriginalPrice - fixedDiscount;
          updates['final_cost'] = newFinalCost > 0 ? newFinalCost : 0.0;
          updatedNotes = updatedNotes.replaceFirst(
            RegExp(r'Original Price: ₱[\d.]+'),
            'Original Price: ₱${newOriginalPrice.toStringAsFixed(2)}'
          );
        }
        updates['diagnostic_notes'] = updatedNotes;
      } else {
        final currentCost = booking.finalCost ?? booking.estimatedCost ?? 0.0;
        final newFinalCost = currentCost + priceAdjustment;
        updates['final_cost'] = newFinalCost > 0 ? newFinalCost : 0.0;
      }
    }
    await _supabase
        .from(DBConstants.bookings)
        .update(updates)
        .filter('id::text', 'eq', bookingId);
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
  Stream<BookingModel?> watchBookingById(String bookingId) {
    return _supabase
        .from(DBConstants.bookings)
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .map((data) => data.isEmpty ? null : BookingModel.fromJson(data.first));
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
  Stream<List<BookingModel>> watchPostProblemBookings() {
    return _supabase
        .from(DBConstants.bookings)
        .stream(primaryKey: ['id'])
        .eq('booking_source', 'post_problem')
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((e) => BookingModel.fromJson(e)).toList());
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