enum CustomerStatus {
  active,
  inactive,
  suspended,
}

class CustomerModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final CustomerStatus status;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double totalSpent;
  final List<String> addresses;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    this.status = CustomerStatus.active,
    required this.createdAt,
    this.lastActiveAt,
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.totalSpent = 0.0,
    this.addresses = const [],
  });

  // Check if customer is currently active (active within last 7 days)
  bool get isCurrentlyActive {
    if (lastActiveAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt!);
    return difference.inDays <= 7;
  }

  // Get activity status string
  String get activityStatus {
    if (lastActiveAt == null) return 'Never active';
    if (isCurrentlyActive) return 'Active';
    final now = DateTime.now();
    final difference = now.difference(lastActiveAt!);
    if (difference.inDays <= 30) return 'Active ${difference.inDays} days ago';
    if (difference.inDays <= 90) return 'Inactive (${(difference.inDays / 30).floor()} months ago)';
    return 'Inactive';
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      status: CustomerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CustomerStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      totalBookings: json['total_bookings'] as int? ?? 0,
      completedBookings: json['completed_bookings'] as int? ?? 0,
      cancelledBookings: json['cancelled_bookings'] as int? ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      addresses: json['addresses'] != null
          ? List<String>.from(json['addresses'] as List)
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'total_bookings': totalBookings,
      'completed_bookings': completedBookings,
      'cancelled_bookings': cancelledBookings,
      'total_spent': totalSpent,
      'addresses': addresses,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    CustomerStatus? status,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? totalBookings,
    int? completedBookings,
    int? cancelledBookings,
    double? totalSpent,
    List<String>? addresses,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalBookings: totalBookings ?? this.totalBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
      totalSpent: totalSpent ?? this.totalSpent,
      addresses: addresses ?? this.addresses,
    );
  }
}

class CustomerBookingHistory {
  final String bookingId;
  final String serviceName;
  final String technicianName;
  final DateTime bookingDate;
  final String status;
  final double amount;

  CustomerBookingHistory({
    required this.bookingId,
    required this.serviceName,
    required this.technicianName,
    required this.bookingDate,
    required this.status,
    required this.amount,
  });

  factory CustomerBookingHistory.fromJson(Map<String, dynamic> json) {
    return CustomerBookingHistory(
      bookingId: json['booking_id'] as String,
      serviceName: json['service_name'] as String,
      technicianName: json['technician_name'] as String,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'service_name': serviceName,
      'technician_name': technicianName,
      'booking_date': bookingDate.toIso8601String(),
      'status': status,
      'amount': amount,
    };
  }
}
