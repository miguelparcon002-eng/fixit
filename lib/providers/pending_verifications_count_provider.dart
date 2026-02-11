import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/verification_request_model.dart';
import '../providers/verification_provider.dart';

/// A polling-based pending verifications stream.
///
/// Use this if Supabase realtime isn't enabled/reliable in the current project.
final pendingVerificationsPollingProvider =
    StreamProvider<List<VerificationRequestModel>>((ref) {
  final service = ref.watch(verificationServiceProvider);

  // Emit immediately, then poll every 3 seconds.
  final controller = StreamController<List<VerificationRequestModel>>();

  Future<void> emit() async {
    try {
      final list = await service.getPendingVerifications();
      controller.add(list);
    } catch (e, st) {
      controller.addError(e, st);
    }
  }

  emit();
  final timer = Timer.periodic(const Duration(seconds: 3), (_) => emit());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
