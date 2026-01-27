import 'package:uuid/uuid.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/db_constants.dart';
import '../models/technician_profile_model.dart';

class TechnicianService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  Future<TechnicianProfileModel> createProfile({
    required String userId,
    required List<String> specialties,
    int yearsExperience = 0,
    String? bio,
    String? shopName,
    List<String>? certifications,
    List<String>? tools,
    double? hourlyRate,
    double? diagnosticFee,
    String? warrantyPolicy,
    int? turnaroundTime,
    double? serviceRadius,
  }) async {
    final profileId = _uuid.v4();

    final response = await _supabase.from(DBConstants.technicianProfiles).insert({
      'id': profileId,
      'user_id': userId,
      'specialties': specialties,
      'years_experience': yearsExperience,
      'bio': bio,
      'shop_name': shopName,
      'certifications': certifications ?? [],
      'tools': tools ?? [],
      'hourly_rate': hourlyRate,
      'diagnostic_fee': diagnosticFee,
      'warranty_policy': warrantyPolicy,
      'turnaround_time': turnaroundTime,
      'service_radius': serviceRadius,
      'is_available': true,
      'rating': 0.0,
      'total_jobs': 0,
      'acceptance_rate': 0,
    }).select().single();

    return TechnicianProfileModel.fromJson(response);
  }

  Future<void> updateProfile({
    required String userId,
    List<String>? specialties,
    int? yearsExperience,
    String? bio,
    String? shopName,
    List<String>? certifications,
    List<String>? tools,
    double? hourlyRate,
    double? diagnosticFee,
    String? warrantyPolicy,
    int? turnaroundTime,
    double? serviceRadius,
    bool? isAvailable,
  }) async {
    final updates = <String, dynamic>{};

    if (specialties != null) updates['specialties'] = specialties;
    if (yearsExperience != null) updates['years_experience'] = yearsExperience;
    if (bio != null) updates['bio'] = bio;
    if (shopName != null) updates['shop_name'] = shopName;
    if (certifications != null) updates['certifications'] = certifications;
    if (tools != null) updates['tools'] = tools;
    if (hourlyRate != null) updates['hourly_rate'] = hourlyRate;
    if (diagnosticFee != null) updates['diagnostic_fee'] = diagnosticFee;
    if (warrantyPolicy != null) updates['warranty_policy'] = warrantyPolicy;
    if (turnaroundTime != null) updates['turnaround_time'] = turnaroundTime;
    if (serviceRadius != null) updates['service_radius'] = serviceRadius;
    if (isAvailable != null) updates['is_available'] = isAvailable;

    if (updates.isNotEmpty) {
      await _supabase
          .from(DBConstants.technicianProfiles)
          .update(updates)
          .eq('user_id', userId);
    }
  }

  Future<TechnicianProfileModel?> getProfileByUserId(String userId) async {
    final response = await _supabase
        .from(DBConstants.technicianProfiles)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return TechnicianProfileModel.fromJson(response);
  }

  Future<List<TechnicianProfileModel>> searchTechnicians({
    String? specialty,
    double? maxRate,
    double? minRating,
    bool? isAvailable,
  }) async {
    var queryBuilder = _supabase
        .from(DBConstants.technicianProfiles)
        .select();

    if (specialty != null) {
      queryBuilder = queryBuilder.contains('specialties', [specialty]);
    }

    if (maxRate != null) {
      queryBuilder = queryBuilder.lte('hourly_rate', maxRate);
    }

    if (minRating != null) {
      queryBuilder = queryBuilder.gte('rating', minRating);
    }

    if (isAvailable != null) {
      queryBuilder = queryBuilder.eq('is_available', isAvailable);
    }

    final response = await queryBuilder.order('rating', ascending: false);

    return (response as List).map((e) => TechnicianProfileModel.fromJson(e)).toList();
  }

  Future<void> toggleAvailability(String userId, bool isAvailable) async {
    await _supabase
        .from(DBConstants.technicianProfiles)
        .update({'is_available': isAvailable})
        .eq('user_id', userId);
  }
}
