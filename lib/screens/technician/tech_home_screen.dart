import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/technician_stats_provider.dart';
import '../../providers/address_provider.dart';
import 'tech_ratings_screen.dart';
import 'tech_jobs_screen_new.dart';

// Monthly goal provider - can be updated by technician
final monthlyGoalProvider = StateProvider<double>((ref) => 50000);

// Date filter enum
enum TechDateFilter { today, week, month }

// Provider for date filter
final techDateFilterProvider = StateProvider<TechDateFilter>(
  (ref) => TechDateFilter.today,
);

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
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.lightBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Notifications List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  _NotificationItem(
                    icon: Icons.assignment,
                    iconColor: AppTheme.lightBlue,
                    iconBgColor: Color(0xFFE3F2FD),
                    title: 'New Job Request',
                    message:
                        'You have a new job request from John Doe for iPhone screen repair.',
                    time: '5 mins ago',
                    isNew: true,
                  ),
                  SizedBox(height: 12),
                  _NotificationItem(
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                    iconBgColor: Color(0xFFE8F5E9),
                    title: 'Payment Received',
                    message:
                        'Payment of ₱1,500 has been received for Job #12345.',
                    time: '1 hour ago',
                    isNew: true,
                  ),
                  SizedBox(height: 12),
                  _NotificationItem(
                    icon: Icons.star,
                    iconColor: Colors.orange,
                    iconBgColor: Color(0xFFFFF3E0),
                    title: 'New Review',
                    message: 'Sarah left you a 5-star review!',
                    time: '3 hours ago',
                    isNew: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user data
    final userAsync = ref.watch(currentUserProvider);
    final userName =
        userAsync.whenOrNull(data: (user) => user?.fullName) ?? 'Technician';

    // Use saved addresses (same mechanism customers use) so technicians also
    // see/manage their real "default address".
    final defaultAddress = ref.watch(defaultAddressProvider);
    final addressesAsync = ref.watch(userAddressesProvider);
    final firstSavedAddress = addressesAsync.whenOrNull(
      data: (addresses) => addresses.isNotEmpty ? addresses.first : null,
    );

    final profileAddressFallback =
        userAsync.whenOrNull(data: (user) => user?.address) ?? '';
    final displayAddress =
        defaultAddress?.address ??
        firstSavedAddress?.address ??
        profileAddressFallback;

    // Use Supabase bookings instead of local bookings
    final bookingsAsync = ref.watch(technicianBookingsProvider);

    // Get technician stats (for rating)
    final statsAsync = ref.watch(technicianStatsProvider);
    final technicianRating =
        statsAsync.whenOrNull(data: (stats) => stats.averageRating) ?? 0.0;
    final totalReviews =
        statsAsync.whenOrNull(data: (stats) => stats.totalReviews) ?? 0;

    // Get selected date filter
    final selectedFilter = ref.watch(techDateFilterProvider);

    // Get date range based on filter
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    DateTime startDate;
    DateTime endDate;

    switch (selectedFilter) {
      case TechDateFilter.today:
        startDate = todayStart;
        endDate = todayStart.add(const Duration(days: 1));
        break;
      case TechDateFilter.week:
        startDate = todayStart.subtract(Duration(days: todayStart.weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
        break;
      case TechDateFilter.month:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
    }

    // Get filter label
    String filterLabel;
    switch (selectedFilter) {
      case TechDateFilter.today:
        filterLabel = 'Today';
        break;
      case TechDateFilter.week:
        filterLabel = 'This Week';
        break;
      case TechDateFilter.month:
        filterLabel = 'This Month';
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _showNotifications(context),
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.deepBlue,
            ),
          ),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue),
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading bookings',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        data: (allBookings) {
          // Filter bookings based on selected date range
          final filteredBookings = allBookings.where((booking) {
            if (booking.scheduledDate == null) return false;
            final bookingDate = booking.scheduledDate!;
            return bookingDate.isAfter(
                  startDate.subtract(const Duration(seconds: 1)),
                ) &&
                bookingDate.isBefore(endDate);
          }).toList();

          // Calculate stats based on filtered bookings
          final techScheduledCount = filteredBookings
              .where(
                (booking) =>
                    booking.status == 'requested' ||
                    booking.status == 'accepted',
              )
              .length;
          final techActiveCount = filteredBookings
              .where((booking) => booking.status == 'in_progress')
              .length;
          final techCompletedCount = filteredBookings
              .where((booking) => booking.status == 'completed')
              .length;

          // Calculate earnings for the period
          final periodEarnings = filteredBookings
              .where((b) => b.status == 'completed')
              .fold<double>(
                0,
                (sum, b) => sum + (b.finalCost ?? b.estimatedCost ?? 0),
              );

          // Calculate previous period for comparison
          final periodDuration = endDate.difference(startDate);
          final prevStartDate = startDate.subtract(periodDuration);
          final prevEndDate = startDate;

          final prevFilteredBookings = allBookings.where((booking) {
            if (booking.scheduledDate == null) return false;
            final bookingDate = booking.scheduledDate!;
            return bookingDate.isAfter(
                  prevStartDate.subtract(const Duration(seconds: 1)),
                ) &&
                bookingDate.isBefore(prevEndDate);
          }).toList();

          final prevPeriodEarnings = prevFilteredBookings
              .where((b) => b.status == 'completed')
              .fold<double>(
                0,
                (sum, b) => sum + (b.finalCost ?? b.estimatedCost ?? 0),
              );

          final prevCompletedCount = prevFilteredBookings
              .where((booking) => booking.status == 'completed')
              .length;

          // Calculate trends
          final earningsTrend = prevPeriodEarnings > 0
              ? ((periodEarnings - prevPeriodEarnings) /
                        prevPeriodEarnings *
                        100)
                    .toDouble()
              : (periodEarnings > 0 ? 100.0 : 0.0);
          final completedTrend = prevCompletedCount > 0
              ? ((techCompletedCount - prevCompletedCount) /
                        prevCompletedCount *
                        100)
                    .toDouble()
              : (techCompletedCount > 0 ? 100.0 : 0.0);

          // Calculate completion rate
          final totalJobsInPeriod = filteredBookings.length;
          final completionRate = totalJobsInPeriod > 0
              ? (techCompletedCount / totalJobsInPeriod * 100).toDouble()
              : 0.0;

          // Calculate weekly data for chart (last 7 days)
          final weeklyData = <double>[];
          for (int i = 6; i >= 0; i--) {
            final dayStart = DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(Duration(days: i));
            final dayEnd = dayStart.add(const Duration(days: 1));
            final dayEarnings = allBookings
                .where(
                  (b) =>
                      b.status == 'completed' &&
                      b.scheduledDate != null &&
                      b.scheduledDate!.isAfter(
                        dayStart.subtract(const Duration(seconds: 1)),
                      ) &&
                      b.scheduledDate!.isBefore(dayEnd),
                )
                .fold<double>(
                  0,
                  (sum, b) => sum + (b.finalCost ?? b.estimatedCost ?? 0),
                );
            weeklyData.add(dayEarnings);
          }

          // Job status counts for donut chart
          final pendingCount = allBookings
              .where((b) => b.status == 'requested' || b.status == 'accepted')
              .length;
          final inProgressCount = allBookings
              .where((b) => b.status == 'in_progress')
              .length;
          final allCompletedCount = allBookings
              .where((b) => b.status == 'completed')
              .length;
          final cancelledCount = allBookings
              .where((b) => b.status == 'cancelled')
              .length;

          // Monthly earnings for goal tracking
          final monthStart = DateTime(now.year, now.month, 1);
          final monthEnd = DateTime(now.year, now.month + 1, 1);
          final monthlyEarnings = allBookings
              .where(
                (b) =>
                    b.status == 'completed' &&
                    b.scheduledDate != null &&
                    b.scheduledDate!.isAfter(
                      monthStart.subtract(const Duration(seconds: 1)),
                    ) &&
                    b.scheduledDate!.isBefore(monthEnd),
              )
              .fold<double>(
                0,
                (sum, b) => sum + (b.finalCost ?? b.estimatedCost ?? 0),
              );

          final monthlyGoal = ref.watch(monthlyGoalProvider);
          final goalProgress = monthlyGoal > 0
              ? (monthlyEarnings / monthlyGoal).clamp(0.0, 1.0)
              : 0.0;

          // Bookings to show in the "Today's Schedule" area.
          // Previously this only showed `in_progress`, which hides newly-created
          // bookings (including emergency) that are still `requested`/`accepted`.
          //
          // We show all appointments within the selected date range, prioritizing
          // emergency bookings first.
          // "Today's Schedule" should always mean *today* (independent of the
          // selected filter used for stats/cards above).
          final todayEnd = todayStart.add(const Duration(days: 1));

          final scheduleBookings = allBookings
              .where((b) {
                final sd = b.scheduledDate;
                if (sd == null) return false;

                final inToday = sd.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
                    sd.isBefore(todayEnd);

                if (!inToday) return false;

                return b.status == 'requested' ||
                    b.status == 'accepted' ||
                    b.status == 'scheduled' ||
                    b.status == 'en_route' ||
                    b.status == 'in_progress';
              })
              .toList();

          scheduleBookings.sort((a, b) {
            final prio = (b.isEmergency ? 1 : 0).compareTo(a.isEmergency ? 1 : 0);
            if (prio != 0) return prio;
            final aTime = a.scheduledDate ?? a.createdAt;
            final bTime = b.scheduledDate ?? b.createdAt;
            return aTime.compareTo(bTime); // earlier appointments first
          });

          return Container(
            color: const Color(0xFFF5F7FA),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Technician summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.deepBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: AppTheme.deepBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => context.push('/addresses'),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        displayAddress.isNotEmpty
                                            ? displayAddress
                                            : 'Location not set',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _MiniPill(
                                    icon: Icons.star,
                                    label: technicianRating > 0
                                        ? technicianRating.toStringAsFixed(1)
                                        : 'N/A',
                                  ),
                                  const SizedBox(width: 8),
                                  _MiniPill(
                                    icon: Icons.reviews_outlined,
                                    label: '$totalReviews reviews',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date Filter Tabs
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _DateFilterTab(
                            label: 'Today',
                            isSelected: selectedFilter == TechDateFilter.today,
                            onTap: () =>
                                ref
                                        .read(techDateFilterProvider.notifier)
                                        .state =
                                    TechDateFilter.today,
                          ),
                          _DateFilterTab(
                            label: 'This Week',
                            isSelected: selectedFilter == TechDateFilter.week,
                            onTap: () =>
                                ref
                                        .read(techDateFilterProvider.notifier)
                                        .state =
                                    TechDateFilter.week,
                          ),
                          _DateFilterTab(
                            label: 'This Month',
                            isSelected: selectedFilter == TechDateFilter.month,
                            onTap: () =>
                                ref
                                        .read(techDateFilterProvider.notifier)
                                        .state =
                                    TechDateFilter.month,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                          label: '$filterLabel\'s Jobs',
                          onTap: () {
                            // Set tab to Active (1) before navigating
                            ref
                                    .read(techJobsInitialTabProvider.notifier)
                                    .state =
                                1;
                            context.go('/tech-jobs');
                          },
                        ),
                        _StatCard(
                          icon: Icons.check_circle_outline,
                          iconColor: Colors.white,
                          bgColor: const Color(0xFF00C853),
                          value: '$techCompletedCount',
                          label: 'Completed',
                          onTap: () {
                            // Set tab to Complete (2) before navigating
                            ref
                                    .read(techJobsInitialTabProvider.notifier)
                                    .state =
                                2;
                            context.go('/tech-jobs');
                          },
                        ),
                        _StatCard(
                          icon: Icons.assignment_outlined,
                          iconColor: Colors.white,
                          bgColor: const Color(0xFFFF6B35),
                          value: '$techScheduledCount',
                          label: 'Job Requests',
                          onTap: () {
                            // Set tab to Request (0) before navigating
                            ref
                                    .read(techJobsInitialTabProvider.notifier)
                                    .state =
                                0;
                            context.go('/tech-jobs');
                          },
                        ),
                        _StatCard(
                          icon: Icons.attach_money,
                          iconColor: Colors.white,
                          bgColor: const Color(0xFFB845F5),
                          value: '₱${periodEarnings.toStringAsFixed(0)}',
                          label: 'Earnings',
                          onTap: () => context.go('/tech-earnings'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Performance Metrics
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Performance Metrics',
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
                              child: _MetricCard(
                                label: 'Completion Rate',
                                value: '${completionRate.toStringAsFixed(1)}%',
                                icon: Icons.check_circle,
                                color: Colors.green,
                                subtitle:
                                    '$techCompletedCount of $totalJobsInPeriod jobs',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: 'Customer Rating',
                                value: technicianRating > 0
                                    ? technicianRating.toStringAsFixed(1)
                                    : 'N/A',
                                icon: Icons.star,
                                color: Colors.orange,
                                subtitle: 'Based on $totalReviews reviews',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Monthly Goal Progress
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MonthlyGoalCard(
                      currentEarnings: monthlyEarnings,
                      goalAmount: monthlyGoal,
                      progress: goalProgress,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Weekly Performance Chart
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _WeeklyPerformanceChart(
                      weeklyData: weeklyData,
                      earningsTrend: earningsTrend,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Job Status Distribution
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _JobStatusChart(
                      pending: pendingCount,
                      inProgress: inProgressCount,
                      completed: allCompletedCount,
                      cancelled: cancelledCount,
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
                                icon: Icons.star,
                                iconColor: Colors.pink,
                                iconBgColor: Colors.pink.withValues(
                                  alpha: 0.15,
                                ),
                                label: 'View\nRating',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TechRatingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.location_on,
                                iconColor: Colors.green,
                                iconBgColor: Colors.green.withValues(
                                  alpha: 0.15,
                                ),
                                label: 'Mark\nAvailable',
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.headset_mic,
                                iconColor: AppTheme.lightBlue,
                                iconBgColor: AppTheme.lightBlue.withValues(
                                  alpha: 0.15,
                                ),
                                label: 'Contact\nSupport',
                                onTap: () {
                                  context.go('/tech-help-support');
                                },
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.lightBlue,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.lightBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${scheduleBookings.length} Scheduled',
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
                        // Dynamic Job Cards - Show schedule bookings for the selected period
                        ...scheduleBookings.map((booking) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SimpleJobCard(booking: booking),
                          );
                        }),
                        // Show message if no bookings in schedule
                        if (scheduleBookings.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.work_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
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
          );
        },
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Icon(
                  Icons.arrow_forward,
                  color: iconColor.withValues(alpha: 0.5),
                  size: 16,
                ),
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
        color: isNew
            ? AppTheme.primaryCyan.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew
              ? AppTheme.lightBlue.withValues(alpha: 0.3)
              : Colors.grey.shade200,
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
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
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

class _SimpleJobCard extends ConsumerWidget {
  final BookingModel booking;

  const _SimpleJobCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        Icons.build,
                        color: AppTheme.lightBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Job #${booking.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'IN PROGRESS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (booking.scheduledDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat(
                            'MMM dd, hh:mm a',
                          ).format(booking.scheduledDate!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  if (booking.scheduledDate != null &&
                      booking.customerAddress != null)
                    const SizedBox(height: 6),
                  if (booking.customerAddress != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking.customerAddress!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Price and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₱${booking.finalCost ?? booking.estimatedCost ?? 0}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Set tab to Active (1) before navigating
                    ref.read(techJobsInitialTabProvider.notifier).state = 1;
                    context.go('/tech-jobs');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateFilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.deepBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

// Performance Metric Card
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// Monthly Goal Progress Card
class _MonthlyGoalCard extends StatelessWidget {
  final double currentEarnings;
  final double goalAmount;
  final double progress;

  const _MonthlyGoalCard({
    required this.currentEarnings,
    required this.goalAmount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepBlue, AppTheme.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₱${currentEarnings.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            'of ₱${goalAmount.toStringAsFixed(0)} goal',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryCyan,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${(goalAmount - currentEarnings).toStringAsFixed(0)} remaining',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// Weekly Performance Chart
class _WeeklyPerformanceChart extends StatelessWidget {
  final List<double> weeklyData;
  final double earningsTrend;

  const _WeeklyPerformanceChart({
    required this.weeklyData,
    required this.earningsTrend,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = weeklyData.isNotEmpty ? weeklyData.reduce(max) : 1.0;
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final todayIndex = 6; // Last item is today

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Earnings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: earningsTrend >= 0
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      earningsTrend >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 14,
                      color: earningsTrend >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${earningsTrend >= 0 ? '+' : ''}${earningsTrend.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: earningsTrend >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = weeklyData.length > index
                    ? weeklyData[index]
                    : 0.0;
                final height = maxValue > 0 ? (value / maxValue * 80) : 0.0;
                final isToday = index == todayIndex;
                final dayOffset = 6 - index;
                final dayDate = now.subtract(Duration(days: dayOffset));
                final dayLabel = dayLabels[dayDate.weekday - 1];

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (value > 0)
                        Text(
                          '₱${value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? AppTheme.deepBlue
                                : Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        height: height.clamp(4.0, 80.0),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppTheme.deepBlue
                              : AppTheme.lightBlue.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isToday
                              ? AppTheme.deepBlue
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Job Status Distribution Chart
class _JobStatusChart extends StatelessWidget {
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;

  const _JobStatusChart({
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    final total = pending + inProgress + completed + cancelled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Job Status Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    pending: pending,
                    inProgress: inProgress,
                    completed: completed,
                    cancelled: cancelled,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendItem(
                      color: const Color(0xFFFF6B35),
                      label: 'Pending',
                      count: pending,
                    ),
                    const SizedBox(height: 8),
                    _LegendItem(
                      color: const Color(0xFF9C27B0),
                      label: 'In Progress',
                      count: inProgress,
                    ),
                    const SizedBox(height: 8),
                    _LegendItem(
                      color: const Color(0xFF00C853),
                      label: 'Completed',
                      count: completed,
                    ),
                    const SizedBox(height: 8),
                    _LegendItem(
                      color: Colors.grey,
                      label: 'Cancelled',
                      count: cancelled,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Legend Item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

// Donut Chart Painter
class _DonutChartPainter extends CustomPainter {
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;

  _DonutChartPainter({
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = pending + inProgress + completed + cancelled;
    if (total == 0) {
      // Draw empty circle
      final paint = Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - 10,
        paint,
      );
      return;
    }

    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    const strokeWidth = 20.0;

    final segments = [
      (pending / total, const Color(0xFFFF6B35)),
      (inProgress / total, const Color(0xFF9C27B0)),
      (completed / total, const Color(0xFF00C853)),
      (cancelled / total, Colors.grey),
    ];

    var startAngle = -pi / 2;
    for (final segment in segments) {
      if (segment.$1 > 0) {
        final sweepAngle = segment.$1 * 2 * pi;
        final paint = Paint()
          ..color = segment.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
        startAngle += sweepAngle;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
