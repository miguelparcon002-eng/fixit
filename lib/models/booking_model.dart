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

  // Helper getters for UI compatibility (matching LocalBooking fields)
  String get icon => '📱'; // Default icon
  
  String get deviceName => 'Service'; // Will be replaced when we fetch service details
  
  String get serviceName => 'Repair Service'; // Will be replaced when we fetch service details
  
  String get date {
    if (scheduledDate == null) return 'TBD';
    final date = scheduledDate!;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  String get time {
    if (scheduledDate == null) return 'TBD';
    final date = scheduledDate!;
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
  
  String get location => customerAddress ?? 'N/A';
  
  String get technician => 'Technician'; // Will be replaced when we fetch technician details
  
  String get total => '₱${finalCost?.toStringAsFixed(2) ?? estimatedCost?.toStringAsFixed(2) ?? '0.00'}';
  
  String get customerName => 'Customer'; // Will be replaced when we fetch customer details
  
  String get customerPhone => 'No phone'; // Will be replaced when we fetch customer details
  
  String get priority => 'Normal';
  
  String? get moreDetails {
    // Extract only the customer's original booking details (before "---TECHNICIAN NOTES---")
    if (diagnosticNotes == null) return null;
    final parts = diagnosticNotes!.split('---TECHNICIAN NOTES---');
    return parts[0].trim();
  }

  String? get technicianNotes {
    // Extract only technician's notes (after "---TECHNICIAN NOTES---")
    if (diagnosticNotes == null) return null;
    final parts = diagnosticNotes!.split('---TECHNICIAN NOTES---');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return null;
  }

  String? get promoCode {
    if (diagnosticNotes == null) return null;
    final match = RegExp(r'Promo Code: ([A-Z0-9]+)').firstMatch(diagnosticNotes!);
    return match?.group(1);
  }

  String? get discountAmount {
    if (diagnosticNotes == null) return null;
    final match = RegExp(r'Discount: ([\d.]+%|₱[\d.]+)').firstMatch(diagnosticNotes!);
    return match?.group(1);
  }

  String? get originalPrice {
    if (diagnosticNotes == null) return null;
    final match = RegExp(r'Original Price: ₱([\d.]+)').firstMatch(diagnosticNotes!);
    if (match != null) {
      return '₱${match.group(1)}';
    }
    return null;
  }
}
