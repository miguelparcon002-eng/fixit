import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/notification_settings_provider.dart';
import '../../services/notification_settings_service.dart';

class TechNotificationSettingsScreen extends ConsumerWidget {
  const TechNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tech-profile');
            }
          },
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, st) => const Center(child: Text('Failed to load settings')),
        data: (settings) => _TechSettingsBody(settings: settings),
      ),
    );
  }
}

class _TechSettingsBody extends ConsumerWidget {
  final NotificationSettings settings;

  const _TechSettingsBody({required this.settings});

  void _toggle(WidgetRef ref, NotificationSettings updated) {
    ref.read(notificationSettingsProvider.notifier).save(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(notificationSettingsProvider).valueOrNull ?? settings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── General ──────────────────────────────────────────
        _Section(
          title: 'General',
          children: [
            _NotificationTile(
              icon: Icons.notifications_active,
              iconColor: AppTheme.primaryCyan,
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              value: s.pushNotifications,
              onChanged: (v) => _toggle(ref, s.copyWith(pushNotifications: v)),
            ),
            _NotificationTile(
              icon: Icons.email,
              iconColor: AppTheme.deepBlue,
              title: 'Email Notifications',
              subtitle: 'Receive updates via email',
              value: s.emailNotifications,
              onChanged: (v) => _toggle(ref, s.copyWith(emailNotifications: v)),
            ),
            _NotificationTile(
              icon: Icons.sms,
              iconColor: AppTheme.accentPurple,
              title: 'SMS Notifications',
              subtitle: 'Receive updates via text message',
              value: s.smsNotifications,
              onChanged: (v) => _toggle(ref, s.copyWith(smsNotifications: v)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Job & Customer Updates ────────────────────────────
        _Section(
          title: 'Job & Customer Updates',
          children: [
            _NotificationTile(
              icon: Icons.work,
              iconColor: AppTheme.lightBlue,
              title: 'Job Updates',
              subtitle: 'New requests, status changes, reminders',
              value: s.bookingUpdates,
              onChanged: (v) => _toggle(ref, s.copyWith(bookingUpdates: v)),
            ),
            _NotificationTile(
              icon: Icons.message,
              iconColor: Colors.green,
              title: 'Customer Messages',
              subtitle: 'Messages from customers',
              value: s.technicianMessages,
              onChanged: (v) => _toggle(ref, s.copyWith(technicianMessages: v)),
            ),
            _NotificationTile(
              icon: Icons.payments,
              iconColor: AppTheme.successColor,
              title: 'Payment Reminders',
              subtitle: 'Payment and payout updates',
              value: s.paymentReminders,
              onChanged: (v) => _toggle(ref, s.copyWith(paymentReminders: v)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Marketing ─────────────────────────────────────────
        _Section(
          title: 'Marketing',
          children: [
            _NotificationTile(
              icon: Icons.local_offer,
              iconColor: AppTheme.warningColor,
              title: 'Promotional Notifications',
              subtitle: 'Offers and promotions from FixIt',
              value: s.promotional,
              onChanged: (v) => _toggle(ref, s.copyWith(promotional: v)),
            ),
            _NotificationTile(
              icon: Icons.new_releases,
              iconColor: AppTheme.accentPurple,
              title: 'New Offers',
              subtitle: 'Be the first to know about new services',
              value: s.newOffers,
              onChanged: (v) => _toggle(ref, s.copyWith(newOffers: v)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Text(
            'You can change these settings anytime. Some critical account notifications may still be sent.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primaryCyan,
          activeTrackColor: AppTheme.primaryCyan.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
