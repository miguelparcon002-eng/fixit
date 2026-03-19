import '../core/config/supabase_config.dart';
import '../core/utils/app_logger.dart';

class Rating {
  final String id;
  final String customerName;
  final String technician;
  final int rating;
  final String review;
  final String date;
  final String service;
  final String device;
  final String bookingId;

  Rating({
    required this.id,
    required this.customerName,
    required this.technician,
    required this.rating,
    required this.review,
    required this.date,
    required this.service,
    required this.device,
    required this.bookingId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_name': customerName,
    'technician': technician,
    'rating': rating,
    'review': review,
    'date': date,
    'service': service,
    'device': device,
    'booking_id': bookingId,
  };

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    id: json['id'] as String,
    customerName: json['customer_name'] as String,
    technician: json['technician'] as String,
    rating: json['rating'] as int,
    review: json['review'] as String? ?? '',
    date: json['date'] as String,
    service: json['service'] as String,
    device: json['device'] as String,
    bookingId: json['booking_id'] as String? ?? '',
  );

  // Convert from Supabase response
  factory Rating.fromSupabase(Map<String, dynamic> json) => Rating(
    id: json['id'] as String,
    customerName: json['customer_name'] as String,
    technician: json['technician'] as String,
    rating: json['rating'] as int,
    review: json['review'] as String? ?? '',
    date: json['date'] as String,
    service: json['service'] as String,
    device: json['device'] as String,
    bookingId: '', // Not stored in app_ratings table
  );
}

class RatingsService {
  static const String _tableName = 'app_ratings';

  Future<List<Rating>> getAllRatings() async {
    try {
      AppLogger.p('RatingsService: Loading all ratings from Supabase...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      AppLogger.p('RatingsService: Loaded ${response.length} ratings');
      return (response as List).map((item) => Rating.fromSupabase(item)).toList();
    } catch (e) {
      AppLogger.p('RatingsService: Error loading ratings - $e');
      return [];
    }
  }

  Future<List<Rating>> getRatingsForTechnician(String technician) async {
    try {
      AppLogger.p('RatingsService: Loading ratings for $technician...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .ilike('technician', technician)
          .order('created_at', ascending: false);

      AppLogger.p('RatingsService: Found ${response.length} ratings for $technician');
      return (response as List).map((item) => Rating.fromSupabase(item)).toList();
    } catch (e) {
      AppLogger.p('RatingsService: Error loading ratings - $e');
      return [];
    }
  }

  Future<void> addRating(Rating rating) async {
    try {
      AppLogger.p('RatingsService: Adding rating to Supabase...');

      await SupabaseConfig.client
          .from(_tableName)
          .insert({
            'customer_name': rating.customerName,
            'technician': rating.technician,
            'rating': rating.rating,
            'review': rating.review,
            'date': rating.date,
            'service': rating.service,
            'device': rating.device,
          });

      AppLogger.p('RatingsService: Rating added successfully');
    } catch (e) {
      AppLogger.p('RatingsService: Error adding rating - $e');
    }
  }

  /// Same flexible name matching used by the technician's own ratings screen
  static bool _nameMatches(String storedTech, String technicianName) {
    final stored = storedTech.toLowerCase().trim();
    final myName = technicianName.toLowerCase().trim();
    if (stored == myName) return true;
    if (myName.contains(stored) && stored.length > 2) return true;
    final parts = myName.split(' ');
    if (parts.length > 1 && stored == parts.last.toLowerCase()) return true;
    return false;
  }

  /// Fetch all reviews for a technician from app_ratings.
  /// Primary: query by technician_id UUID (reliable).
  /// Fallback: flexible name matching for older rows without technician_id.
  Future<List<Rating>> getAllReviewsForTechnician(String technicianName, String technicianId) async {
    final results = <Rating>[];
    final seenIds = <String>{};

    // 1. From app_ratings by technician_id UUID (most reliable, post-SQL-migration)
    try {
      final r1 = await SupabaseConfig.client
          .from('app_ratings')
          .select()
          .eq('technician_id', technicianId)
          .order('created_at', ascending: false);
      for (final item in (r1 as List)) {
        final rating = Rating.fromSupabase(item);
        if (seenIds.add(rating.id)) results.add(rating);
      }
    } catch (_) {
      // technician_id column not yet added — fall through to name matching
    }

    // 2. Fallback: name matching for legacy rows without technician_id
    try {
      final r2 = await SupabaseConfig.client
          .from('app_ratings')
          .select()
          .order('created_at', ascending: false);
      final matched = (r2 as List)
          .where((item) {
            final id = item['id'] as String? ?? '';
            if (seenIds.contains(id)) return false;
            if (item['technician_id'] != null) return false;
            return _nameMatches(item['technician'] as String? ?? '', technicianName);
          })
          .map((item) => Rating.fromSupabase(item))
          .toList();
      results.addAll(matched);
    } catch (e) {
      AppLogger.p('RatingsService: app_ratings name-fallback query failed — $e');
    }

    // Deduplicate by row id
    final seen = <String>{};
    final deduped = <Rating>[];
    for (final r in results) {
      final key = r.id;
      if (seen.add(key)) deduped.add(r);
    }
    return deduped;
  }

  Future<bool> hasRatingForBooking(String bookingId) async {
    // For now, since we don't store booking_id in app_ratings,
    // we'll return false. You can enhance this later if needed.
    return false;
  }

  Future<Rating?> getRatingForBooking(String bookingId) async {
    // For now, since we don't store booking_id in app_ratings,
    // we'll return null. You can enhance this later if needed.
    return null;
  }
}
