import 'package:shared_preferences/shared_preferences.dart';

/// Simple local storage helper with per-user key isolation.
///
/// This project uses it to prevent data leaking between accounts by prefixing
/// keys with the currently authenticated user's id.
class StorageService {
  StorageService._();

  static String? _currentUserId;

  static String? get currentUserId => _currentUserId;

  static void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }

  static String _scopedKey(String key) {
    // If no user, store in a global namespace.
    final prefix = _currentUserId == null ? 'global' : 'user:${_currentUserId!}';
    return '$prefix:$key';
  }

  /// Used by the booking migration utility.
  static const String _globalBookingsKey = 'bookings';

  /// Loads legacy/global bookings JSON.
  /// NOTE: Kept for backwards compatibility with existing migration utilities.
  static Future<String?> loadGlobalBookings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scopedKey(_globalBookingsKey));
  }

  static Future<void> saveGlobalBookings(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(_globalBookingsKey), json);
  }

  // Generic helpers
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(key), value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scopedKey(key));
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scopedKey(key));
  }

  static Future<void> clearCurrentUserScope() async {
    // SharedPreferences does not support prefix deletes; keep this as a no-op.
    // Providers are invalidated on logout instead.
  }
}
