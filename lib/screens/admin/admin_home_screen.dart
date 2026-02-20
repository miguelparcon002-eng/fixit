import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/pending_verifications_count_provider.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final pendingVerificationsStream = ref.watch(pendingVerificationsPollingProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(
              size: 30,
              showText: false,
              assetPath: 'assets/images/logo_square.png',
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminDashboardStatsProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: statsAsync.when(
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminDashboardStatsProvider);
              await ref.read(adminDashboardStatsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Quick stats
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _StatCard(
                      title: 'Pending\nVerifications',
                      value: pendingVerificationsStream.maybeWhen(
                        data: (items) => '${items.length}',
                        orElse: () => '${stats.pendingVerifications}',
                      ),
                      icon: Icons.verified_user,
                      color: Colors.orange,
                      onTap: () => context.go('/verification-review'),
                    ),
                    _StatCard(
                      title: 'Open\nTickets',
                      value: '${stats.openSupportTickets}',
                      icon: Icons.support_agent,
                      color: AppTheme.lightBlue,
                      onTap: () => context.go('/admin-support'),
                    ),
                    _StatCard(
                      title: 'Bookings\nToday',
                      value: '${stats.bookingsToday}',
                      icon: Icons.today,
                      color: Colors.green,
                      onTap: () => context.go('/admin-appointments?range=day&status=all'),
                    ),
                    _StatCard(
                      title: 'Total\nBookings',
                      value: '${stats.totalBookings}',
                      icon: Icons.receipt_long,
                      color: AppTheme.deepBlue,
                      onTap: () => context.go('/admin-appointments?range=month&status=all'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _SectionTitle('Management'),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.people,
                  color: AppTheme.deepBlue,
                  title: 'Customers',
                  subtitle: '${stats.totalCustomers} total',
                  onTap: () => context.go('/admin-customers'),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.engineering,
                  color: AppTheme.accentPurple,
                  title: 'Technicians',
                  subtitle: '${stats.totalTechnicians} total',
                  onTap: () => context.go('/admin-technicians'),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.star,
                  color: Colors.pink,
                  title: 'Reviews',
                  subtitle: 'View customer feedback',
                  onTap: () => context.go('/admin-reviews'),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  title: 'Earnings Management',
                  subtitle: 'Track technician & customer earnings',
                  onTap: () => context.go('/admin-earnings'),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.bar_chart,
                  color: AppTheme.lightBlue,
                  title: 'Reports',
                  subtitle: 'Platform performance',
                  onTap: () => context.go('/admin-reports'),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.qr_code,
                  color: Colors.green,
                  title: 'Payment Settings',
                  subtitle: 'GCash QR code & details',
                  onTap: () => context.push('/admin-payment-settings'),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.feedback,
                  color: Colors.orange,
                  title: 'Feedback & Bug Reports',
                  subtitle: 'View customer feedback',
                  onTap: () => context.push('/admin-feedback'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Failed to load dashboard stats:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(adminDashboardStatsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}
