class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool verified;
  final String? contactNumber;
  final String? address;
  final String? profilePicture;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? neighborhood;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.verified = false,
    this.contactNumber,
    this.address,
    this.profilePicture,
    this.latitude,
    this.longitude,
    this.city,
    this.neighborhood,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      verified: json['verified'] as bool? ?? false,
      contactNumber: json['contact_number'] as String?,
      address: json['address'] as String?,
      profilePicture: json['profile_picture'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      city: json['city'] as String?,
      neighborhood: json['neighborhood'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'verified': verified,
      'contact_number': contactNumber,
      'address': address,
      'profile_picture': profilePicture,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'neighborhood': neighborhood,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    bool? verified,
    String? contactNumber,
    String? address,
    String? profilePicture,
    double? latitude,
    double? longitude,
    String? city,
    String? neighborhood,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      verified: verified ?? this.verified,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
