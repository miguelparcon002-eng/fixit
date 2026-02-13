import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_earnings_model.dart';
import '../services/admin_earnings_service.dart';

final adminEarningsServiceProvider = Provider((ref) => AdminEarningsService());

/// Overall platform earnings overview
final adminEarningsOverviewProvider = FutureProvider<AdminEarningsOverview>((ref) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getEarningsOverview();
});

/// All technicians earnings list
final allTechniciansEarningsProvider = FutureProvider<List<TechnicianEarnings>>((ref) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getAllTechniciansEarnings();
});

/// Specific technician earnings
final technicianEarningsProvider = FutureProvider.family<TechnicianEarnings, String>((ref, technicianId) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getTechnicianEarnings(technicianId);
});

/// Specific technician transaction history
final technicianTransactionsProvider = FutureProvider.family<List<EarningsTransaction>, String>((ref, technicianId) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getTechnicianTransactions(technicianId);
});

/// All customers spending data
final allCustomersSpendingProvider = FutureProvider<List<CustomerSpending>>((ref) async {
  final service = ref.watch(adminEarningsServiceProvider);
  return service.getAllCustomersSpending();
});
