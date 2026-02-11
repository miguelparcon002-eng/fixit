class AdminCustomerUser {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final bool verified;
  final bool isSuspended;
  final String? profilePicture;
  final DateTime? createdAt;
  final DateTime? lastBookingAt;

  bool get isActive {
    final last = lastBookingAt;
    if (last == null) return false;
    return DateTime.now().difference(last).inDays < 7;
  }

  const AdminCustomerUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.verified,
    required this.isSuspended,
    required this.profilePicture,
    required this.createdAt,
    required this.lastBookingAt,
  });

  factory AdminCustomerUser.fromJson(Map<String, dynamic> json) {
    return AdminCustomerUser(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? 'Customer',
      email: (json['email'] as String?) ?? '',
      phone: json['contact_number'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      verified: (json['verified'] as bool?) ?? false,
      isSuspended: (json['is_suspended'] as bool?) ?? false,
      profilePicture: json['profile_picture'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastBookingAt: json['last_booking_at'] != null
          ? DateTime.tryParse(json['last_booking_at'] as String)
          : null,
    );
  }
}
