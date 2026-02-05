import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import '../services/ratings_service.dart';
import 'booking_provider.dart';
import 'auth_provider.dart';
import 'ratings_provider.dart';
import 'earnings_provider.dart';

// Re-export Rating class for use in this file
export '../services/ratings_service.dart' show Rating;

/// Model to hold technician statistics
class TechnicianStats {
  final double averageRating;
  final int totalReviews;
  final int completedJobs;
  final double totalEarnings;
  final String experience;

  TechnicianStats({
    required this.averageRating,
    required this.totalReviews,
    required this.completedJobs,
    required this.totalEarnings,
    required this.experience,
  });

  factory TechnicianStats.empty() => TechnicianStats(
    averageRating: 0.0,
    totalReviews: 0,
    completedJobs: 0,
    totalEarnings: 0.0,
    experience: 'New',
  );

  /// Calculate experience level based on completed jobs
  static String calculateExperience(int completedJobs) {
    if (completedJobs == 0) return 'New';
    if (completedJobs < 10) return 'Beginner';
    if (completedJobs < 25) return 'Intermediate';
    if (completedJobs < 50) return 'Experienced';
    if (completedJobs < 100) return 'Expert';
    return 'Master';
  }

  TechnicianStats copyWith({
    double? averageRating,
    int? totalReviews,
    int? completedJobs,
    double? totalEarnings,
    String? experience,
  }) {
    return TechnicianStats(
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedJobs: completedJobs ?? this.completedJobs,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      experience: experience ?? this.experience,
    );
  }
}

/// Provider for technician statistics
class TechnicianStatsNotifier extends StateNotifier<AsyncValue<TechnicianStats>> {
  final Ref _ref;
  String? _technicianName;
  String? _technicianId;

  TechnicianStatsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    // Wait for user data
    final user = await _ref.read(currentUserProvider.future);
    if (user != null) {
      _technicianName = user.fullName;
      _technicianId = user.id;
      await loadStats();
    } else {
      state = AsyncValue.data(TechnicianStats.empty());
    }
  }

  /// Helper to check if rating belongs to this technician
  bool _isRatingForTechnician(String ratingTechnician, String userName) {
    final userNameLower = userName.toLowerCase();
    final ratingTechLower = ratingTechnician.toLowerCase();

    if (ratingTechLower == userNameLower) return true;
    if (userNameLower.contains(ratingTechLower)) return true;

    final nameParts = userName.split(' ');
    if (nameParts.length > 1) {
      final lastName = nameParts.last.toLowerCase();
      if (lastName == ratingTechLower) return true;
    }

    return false;
  }

  Future<void> loadStats() async {
    if (_technicianName == null || _technicianId == null) {
      state = AsyncValue.data(TechnicianStats.empty());
      return;
    }

    try {
      state = const AsyncValue.loading();

      // 1. Get ratings for this technician - load directly from Supabase for accuracy
      List<Rating> allRatings = [];

      // First try to get from provider
      final ratingsAsync = _ref.read(ratingsProvider);
      if (ratingsAsync.hasValue && ratingsAsync.value!.isNotEmpty) {
        allRatings = ratingsAsync.value!;
      } else {
        // If provider doesn't have data, load directly from Supabase
        try {
          final ratingsService = _ref.read(ratingsServiceProvider);
          allRatings = await ratingsService.getAllRatings();
          print('TechnicianStatsNotifier: Loaded ${allRatings.length} ratings from Supabase');
        } catch (e) {
          print('TechnicianStatsNotifier: Could not load ratings from Supabase - $e');
        }
      }

      final technicianRatings = allRatings.where(
        (r) => _isRatingForTechnician(r.technician, _technicianName!)
      ).toList();

      double averageRating = 0.0;
      if (technicianRatings.isNotEmpty) {
        final sum = technicianRatings.map((r) => r.rating).reduce((a, b) => a + b);
        averageRating = sum / technicianRatings.length;
      }

      print('TechnicianStatsNotifier: Found ${technicianRatings.length} ratings for $_technicianName, average: $averageRating');

      // 2. Count completed jobs from Supabase bookings
      final bookingsAsync = await _ref.read(technicianBookingsProvider.future);
      final completedBookings = bookingsAsync.where((b) => b.status == 'completed').toList();

      // 3. Calculate earnings from completed bookings (use finalCost or estimatedCost)
      double totalEarnings = 0.0;
      for (final booking in completedBookings) {
        totalEarnings += (booking.finalCost ?? booking.estimatedCost ?? 0.0);
      }

      print('TechnicianStatsNotifier: Counted ${completedBookings.length} completed jobs from Supabase');
      print('TechnicianStatsNotifier: Total earnings: ₱$totalEarnings from Supabase');

      // 4. Calculate experience level
      final experience = TechnicianStats.calculateExperience(completedBookings.length);

      final stats = TechnicianStats(
        averageRating: averageRating,
        totalReviews: technicianRatings.length,
        completedJobs: completedBookings.length,
        totalEarnings: totalEarnings,
        experience: experience,
      );

      state = AsyncValue.data(stats);

      // 5. Persist stats to Supabase
      await _saveStatsToSupabase(stats);

      print('TechnicianStatsNotifier: Loaded stats - Rating: ${stats.averageRating}, Jobs: ${stats.completedJobs}, Earnings: ₱${stats.totalEarnings}');
    } catch (e, stack) {
      print('TechnicianStatsNotifier: Error loading stats - $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _saveStatsToSupabase(TechnicianStats stats) async {
    if (_technicianId == null) return;

    try {
      // Check if technician stats record exists
      final existing = await SupabaseConfig.client
          .from('app_technician_stats')
          .select()
          .eq('technician_id', _technicianId!)
          .maybeSingle();

      final data = {
        'technician_id': _technicianId,
        'average_rating': stats.averageRating,
        'total_reviews': stats.totalReviews,
        'completed_jobs': stats.completedJobs,
        'total_earnings': stats.totalEarnings,
        'experience': stats.experience,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        // Update existing record
        await SupabaseConfig.client
            .from('app_technician_stats')
            .update(data)
            .eq('technician_id', _technicianId!);
      } else {
        // Insert new record
        await SupabaseConfig.client
            .from('app_technician_stats')
            .insert(data);
      }

      print('TechnicianStatsNotifier: Stats saved to Supabase');
    } catch (e) {
      // Table might not exist yet, which is okay for now
      print('TechnicianStatsNotifier: Could not save stats to Supabase (table may not exist) - $e');
    }
  }

  /// Reload stats (call when user changes or data updates)
  Future<void> reload() async {
    final user = await _ref.read(currentUserProvider.future);
    if (user != null) {
      _technicianName = user.fullName;
      _technicianId = user.id;
    }
    await loadStats();
  }
}

final technicianStatsProvider = StateNotifierProvider<TechnicianStatsNotifier, AsyncValue<TechnicianStats>>((ref) {
  return TechnicianStatsNotifier(ref);
});
