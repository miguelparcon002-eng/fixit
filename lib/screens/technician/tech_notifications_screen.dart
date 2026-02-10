import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isRead;
  final String type;
  final String? route;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
    required this.type,
    this.route,
  });
}

class TechNotificationsScreen extends StatefulWidget {
  const TechNotificationsScreen({super.key});

  @override
  State<TechNotificationsScreen> createState() => _TechNotificationsScreenState();
}

class _TechNotificationsScreenState extends State<TechNotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'New Job Request 🔔',
      message: 'iPhone 14 Pro screen replacement needed at Barangay 1, SFADS. Customer is willing to pay ₱5,499.',
      time: '2 minutes ago',
      icon: Icons.assignment_outlined,
      iconColor: AppTheme.primaryCyan,
      type: 'job_request',
      route: '/tech-jobs',
    ),
    NotificationItem(
      id: '2',
      title: 'Job Accepted ✅',
      message: 'You have successfully accepted the MacBook Pro battery replacement job. Customer is waiting for confirmation.',
      time: '15 minutes ago',
      icon: Icons.check_circle,
      iconColor: AppTheme.successColor,
      type: 'job_accepted',
      isRead: true,
      route: '/tech-jobs',
    ),
    NotificationItem(
      id: '3',
      title: 'Payment Received 💰',
      message: 'You received ₱3,450 payment for Samsung Galaxy screen repair. Amount will be transferred in 3-5 business days.',
      time: '1 hour ago',
      icon: Icons.payments,
      iconColor: Colors.green,
      type: 'payment',
      route: '/tech-earnings',
    ),
    NotificationItem(
      id: '4',
      title: 'Upcoming Appointment',
      message: 'Reminder: You have a laptop repair appointment at 3:00 PM today at Barangay 3, SFADS.',
      time: '2 hours ago',
      icon: Icons.schedule,
      iconColor: AppTheme.warningColor,
      type: 'reminder',
      isRead: true,
      route: '/tech-jobs',
    ),
    NotificationItem(
      id: '5',
      title: 'New Message from Customer',
      message: 'Maria Santos: "Are you still available for the repair today? Please let me know."',
      time: '3 hours ago',
      icon: Icons.message,
      iconColor: AppTheme.lightBlue,
      type: 'message',
      route: '/tech-jobs',
    ),
    NotificationItem(
      id: '6',
      title: 'New Review ⭐',
      message: 'John Michael left you a 5-star review: "Excellent service! Very professional and quick repair."',
      time: '5 hours ago',
      icon: Icons.star,
      iconColor: Colors.amber,
      type: 'review',
      isRead: true,
      route: '/tech-ratings',
    ),
    NotificationItem(
      id: '7',
      title: 'Job Completion Reminder',
      message: 'Don\'t forget to mark the iPhone screen repair job as completed after finishing the work.',
      time: '1 day ago',
      icon: Icons.task_alt,
      iconColor: AppTheme.deepBlue,
      type: 'reminder',
      isRead: true,
      route: '/tech-jobs',
    ),
    NotificationItem(
      id: '8',
      title: 'Weekly Summary 📊',
      message: 'Great work this week! You completed 12 jobs and earned ₱18,500. Keep up the excellent service!',
      time: '2 days ago',
      icon: Icons.analytics,
      iconColor: AppTheme.accentPurple,
      type: 'summary',
      isRead: true,
      route: '/tech-earnings',
    ),
    NotificationItem(
      id: '9',
      title: 'Promo Code Available 🎁',
      message: 'Use promo code TECH20 to get 20% off on repair parts this month. Valid until end of month.',
      time: '3 days ago',
      icon: Icons.local_offer,
      iconColor: AppTheme.errorColor,
      type: 'promo',
      isRead: true,
    ),
  ];

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          time: _notifications[index].time,
          icon: _notifications[index].icon,
          iconColor: _notifications[index].iconColor,
          type: _notifications[index].type,
          route: _notifications[index].route,
          isRead: true,
        );
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationItem(
          id: _notifications[i].id,
          title: _notifications[i].title,
          message: _notifications[i].message,
          time: _notifications[i].time,
          icon: _notifications[i].icon,
          iconColor: _notifications[i].iconColor,
          type: _notifications[i].type,
          route: _notifications[i].route,
          isRead: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount new notification${unreadCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppTheme.deepBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: _notifications.isEmpty
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
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      notification: notification,
                      onTap: () {
                        _markAsRead(notification.id);
                        if (notification.route != null) {
                          context.push(notification.route!);
                        }
                      },
                      onDismiss: () => _removeNotification(notification.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : AppTheme.primaryCyan.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.shade200
              : AppTheme.primaryCyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
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
                          InkWell(
                            onTap: onDismiss,
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey[400],
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
