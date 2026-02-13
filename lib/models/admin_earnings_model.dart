/// Model for tracking earnings at the platform level
class AdminEarningsOverview {
  final double totalEarnings;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final int totalCompletedBookings;
  final int todayCompletedBookings;
  final int weekCompletedBookings;
  final int monthCompletedBookings;

  const AdminEarningsOverview({
    required this.totalEarnings,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.totalCompletedBookings,
    required this.todayCompletedBookings,
    required this.weekCompletedBookings,
    required this.monthCompletedBookings,
  });
}

/// Model for tracking individual technician earnings
class TechnicianEarnings {
  final String technicianId;
  final String technicianName;
  final String? technicianEmail;
  final String? technicianPhone;
  final String? profileImageUrl;
  final double totalEarnings;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final int totalCompletedJobs;
  final int todayCompletedJobs;
  final int weekCompletedJobs;
  final int monthCompletedJobs;
  final double? averageRating;
  final String? gcashNumber;
  final String? gcashName;

  const TechnicianEarnings({
    required this.technicianId,
    required this.technicianName,
    this.technicianEmail,
    this.technicianPhone,
    this.profileImageUrl,
    required this.totalEarnings,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.totalCompletedJobs,
    required this.todayCompletedJobs,
    required this.weekCompletedJobs,
    required this.monthCompletedJobs,
    this.averageRating,
    this.gcashNumber,
    this.gcashName,
  });
}

/// Model for individual transaction/booking earnings
class EarningsTransaction {
  final String bookingId;
  final String technicianId;
  final String technicianName;
  final String customerId;
  final String customerName;
  final String serviceName;
  final double amount;
  final DateTime completedAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final bool isEmergency;

  const EarningsTransaction({
    required this.bookingId,
    required this.technicianId,
    required this.technicianName,
    required this.customerId,
    required this.customerName,
    required this.serviceName,
    required this.amount,
    required this.completedAt,
    this.paymentMethod,
    this.paymentStatus,
    required this.isEmergency,
  });
}

/// Model for customer spending analytics
class CustomerSpending {
  final String customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final double totalSpent;
  final double todaySpent;
  final double weekSpent;
  final double monthSpent;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;

  const CustomerSpending({
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.totalSpent,
    required this.todaySpent,
    required this.weekSpent,
    required this.monthSpent,
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
  });
}
