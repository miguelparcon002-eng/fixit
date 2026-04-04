class AdminDashboardStats {
  final int pendingVerifications;
  final int openSupportTickets;
  final int totalBookings;
  final int bookingsToday;
  final int totalCustomers;
  final int totalTechnicians;
  final int pendingPayments;
  const AdminDashboardStats({
    required this.pendingVerifications,
    required this.openSupportTickets,
    required this.totalBookings,
    required this.bookingsToday,
    required this.totalCustomers,
    required this.totalTechnicians,
    required this.pendingPayments,
  });
}