import '../core/config/supabase_config.dart';

class DistanceFeeService {
  static const _table = 'app_settings';
  static const _key = 'distance_fee_per_100m';

  /// Returns the current fee rate (₱ per 100 m). Defaults to 5.0 if not set.
  static Future<double> getRate() async {
    try {
      final rows = await SupabaseConfig.client
          .from(_table)
          .select('setting_value')
          .eq('setting_key', _key)
          .limit(1);
      final list = rows as List;
      if (list.isNotEmpty) {
        final val = list.first['setting_value'];
        return double.tryParse(val.toString()) ?? 5.0;
      }
    } catch (_) {}
    return 5.0;
  }

  /// Saves a new rate. Creates the row if it doesn't exist yet.
  static Future<void> setRate(double ratePerHundredM) async {
    await SupabaseConfig.client.from(_table).upsert({
      'setting_key': _key,
      'setting_value': ratePerHundredM,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'setting_key');
  }
}
