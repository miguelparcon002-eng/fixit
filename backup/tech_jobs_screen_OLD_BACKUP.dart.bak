import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';

class TechJobsScreen extends ConsumerStatefulWidget {
  const TechJobsScreen({super.key});

  @override
  ConsumerState<TechJobsScreen> createState() => _TechJobsScreenState();
}

class _TechJobsScreenState extends ConsumerState<TechJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Helper to check if booking belongs to this technician
  bool _isBookingForTechnician(String bookingTechnician, String userName) {
    // Match if:
    // 1. Exact match (booking.technician == userName)
    // 2. Booking technician is contained in user's full name (e.g., "Estino" in "Ethan Estino")
    // 3. User's last name matches booking technician
    final userNameLower = userName.toLowerCase();
    final bookingTechLower = bookingTechnician.toLowerCase();

    if (bookingTechLower == userNameLower) return true;
    if (userNameLower.contains(bookingTechLower)) return true;

    // Check if last name matches
    final nameParts = userName.split(' ');
    if (nameParts.length > 1) {
      final lastName = nameParts.last.toLowerCase();
      if (lastName == bookingTechLower) return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Method to switch to completed tab - can be called from anywhere
  void switchToCompletedTab() {
    _tabController.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    // Get current user data
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.whenOrNull(data: (user) => user?.fullName) ?? 'Technician';
    final userAddress = userAsync.whenOrNull(data: (user) => user?.address) ?? '';

    return Scaffold(
      backgroundColor: AppTheme.deepBlue,
      body: Column(
        children: [
          // Profile Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.deepBlue, AppTheme.lightBlue],
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FixIT Technician',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: const Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      userAddress.isNotEmpty ? userAddress : 'Location not set',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Main Content with Tabs
          Expanded(
            child: Container(
              color: AppTheme.primaryCyan,
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search jobs...',
                        prefixIcon: const Icon(Icons.search, color: Colors.black54),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.black54),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Custom Tab Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.black,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(text: 'Request'),
                          Tab(text: 'Active'),
                          Tab(text: 'Completed'),
                          Tab(text: 'All'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Request Jobs - Display bookings for Estino
                        _buildRequestJobsList(),
                        // Active Jobs - Display in-progress bookings for Estino
                        _buildActiveJobsList(),
                        // Completed Jobs - Display completed bookings for Estino
                        _buildCompletedJobsList(),
                        // All Jobs - Show all jobs combined
                        _buildAllJobsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestJobsList() {
    final localBookings = ref.watch(localBookingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.whenOrNull(data: (user) => user?.fullName) ?? 'Technician';

    // Filter bookings for this technician only with "Scheduled" status
    final techBookings = localBookings.where((booking) =>
      _isBookingForTechnician(booking.technician, userName) && booking.status == 'Scheduled'
    ).toList();

    if (techBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No job requests at the moment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: techBookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = techBookings[index];
        return _RequestJobCard(booking: booking);
      },
    );
  }

  Widget _buildActiveJobsList() {
    final localBookings = ref.watch(localBookingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.whenOrNull(data: (user) => user?.fullName) ?? 'Technician';

    // Filter bookings for this technician only with "In Progress" status
    final activeBookings = localBookings.where((booking) =>
      _isBookingForTechnician(booking.technician, userName) && booking.status == 'In Progress'
    ).toList();

    if (activeBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No active jobs at the moment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: activeBookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = activeBookings[index];
        return _ActiveJobCard(
          booking: booking,
          tabController: _tabController,
        );
      },
    );
  }

  Widget _buildCompletedJobsList() {
    final localBookings = ref.watch(localBookingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.whenOrNull(data: (user) => user?.fullName) ?? 'Technician';

    // Filter bookings for this technician only with "Completed" status
    final completedBookings = localBookings.where((booking) =>
      _isBookingForTechnician(booking.technician, userName) && booking.status == 'Completed'
    ).toList();

    if (completedBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No completed jobs yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: completedBookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = completedBookings[index];
        return _CompletedJobCard(booking: booking);
      },
    );
  }

  Widget _buildAllJobsList() {
    final localBookings = ref.watch(localBookingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.whenOrNull(data: (user) => user?.fullName) ?? 'Technician';

    // Filter all bookings for this technician
    final allBookings = localBookings.where((booking) =>
      _isBookingForTechnician(booking.technician, userName)
    ).toList();

    if (allBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No jobs at the moment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: allBookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = allBookings[index];
        // Show different card based on status
        if (booking.status == 'Scheduled') {
          return _RequestJobCard(booking: booking);
        } else if (booking.status == 'In Progress') {
          return _ActiveJobCard(booking: booking, tabController: _tabController);
        } else if (booking.status == 'Completed') {
          return _CompletedJobCard(booking: booking);
        }
        // Default fallback
        return _RequestJobCard(booking: booking);
      },
    );
  }

}

class _RequestJobCard extends ConsumerWidget {
  final LocalBooking booking;

  const _RequestJobCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Map priority to color
    Color priorityColor;
    String priorityText;
    switch (booking.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        priorityText = 'HIGH';
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityText = 'MEDIUM';
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityText = 'LOW';
        break;
      default:
        priorityColor = Colors.grey;
        priorityText = 'NORMAL';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              booking.id,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priorityText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.deviceName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            booking.serviceName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${booking.date} at ${booking.time}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            booking.customerPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (booking.moreDetails != null && booking.moreDetails!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking.moreDetails!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Discount information (if applicable)
                if (booking.promoCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          booking.promoCode!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(-${booking.discountAmount})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Original:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        booking.originalPrice ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.promoCode != null ? 'Final Total:' : 'Total:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            booking.total,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Accept the booking - change status to "In Progress"
                            ref.read(localBookingsProvider.notifier).updateBookingStatus(booking.id, 'In Progress');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Booking ${booking.id} accepted!'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            // Decline the booking - remove it from the list
                            ref.read(localBookingsProvider.notifier).removeBooking(booking.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Booking ${booking.id} declined'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveJobCard extends ConsumerWidget {
  final LocalBooking booking;
  final TabController tabController;

  const _ActiveJobCard({required this.booking, required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Map priority to color
    Color priorityColor;
    String priorityText;
    switch (booking.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        priorityText = 'HIGH';
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityText = 'MEDIUM';
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityText = 'LOW';
        break;
      default:
        priorityColor = Colors.grey;
        priorityText = 'NORMAL';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person, color: AppTheme.lightBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              booking.id,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priorityText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.deviceName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            booking.serviceName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${booking.date} at ${booking.time}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            booking.customerPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (booking.moreDetails != null && booking.moreDetails!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking.moreDetails!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Discount information (if applicable)
                if (booking.promoCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          booking.promoCode!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(-${booking.discountAmount})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Original:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        booking.originalPrice ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.promoCode != null ? 'Final Total:' : 'Total:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            booking.total,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: AppTheme.lightBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            // Show dialog to add additional charges or details
                            _showEditBookingDialog(context, ref, booking);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            // Capture references BEFORE showing the dialog
                            final bookingNotifier = ref.read(localBookingsProvider.notifier);
                            final bookingId = booking.id;
                            final parentContext = context;
                            final controller = tabController;

                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: const Text('Mark as Complete'),
                                  content: Text('Are you sure you want to mark booking $bookingId as complete?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Close dialog first
                                        Navigator.of(dialogContext).pop();

                                        // Mark booking as completed using captured notifier
                                        await bookingNotifier.updateBookingStatus(bookingId, 'Completed');

                                        // Show success message
                                        if (parentContext.mounted) {
                                          ScaffoldMessenger.of(parentContext).showSnackBar(
                                            SnackBar(
                                              content: Text('Booking $bookingId marked as complete!'),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );

                                          // Switch to Completed tab (index 2)
                                          controller.animateTo(2);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Mark Complete',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedJobCard extends StatelessWidget {
  final LocalBooking booking;

  const _CompletedJobCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    // Map priority to color
    Color priorityColor;
    String priorityText;
    switch (booking.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        priorityText = 'HIGH';
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityText = 'MEDIUM';
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityText = 'LOW';
        break;
      default:
        priorityColor = Colors.grey;
        priorityText = 'NORMAL';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              booking.id,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priorityText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.deviceName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            booking.serviceName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${booking.date} at ${booking.time}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (booking.moreDetails != null && booking.moreDetails!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Customer: ${booking.moreDetails!}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (booking.technicianNotes != null && booking.technicianNotes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.engineering, size: 16, color: Colors.black),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Technician Notes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      booking.technicianNotes!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Discount information (if applicable)
                if (booking.promoCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_offer, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          booking.promoCode!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(-${booking.discountAmount})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Original:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        booking.originalPrice ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.promoCode != null ? 'Final Total:' : 'Total:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            booking.total,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showEditBookingDialog(BuildContext context, WidgetRef ref, LocalBooking booking) {
  // Capture the notifier reference IMMEDIATELY before showing dialog
  // This prevents the _dependents.isEmpty error
  final bookingNotifier = ref.read(localBookingsProvider.notifier);

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return _EditBookingDialog(
        booking: booking,
        bookingNotifier: bookingNotifier,
        parentContext: context,
      );
    },
  );
}

class _EditBookingDialog extends StatefulWidget {
  final LocalBooking booking;
  final LocalBookingNotifier bookingNotifier;
  final BuildContext parentContext;

  const _EditBookingDialog({
    required this.booking,
    required this.bookingNotifier,
    required this.parentContext,
  });

  @override
  State<_EditBookingDialog> createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends State<_EditBookingDialog> {
  late TextEditingController _additionalNotesController;
  late TextEditingController _additionalChargeController;

  @override
  void initState() {
    super.initState();
    _additionalNotesController = TextEditingController(text: widget.booking.technicianNotes ?? '');
    _additionalChargeController = TextEditingController();
  }

  @override
  void dispose() {
    _additionalNotesController.dispose();
    _additionalChargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return AlertDialog(
      title: const Text(
        'Edit Booking Details',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Found additional issues? Update the booking with extra charges and details.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 20),
            // Show customer's original notes if they exist
            if (booking.moreDetails != null && booking.moreDetails!.isNotEmpty) ...[
              const Text(
                'Customer Notes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppTheme.deepBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.moreDetails!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Technician Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _additionalNotesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe additional issues found (e.g., battery also needs replacement)',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Price Adjustment (₱)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _additionalChargeController,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter amount (use - for discount)',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Colors.grey[50],
                prefixText: '₱ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use positive values to increase price, negative values to decrease (e.g., -100 for ₱100 discount)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleUpdateBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.deepBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update Booking'),
        ),
      ],
    );
  }

  void _handleUpdateBooking() {
    final booking = widget.booking;

    // Parse current total (final price after any discount)
    final currentTotalStr = booking.total.replaceAll('₱', '').replaceAll(',', '').trim();
    final currentTotal = double.tryParse(currentTotalStr) ?? 0.0;

    // Parse additional charge
    final additionalCharge = double.tryParse(_additionalChargeController.text.trim()) ?? 0.0;

    // Calculate new base price (before discount)
    double newOriginalPrice = currentTotal + additionalCharge;
    double newFinalTotal = currentTotal + additionalCharge;
    String? newDiscountAmount = booking.discountAmount;

    if (booking.promoCode != null && booking.originalPrice != null) {
      // Parse original price
      final originalPriceStr = booking.originalPrice!.replaceAll('₱', '').replaceAll(',', '').trim();
      final originalPrice = double.tryParse(originalPriceStr) ?? 0.0;

      // Calculate discount percentage/amount from original booking
      final discountAmountStr = booking.discountAmount?.replaceAll('₱', '').replaceAll(',', '').trim() ?? '0';
      final discountAmount = double.tryParse(discountAmountStr) ?? 0.0;

      // New original price = old original price + additional charge
      newOriginalPrice = originalPrice + additionalCharge;

      // Apply the same discount to the new original price
      if (discountAmount > 0) {
        final discountRatio = discountAmount / originalPrice;

        if (discountRatio > 0 && discountRatio < 1) {
          final newDiscount = newOriginalPrice * discountRatio;
          newFinalTotal = newOriginalPrice - newDiscount;
          newDiscountAmount = '₱${newDiscount.toStringAsFixed(0)}';
        } else {
          newFinalTotal = newOriginalPrice - discountAmount;
          newDiscountAmount = booking.discountAmount;
        }
      }
    }

    // Update technician notes
    String updatedTechnicianNotes = _additionalNotesController.text.trim();
    if (updatedTechnicianNotes.isNotEmpty && additionalCharge != 0) {
      if (additionalCharge > 0) {
        updatedTechnicianNotes += '\n\n[Additional charge: ₱${additionalCharge.toStringAsFixed(0)} for extra repairs]';
      } else {
        updatedTechnicianNotes += '\n\n[Price reduced by ₱${(-additionalCharge).toStringAsFixed(0)} as compensation]';
      }
    }

    // Create updated booking
    final updatedBooking = LocalBooking(
      id: booking.id,
      icon: booking.icon,
      status: booking.status,
      deviceName: booking.deviceName,
      serviceName: booking.serviceName,
      date: booking.date,
      time: booking.time,
      location: booking.location,
      technician: booking.technician,
      total: '₱${newFinalTotal.toStringAsFixed(0)}',
      customerName: booking.customerName,
      customerPhone: booking.customerPhone,
      priority: booking.priority,
      moreDetails: booking.moreDetails,
      technicianNotes: updatedTechnicianNotes.isNotEmpty ? updatedTechnicianNotes : booking.technicianNotes,
      promoCode: booking.promoCode,
      discountAmount: newDiscountAmount,
      originalPrice: booking.promoCode != null ? '₱${newOriginalPrice.toStringAsFixed(0)}' : null,
    );

    // Store message for later
    final message = additionalCharge > 0
        ? 'Booking updated with additional charge of ₱${additionalCharge.toStringAsFixed(0)}'
        : additionalCharge < 0
          ? 'Booking updated with price reduction of ₱${(-additionalCharge).toStringAsFixed(0)}'
          : 'Booking notes updated';

    // Close dialog first
    Navigator.of(context).pop();

    // Use addPostFrameCallback to update AFTER the dialog is fully closed
    // This prevents the _dependents.isEmpty error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.bookingNotifier.updateBooking(updatedBooking);

      // Show success message using the parent context
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }
}
