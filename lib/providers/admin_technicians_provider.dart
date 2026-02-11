import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_technician_list_item.dart';
import '../services/admin_technicians_service.dart';

final adminTechniciansServiceProvider = Provider((ref) => AdminTechniciansService());

final adminTechniciansProvider = FutureProvider<List<AdminTechnicianListItem>>((ref) async {
  final svc = ref.watch(adminTechniciansServiceProvider);
  return svc.listTechnicians();
});
