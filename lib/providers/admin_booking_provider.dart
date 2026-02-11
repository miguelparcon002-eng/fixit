import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_booking_view.dart';
import '../services/admin_booking_service.dart';

final adminBookingServiceProvider = Provider((ref) => AdminBookingService());

final adminBookingsProvider = FutureProvider<List<AdminBookingView>>((ref) async {
  final svc = ref.watch(adminBookingServiceProvider);
  return svc.listBookings();
});

final adminBookingsByCustomerProvider = FutureProvider.family<List<AdminBookingView>, String>((ref, customerId) async {
  final svc = ref.watch(adminBookingServiceProvider);
  return svc.listBookingsForCustomer(customerId);
});

final adminBookingsByTechnicianProvider = FutureProvider.family<List<AdminBookingView>, String>((ref, technicianId) async {
  final svc = ref.watch(adminBookingServiceProvider);
  return svc.listBookingsForTechnician(technicianId);
});
