import '../core/config/supabase_config.dart';
import '../models/admin_earnings_model.dart';

class AdminEarningsService {
  final _client = SupabaseConfig.client;

  /// Get overall platform earnings overview
  Future<AdminEarningsOverview> getEarningsOverview() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toUtc();
    final startOfWeek = now.subtract(Duration(days: 7)).toUtc();
    final startOfMonth = DateTime(now.year, now.month, 1).toUtc();

    // Fetch all completed bookings
    final bookingsData = await _client
        .from('bookings')
        .select('final_cost, estimated_cost, completed_at, created_at')
        .eq('status', 'completed');

    final bookings = bookingsData as List;

    double totalEarnings = 0;
    double todayEarnings = 0;
    double weekEarnings = 0;
    double monthEarnings = 0;
    int totalCount = bookings.length;
    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;

    for (var booking in bookings) {
      final amount = (booking['final_cost'] ?? booking['estimated_cost'] ?? 0).toDouble();
      totalEarnings += amount;

      final completedAt = booking['completed_at'] != null
          ? DateTime.parse(booking['completed_at'])
          : DateTime.parse(booking['created_at']);

      if (completedAt.isAfter(startOfToday)) {
        todayEarnings += amount;
        todayCount++;
      }
      if (completedAt.isAfter(startOfWeek)) {
        weekEarnings += amount;
        weekCount++;
      }
      if (completedAt.isAfter(startOfMonth)) {
        monthEarnings += amount;
        monthCount++;
      }
    }

    return AdminEarningsOverview(
      totalEarnings: totalEarnings,
      todayEarnings: todayEarnings,
      weekEarnings: weekEarnings,
      monthEarnings: monthEarnings,
      totalCompletedBookings: totalCount,
      todayCompletedBookings: todayCount,
      weekCompletedBookings: weekCount,
      monthCompletedBookings: monthCount,
    );
  }

  /// Get earnings for all technicians
  Future<List<TechnicianEarnings>> getAllTechniciansEarnings() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toUtc();
    final startOfWeek = now.subtract(Duration(days: 7)).toUtc();
    final startOfMonth = DateTime(now.year, now.month, 1).toUtc();

    // Fetch all technicians
    final techniciansData = await _client
        .from('users')
        .select('id, full_name, email, contact_number, profile_picture')
        .eq('role', 'technician');

    final technicians = techniciansData as List;
    final List<TechnicianEarnings> earningsList = [];

    for (var tech in technicians) {
      final techId = tech['id'] as String;

      // Fetch all completed bookings for this technician
      final bookingsData = await _client
          .from('bookings')
          .select('final_cost, estimated_cost, completed_at, created_at')
          .eq('technician_id', techId)
          .eq('status', 'completed');

      final bookings = bookingsData as List;

      // Fetch average rating
      final ratingsData = await _client
          .from('bookings')
          .select('rating')
          .eq('technician_id', techId)
          .not('rating', 'is', null);

      double? averageRating;
      final ratingsList = ratingsData as List;
      if (ratingsList.isNotEmpty) {
        final ratings = ratingsList.map((r) => (r['rating'] as num).toDouble()).toList();
        averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }

      double totalEarnings = 0;
      double todayEarnings = 0;
      double weekEarnings = 0;
      double monthEarnings = 0;
      int totalJobs = bookings.length;
      int todayJobs = 0;
      int weekJobs = 0;
      int monthJobs = 0;

      for (var booking in bookings) {
        final amount = (booking['final_cost'] ?? booking['estimated_cost'] ?? 0).toDouble();
        totalEarnings += amount;

        final completedAt = booking['completed_at'] != null
            ? DateTime.parse(booking['completed_at'])
            : DateTime.parse(booking['created_at']);

        if (completedAt.isAfter(startOfToday)) {
          todayEarnings += amount;
          todayJobs++;
        }
        if (completedAt.isAfter(startOfWeek)) {
          weekEarnings += amount;
          weekJobs++;
        }
        if (completedAt.isAfter(startOfMonth)) {
          monthEarnings += amount;
          monthJobs++;
        }
      }

      earningsList.add(TechnicianEarnings(
        technicianId: techId,
        technicianName: tech['full_name'] ?? 'Unknown',
        technicianEmail: tech['email'],
        technicianPhone: tech['contact_number'],
        profileImageUrl: tech['profile_picture'],
        totalEarnings: totalEarnings,
        todayEarnings: todayEarnings,
        weekEarnings: weekEarnings,
        monthEarnings: monthEarnings,
        totalCompletedJobs: totalJobs,
        todayCompletedJobs: todayJobs,
        weekCompletedJobs: weekJobs,
        monthCompletedJobs: monthJobs,
        averageRating: averageRating,
        gcashNumber: null,
        gcashName: null,
      ));
    }

    // Sort by total earnings descending
    earningsList.sort((a, b) => b.totalEarnings.compareTo(a.totalEarnings));

    return earningsList;
  }

  /// Get earnings for a specific technician
  Future<TechnicianEarnings> getTechnicianEarnings(String technicianId) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toUtc();
    final startOfWeek = now.subtract(Duration(days: 7)).toUtc();
    final startOfMonth = DateTime(now.year, now.month, 1).toUtc();

    // Fetch technician info
    final techData = await _client
        .from('users')
        .select('id, full_name, email, contact_number, profile_picture')
        .eq('id', technicianId)
        .single();

    // Fetch all completed bookings
    final bookingsData = await _client
        .from('bookings')
        .select('final_cost, estimated_cost, completed_at, created_at')
        .eq('technician_id', technicianId)
        .eq('status', 'completed');

    final bookings = bookingsData as List;

    // Fetch average rating
    final ratingsData = await _client
        .from('bookings')
        .select('rating')
        .eq('technician_id', technicianId)
        .not('rating', 'is', null);

    double? averageRating;
    final ratingsList = ratingsData as List;
    if (ratingsList.isNotEmpty) {
      final ratings = ratingsList.map((r) => (r['rating'] as num).toDouble()).toList();
      averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
    }

    double totalEarnings = 0;
    double todayEarnings = 0;
    double weekEarnings = 0;
    double monthEarnings = 0;
    int totalJobs = bookings.length;
    int todayJobs = 0;
    int weekJobs = 0;
    int monthJobs = 0;

    for (var booking in bookings) {
      final amount = (booking['final_cost'] ?? booking['estimated_cost'] ?? 0).toDouble();
      totalEarnings += amount;

      final completedAt = booking['completed_at'] != null
          ? DateTime.parse(booking['completed_at'])
          : DateTime.parse(booking['created_at']);

      if (completedAt.isAfter(startOfToday)) {
        todayEarnings += amount;
        todayJobs++;
      }
      if (completedAt.isAfter(startOfWeek)) {
        weekEarnings += amount;
        weekJobs++;
      }
      if (completedAt.isAfter(startOfMonth)) {
        monthEarnings += amount;
        monthJobs++;
      }
    }

    return TechnicianEarnings(
      technicianId: technicianId,
      technicianName: techData['full_name'] ?? 'Unknown',
      technicianEmail: techData['email'],
      technicianPhone: techData['contact_number'],
      profileImageUrl: techData['profile_picture'],
      totalEarnings: totalEarnings,
      todayEarnings: todayEarnings,
      weekEarnings: weekEarnings,
      monthEarnings: monthEarnings,
      totalCompletedJobs: totalJobs,
      todayCompletedJobs: todayJobs,
      weekCompletedJobs: weekJobs,
      monthCompletedJobs: monthJobs,
      averageRating: averageRating,
      gcashNumber: null,
      gcashName: null,
    );
  }

  /// Get transaction history for a specific technician
  Future<List<EarningsTransaction>> getTechnicianTransactions(String technicianId) async {
    final bookingsData = await _client
        .from('bookings')
        .select('''
          id,
          technician_id,
          customer_id,
          service_id,
          final_cost,
          estimated_cost,
          completed_at,
          created_at,
          payment_method,
          payment_status,
          is_emergency
        ''')
        .eq('technician_id', technicianId)
        .eq('status', 'completed')
        .order('completed_at', ascending: false);

    final bookings = bookingsData as List;
    final List<EarningsTransaction> transactions = [];

    for (var booking in bookings) {
      // Fetch customer name
      final customerData = await _client
          .from('users')
          .select('full_name')
          .eq('id', booking['customer_id'])
          .maybeSingle();

      // Fetch technician name
      final techData = await _client
          .from('users')
          .select('full_name')
          .eq('id', booking['technician_id'])
          .maybeSingle();

      // Fetch service name
      final serviceData = await _client
          .from('services')
          .select('name')
          .eq('id', booking['service_id'])
          .maybeSingle();

      final amount = (booking['final_cost'] ?? booking['estimated_cost'] ?? 0).toDouble();
      final completedAt = booking['completed_at'] != null
          ? DateTime.parse(booking['completed_at'])
          : DateTime.parse(booking['created_at']);

      transactions.add(EarningsTransaction(
        bookingId: booking['id'],
        technicianId: booking['technician_id'],
        technicianName: techData?['full_name'] ?? 'Unknown',
        customerId: booking['customer_id'],
        customerName: customerData?['full_name'] ?? 'Unknown',
        serviceName: serviceData?['name'] ?? 'Unknown Service',
        amount: amount,
        completedAt: completedAt,
        paymentMethod: booking['payment_method'],
        paymentStatus: booking['payment_status'],
        isEmergency: booking['is_emergency'] ?? false,
      ));
    }

    return transactions;
  }

  /// Get customer spending data
  Future<List<CustomerSpending>> getAllCustomersSpending() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toUtc();
    final startOfWeek = now.subtract(Duration(days: 7)).toUtc();
    final startOfMonth = DateTime(now.year, now.month, 1).toUtc();

    // Fetch all customers
    final customersData = await _client
        .from('users')
        .select('id, full_name, email, contact_number')
        .eq('role', 'customer');

    final customers = customersData as List;
    final List<CustomerSpending> spendingList = [];

    for (var customer in customers) {
      final customerId = customer['id'] as String;

      // Fetch all bookings for this customer
      final allBookingsData = await _client
          .from('bookings')
          .select('id, status')
          .eq('customer_id', customerId);

      final allBookings = allBookingsData as List;
      final totalBookings = allBookings.length;
      final completedBookings = allBookings.where((b) => b['status'] == 'completed').length;
      final cancelledBookings = allBookings.where((b) => b['status'] == 'cancelled').length;

      // Fetch completed bookings with costs
      final bookingsData = await _client
          .from('bookings')
          .select('final_cost, estimated_cost, completed_at, created_at')
          .eq('customer_id', customerId)
          .eq('status', 'completed');

      final bookings = bookingsData as List;

      double totalSpent = 0;
      double todaySpent = 0;
      double weekSpent = 0;
      double monthSpent = 0;

      for (var booking in bookings) {
        final amount = (booking['final_cost'] ?? booking['estimated_cost'] ?? 0).toDouble();
        totalSpent += amount;

        final completedAt = booking['completed_at'] != null
            ? DateTime.parse(booking['completed_at'])
            : DateTime.parse(booking['created_at']);

        if (completedAt.isAfter(startOfToday)) {
          todaySpent += amount;
        }
        if (completedAt.isAfter(startOfWeek)) {
          weekSpent += amount;
        }
        if (completedAt.isAfter(startOfMonth)) {
          monthSpent += amount;
        }
      }

      spendingList.add(CustomerSpending(
        customerId: customerId,
        customerName: customer['full_name'] ?? 'Unknown',
        customerEmail: customer['email'],
        customerPhone: customer['contact_number'],
        totalSpent: totalSpent,
        todaySpent: todaySpent,
        weekSpent: weekSpent,
        monthSpent: monthSpent,
        totalBookings: totalBookings,
        completedBookings: completedBookings,
        cancelledBookings: cancelledBookings,
      ));
    }

    // Sort by total spent descending
    spendingList.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    return spendingList;
  }
}
