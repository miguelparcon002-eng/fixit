import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_earnings_model.dart';
import '../services/admin_earnings_service.dart';
final adminEarningsServiceProvider = Provider((ref) => AdminEarningsService());
final adminEarningsOverviewProvider = FutureProvider<AdminEarningsOverview>((ref) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getEarningsOverview();
});
final allTechniciansEarningsProvider = FutureProvider<List<TechnicianEarnings>>((ref) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getAllTechniciansEarnings();
});
final technicianEarningsProvider = FutureProvider.family<TechnicianEarnings, String>((ref, technicianId) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getTechnicianEarnings(technicianId);
});
final technicianTransactionsProvider = FutureProvider.family<List<EarningsTransaction>, String>((ref, technicianId) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getTechnicianTransactions(technicianId);
});
final allCustomersSpendingProvider = FutureProvider<List<CustomerSpending>>((ref) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getAllCustomersSpending();
});