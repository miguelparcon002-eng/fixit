import 'package:shared_preferences/shared_preferences.dart';

class StorageDebug {
  static Future<void> printAllKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    print('=== All SharedPreferences Keys ===');
    for (var key in keys) {
      final value = prefs.get(key);
      print('$key: ${value.toString().substring(0, value.toString().length > 100 ? 100 : value.toString().length)}...');
    }
    print('==================================');
  }

  static Future<void> printBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = prefs.getString('local_bookings');
    print('=== Bookings Data ===');
    print(bookings ?? 'NULL');
    print('=====================');
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('All data cleared!');
  }
}
