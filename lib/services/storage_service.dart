import 'package:shared_preferences/shared_preferences.dart';
class StorageService {
  StorageService._();
  static String? _currentUserId;
  static String? get currentUserId => _currentUserId;
  static void setCurrentUser(String? userId) {
    _currentUserId = userId;
  }
  static String _scopedKey(String key) {
    final prefix = _currentUserId == null ? 'global' : 'user:${_currentUserId!}';
    return '$prefix:$key';
  }
  static const String _globalBookingsKey = 'bookings';
  static Future<String?> loadGlobalBookings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scopedKey(_globalBookingsKey));
  }
  static Future<void> saveGlobalBookings(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(_globalBookingsKey), json);
  }
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
  }
}