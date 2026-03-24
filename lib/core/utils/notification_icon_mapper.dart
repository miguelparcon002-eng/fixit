import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

({IconData icon, Color color}) mapNotificationIcon(String type) {
  switch (type) {
    case 'job_request':
    case 'booking_request':
      return (icon: Icons.assignment_outlined, color: AppTheme.primaryCyan);
    case 'job_accepted':
    case 'booking_accepted':
    case 'job_request_accepted':
      return (icon: Icons.check_circle, color: AppTheme.successColor);
    case 'booking_started':
      return (icon: Icons.play_circle_outline, color: AppTheme.accentPurple);
    case 'booking_declined':
    case 'job_request_declined':
      return (icon: Icons.cancel, color: Colors.red);
    case 'booking_cancelled':
    case 'job_request_cancelled':
      return (icon: Icons.cancel_outlined, color: Colors.red);
    case 'booking_completed':
      return (icon: Icons.task_alt, color: AppTheme.successColor);
    case 'booking_update':
      return (icon: Icons.update_rounded, color: AppTheme.lightBlue);
    case 'booking_paid':
      return (icon: Icons.payments_rounded, color: Colors.green);
    case 'new_job_request':
      return (icon: Icons.notifications_active_rounded, color: AppTheme.warningColor);
    case 'tech_proposed':
      return (icon: Icons.person_pin_circle_rounded, color: AppTheme.deepBlue);
    case 'price_updated':
      return (icon: Icons.price_change_outlined, color: AppTheme.warningColor);
    case 'payment':
      return (icon: Icons.payments, color: Colors.green);
    case 'reminder':
      return (icon: Icons.schedule, color: AppTheme.warningColor);
    case 'message':
      return (icon: Icons.message, color: AppTheme.lightBlue);
    case 'rating':
      return (icon: Icons.star, color: Colors.pink);
    case 'verification_result':
      return (icon: Icons.verified_user, color: AppTheme.deepBlue);
    case 'support_reply':
      return (icon: Icons.support_agent, color: AppTheme.lightBlue);
    case 'support_update':
      return (icon: Icons.confirmation_number_outlined, color: Colors.teal);
    default:
      return (icon: Icons.notifications, color: AppTheme.deepBlue);
  }
}
