import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_technician_actions_service.dart';

final adminTechnicianActionsServiceProvider =
    Provider((ref) => AdminTechnicianActionsService());
