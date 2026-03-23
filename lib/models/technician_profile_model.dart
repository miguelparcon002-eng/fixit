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
  final bool isBusy;
  final bool acceptRequestsWhileBusy;
  final double rating;
  final int totalJobs;
  final int acceptanceRate;
  final int? averageResponseTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Weekly schedule: keys are day names ("Monday"…"Sunday"),
  // values are {"enabled": bool, "start": "HH:mm", "end": "HH:mm"}
  // Stored in weekly_schedule JSONB column in technician_profiles.
  final Map<String, Map<String, dynamic>>? weeklySchedule;

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
    this.isBusy = false,
    this.acceptRequestsWhileBusy = false,
    this.rating = 0.0,
    this.totalJobs = 0,
    this.acceptanceRate = 0,
    this.averageResponseTime,
    required this.createdAt,
    this.updatedAt,
    this.weeklySchedule,
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
      isBusy: json['is_busy'] as bool? ?? false,
      acceptRequestsWhileBusy: json['accept_requests_while_busy'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalJobs: json['total_jobs'] as int? ?? 0,
      acceptanceRate: json['acceptance_rate'] as int? ?? 0,
      averageResponseTime: json['average_response_time'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      weeklySchedule: json['weekly_schedule'] != null
          ? Map<String, Map<String, dynamic>>.from(
              (json['weekly_schedule'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
              ),
            )
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
      'is_busy': isBusy,
      'accept_requests_while_busy': acceptRequestsWhileBusy,
      'rating': rating,
      'total_jobs': totalJobs,
      'acceptance_rate': acceptanceRate,
      'average_response_time': averageResponseTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'weekly_schedule': weeklySchedule,
    };
  }

  /// Returns true if the current time falls within today's scheduled hours.
  /// Falls back to [isAvailable] when no schedule is set.
  bool get isScheduledOnlineNow {
    if (weeklySchedule == null || weeklySchedule!.isEmpty) return isAvailable;
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[DateTime.now().weekday - 1];
    final dayData = weeklySchedule![dayName];
    if (dayData == null || dayData['enabled'] != true) return false;
    final startStr = (dayData['start'] as String?) ?? '09:00';
    final endStr   = (dayData['end']   as String?) ?? '18:00';
    final sp = startStr.split(':');
    final ep = endStr.split(':');
    final startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
    final endMin   = int.parse(ep[0]) * 60 + int.parse(ep[1]);
    final nowMin   = DateTime.now().hour * 60 + DateTime.now().minute;
    return nowMin >= startMin && nowMin < endMin;
  }
}
