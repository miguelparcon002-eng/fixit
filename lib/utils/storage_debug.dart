import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';

class StorageDebug {
  static Future<void> printAllKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    AppLogger.p('=== All SharedPreferences Keys ===');
    for (var key in keys) {
      final value = prefs.get(key);
      AppLogger.p('$key: ${value.toString().substring(0, value.toString().length > 100 ? 100 : value.toString().length)}...');
    }
    AppLogger.p('==================================');
  }

  static Future<void> printBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = prefs.getString('local_bookings');
    AppLogger.p('=== Bookings Data ===');
    AppLogger.p(bookings ?? 'NULL');
    AppLogger.p('=====================');
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    AppLogger.p('All data cleared!');
  }
}
