import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

// Providers for notification settings
final pushNotificationsProvider = StateProvider<bool>((ref) => true);
final emailNotificationsProvider = StateProvider<bool>((ref) => true);
final smsNotificationsProvider = StateProvider<bool>((ref) => false);
final bookingUpdatesProvider = StateProvider<bool>((ref) => true);
final promotionalProvider = StateProvider<bool>((ref) => true);
final technicianMessagesProvider = StateProvider<bool>((ref) => true);
final paymentRemindersProvider = StateProvider<bool>((ref) => true);
final serviceCompletedProvider = StateProvider<bool>((ref) => true);
final newOffersProvider = StateProvider<bool>((ref) => false);

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Notification Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // General Notifications Section
              _buildSectionHeader('General'),
              const SizedBox(height: 12),
              _buildNotificationTile(
                context,
                ref,
                icon: Icons.notifications_active,
                iconColor: AppTheme.primaryCyan,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications on your device',
                provider: pushNotificationsProvider,
              ),
              _buildNotificationTile(
                context,
                ref,
                icon: Icons.email_outlined,
                iconColor: AppTheme.deepBlue,
                title: 'Email Notifications',
                subtitle: 'Receive updates via email',
                provider: emailNotificationsProvider,
              ),
              _buildNotificationTile(
                context,
                ref,
                icon: Icons.sms_outlined,
                iconColor: AppTheme.accentPurple,
                title: 'SMS Notifications',
                subtitle: 'Receive updates via text message',
                provider: smsNotificationsProvider,
              ),

              const SizedBox(height: 24),
              // Booking & Service Section
              _buildSectionHeader('Booking & Service'),
              const SizedBox(height: 12),
              _buildNotificationTile(
                context,
                ref,
                icon: Icons.calendar_today,
                iconColor: AppTheme.successColor,
                title: 'Booking Updates',
                subtitle: 'Status changes, confirmations, cancellations',
                provider: bookingUpdatesProvider,
              ),
              _buildNotificationTile(
                context,
                ref,
                icon: Icons.message_outlined,
                iconColor: AppTheme.lightBlue,
                title: 'Technician Messages',
                subtitle: 'Messages from your assigned technician',
                provider: technicianMessagesProvider,
              ),
              _buildNotificationTile(
                context,
                ref,
                icon: Icons.task_alt,
                iconColor: AppTheme.successColor,
                title: 'Service Completed',
                subtitle: 'Notifications when your service is done',
                provider: serviceCompletedProvider,
              ),
              _buildNotificationTile(
                context,
                ref,
                icon: Icons.payment,
                iconColor: AppTheme.warningColor,
                title: 'Payment Reminders',
                subtitle: 'Reminders for pending payments',
                provider: paymentRemindersProvider,
              ),

              const SizedBox(height: 24),
              // Promotions Section
              _buildSectionHeader('Promotions & Offers'),
              const SizedBox(height: 12),
              _buildNotificationTile(
                context,
                ref,
                icon: Icons.local_offer,
                iconColor: AppTheme.accentPurple,
                title: 'Promotional Notifications',
                subtitle: 'Discounts, special offers, and deals',
                provider: promotionalProvider,
              ),
              _buildNotificationTile(
                context,
                ref,
                icon: Icons.new_releases,
                iconColor: AppTheme.warningColor,
                title: 'New Offers',
                subtitle: 'Be the first to know about new services',
                provider: newOffersProvider,
              ),

              const SizedBox(height: 32),
              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.darkCyan,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can change these settings anytime. Some notifications may still be sent for important account updates.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required StateProvider<bool> provider,
  }) {
    final isEnabled = ref.watch(provider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
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
          value: isEnabled,
          onChanged: (value) {
            ref.read(provider.notifier).state = value;
          },
          activeThumbColor: AppTheme.primaryCyan,
          activeTrackColor: AppTheme.primaryCyan.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
