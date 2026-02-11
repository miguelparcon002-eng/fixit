import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class TechnicianVerificationException implements Exception {
  final String message;
  TechnicianVerificationException(this.message);

  @override
  String toString() => message;
}

/// Guard for blocking technician "write" actions when not verified.
class TechnicianVerificationGuard {
  static Future<void> requireVerifiedForWrite(Ref ref) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      throw TechnicianVerificationException('Please sign in again.');
    }

    if (user.role == AppConstants.roleTechnician && !user.verified) {
      throw TechnicianVerificationException(
        'Verification required. You can browse the app, but actions are disabled until your account is approved.',
      );
    }
  }
}
