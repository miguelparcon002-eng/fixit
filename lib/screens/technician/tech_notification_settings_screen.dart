import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

// Technician notification settings (mirrors customer NotificationSettingsScreen)
final techPushNotificationsProvider = StateProvider<bool>((ref) => true);
final techEmailNotificationsProvider = StateProvider<bool>((ref) => true);
final techSmsNotificationsProvider = StateProvider<bool>((ref) => false);
final techJobUpdatesProvider = StateProvider<bool>((ref) => true);
final techPaymentRemindersProvider = StateProvider<bool>((ref) => true);
final techCustomerMessagesProvider = StateProvider<bool>((ref) => true);
final techPromotionalProvider = StateProvider<bool>((ref) => false);

class TechNotificationSettingsScreen extends ConsumerWidget {
  const TechNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'General',
            children: [
              _NotificationTile(
                icon: Icons.notifications_active,
                iconColor: AppTheme.primaryCyan,
                title: 'Push Notifications',
                subtitle: 'Receive notifications on your device',
                provider: techPushNotificationsProvider,
              ),
              _NotificationTile(
                icon: Icons.email,
                iconColor: AppTheme.deepBlue,
                title: 'Email Notifications',
                subtitle: 'Receive updates via email',
                provider: techEmailNotificationsProvider,
              ),
              _NotificationTile(
                icon: Icons.sms,
                iconColor: AppTheme.accentPurple,
                title: 'SMS Notifications',
                subtitle: 'Receive updates via text message',
                provider: techSmsNotificationsProvider,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Job & Customer Updates',
            children: [
              _NotificationTile(
                icon: Icons.work,
                iconColor: AppTheme.lightBlue,
                title: 'Job Updates',
                subtitle: 'New requests, status changes, reminders',
                provider: techJobUpdatesProvider,
              ),
              _NotificationTile(
                icon: Icons.message,
                iconColor: Colors.green,
                title: 'Customer Messages',
                subtitle: 'Messages from customers',
                provider: techCustomerMessagesProvider,
              ),
              _NotificationTile(
                icon: Icons.payments,
                iconColor: AppTheme.successColor,
                title: 'Payment Reminders',
                subtitle: 'Payment and payout updates',
                provider: techPaymentRemindersProvider,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Marketing',
            children: [
              _NotificationTile(
                icon: Icons.local_offer,
                iconColor: AppTheme.warningColor,
                title: 'Promotional Notifications',
                subtitle: 'Offers and promotions from FixIt',
                provider: techPromotionalProvider,
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
      ),
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

class _NotificationTile extends ConsumerWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final StateProvider<bool> provider;

  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(provider);

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
          value: enabled,
          onChanged: (v) => ref.read(provider.notifier).state = v,
          activeThumbColor: AppTheme.primaryCyan,
          activeTrackColor: AppTheme.primaryCyan.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
