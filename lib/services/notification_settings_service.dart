import '../core/config/supabase_config.dart';
import '../core/utils/app_logger.dart';
class NotificationSettings {
  final String userId;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool bookingUpdates;
  final bool technicianMessages;
  final bool serviceCompleted;
  final bool paymentReminders;
  final bool promotional;
  final bool newOffers;
  const NotificationSettings({
    required this.userId,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.bookingUpdates = true,
    this.technicianMessages = true,
    this.serviceCompleted = true,
    this.paymentReminders = true,
    this.promotional = true,
    this.newOffers = false,
  });
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['user_id'] as String,
      pushNotifications: (json['push_notifications'] as bool?) ?? true,
      emailNotifications: (json['email_notifications'] as bool?) ?? true,
      smsNotifications: (json['sms_notifications'] as bool?) ?? false,
      bookingUpdates: (json['booking_updates'] as bool?) ?? true,
      technicianMessages: (json['technician_messages'] as bool?) ?? true,
      serviceCompleted: (json['service_completed'] as bool?) ?? true,
      paymentReminders: (json['payment_reminders'] as bool?) ?? true,
      promotional: (json['promotional'] as bool?) ?? true,
      newOffers: (json['new_offers'] as bool?) ?? false,
    );
  }
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'push_notifications': pushNotifications,
        'email_notifications': emailNotifications,
        'sms_notifications': smsNotifications,
        'booking_updates': bookingUpdates,
        'technician_messages': technicianMessages,
        'service_completed': serviceCompleted,
        'payment_reminders': paymentReminders,
        'promotional': promotional,
        'new_offers': newOffers,
      };
  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? bookingUpdates,
    bool? technicianMessages,
    bool? serviceCompleted,
    bool? paymentReminders,
    bool? promotional,
    bool? newOffers,
  }) {
    return NotificationSettings(
      userId: userId,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      technicianMessages: technicianMessages ?? this.technicianMessages,
      serviceCompleted: serviceCompleted ?? this.serviceCompleted,
      paymentReminders: paymentReminders ?? this.paymentReminders,
      promotional: promotional ?? this.promotional,
      newOffers: newOffers ?? this.newOffers,
    );
  }
  bool allows(String type) {
    switch (type) {
      case 'job_request':
      case 'booking_request':
      case 'job_accepted':
        return bookingUpdates;
      case 'reminder':
        return bookingUpdates;
      case 'payment':
        return paymentReminders;
      case 'message':
        return technicianMessages;
      case 'service_completed':
        return serviceCompleted;
      case 'promotional':
        return promotional;
      case 'new_offer':
        return newOffers;
      case 'verification_result':
      case 'rating':
      default:
        return true;
    }
  }
}
class NotificationSettingsService {
  final _supabase = SupabaseConfig.client;
  static const _table = 'user_notification_settings';
  Future<NotificationSettings> getSettings(String userId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) {
        return NotificationSettings(userId: userId);
      }
      return NotificationSettings.fromJson(response);
    } catch (e) {
      AppLogger.p('NotificationSettingsService: getSettings error - $e');
      return NotificationSettings(userId: userId);
    }
  }
  Future<void> saveSettings(NotificationSettings settings) async {
    try {
      await _supabase.from(_table).upsert(
            settings.toJson(),
            onConflict: 'user_id',
          );
    } catch (e) {
      AppLogger.p('NotificationSettingsService: saveSettings error - $e');
    }
  }
}