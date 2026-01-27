class TechnicianProfileModel {
  final String id;
  final String userId;
  final List<String> specialties;
  final int yearsExperience;
  final String? bio;
  final String? shopName;
  final List<String> certifications;
  final List<String> tools;
  final double? hourlyRate;
  final double? diagnosticFee;
  final String? warrantyPolicy;
  final int? turnaroundTime;
  final double? serviceRadius;
  final bool isAvailable;
  final double rating;
  final int totalJobs;
  final int acceptanceRate;
  final int? averageResponseTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TechnicianProfileModel({
    required this.id,
    required this.userId,
    required this.specialties,
    this.yearsExperience = 0,
    this.bio,
    this.shopName,
    this.certifications = const [],
    this.tools = const [],
    this.hourlyRate,
    this.diagnosticFee,
    this.warrantyPolicy,
    this.turnaroundTime,
    this.serviceRadius,
    this.isAvailable = true,
    this.rating = 0.0,
    this.totalJobs = 0,
    this.acceptanceRate = 0,
    this.averageResponseTime,
    required this.createdAt,
    this.updatedAt,
  });

  factory TechnicianProfileModel.fromJson(Map<String, dynamic> json) {
    return TechnicianProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      specialties: List<String>.from(json['specialties'] as List),
      yearsExperience: json['years_experience'] as int? ?? 0,
      bio: json['bio'] as String?,
      shopName: json['shop_name'] as String?,
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'] as List)
          : [],
      tools: json['tools'] != null
          ? List<String>.from(json['tools'] as List)
          : [],
      hourlyRate: json['hourly_rate'] as double?,
      diagnosticFee: json['diagnostic_fee'] as double?,
      warrantyPolicy: json['warranty_policy'] as String?,
      turnaroundTime: json['turnaround_time'] as int?,
      serviceRadius: json['service_radius'] as double?,
      isAvailable: json['is_available'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalJobs: json['total_jobs'] as int? ?? 0,
      acceptanceRate: json['acceptance_rate'] as int? ?? 0,
      averageResponseTime: json['average_response_time'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'specialties': specialties,
      'years_experience': yearsExperience,
      'bio': bio,
      'shop_name': shopName,
      'certifications': certifications,
      'tools': tools,
      'hourly_rate': hourlyRate,
      'diagnostic_fee': diagnosticFee,
      'warranty_policy': warrantyPolicy,
      'turnaround_time': turnaroundTime,
      'service_radius': serviceRadius,
      'is_available': isAvailable,
      'rating': rating,
      'total_jobs': totalJobs,
      'acceptance_rate': acceptanceRate,
      'average_response_time': averageResponseTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
