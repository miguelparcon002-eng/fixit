import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_reports_service.dart';

final adminReportsServiceProvider = Provider((ref) => AdminReportsService());

final adminReportsPeriodProvider = StateProvider<String>((ref) => 'Month');

final adminReportsProvider = FutureProvider<AdminReportsData>((ref) async {
  final service = ref.watch(adminReportsServiceProvider);
  ref.watch(adminReportsPeriodProvider); // re-fetch when period changes
  return service.load();
});
