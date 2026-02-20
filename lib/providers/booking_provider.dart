import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'auth_provider.dart';
import '../core/utils/app_logger.dart';

final bookingServiceProvider = Provider((ref) => BookingService(ref: ref));

final bookingByIdProvider = FutureProvider.family<BookingModel?, String>((ref, bookingId) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getBookingById(bookingId);
});

final customerBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  // Wait for user to load
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      AppLogger.p('📱 CUSTOMER BOOKINGS PROVIDER: Watching bookings for ${user.id}');
      return bookingService.watchCustomerBookings(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final technicianBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  final userAsync = ref.watch(currentUserProvider);

  // Wait for user to load
  return userAsync.when(
    data: (user) {
      AppLogger.p('🔍 TECHNICIAN BOOKINGS PROVIDER: User = ${user?.id ?? "null"}');
      
      if (user == null) {
        AppLogger.p('⚠️ TECHNICIAN BOOKINGS PROVIDER: No user, returning empty stream');
        return Stream.value([]);
      }

      AppLogger.p('✅ TECHNICIAN BOOKINGS PROVIDER: Watching bookings for ${user.id}');
      return bookingService.watchTechnicianBookings(user.id);
    },
    loading: () {
      AppLogger.p('⏳ TECHNICIAN BOOKINGS PROVIDER: User loading...');
      return Stream.value([]);
    },
    error: (error, stack) {
      AppLogger.p('❌ TECHNICIAN BOOKINGS PROVIDER: Error loading user: $error');
      return Stream.value([]);
    },
  );
});

class BookingsByStatusParams {
  final String status;
  final bool isTechnician;

  BookingsByStatusParams({required this.status, required this.isTechnician});
}

final bookingsByStatusProvider = FutureProvider.family<List<BookingModel>, BookingsByStatusParams>((ref, params) async {
  final bookingService = ref.watch(bookingServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await bookingService.getBookingsByStatus(
    userId: user.id,
    status: params.status,
    isTechnician: params.isTechnician,
  );
});
