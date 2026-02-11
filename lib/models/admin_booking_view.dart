import 'booking_model.dart';

class AdminBookingView {
  final BookingModel booking;
  final String customerName;
  final String technicianName;
  final String serviceName;

  const AdminBookingView({
    required this.booking,
    required this.customerName,
    required this.technicianName,
    required this.serviceName,
  });
}
