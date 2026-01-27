class BookingModel {
  final String id;
  final String customerId;
  final String technicianId;
  final String serviceId;
  final String status;
  final DateTime? scheduledDate;
  final String? customerAddress;
  final double? customerLatitude;
  final double? customerLongitude;
  final String? diagnosticNotes;
  final List<String> partsList;
  final double? estimatedCost;
  final double? finalCost;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? cancellationReason;
  final int? rating;
  final String? review;
  final String? invoiceUrl;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.technicianId,
    required this.serviceId,
    required this.status,
    this.scheduledDate,
    this.customerAddress,
    this.customerLatitude,
    this.customerLongitude,
    this.diagnosticNotes,
    this.partsList = const [],
    this.estimatedCost,
    this.finalCost,
    this.paymentMethod,
    this.paymentStatus,
    this.cancellationReason,
    this.rating,
    this.review,
    this.invoiceUrl,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      technicianId: json['technician_id'] as String,
      serviceId: json['service_id'] as String,
      status: json['status'] as String,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : null,
      customerAddress: json['customer_address'] as String?,
      customerLatitude: json['customer_latitude'] as double?,
      customerLongitude: json['customer_longitude'] as double?,
      diagnosticNotes: json['diagnostic_notes'] as String?,
      partsList: json['parts_list'] != null
          ? List<String>.from(json['parts_list'] as List)
          : [],
      estimatedCost: json['estimated_cost'] as double?,
      finalCost: json['final_cost'] as double?,
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      rating: json['rating'] as int?,
      review: json['review'] as String?,
      invoiceUrl: json['invoice_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'technician_id': technicianId,
      'service_id': serviceId,
      'status': status,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'customer_address': customerAddress,
      'customer_latitude': customerLatitude,
      'customer_longitude': customerLongitude,
      'diagnostic_notes': diagnosticNotes,
      'parts_list': partsList,
      'estimated_cost': estimatedCost,
      'final_cost': finalCost,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'cancellation_reason': cancellationReason,
      'rating': rating,
      'review': review,
      'invoice_url': invoiceUrl,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
