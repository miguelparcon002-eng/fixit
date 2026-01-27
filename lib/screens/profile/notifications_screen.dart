import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

// Provider to track if promo notification should be shown
final promoNotificationProvider = StateProvider<bool>((ref) => false);

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isRead;
  final String type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
    required this.type,
  });
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<NotificationItem> _getNotifications() {
    final showPromo = ref.watch(promoNotificationProvider);

    final baseNotifications = [
      NotificationItem(
        id: '1',
        title: 'Welcome to FixIT! 🎉',
        message: 'Your account has been successfully created. Book your first repair service and get 10% off!',
        time: '2 hours ago',
        icon: Icons.celebration,
        iconColor: AppTheme.primaryCyan,
        type: 'welcome',
      ),
    ];

    // Add promo notification at the top if claimed
    if (showPromo) {
      baseNotifications.insert(0, NotificationItem(
        id: '0',
        title: '20% OFF Promo Code! 🎁',
        message: 'Your promo code FIRST20 is ready to use! Apply it at checkout to get 20% off your first repair.',
        time: 'Just now',
        icon: Icons.local_offer,
        iconColor: AppTheme.warningColor,
        type: 'promo',
        isRead: false,
      ));
    }

    return baseNotifications;
  }

  @override
  Widget build(BuildContext context) {
    // Combine all notifications
    final notifications = [
      ..._getNotifications(),
      NotificationItem(
        id: '2',
        title: 'Booking Confirmed',
        message: 'Your iPhone screen repair has been confirmed. Technician Estino will arrive at 2:00 PM today.',
        time: '5 hours ago',
        icon: Icons.check_circle,
        iconColor: AppTheme.successColor,
        type: 'booking',
        isRead: true,
      ),
      NotificationItem(
        id: '3',
        title: 'Special Offer: 20% OFF! 🔥',
        message: 'Get 20% off on all laptop repairs this weekend. Book now and save big on your repairs!',
        time: '1 day ago',
        icon: Icons.local_offer,
        iconColor: AppTheme.accentPurple,
        type: 'promotion',
      ),
      NotificationItem(
        id: '4',
        title: 'New Message from Technician',
        message: 'Estino sent you a message: "I\'m on my way, will reach in 15 minutes."',
        time: '1 day ago',
        icon: Icons.message,
        iconColor: AppTheme.lightBlue,
        type: 'message',
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        title: 'Service Completed ✅',
        message: 'Your MacBook Pro repair has been successfully completed. Rate your experience!',
        time: '2 days ago',
        icon: Icons.task_alt,
        iconColor: AppTheme.successColor,
        type: 'completed',
        isRead: true,
      ),
      NotificationItem(
        id: '6',
        title: 'Payment Reminder',
        message: 'Payment of ₱1,299 is pending for your laptop repair. Please complete the payment.',
        time: '3 days ago',
        icon: Icons.payment,
        iconColor: AppTheme.warningColor,
        type: 'payment',
      ),
      NotificationItem(
        id: '7',
        title: 'New Technician Available',
        message: 'We have 5 certified technicians available in your area. Book a repair service now!',
        time: '3 days ago',
        icon: Icons.person_add,
        iconColor: AppTheme.deepBlue,
        type: 'info',
        isRead: true,
      ),
      NotificationItem(
        id: '8',
        title: 'Feedback Request',
        message: 'How was your experience with Estino? Your feedback helps us improve our service.',
        time: '4 days ago',
        icon: Icons.star_rate,
        iconColor: AppTheme.warningColor,
        type: 'feedback',
        isRead: true,
      ),
    ];

    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount new notification${unreadCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in notifications) {
                    notification.isRead == false;
                  }
                });
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
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
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(notification: notification),
                  );
                },
              ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppTheme.primaryCyan.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? Colors.grey.shade200 : AppTheme.primaryCyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle notification tap
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notification.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
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
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
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
      ),
    );
  }
}
