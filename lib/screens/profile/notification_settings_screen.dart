import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/notification_settings_provider.dart';
import '../../services/notification_settings_service.dart';
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Failed to load settings')),
          data: (settings) => _SettingsBody(settings: settings),
        ),
      ),
    );
  }
}
class _SettingsBody extends ConsumerWidget {
  final NotificationSettings settings;
  const _SettingsBody({required this.settings});
  void _toggle(WidgetRef ref, NotificationSettings updated) {
    ref.read(notificationSettingsProvider.notifier).save(updated);
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s =
        ref.watch(notificationSettingsProvider).valueOrNull ?? settings;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.notifications_rounded,
            iconColor: AppTheme.primaryCyan,
            title: 'General',
          ),
          const SizedBox(height: 12),
          _NotifTile(
            icon: Icons.notifications_active_rounded,
            iconColor: AppTheme.primaryCyan,
            title: 'Push Notifications',
            subtitle: 'Receive push notifications on your device',
            value: s.pushNotifications,
            onChanged: (v) => _toggle(ref, s.copyWith(pushNotifications: v)),
          ),
          const SizedBox(height: 10),
          _NotifTile(
            icon: Icons.email_rounded,
            iconColor: AppTheme.deepBlue,
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            value: s.emailNotifications,
            onChanged: (v) =>
                _toggle(ref, s.copyWith(emailNotifications: v)),
          ),
          const SizedBox(height: 10),
          _NotifTile(
            icon: Icons.sms_rounded,
            iconColor: AppTheme.accentPurple,
            title: 'SMS Notifications',
            subtitle: 'Receive updates via text message',
            value: s.smsNotifications,
            onChanged: (v) =>
                _toggle(ref, s.copyWith(smsNotifications: v)),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.build_rounded,
            iconColor: AppTheme.successColor,
            title: 'Booking & Service',
          ),
          const SizedBox(height: 12),
          _NotifTile(
            icon: Icons.calendar_month_rounded,
            iconColor: AppTheme.successColor,
            title: 'Booking Updates',
            subtitle: 'Status changes, confirmations, cancellations',
            value: s.bookingUpdates,
            onChanged: (v) => _toggle(ref, s.copyWith(bookingUpdates: v)),
          ),
          const SizedBox(height: 10),
          _NotifTile(
            icon: Icons.chat_rounded,
            iconColor: AppTheme.lightBlue,
            title: 'Technician Messages',
            subtitle: 'Messages from your assigned technician',
            value: s.technicianMessages,
            onChanged: (v) =>
                _toggle(ref, s.copyWith(technicianMessages: v)),
          ),
          const SizedBox(height: 10),
          _NotifTile(
            icon: Icons.task_alt_rounded,
            iconColor: AppTheme.successColor,
            title: 'Service Completed',
            subtitle: 'Notifications when your service is done',
            value: s.serviceCompleted,
            onChanged: (v) =>
                _toggle(ref, s.copyWith(serviceCompleted: v)),
          ),
          const SizedBox(height: 10),
          _NotifTile(
            icon: Icons.payment_rounded,
            iconColor: AppTheme.warningColor,
            title: 'Payment Reminders',
            subtitle: 'Reminders for pending payments',
            value: s.paymentReminders,
            onChanged: (v) =>
                _toggle(ref, s.copyWith(paymentReminders: v)),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.local_offer_rounded,
            iconColor: AppTheme.accentPurple,
            title: 'Promotions & Offers',
          ),
          const SizedBox(height: 12),
          _NotifTile(
            icon: Icons.discount_rounded,
            iconColor: AppTheme.accentPurple,
            title: 'Promotional Notifications',
            subtitle: 'Discounts, special offers, and deals',
            value: s.promotional,
            onChanged: (v) => _toggle(ref, s.copyWith(promotional: v)),
          ),
          const SizedBox(height: 10),
          _NotifTile(
            icon: Icons.new_releases_rounded,
            iconColor: AppTheme.warningColor,
            title: 'New Offers',
            subtitle: 'Be the first to know about new services',
            value: s.newOffers,
            onChanged: (v) => _toggle(ref, s.copyWith(newOffers: v)),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryCyan.withValues(alpha: 0.08),
                  AppTheme.deepBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryCyan.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: AppTheme.darkCyan, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'You can change these settings anytime. Some notifications may still be sent for important account updates.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: iconColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
class _NotifTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
            height: 1.4,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: iconColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ),
    );
  }
}