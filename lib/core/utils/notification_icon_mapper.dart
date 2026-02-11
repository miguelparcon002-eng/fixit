import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

({IconData icon, Color color}) mapNotificationIcon(String type) {
  switch (type) {
    case 'job_request':
      return (icon: Icons.assignment_outlined, color: AppTheme.primaryCyan);
    case 'job_accepted':
      return (icon: Icons.check_circle, color: AppTheme.successColor);
    case 'payment':
      return (icon: Icons.payments, color: Colors.green);
    case 'reminder':
      return (icon: Icons.schedule, color: AppTheme.warningColor);
    case 'message':
      return (icon: Icons.message, color: AppTheme.lightBlue);
    case 'rating':
      return (icon: Icons.star, color: Colors.pink);
    default:
      return (icon: Icons.notifications, color: AppTheme.deepBlue);
  }
}
