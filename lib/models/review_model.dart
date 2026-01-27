class ReviewModel {
  final String id;
  final String bookingId;
  final String customerId;
  final String technicianId;
  final int rating;
  final String? review;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.technicianId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      customerId: json['customer_id'] as String,
      technicianId: json['technician_id'] as String,
      rating: json['rating'] as int,
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'customer_id': customerId,
      'technician_id': technicianId,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
