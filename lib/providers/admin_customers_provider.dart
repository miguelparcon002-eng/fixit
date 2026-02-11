import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_customer_user.dart';
import '../services/admin_customers_service.dart';

final adminCustomersServiceProvider = Provider((ref) => AdminCustomersService());

final adminCustomersProvider = FutureProvider<List<AdminCustomerUser>>((ref) async {
  return ref.watch(adminCustomersServiceProvider).listCustomers();
});

final adminCustomerByIdProvider = FutureProvider.family<AdminCustomerUser?, String>((ref, id) async {
  return ref.watch(adminCustomersServiceProvider).getCustomer(id);
});
