import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/notification_icon_mapper.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/app_logo.dart';
import '../../models/notification_model.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/admin_notifications_provider.dart';
import '../../providers/pending_verifications_count_provider.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final pendingVerificationsStream = ref.watch(pendingVerificationsPollingProvider);
    final unreadCount = ref.watch(adminUnreadNotificationsCountProvider);

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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showNotificationsSheet(context, ref),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
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

void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AdminNotificationsSheet(),
  );
}

class _AdminNotificationsSheet extends ConsumerWidget {
  const _AdminNotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(adminNotificationsFeedProvider);
    final unreadCount = ref.watch(adminUnreadNotificationsCountProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  const Spacer(),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () async {
                        final items = feedAsync.valueOrNull ?? [];
                        final svc = ref.read(adminNotificationsServiceProvider);
                        for (final n in items.where((n) => !n.isRead)) {
                          await svc.markAsRead(n.id);
                        }
                      },
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$unreadCount new notification${unreadCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: feedAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No notifications yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return _AdminNotificationCard(
                        notification: n,
                        onTap: () async {
                          final route = n.route;
                          if (!n.isRead) {
                            await ref
                                .read(adminNotificationsServiceProvider)
                                .markAsRead(n.id);
                          }
                          if (route != null && route.isNotEmpty && context.mounted) {
                            Navigator.of(context).pop();
                            context.go(route);
                          }
                        },
                        onDismiss: () async {
                          await ref
                              .read(adminNotificationsServiceProvider)
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AdminNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _AdminNotificationCard({
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
