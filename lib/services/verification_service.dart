import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/db_constants.dart';
import '../models/verification_request_model.dart';

class VerificationService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  Future<String> uploadDocument({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // Upload with proper content type
    await _supabase.storage
        .from(AppConstants.bucketDocuments)
        .uploadBinary(
          path, 
          fileBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    // Create signed URL with long expiry (1 year) for admin viewing
    final signedUrl = await _supabase.storage
        .from(AppConstants.bucketDocuments)
        .createSignedUrl(path, 31536000); // 1 year in seconds

    print('Uploaded document: $path');
    print('Signed URL: $signedUrl');
    
    return signedUrl;
  }

  Future<VerificationRequestModel> submitVerificationRequest({
    required String userId,
    required List<String> documentUrls,
    String? fullName,
    String? contactNumber,
    String? address,
    int? yearsExperience,
    String? shopName,
    String? bio,
    List<String>? specialties,
  }) async {
    final requestId = _uuid.v4();

    final response = await _supabase.from(DBConstants.verificationRequests).insert({
      'id': requestId,
      'user_id': userId,
      'documents': documentUrls,
      'status': AppConstants.verificationPending,
      'full_name': fullName,
      'contact_number': contactNumber,
      'address': address,
      'years_experience': yearsExperience,
      'shop_name': shopName,
      'bio': bio,
      'specialties': specialties,
    }).select().single();

    return VerificationRequestModel.fromJson(response);
  }

  Future<VerificationRequestModel?> getUserVerificationRequest(String userId) async {
    final response = await _supabase
        .from(DBConstants.verificationRequests)
        .select()
        .eq('user_id', userId)
        .order('submitted_at', ascending: false)
        .maybeSingle();

    if (response == null) return null;
    return VerificationRequestModel.fromJson(response);
  }

  Future<List<VerificationRequestModel>> getPendingVerifications() async {
    final response = await _supabase
        .from(DBConstants.verificationRequests)
        .select()
        .eq('status', AppConstants.verificationPending)
        .order('submitted_at', ascending: true);

    return (response as List).map((e) => VerificationRequestModel.fromJson(e)).toList();
  }

  Future<void> approveVerification({
    required String requestId,
    required String adminId,
    String? notes,
  }) async {
    // Get the verification request with all technician data
    final request = await _supabase
        .from(DBConstants.verificationRequests)
        .select()
        .eq('id', requestId)
        .single();

    final userId = request['user_id'];

    // Update verification request status
    await _supabase.from(DBConstants.verificationRequests).update({
      'status': AppConstants.verificationApproved,
      'admin_notes': notes,
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': adminId,
    }).eq('id', requestId);

    // Update user profile with verification data
    final userUpdates = <String, dynamic>{
      'verified': true,
    };

    // Copy verification data to user profile
    if (request['full_name'] != null) {
      userUpdates['full_name'] = request['full_name'];
    }
    if (request['contact_number'] != null) {
      userUpdates['contact_number'] = request['contact_number'];
    }
    if (request['address'] != null) {
      userUpdates['address'] = request['address'];
    }

    await _supabase
        .from(DBConstants.users)
        .update(userUpdates)
        .eq('id', userId);

    // Update or create technician profile
    if (request['years_experience'] != null || 
        request['shop_name'] != null || 
        request['bio'] != null || 
        request['specialties'] != null) {
      
      // Check if technician profile exists
      final existingProfile = await _supabase
          .from(DBConstants.technicianProfiles)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final profileData = <String, dynamic>{
        'user_id': userId,
      };

      if (request['years_experience'] != null) {
        profileData['years_experience'] = request['years_experience'];
      }
      if (request['shop_name'] != null) {
        profileData['shop_name'] = request['shop_name'];
      }
      if (request['bio'] != null) {
        profileData['bio'] = request['bio'];
      }
      if (request['specialties'] != null) {
        profileData['specialties'] = request['specialties'];
      }

      if (existingProfile == null) {
        // Create new technician profile
        profileData['id'] = _uuid.v4();
        profileData['rating'] = 0.0;
        profileData['total_jobs'] = 0;
        profileData['is_available'] = true;
        
        await _supabase
            .from(DBConstants.technicianProfiles)
            .insert(profileData);
      } else {
        // Update existing technician profile
        await _supabase
            .from(DBConstants.technicianProfiles)
            .update(profileData)
            .eq('user_id', userId);
      }
    }

    print('✅ User profile updated with verification data for user: $userId');
  }

  Future<void> rejectVerification({
    required String requestId,
    required String adminId,
    required String notes,
  }) async {
    await _supabase.from(DBConstants.verificationRequests).update({
      'status': AppConstants.verificationRejected,
      'admin_notes': notes,
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': adminId,
    }).eq('id', requestId);
  }

  Future<void> requestResubmission({
    required String requestId,
    required String adminId,
    required String notes,
  }) async {
    await _supabase.from(DBConstants.verificationRequests).update({
      'status': AppConstants.verificationResubmit,
      'admin_notes': notes,
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': adminId,
    }).eq('id', requestId);
  }

  Stream<List<VerificationRequestModel>> watchPendingVerifications() {
    return _supabase
        .from(DBConstants.verificationRequests)
        .stream(primaryKey: ['id'])
        .eq('status', AppConstants.verificationPending)
        .order('submitted_at', ascending: true)
        .map((data) => data.map((e) => VerificationRequestModel.fromJson(e)).toList());
  }
}
