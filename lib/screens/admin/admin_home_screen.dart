import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../providers/booking_provider.dart';
import '../../providers/support_ticket_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_session_service.dart';
import 'widgets/admin_notifications_dialog.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(localBookingsProvider);
    final openTicketsCount = ref.watch(openTicketsCountProvider);
    final activeCustomersCount = ref.watch(activeCustomersCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppLogo(size: 48),
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications, size: 28, color: Colors.black),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AdminNotificationsDialog(),
                              );
                            },
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 24, color: Colors.black),
                        onPressed: () async {
                          // Clear session data first
                          await ref.read(userSessionServiceProvider).onUserLogout();
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Export Report Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exporting report...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Export Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Stats Grid and Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0,
                      children: [
                        _StatCard(
                          icon: Icons.calendar_today,
                          iconColor: AppTheme.lightBlue,
                          iconBgColor: AppTheme.lightBlue.withValues(alpha: 0.2),
                          value: '145',
                          label: 'Total Bookings',
                          percentage: '+12%',
                          isPositive: true,
                        ),
                        _StatCard(
                          icon: Icons.build,
                          iconColor: Colors.orange,
                          iconBgColor: Colors.orange.withValues(alpha: 0.2),
                          value: '23',
                          label: 'Active Repairs',
                          percentage: '+5%',
                          isPositive: true,
                        ),
                        _StatCard(
                          icon: Icons.attach_money,
                          iconColor: Colors.green,
                          iconBgColor: Colors.green.withValues(alpha: 0.2),
                          value: '₱100,450',
                          label: 'Revenue Today',
                          percentage: '+18%',
                          isPositive: true,
                        ),
                        _StatCard(
                          icon: Icons.people,
                          iconColor: Colors.purple,
                          iconBgColor: Colors.purple.withValues(alpha: 0.2),
                          value: '8',
                          label: 'Active Technicians',
                          percentage: '0%',
                          isPositive: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.support_agent,
                            label: 'Customer Support',
                            badge: openTicketsCount > 0 ? '$openTicketsCount' : null,
                            badgeColor: Colors.red,
                            onTap: () => context.push('/admin-support'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.verified_user,
                            label: 'Verifications',
                            badge: '2',
                            badgeColor: Colors.orange,
                            onTap: () => context.push('/verification-review'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.people,
                            label: 'Customers',
                            badge: activeCustomersCount > 0 ? '$activeCustomersCount active' : null,
                            badgeColor: Colors.green,
                            onTap: () => context.push('/admin-customers'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Recent Appointments
                    const Text(
                      'Recent Appointments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...bookings.map((booking) {
                      Color priorityColor;
                      switch (booking.priority) {
                        case 'high':
                          priorityColor = const Color(0xFFFF6B6B);
                          break;
                        case 'medium':
                          priorityColor = Colors.yellow.shade700;
                          break;
                        case 'low':
                          priorityColor = Colors.green;
                          break;
                        default:
                          priorityColor = Colors.grey;
                      }

                      Color statusColor;
                      String statusText = booking.status.toLowerCase();
                      String displayStatus = statusText;
                      switch (statusText) {
                        case 'scheduled':
                          statusColor = const Color(0xFFFF9800);
                          displayStatus = 'requesting';
                          break;
                        case 'in progress':
                          statusColor = AppTheme.lightBlue;
                          break;
                        case 'completed':
                          statusColor = Colors.green;
                          break;
                        default:
                          statusColor = Colors.grey;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AppointmentCard(
                          jobId: booking.id,
                          priority: booking.priority,
                          priorityColor: priorityColor,
                          status: displayStatus,
                          statusColor: statusColor,
                          customerName: booking.customerName,
                          device: '${booking.deviceName} - ${booking.serviceName}',
                          technician: 'Technician: ${booking.technician}',
                          time: 'Time: ${booking.time}',
                        ),
                      );
                    }),
                    if (bookings.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No appointments yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String value;
  final String label;
  final String percentage;
  final bool isPositive;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.value,
    required this.label,
    required this.percentage,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPositive ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String jobId;
  final String priority;
  final Color priorityColor;
  final String status;
  final Color statusColor;
  final String customerName;
  final String device;
  final String technician;
  final String time;

  const _AppointmentCard({
    required this.jobId,
    required this.priority,
    required this.priorityColor,
    required this.status,
    required this.statusColor,
    required this.customerName,
    required this.device,
    required this.technician,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                jobId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priority,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
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
          if (customerName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              customerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              device,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              technician,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Contacting $customerName...')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.deepBlue,
                    side: const BorderSide(color: AppTheme.deepBlue),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: const Text('Contact'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.push('/booking/$jobId');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeColor,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.deepBlue, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
