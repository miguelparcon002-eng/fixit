import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_dashboard_stats.dart';
import '../services/admin_dashboard_service.dart';

final adminDashboardServiceProvider = Provider((ref) => AdminDashboardService());

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((ref) async {
  final svc = ref.watch(adminDashboardServiceProvider);
  return svc.load();
});
