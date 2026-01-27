import '../core/config/supabase_config.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class EarningsService {
  static const String _tableName = 'app_earnings';

  // Get current user ID for user-specific earnings
  String? get _userId => StorageService.currentUserId;

  Future<double> getTodayEarnings() async {
    if (_userId == null) return 0.0;

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      print('EarningsService: Loading today earnings for user $_userId...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('amount')
          .eq('technician_id', _userId!)
          .eq('date', today);

      double total = 0.0;
      for (var item in response as List) {
        total += (item['amount'] as num).toDouble();
      }

      print('EarningsService: Today earnings: ₱$total');
      return total;
    } catch (e) {
      print('EarningsService: Error loading today earnings - $e');
      return 0.0;
    }
  }

  Future<void> addEarning(double amount, String customerName, String service, String jobId) async {
    if (_userId == null) return;

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      print('EarningsService: Adding earning ₱$amount for user $_userId...');

      await SupabaseConfig.client
          .from(_tableName)
          .insert({
            'technician_id': _userId,
            'amount': amount,
            'customer_name': customerName,
            'service': service,
            'job_id': jobId,
            'date': today,
          });

      print('EarningsService: Earning added successfully');
    } catch (e) {
      print('EarningsService: Error adding earning - $e');
    }
  }

  Future<double> getTotalEarnings() async {
    if (_userId == null) return 0.0;

    try {
      print('EarningsService: Loading total earnings for user $_userId...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('amount')
          .eq('technician_id', _userId!);

      double total = 0.0;
      for (var item in response as List) {
        total += (item['amount'] as num).toDouble();
      }

      print('EarningsService: Total earnings: ₱$total');
      return total;
    } catch (e) {
      print('EarningsService: Error loading total earnings - $e');
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    if (_userId == null) return [];

    try {
      print('EarningsService: Loading transactions for user $_userId...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('technician_id', _userId!)
          .order('created_at', ascending: false)
          .limit(50);

      print('EarningsService: Loaded ${response.length} transactions');
      return (response as List).map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      print('EarningsService: Error loading transactions - $e');
      return [];
    }
  }

  Future<double> getWeekEarnings() async {
    if (_userId == null) return 0.0;

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('amount')
          .eq('technician_id', _userId!)
          .gte('date', startDate);

      double total = 0.0;
      for (var item in response as List) {
        total += (item['amount'] as num).toDouble();
      }

      return total;
    } catch (e) {
      print('EarningsService: Error loading week earnings - $e');
      return 0.0;
    }
  }

  Future<double> getMonthEarnings() async {
    if (_userId == null) return 0.0;

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startDate = DateFormat('yyyy-MM-dd').format(startOfMonth);

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('amount')
          .eq('technician_id', _userId!)
          .gte('date', startDate);

      double total = 0.0;
      for (var item in response as List) {
        total += (item['amount'] as num).toDouble();
      }

      return total;
    } catch (e) {
      print('EarningsService: Error loading month earnings - $e');
      return 0.0;
    }
  }
}
