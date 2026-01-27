import '../core/config/supabase_config.dart';

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
      print('RatingsService: Loading all ratings from Supabase...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      print('RatingsService: Loaded ${response.length} ratings');
      return (response as List).map((item) => Rating.fromSupabase(item)).toList();
    } catch (e) {
      print('RatingsService: Error loading ratings - $e');
      return [];
    }
  }

  Future<List<Rating>> getRatingsForTechnician(String technician) async {
    try {
      print('RatingsService: Loading ratings for $technician...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('technician', technician)
          .order('created_at', ascending: false);

      print('RatingsService: Found ${response.length} ratings for $technician');
      return (response as List).map((item) => Rating.fromSupabase(item)).toList();
    } catch (e) {
      print('RatingsService: Error loading ratings - $e');
      return [];
    }
  }

  Future<void> addRating(Rating rating) async {
    try {
      print('RatingsService: Adding rating to Supabase...');

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

      print('RatingsService: Rating added successfully');
    } catch (e) {
      print('RatingsService: Error adding rating - $e');
    }
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
