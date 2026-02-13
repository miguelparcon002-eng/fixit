import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);

  // If there's no auth session, don't hit the DB (and don't log noise).
  if (authService.currentUser == null) {
    return null;
  }

  // On some devices / networks the profile row can be briefly unavailable right
  // after login (or the first read can fail transiently). Retrying avoids the
  // UX bug where users have to "login twice".
  const maxAttempts = 3;
  var attempt = 0;

  while (true) {
    attempt++;
    try {
      final profile = await authService.getCurrentUserProfile();

      // If auth has a user but profile is still null, treat as transient and retry.
      if (profile == null && authService.currentUser != null && attempt < maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
        continue;
      }

      return profile;
    } catch (_) {
      if (authService.currentUser != null && attempt < maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
        continue;
      }
      rethrow;
    }
  }
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.role;
});

final isVerifiedProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isUserVerified();
});
