import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_customer_actions_service.dart';

final adminCustomerActionsServiceProvider =
    Provider((ref) => AdminCustomerActionsService());
