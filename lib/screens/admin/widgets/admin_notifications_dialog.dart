import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isRead;
  final String type;
  final String? route; // Route to navigate when tapped

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

class AdminNotificationsDialog extends StatefulWidget {
  const AdminNotificationsDialog({super.key});

  @override
  State<AdminNotificationsDialog> createState() =>
      _AdminNotificationsDialogState();
}

class _AdminNotificationsDialogState extends State<AdminNotificationsDialog> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'High Priority Booking',
      message: 'Emergency repair request for water damaged iPhone 15 Pro',
      time: '5 minutes ago',
      icon: Icons.priority_high,
      iconColor: const Color(0xFFFF6B6B),
      type: 'urgent',
      route: '/admin-bookings',
    ),
    NotificationItem(
      id: '2',
      title: 'Technician Check-In',
      message: 'Ethanjames has started the screen replacement job',
      time: '8 minutes ago',
      icon: Icons.engineering,
      iconColor: AppTheme.lightBlue,
      type: 'technician',
      isRead: true,
      route: '/admin-team',
    ),
    NotificationItem(
      id: '3',
      title: 'Job Completed',
      message: 'Shen Anthony completed MacBook battery replacement for #FX156',
      time: '15 minutes ago',
      icon: Icons.check_circle,
      iconColor: Colors.green,
      type: 'completed',
      route: '/admin-bookings',
    ),
    NotificationItem(
      id: '4',
      title: 'Appointment Reminder',
      message: 'Upcoming appointment at 4:00 PM - Emily Davis laptop repair',
      time: '30 minutes ago',
      icon: Icons.schedule,
      iconColor: Colors.orange,
      type: 'reminder',
      route: '/admin-bookings',
    ),
    NotificationItem(
      id: '5',
      title: 'New Customer Registration',
      message: 'John Michael registered and booked iPhone screen repair',
      time: '45 minutes ago',
      icon: Icons.person_add,
      iconColor: Colors.purple,
      type: 'customer',
      isRead: true,
      route: '/admin-customers',
    ),
    NotificationItem(
      id: '6',
      title: 'Payment Received',
      message: '₱10,000 payment confirmed for job #FX156',
      time: '1 hour ago',
      icon: Icons.payments,
      iconColor: Colors.green,
      type: 'payment',
      route: '/admin-reports',
    ),
    NotificationItem(
      id: '7',
      title: 'Technician Unavailable',
      message: 'Sarah Chen marked as unavailable due to emergency',
      time: '2 hours ago',
      icon: Icons.warning,
      iconColor: Colors.amber,
      type: 'warning',
      isRead: true,
      route: '/admin-team',
    ),
    NotificationItem(
      id: '8',
      title: 'New Review',
      message: 'Hernan Miguel left 5-star review for technician Shen Anthony',
      time: '3 hours ago',
      icon: Icons.star,
      iconColor: Colors.amber,
      type: 'review',
      isRead: true,
      route: '/admin-reviews',
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

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      if (unreadCount > 0)
                        Text(
                          '$unreadCount new notification${unreadCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Notifications List
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
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
                              Navigator.of(context).pop();
                              if (notification.route != null) {
                                context.go(notification.route!);
                              }
                            },
                            onDismiss: () =>
                                _removeNotification(notification.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
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
