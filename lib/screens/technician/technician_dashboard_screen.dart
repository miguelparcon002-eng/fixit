import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/earnings_provider.dart';
import 'tech_jobs_screen_new.dart';

// Provider for date filter selection
enum DateFilter { today, week, month }

final dateFilterProvider = StateProvider<DateFilter>((ref) => DateFilter.today);

// Provider for monthly earnings goal (can be customized by technician)
final monthlyGoalProvider = StateProvider<double>((ref) => 50000.0);

class TechnicianDashboardScreen extends ConsumerWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(dateFilterProvider);
    final bookingsAsync = ref.watch(technicianBookingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              ref.invalidate(technicianBookingsProvider);
              ref.invalidate(todayEarningsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  _FilterTab(
                    label: 'Today',
                    isSelected: selectedFilter == DateFilter.today,
                    onTap: () => ref.read(dateFilterProvider.notifier).state = DateFilter.today,
                  ),
                  _FilterTab(
                    label: 'This Week',
                    isSelected: selectedFilter == DateFilter.week,
                    onTap: () => ref.read(dateFilterProvider.notifier).state = DateFilter.week,
                  ),
                  _FilterTab(
                    label: 'This Month',
                    isSelected: selectedFilter == DateFilter.month,
                    onTap: () => ref.read(dateFilterProvider.notifier).state = DateFilter.month,
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: bookingsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                data: (allBookings) => _buildDashboardContent(context, ref, allBookings, selectedFilter),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    List<BookingModel> allBookings,
    DateFilter filter,
  ) {
    // Get date range based on filter
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    DateTime startDate;
    DateTime endDate = now.add(const Duration(days: 1));

    switch (filter) {
      case DateFilter.today:
        startDate = todayStart;
        endDate = todayStart.add(const Duration(days: 1));
        break;
      case DateFilter.week:
        // Start from beginning of current week (Monday)
        startDate = todayStart.subtract(Duration(days: todayStart.weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
        break;
      case DateFilter.month:
        // Start from beginning of current month
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
    }

    // Calculate PREVIOUS period for comparison
    DateTime prevStartDate;
    DateTime prevEndDate;
    switch (filter) {
      case DateFilter.today:
        prevStartDate = todayStart.subtract(const Duration(days: 1));
        prevEndDate = todayStart;
        break;
      case DateFilter.week:
        prevStartDate = startDate.subtract(const Duration(days: 7));
        prevEndDate = startDate;
        break;
      case DateFilter.month:
        prevStartDate = DateTime(now.year, now.month - 1, 1);
        prevEndDate = DateTime(now.year, now.month, 1);
        break;
    }

    // Filter bookings by date range
    final filteredBookings = allBookings.where((booking) {
      if (booking.scheduledDate == null) return false;
      final bookingDate = booking.scheduledDate!;
      return bookingDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          bookingDate.isBefore(endDate);
    }).toList();

    // Filter PREVIOUS period bookings for comparison
    final prevFilteredBookings = allBookings.where((booking) {
      if (booking.scheduledDate == null) return false;
      final bookingDate = booking.scheduledDate!;
      return bookingDate.isAfter(prevStartDate.subtract(const Duration(seconds: 1))) &&
          bookingDate.isBefore(prevEndDate);
    }).toList();

    // Calculate stats
    final requestedCount = filteredBookings.where((b) =>
      b.status == 'requested' || b.status == 'accepted'
    ).length;
    final activeCount = filteredBookings.where((b) => b.status == 'in_progress').length;
    final completedCount = filteredBookings.where((b) => b.status == 'completed').length;
    final cancelledCount = filteredBookings.where((b) => b.status == 'cancelled').length;
    final totalJobsCount = filteredBookings.length;

    // Previous period stats for trends
    final prevCompletedCount = prevFilteredBookings.where((b) => b.status == 'completed').length;

    // Calculate earnings for the period
    final earnings = filteredBookings
        .where((b) => b.status == 'completed')
        .fold<double>(0, (sum, b) => sum + (b.finalCost ?? b.estimatedCost ?? 0));

    // Previous period earnings for trend
    final prevEarnings = prevFilteredBookings
        .where((b) => b.status == 'completed')
        .fold<double>(0, (sum, b) => sum + (b.finalCost ?? b.estimatedCost ?? 0));

    // Calculate trends (percentage change)
    double earningsTrend = 0;
    if (prevEarnings > 0) {
      earningsTrend = ((earnings - prevEarnings) / prevEarnings) * 100;
    } else if (earnings > 0) {
      earningsTrend = 100;
    }

    double completedTrend = 0;
    if (prevCompletedCount > 0) {
      completedTrend = ((completedCount - prevCompletedCount) / prevCompletedCount) * 100;
    } else if (completedCount > 0) {
      completedTrend = 100;
    }

    // Calculate completion rate
    final totalFinishedJobs = completedCount + cancelledCount;
    final completionRate = totalFinishedJobs > 0
        ? (completedCount / totalFinishedJobs) * 100
        : 100.0;

    // Monthly goal progress
    final monthlyGoal = ref.watch(monthlyGoalProvider);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final monthlyEarnings = allBookings
        .where((b) {
          if (b.scheduledDate == null) return false;
          return b.status == 'completed' &&
              b.scheduledDate!.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
              b.scheduledDate!.isBefore(monthEnd);
        })
        .fold<double>(0, (sum, b) => sum + (b.finalCost ?? b.estimatedCost ?? 0));
    final goalProgress = (monthlyEarnings / monthlyGoal).clamp(0.0, 1.0);

    // Calculate weekly performance data (last 7 days)
    final weeklyData = <String, double>{};
    final weeklyJobCounts = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = todayStart.subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      final dayLabel = DateFormat('EEE').format(day);

      final dayEarnings = allBookings
          .where((b) {
            if (b.scheduledDate == null) return false;
            return b.status == 'completed' &&
                b.scheduledDate!.isAfter(day.subtract(const Duration(seconds: 1))) &&
                b.scheduledDate!.isBefore(dayEnd);
          })
          .fold<double>(0, (sum, b) => sum + (b.finalCost ?? b.estimatedCost ?? 0));

      final dayJobCount = allBookings
          .where((b) {
            if (b.scheduledDate == null) return false;
            return b.status == 'completed' &&
                b.scheduledDate!.isAfter(day.subtract(const Duration(seconds: 1))) &&
                b.scheduledDate!.isBefore(dayEnd);
          })
          .length;

      weeklyData[dayLabel] = dayEarnings;
      weeklyJobCounts[dayLabel] = dayJobCount;
    }

    // Calculate average rating (mock - would come from reviews table)
    // For now, we'll simulate based on completed jobs
    final avgRating = completedCount > 0 ? 4.5 + (completedCount % 5) * 0.1 : 0.0;
    final totalReviews = (completedCount * 0.7).round(); // Assume 70% leave reviews

    // Get period label
    String periodLabel;
    switch (filter) {
      case DateFilter.today:
        periodLabel = DateFormat('EEEE, MMM d').format(now);
        break;
      case DateFilter.week:
        periodLabel = '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate.subtract(const Duration(days: 1)))}';
        break;
      case DateFilter.month:
        periodLabel = DateFormat('MMMM yyyy').format(now);
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Label
          Text(
            periodLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Stats Grid with Trend Indicators
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _DashboardStatCardWithTrend(
                icon: Icons.inbox_rounded,
                iconColor: Colors.white,
                bgColor: const Color(0xFFFF9800),
                value: '$requestedCount',
                label: 'Pending Requests',
                onTap: () {
                  ref.read(techJobsInitialTabProvider.notifier).state = 0;
                  context.go('/tech-jobs');
                },
              ),
              _DashboardStatCardWithTrend(
                icon: Icons.work_rounded,
                iconColor: Colors.white,
                bgColor: const Color(0xFF2196F3),
                value: '$activeCount',
                label: 'Active Jobs',
                onTap: () {
                  ref.read(techJobsInitialTabProvider.notifier).state = 1;
                  context.go('/tech-jobs');
                },
              ),
              _DashboardStatCardWithTrend(
                icon: Icons.check_circle_rounded,
                iconColor: Colors.white,
                bgColor: const Color(0xFF4CAF50),
                value: '$completedCount',
                label: 'Completed',
                trend: completedTrend,
                onTap: () {
                  ref.read(techJobsInitialTabProvider.notifier).state = 2;
                  context.go('/tech-jobs');
                },
              ),
              _DashboardStatCardWithTrend(
                icon: Icons.attach_money_rounded,
                iconColor: Colors.white,
                bgColor: const Color(0xFF9C27B0),
                value: '₱${earnings.toStringAsFixed(0)}',
                label: 'Earnings',
                trend: earningsTrend,
                onTap: () => context.go('/tech-earnings'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Performance Metrics Row
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Completion Rate
              Expanded(
                child: _MetricCard(
                  title: 'Completion Rate',
                  value: '${completionRate.toStringAsFixed(1)}%',
                  icon: Icons.verified_rounded,
                  color: completionRate >= 90
                      ? const Color(0xFF4CAF50)
                      : completionRate >= 70
                          ? const Color(0xFFFF9800)
                          : Colors.red,
                  subtitle: '$completedCount of $totalFinishedJobs jobs',
                ),
              ),
              const SizedBox(width: 12),
              // Customer Rating
              Expanded(
                child: _MetricCard(
                  title: 'Customer Rating',
                  value: avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                  icon: Icons.star_rounded,
                  color: const Color(0xFFFFB800),
                  subtitle: '$totalReviews reviews',
                  showStars: avgRating > 0,
                  rating: avgRating,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Monthly Goal Progress
          _MonthlyGoalCard(
            currentEarnings: monthlyEarnings,
            goal: monthlyGoal,
            progress: goalProgress,
          ),
          const SizedBox(height: 24),

          // Weekly Performance Chart
          const Text(
            'Weekly Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _WeeklyPerformanceChart(
            data: weeklyData,
            jobCounts: weeklyJobCounts,
          ),
          const SizedBox(height: 24),

          // Job Status Distribution (Donut Chart)
          const Text(
            'Job Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _JobStatusChart(
            requested: requestedCount,
            active: activeCount,
            completed: completedCount,
            cancelled: cancelledCount,
            total: totalJobsCount,
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.work_outline,
                  iconColor: AppTheme.deepBlue,
                  label: 'View All Jobs',
                  onTap: () => context.go('/tech-jobs'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF9C27B0),
                  label: 'View Earnings',
                  onTap: () => context.go('/tech-earnings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Jobs Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Jobs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/tech-jobs'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Recent Jobs List (show latest 5)
          if (filteredBookings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No jobs for this period',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredBookings.take(5).map((booking) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecentJobCard(
                booking: booking,
                onTap: () => context.go('/tech-jobs'),
              ),
            )),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.deepBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

class _RecentJobCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _RecentJobCard({
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (booking.status) {
      case 'requested':
        statusColor = const Color(0xFFFF9800);
        statusText = 'Requested';
        break;
      case 'accepted':
        statusColor = const Color(0xFF2196F3);
        statusText = 'Accepted';
        break;
      case 'in_progress':
        statusColor = const Color(0xFF9C27B0);
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.grey;
        statusText = booking.status;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.build_rounded, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job #${booking.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (booking.scheduledDate != null)
                    Text(
                      DateFormat('MMM d, h:mm a').format(booking.scheduledDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== NEW INFOGRAPHIC WIDGETS ====================

/// Stat card with optional trend indicator
class _DashboardStatCardWithTrend extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String label;
  final double? trend;
  final VoidCallback onTap;

  const _DashboardStatCardWithTrend({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
    this.trend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
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
                Icon(icon, color: iconColor, size: 22),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: iconColor,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${trend! >= 0 ? '+' : ''}${trend!.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Icon(Icons.arrow_forward, color: iconColor.withValues(alpha: 0.6), size: 14),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
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

/// Metric card for completion rate and rating
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool showStars;
  final double rating;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.showStars = false,
    this.rating = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (showStars)
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  if (index < rating.floor()) {
                    return Icon(Icons.star_rounded, color: color, size: 16);
                  } else if (index < rating) {
                    return Icon(Icons.star_half_rounded, color: color, size: 16);
                  } else {
                    return Icon(Icons.star_outline_rounded, color: Colors.grey[300], size: 16);
                  }
                }),
              ],
            )
          else
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
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly goal progress card
class _MonthlyGoalCard extends StatelessWidget {
  final double currentEarnings;
  final double goal;
  final double progress;

  const _MonthlyGoalCard({
    required this.currentEarnings,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = goal - currentEarnings;
    final percentComplete = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
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
                'Monthly Goal Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentComplete%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₱${currentEarnings.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'of ₱${goal.toStringAsFixed(0)} goal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              if (remaining > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${remaining.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Goal Reached!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4CAF50),
                        ),
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

/// Weekly performance bar chart
class _WeeklyPerformanceChart extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, int> jobCounts;

  const _WeeklyPerformanceChart({
    required this.data,
    required this.jobCounts,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.values.isEmpty ? 1.0 : data.values.reduce(math.max);
    final maxHeight = maxValue > 0 ? maxValue : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chart
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.entries.map((entry) {
                final barHeight = maxHeight > 0 ? (entry.value / maxHeight) * 120 : 0.0;
                final isToday = entry.key == DateFormat('EEE').format(DateTime.now());
                final jobCount = jobCounts[entry.key] ?? 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${entry.key}: ₱${entry.value.toStringAsFixed(0)} ($jobCount jobs)'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.value > 0)
                          Text(
                            '₱${entry.value >= 1000 ? '${(entry.value / 1000).toStringAsFixed(1)}k' : entry.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isToday ? AppTheme.deepBlue : Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: barHeight > 0 ? barHeight : 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isToday
                                  ? [const Color(0xFF4F7CFF), const Color(0xFF667eea)]
                                  : [Colors.grey.shade300, Colors.grey.shade400],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? AppTheme.deepBlue : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F7CFF), Color(0xFF667eea)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Today',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Previous days',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Job status donut chart
class _JobStatusChart extends StatelessWidget {
  final int requested;
  final int active;
  final int completed;
  final int cancelled;
  final int total;

  const _JobStatusChart({
    required this.requested,
    required this.active,
    required this.completed,
    required this.cancelled,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = total > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Donut Chart
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _DonutChartPainter(
                requested: requested,
                active: active,
                completed: completed,
                cancelled: cancelled,
                total: total,
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
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(
                  color: const Color(0xFFFF9800),
                  label: 'Pending',
                  value: requested,
                  percentage: hasData ? (requested / total * 100) : 0,
                ),
                const SizedBox(height: 8),
                _LegendItem(
                  color: const Color(0xFF2196F3),
                  label: 'Active',
                  value: active,
                  percentage: hasData ? (active / total * 100) : 0,
                ),
                const SizedBox(height: 8),
                _LegendItem(
                  color: const Color(0xFF4CAF50),
                  label: 'Completed',
                  value: completed,
                  percentage: hasData ? (completed / total * 100) : 0,
                ),
                const SizedBox(height: 8),
                _LegendItem(
                  color: Colors.red,
                  label: 'Cancelled',
                  value: cancelled,
                  percentage: hasData ? (cancelled / total * 100) : 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final double percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${percentage.toStringAsFixed(0)}%)',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for donut chart
class _DonutChartPainter extends CustomPainter {
  final int requested;
  final int active;
  final int completed;
  final int cancelled;
  final int total;

  _DonutChartPainter({
    required this.requested,
    required this.active,
    required this.completed,
    required this.cancelled,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 16.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background circle
    paint.color = Colors.grey.shade200;
    canvas.drawCircle(center, radius, paint);

    if (total == 0) return;

    // Calculate angles
    const startAngle = -math.pi / 2;
    double currentAngle = startAngle;

    // Draw segments
    final segments = [
      (requested, const Color(0xFFFF9800)),
      (active, const Color(0xFF2196F3)),
      (completed, const Color(0xFF4CAF50)),
      (cancelled, Colors.red),
    ];

    for (final segment in segments) {
      if (segment.$1 > 0) {
        final sweepAngle = (segment.$1 / total) * 2 * math.pi;
        paint.color = segment.$2;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          currentAngle,
          sweepAngle - 0.05, // Small gap between segments
          false,
          paint,
        );
        currentAngle += sweepAngle;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
