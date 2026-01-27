import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/verification_request_model.dart';
import '../services/verification_service.dart';
import 'auth_provider.dart';

final verificationServiceProvider = Provider((ref) => VerificationService());

final userVerificationRequestProvider = FutureProvider<VerificationRequestModel?>((ref) async {
  final verificationService = ref.watch(verificationServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return null;

  return await verificationService.getUserVerificationRequest(user.id);
});

final pendingVerificationsProvider = StreamProvider<List<VerificationRequestModel>>((ref) {
  final verificationService = ref.watch(verificationServiceProvider);
  return verificationService.watchPendingVerifications();
});
