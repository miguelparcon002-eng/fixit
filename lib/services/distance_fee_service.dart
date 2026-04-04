import '../core/config/supabase_config.dart';
class DistanceFeeService {
  static const _table = 'app_settings';
  static const _key = 'distance_fee_per_100m';
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
  static Future<void> setRate(double ratePerHundredM) async {
    await SupabaseConfig.client.from(_table).upsert({
      'setting_key': _key,
      'setting_value': ratePerHundredM,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'setting_key');
  }
}