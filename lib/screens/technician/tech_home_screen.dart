import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../providers/auth_provider.dart';
import 'tech_ratings_screen.dart';

class TechHomeScreen extends ConsumerWidget {
  const TechHomeScreen({super.key});

  static void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '2 New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _NotificationItem(
                    icon: Icons.assignment_outlined,
                    iconColor: AppTheme.lightBlue,
                    iconBgColor: AppTheme.lightBlue.withValues(alpha: 0.1),
                    title: 'New Job Assignment',
                    message: 'You have been assigned to repair an iPhone 15 Pro for John Smith. Service needed: Screen Replacement.',
                    time: '5 min ago',
                    isNew: true,
                  ),
                  const SizedBox(height: 12),
                  _NotificationItem(
                    icon: Icons.schedule,
                    iconColor: Colors.orange,
                    iconBgColor: Colors.orange.withValues(alpha: 0.1),
                    title: 'Upcoming Job Reminder',
                    message: 'You have a job scheduled at 2:30 PM today. Don\'t forget to check the job details and prepare accordingly.',
                    time: '30 min ago',
                    isNew: true,
                  ),
                  const SizedBox(height: 12),
                  _NotificationItem(
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                    iconBgColor: Colors.green.withValues(alpha: 0.1),
                    title: 'Job Completed',
                    message: 'Great work! MacBook Pro screen repair has been marked as completed. Payment of ₱299 has been processed.',
                    time: '2 hours ago',
                    isNew: false,
                  ),
                  const SizedBox(height: 12),
                  _NotificationItem(
                    icon: Icons.account_balance_wallet,
                    iconColor: AppTheme.deepBlue,
                    iconBgColor: AppTheme.deepBlue.withValues(alpha: 0.1),
                    title: 'Payment Received',
                    message: 'Payment of ₱189 for Samsung Galaxy S23 Screen repair has been deposited to your account.',
                    time: 'Yesterday',
                    isNew: false,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to check if booking belongs to this technician
  static bool _isBookingForTechnician(String bookingTechnician, String userName) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user data
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.whenOrNull(data: (user) => user?.fullName) ?? 'Technician';
    final userAddress = userAsync.whenOrNull(data: (user) => user?.address) ?? '';

    // Get bookings and filter for this technician
    final localBookings = ref.watch(localBookingsProvider);
    final techScheduledCount = localBookings.where((booking) =>
      _isBookingForTechnician(booking.technician, userName) && booking.status == 'Scheduled'
    ).length;
    final techActiveCount = localBookings.where((booking) =>
      _isBookingForTechnician(booking.technician, userName) && booking.status == 'In Progress'
    ).length;
    final techCompletedCount = localBookings.where((booking) =>
      _isBookingForTechnician(booking.technician, userName) && booking.status == 'Completed'
    ).length;

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
                          onPressed: () => _showNotifications(context),
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
          // Main Content Area
          Expanded(
            child: Container(
              color: AppTheme.primaryCyan,
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Stats Grid
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        children: [
                          _StatCard(
                            icon: Icons.work_outline,
                            iconColor: Colors.white,
                            bgColor: const Color(0xFF4F7CFF),
                            value: '$techActiveCount',
                            label: 'Today\'s Jobs',
                          ),
                          _StatCard(
                            icon: Icons.check_circle_outline,
                            iconColor: Colors.white,
                            bgColor: const Color(0xFF00C853),
                            value: '$techCompletedCount',
                            label: 'Completed',
                          ),
                          _StatCard(
                            icon: Icons.assignment_outlined,
                            iconColor: Colors.white,
                            bgColor: const Color(0xFFFF6B35),
                            value: '$techScheduledCount',
                            label: 'Today\'s Job Request',
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final todayEarningsAsync = ref.watch(todayEarningsProvider);
                              return todayEarningsAsync.when(
                                data: (earnings) => _StatCard(
                                  icon: Icons.attach_money,
                                  iconColor: Colors.white,
                                  bgColor: const Color(0xFFB845F5),
                                  value: '₱${earnings.toStringAsFixed(0)}',
                                  label: 'Today\'s Earnings',
                                ),
                                loading: () => _StatCard(
                                  icon: Icons.attach_money,
                                  iconColor: Colors.white,
                                  bgColor: const Color(0xFFB845F5),
                                  value: '₱0',
                                  label: 'Today\'s Earnings',
                                ),
                                error: (_, __) => _StatCard(
                                  icon: Icons.attach_money,
                                  iconColor: Colors.white,
                                  bgColor: const Color(0xFFB845F5),
                                  value: '₱0',
                                  label: 'Today\'s Earnings',
                                ),
                              );
                            },
                          ),
                        ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quick Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.navigation,
                              iconColor: AppTheme.lightBlue,
                              iconBgColor: AppTheme.lightBlue.withValues(alpha: 0.15),
                              label: 'Start\nNavigation',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.location_on,
                              iconColor: Colors.green,
                              iconBgColor: Colors.green.withValues(alpha: 0.15),
                              label: 'Mark\nAvailable',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.star,
                              iconColor: Colors.pink,
                              iconBgColor: Colors.pink.withValues(alpha: 0.15),
                              label: 'View\nRating',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TechRatingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.access_time,
                              iconColor: Colors.orange,
                              iconBgColor: Colors.orange.withValues(alpha: 0.15),
                              label: 'Time\nOff Request',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Today's Schedule
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today\'s Schedule',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBlue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.lightBlue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '$techActiveCount Active',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Dynamic Job Cards - Show active bookings
                      ...localBookings.where((booking) =>
                        _isBookingForTechnician(booking.technician, userName) && booking.status == 'In Progress'
                      ).map((booking) {
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

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _JobCard(
                            customerName: booking.customerName,
                            priority: priorityText,
                            priorityColor: priorityColor,
                            device: booking.deviceName,
                            service: booking.serviceName,
                            time: booking.time,
                            duration: '45 mins',
                            address: booking.location,
                            price: booking.total,
                            status: 'IN PROGRESS',
                            statusColor: AppTheme.lightBlue,
                          ),
                        );
                      }),
                      // Show message if no active bookings
                      if (techActiveCount == 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No active jobs at the moment',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String customerName;
  final String priority;
  final Color priorityColor;
  final String device;
  final String service;
  final String time;
  final String duration;
  final String address;
  final String price;
  final String status;
  final Color statusColor;

  const _JobCard({
    required this.customerName,
    required this.priority,
    required this.priorityColor,
    required this.device,
    required this.service,
    required this.time,
    required this.duration,
    required this.address,
    required this.price,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
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
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person, color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority,
                    style: const TextStyle(
                      fontSize: 10,
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
            padding: const EdgeInsets.all(14),
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
                      child: const Icon(
                        Icons.phone_android,
                        color: AppTheme.lightBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            service,
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '$time • $duration',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: AppTheme.lightBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.deepBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 24),
              Icon(Icons.arrow_forward, color: iconColor.withValues(alpha: 0.5), size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: iconColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String message;
  final String time;
  final bool isNew;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.message,
    required this.time,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? AppTheme.primaryCyan.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew ? AppTheme.lightBlue.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: isNew ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
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
