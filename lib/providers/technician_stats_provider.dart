import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/supabase_config.dart';
import 'booking_provider.dart';
import 'auth_provider.dart';
import '../core/utils/app_logger.dart';

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
    if (completedJobs < 50) return 'Skilled';
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


  Future<void> loadStats() async {
    if (_technicianName == null || _technicianId == null) {
      state = AsyncValue.data(TechnicianStats.empty());
      return;
    }

    try {
      state = const AsyncValue.loading();

      // 1. Calculate average — always combine UUID rows + legacy name-matched rows
      double averageRating = 0.0;
      int totalReviewCount = 0;
      try {
        final seenIds = <String>{};
        final vals = <int>[];

        // UUID rows (have technician_id set)
        try {
          final byId = await SupabaseConfig.client
              .from('app_ratings')
              .select('id, rating')
              .eq('technician_id', _technicianId!);
          for (final r in (byId as List)) {
            final id = r['id'] as String? ?? '';
            if (seenIds.add(id)) {
              vals.add((r['rating'] as num).toInt());
            }
          }
        } catch (_) {}

        // Legacy rows (no technician_id) — always run, not just when UUID returns empty
        final all = await SupabaseConfig.client
            .from('app_ratings')
            .select('id, rating, technician, technician_id');
        final myName = _technicianName!.toLowerCase();
        final nameParts = _technicianName!.split(' ');
        final lastName = nameParts.length > 1 ? nameParts.last.toLowerCase() : null;
        for (final r in (all as List)) {
          if (r['technician_id'] != null) continue; // already counted above
          final id = r['id'] as String? ?? '';
          if (seenIds.contains(id)) continue;
          final tech = (r['technician'] as String? ?? '').toLowerCase();
          final matches = tech == myName ||
              (myName.contains(tech) && tech.length > 2) ||
              (lastName != null && tech == lastName);
          if (matches && seenIds.add(id)) {
            vals.add((r['rating'] as num).toInt());
          }
        }

        if (vals.isNotEmpty) {
          averageRating = vals.reduce((a, b) => a + b) / vals.length;
          totalReviewCount = vals.length;
        }
        AppLogger.p('TechnicianStatsNotifier: ${vals.length} ratings for $_technicianName, average: $averageRating');
      } catch (e) {
        AppLogger.p('TechnicianStatsNotifier: app_ratings query failed — $e');
      }

      // 2. Count completed jobs from Supabase bookings
      final bookingsAsync = await _ref.read(technicianBookingsProvider.future);
      final completedBookings = bookingsAsync.where((b) => b.status == 'completed').toList();

      // 3. Calculate earnings from completed bookings (use finalCost or estimatedCost)
      double totalEarnings = 0.0;
      for (final booking in completedBookings) {
        totalEarnings += (booking.finalCost ?? booking.estimatedCost ?? 0.0);
      }

      AppLogger.p('TechnicianStatsNotifier: Counted ${completedBookings.length} completed jobs from Supabase');
      AppLogger.p('TechnicianStatsNotifier: Total earnings: ₱$totalEarnings from Supabase');

      // 4. Calculate experience level
      final experience = TechnicianStats.calculateExperience(completedBookings.length);

      final stats = TechnicianStats(
        averageRating: averageRating,
        totalReviews: totalReviewCount,
        completedJobs: completedBookings.length,
        totalEarnings: totalEarnings,
        experience: experience,
      );

      state = AsyncValue.data(stats);

      // 5. Persist stats to Supabase
      await _saveStatsToSupabase(stats);

      AppLogger.p('TechnicianStatsNotifier: Loaded stats - Rating: ${stats.averageRating}, Jobs: ${stats.completedJobs}, Earnings: ₱${stats.totalEarnings}');
    } catch (e, stack) {
      AppLogger.p('TechnicianStatsNotifier: Error loading stats - $e');
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

      AppLogger.p('TechnicianStatsNotifier: Stats saved to Supabase');
    } catch (e) {
      // Table might not exist yet, which is okay for now
      AppLogger.p('TechnicianStatsNotifier: Could not save stats to Supabase (table may not exist) - $e');
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
