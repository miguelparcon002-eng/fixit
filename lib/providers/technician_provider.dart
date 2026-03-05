import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/technician_profile_model.dart';
import '../services/technician_service.dart';
import 'auth_provider.dart';

final technicianServiceProvider = Provider((ref) => TechnicianService());

final technicianProfileProvider = FutureProvider.family<TechnicianProfileModel?, String>((ref, userId) async {
  final technicianService = ref.watch(technicianServiceProvider);
  return await technicianService.getProfileByUserId(userId);
});

// Watches the current technician's availability status.
// Returns null while loading or if no profile found.
final currentTechAvailabilityProvider = StreamProvider<bool?>((ref) async* {
  final userAsync = await ref.watch(currentUserProvider.future);
  if (userAsync == null) { yield null; return; }
  final service = ref.watch(technicianServiceProvider);
  final profile = await service.getProfileByUserId(userAsync.id);
  yield profile?.isAvailable;
});

// Notifier that loads and persists availability. Keyed on userId only (stable).
class TechAvailabilityNotifier extends StateNotifier<AsyncValue<bool>> {
  final TechnicianService _service;
  final String _userId;

  TechAvailabilityNotifier(this._service, this._userId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final profile = await _service.getProfileByUserId(_userId);
      if (mounted) state = AsyncValue.data(profile?.isAvailable ?? true);
    } catch (e, s) {
      if (mounted) state = AsyncValue.error(e, s);
    }
  }

  Future<void> setAvailability(bool value) async {
    state = const AsyncValue.loading();
    try {
      await _service.toggleAvailability(_userId, value);
      if (mounted) state = AsyncValue.data(value);
    } catch (e, s) {
      if (mounted) state = AsyncValue.error(e, s);
    }
  }
}

// Stable family keyed on userId only — provider survives re-renders.
final techAvailabilityProviderFamily =
    StateNotifierProvider.family<TechAvailabilityNotifier, AsyncValue<bool>, String>(
  (ref, userId) => TechAvailabilityNotifier(
    ref.watch(technicianServiceProvider),
    userId,
  ),
);

class SearchTechniciansParams {
  final String? specialty;
  final double? maxRate;
  final double? minRating;
  final bool? isAvailable;

  SearchTechniciansParams({
    this.specialty,
    this.maxRate,
    this.minRating,
    this.isAvailable,
  });
}

final searchTechniciansProvider = FutureProvider.family<List<TechnicianProfileModel>, SearchTechniciansParams>((ref, params) async {
  final technicianService = ref.watch(technicianServiceProvider);
  return await technicianService.searchTechnicians(
    specialty: params.specialty,
    maxRate: params.maxRate,
    minRating: params.minRating,
    isAvailable: params.isAvailable,
  );
});
