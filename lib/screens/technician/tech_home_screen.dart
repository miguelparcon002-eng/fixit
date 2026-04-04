import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/notification_icon_mapper.dart';
import '../../core/utils/time_ago.dart';
import '../../models/booking_model.dart';
import '../../models/notification_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/technician_stats_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/technician_provider.dart';
import '../../providers/job_request_provider.dart';
import 'tech_ratings_screen.dart';
import 'tech_jobs_screen_new.dart';
import 'widgets/customer_location_sheet.dart';
final monthlyGoalProvider = StateProvider<double>((ref) => 50000);
enum TechDateFilter { today, week, month }
final techDateFilterProvider = StateProvider<TechDateFilter>(
  (ref) => TechDateFilter.today,
);
enum CompletionRateFilter { day, week, month, all }
final completionRateFilterProvider = StateProvider<CompletionRateFilter>(
  (ref) => CompletionRateFilter.day,
);
class TechHomeScreen extends ConsumerWidget {
  const TechHomeScreen({super.key});
  static void _showNotifications(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _TechNotificationsSheet(),
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openJobCount =
        ref.watch(openJobRequestsProvider).valueOrNull?.length ?? 0;
    final userAsync = ref.watch(currentUserProvider);
    final userName =
        userAsync.whenOrNull(data: (user) => user?.fullName) ?? 'Technician';
    final currentUserId = userAsync.whenOrNull(data: (u) => u?.id);
    final isAvailable = currentUserId != null
        ? (ref.watch(techAvailabilityProviderFamily(currentUserId))
            .valueOrNull ?? true)
        : true;
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
    final bookingsAsync = ref.watch(technicianBookingsProvider);
    final statsAsync = ref.watch(technicianStatsProvider);
    final technicianRating =
        statsAsync.whenOrNull(data: (stats) => stats.averageRating) ?? 0.0;
    final totalReviews =
        statsAsync.whenOrNull(data: (stats) => stats.totalReviews) ?? 0;
    final selectedFilter = ref.watch(techDateFilterProvider);
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
          Builder(
            builder: (context) {
              final unread = ref.watch(unreadNotificationsCountProvider);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => _showNotifications(context, ref),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.deepBlue,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
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
          final filteredBookings = allBookings.where((booking) {
            if (booking.scheduledDate == null) return false;
            final bookingDate = booking.scheduledDate!;
            return bookingDate.isAfter(
                  startDate.subtract(const Duration(seconds: 1)),
                ) &&
                bookingDate.isBefore(endDate);
          }).toList();
          final techScheduledCount = allBookings
              .where((booking) =>
                  booking.status == 'requested' &&
                  booking.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                  booking.createdAt.isBefore(endDate))
              .length;
          final techActiveCount = filteredBookings
              .where((booking) =>
                  booking.status == 'accepted' ||
                  booking.status == 'in_progress')
              .length;
          final techCompletedCount = filteredBookings
              .where((booking) => booking.status == 'completed')
              .length;
          final periodEarnings = filteredBookings
              .where((b) => b.status == 'completed')
              .fold<double>(
                0,
                (sum, b) => sum + (b.finalCost ?? b.estimatedCost ?? 0),
              );
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
          final earningsTrend = prevPeriodEarnings > 0
              ? ((periodEarnings - prevPeriodEarnings) /
                        prevPeriodEarnings *
                        100)
                    .toDouble()
              : (periodEarnings > 0 ? 100.0 : 0.0);
          final crFilter = ref.watch(completionRateFilterProvider);
          DateTime crStart;
          DateTime crEnd = now;
          switch (crFilter) {
            case CompletionRateFilter.day:
              crStart = todayStart;
              crEnd = todayStart.add(const Duration(days: 1));
              break;
            case CompletionRateFilter.week:
              crStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
              crEnd = crStart.add(const Duration(days: 7));
              break;
            case CompletionRateFilter.month:
              crStart = DateTime(now.year, now.month, 1);
              crEnd = DateTime(now.year, now.month + 1, 1);
              break;
            case CompletionRateFilter.all:
              crStart = DateTime(2000);
              crEnd = DateTime(2100);
              break;
          }
          final crBookings = allBookings.where((b) {
            if (b.scheduledDate == null) return false;
            return b.scheduledDate!.isAfter(crStart.subtract(const Duration(seconds: 1))) &&
                b.scheduledDate!.isBefore(crEnd);
          }).toList();
          final crCompleted = crBookings.where((b) => b.status == 'completed').length;
          final crTotal = crBookings.length;
          final crRate = crTotal > 0 ? (crCompleted / crTotal * 100) : 0.0;
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
          final todayEnd = todayStart.add(const Duration(days: 1));
          final scheduleBookings = allBookings
              .where((b) {
                final activeStatuses = {
                  'requested', 'accepted', 'scheduled', 'en_route', 'in_progress'
                };
                if (!activeStatuses.contains(b.status)) return false;
                return b.createdAt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
                    b.createdAt.isBefore(todayEnd);
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
                              Row(
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
                                ],
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
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
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              backgroundColor: Colors.transparent,
                                              builder: (_) => _CrFilterSheet(
                                                current: crFilter,
                                                onSelect: (f) => ref.read(completionRateFilterProvider.notifier).state = f,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  switch (crFilter) {
                                                    CompletionRateFilter.day => 'Day',
                                                    CompletionRateFilter.week => 'Week',
                                                    CompletionRateFilter.month => 'Month',
                                                    CompletionRateFilter.all => 'All',
                                                  },
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                const SizedBox(width: 3),
                                                const Icon(Icons.arrow_drop_down, color: Colors.green, size: 16),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${crRate.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Completion Rate',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$crCompleted of $crTotal jobs',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TechRatingsScreen()),
                                ),
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MonthlyGoalCard(
                      currentEarnings: monthlyEarnings,
                      goalAmount: monthlyGoal,
                      progress: goalProgress,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _WeeklyPerformanceChart(
                      weeklyData: weeklyData,
                      earningsTrend: earningsTrend,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _QuickActionButton(
                                    icon: Icons.map_rounded,
                                    iconColor: Colors.deepOrange,
                                    iconBgColor: Colors.deepOrange.withValues(alpha: 0.15),
                                    label: 'Job Map',
                                    onTap: () => context.push('/tech-job-map'),
                                  ),
                                  if (openJobCount > 0)
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.deepOrange,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: Text(
                                          openJobCount > 99
                                              ? '99+'
                                              : '$openJobCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.star,
                                iconColor: Colors.pink,
                                iconBgColor: Colors.pink.withValues(alpha: 0.15),
                                label: 'View Rating',
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _AvailabilityToggleButton(
                                userId: currentUserId,
                                isAvailable: isAvailable,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.headset_mic,
                                iconColor: AppTheme.lightBlue,
                                iconBgColor: AppTheme.lightBlue.withValues(alpha: 0.15),
                                label: 'Contact Support',
                                onTap: () {
                                  context.go('/tech-help-support');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                        ...scheduleBookings.map((booking) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SimpleJobCard(booking: booking),
                          );
                        }),
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
class _TechNotificationsSheet extends ConsumerWidget {
  const _TechNotificationsSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = AsyncData<List<AppNotification>>(
        ref.watch(filteredNotificationsProvider));
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () async {
                        final user = await ref.read(currentUserProvider.future);
                        if (user == null) return;
                        await ref
                            .read(notificationServiceProvider)
                            .markAllAsRead(user.id);
                      },
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$unreadCount new notification${unreadCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: notificationsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return _TechNotificationCard(
                        notification: n,
                        onTap: () async {
                          final route = n.route;
                          if (!n.isRead) {
                            await ref
                                .read(notificationServiceProvider)
                                .markAsRead(n.id);
                          }
                          if (route != null && route.isNotEmpty && context.mounted) {
                            Navigator.of(context).pop();
                            context.go(route);
                          }
                        },
                        onDismiss: () async {
                          await ref
                              .read(notificationServiceProvider)
                              .deleteNotification(n.id);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Error loading notifications: $e',
                    style: TextStyle(color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _TechNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _TechNotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });
  @override
  Widget build(BuildContext context) {
    final mapped = mapNotificationIcon(notification.type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppTheme.primaryCyan.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : AppTheme.primaryCyan.withValues(alpha: 0.3),
          ),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mapped.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(mapped.icon, color: mapped.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo(notification.createdAt),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: onDismiss,
                          child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                        if (booking.customerLatitude != null && booking.customerLongitude != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CustomerLocationSheet(
                                latitude: booking.customerLatitude!,
                                longitude: booking.customerLongitude!,
                                customerName: 'Customer',
                                address: booking.customerAddress!,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A5FE0).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF4A5FE0).withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map_outlined, size: 12, color: Color(0xFF4A5FE0)),
                                  SizedBox(width: 3),
                                  Text('Map', style: TextStyle(fontSize: 10, color: Color(0xFF4A5FE0), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                  '₱${booking.finalCost ?? booking.estimatedCost ?? 0}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
                GestureDetector(
                  onTap: () {
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
class _CrFilterSheet extends StatelessWidget {
  final CompletionRateFilter current;
  final ValueChanged<CompletionRateFilter> onSelect;
  const _CrFilterSheet({required this.current, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final options = [
      (CompletionRateFilter.day, 'Today', Icons.today),
      (CompletionRateFilter.week, 'This Week', Icons.view_week),
      (CompletionRateFilter.month, 'This Month', Icons.calendar_month),
      (CompletionRateFilter.all, 'All Time', Icons.all_inclusive),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Completion Rate Filter',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final (filter, label, icon) = opt;
            final isSelected = current == filter;
            return GestureDetector(
              onTap: () {
                onSelect(filter);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: isSelected ? Colors.green : AppTheme.textSecondaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.green : AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
class _AvailabilityToggleButton extends ConsumerWidget {
  final String? userId;
  const _AvailabilityToggleButton({required this.userId, required bool isAvailable});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = userId;
    if (uid == null) {
      return const SizedBox.shrink();
    }
    final notifierState = ref.watch(techAvailabilityProviderFamily(uid));
    final isAvailable = notifierState.valueOrNull ?? true;
    final isLoading = notifierState.isLoading;
    final iconColor = isAvailable ? Colors.red.shade400 : Colors.green;
    final iconBgColor = isAvailable
        ? Colors.red.withValues(alpha: 0.12)
        : Colors.green.withValues(alpha: 0.12);
    final label = isAvailable ? 'Go\nOffline' : 'Go\nOnline';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => _AvailabilitySheet(
              userId: uid,
              isAvailable: isAvailable,
            ),
          );
        },
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
                child: isLoading
                    ? SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      )
                    : Icon(
                        isAvailable
                            ? Icons.wifi_tethering_off_rounded
                            : Icons.wifi_tethering_rounded,
                        color: iconColor,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
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
class _AvailabilitySheet extends ConsumerStatefulWidget {
  final String userId;
  final bool isAvailable;
  const _AvailabilitySheet({required this.userId, required this.isAvailable});
  @override
  ConsumerState<_AvailabilitySheet> createState() => _AvailabilitySheetState();
}
class _AvailabilitySheetState extends ConsumerState<_AvailabilitySheet> {
  late bool _pendingValue;
  @override
  void initState() {
    super.initState();
    _pendingValue = widget.isAvailable;
  }
  Future<void> _confirm() async {
    await ref
        .read(techAvailabilityProviderFamily(widget.userId).notifier)
        .setAvailability(_pendingValue);
    if (mounted) Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    final notifierState = ref.watch(techAvailabilityProviderFamily(widget.userId));
    final isLoading = notifierState.isLoading;
    final hasError = notifierState.hasError;
    final willBeOnline = _pendingValue;
    final color = willBeOnline ? Colors.green : Colors.grey.shade600;
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                willBeOnline ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                color: color,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                willBeOnline ? 'Go Online' : 'Go Offline',
                key: ValueKey(willBeOnline),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                willBeOnline
                    ? 'You will be visible to customers and receive new job requests.'
                    : 'You will be hidden from the technician list and stop receiving job requests.',
                key: ValueKey(willBeOnline),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Text(
                'Failed to update. Please try again.',
                style: TextStyle(fontSize: 12, color: Colors.red.shade600),
              ),
            ],
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    willBeOnline ? 'Status: Online' : 'Status: Offline',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Switch(
                    value: _pendingValue,
                    onChanged: isLoading ? null : (v) => setState(() => _pendingValue = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
                ),
              ),
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