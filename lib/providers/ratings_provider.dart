import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ratings_service.dart';

// Provider for RatingsService
final ratingsServiceProvider = Provider<RatingsService>((ref) {
  return RatingsService();
});

// Provider for ratings list
final ratingsProvider = StateNotifierProvider<RatingsNotifier, AsyncValue<List<Rating>>>((ref) {
  final ratingsService = ref.watch(ratingsServiceProvider);
  return RatingsNotifier(ratingsService);
});

class RatingsNotifier extends StateNotifier<AsyncValue<List<Rating>>> {
  final RatingsService _ratingsService;

  RatingsNotifier(this._ratingsService) : super(const AsyncValue.loading()) {
    loadRatings();
  }

  Future<void> loadRatings() async {
    state = const AsyncValue.loading();
    try {
      final ratings = await _ratingsService.getAllRatings();
      state = AsyncValue.data(ratings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addRating(Rating rating) async {
    try {
      await _ratingsService.addRating(rating);
      await loadRatings(); // Reload after adding
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<Rating>> getRatingsForTechnician(String technician) async {
    final allRatings = state.value ?? [];
    return allRatings.where((r) => r.technician == technician).toList();
  }
}
