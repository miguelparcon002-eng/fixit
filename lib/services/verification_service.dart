import 'dart:async';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/db_constants.dart';
import '../models/verification_request_model.dart';
import '../core/utils/app_logger.dart';
class VerificationService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();
  Future<String> uploadDocument({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
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
    final signedUrl = await _supabase.storage
        .from(AppConstants.bucketDocuments)
        .createSignedUrl(path, 31536000); // 1 year in seconds
    AppLogger.p('Uploaded document: $path');
    AppLogger.p('Signed URL: $signedUrl');
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
    final existing = await _supabase
        .from(DBConstants.verificationRequests)
        .select()
        .eq('user_id', userId)
        .order('submitted_at', ascending: false)
        .maybeSingle();
    final payload = {
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
      'submitted_at': DateTime.now().toIso8601String(),
      'admin_notes': null,
      'reviewed_at': null,
      'reviewed_by': null,
    };
    Map<String, dynamic> response;
    if (existing != null &&
        (existing['status'] == AppConstants.verificationResubmit ||
         existing['status'] == AppConstants.verificationPending)) {
      response = await _supabase
          .from(DBConstants.verificationRequests)
          .update(payload)
          .eq('id', existing['id'])
          .select()
          .single();
    } else if (existing != null &&
         existing['status'] == AppConstants.verificationApproved) {
      throw Exception('Your verification is already approved.');
    } else if (existing != null &&
         existing['status'] == AppConstants.verificationRejected) {
      throw Exception('Your verification was rejected. You cannot resubmit unless an admin allows it.');
    } else {
      payload['id'] = _uuid.v4();
      response = await _supabase
          .from(DBConstants.verificationRequests)
          .insert(payload)
          .select()
          .single();
    }
    try {
      final userUpdates = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) userUpdates['full_name'] = fullName;
      if (contactNumber != null && contactNumber.isNotEmpty) userUpdates['contact_number'] = contactNumber;
      if (address != null && address.isNotEmpty) userUpdates['address'] = address;
      if (userUpdates.isNotEmpty) {
        await _supabase.from(DBConstants.users).update(userUpdates).eq('id', userId);
      }
      final profileData = <String, dynamic>{'user_id': userId};
      if (yearsExperience != null) profileData['years_experience'] = yearsExperience;
      if (shopName != null && shopName.isNotEmpty) profileData['shop_name'] = shopName;
      if (bio != null && bio.isNotEmpty) profileData['bio'] = bio;
      if (specialties != null && specialties.isNotEmpty) profileData['specialties'] = specialties;
      if (profileData.length > 1) {
        final existing = await _supabase
            .from(DBConstants.technicianProfiles)
            .select('user_id')
            .eq('user_id', userId)
            .maybeSingle();
        if (existing == null) {
          profileData['id'] = _uuid.v4();
          profileData['rating'] = 0.0;
          profileData['total_jobs'] = 0;
          profileData['is_available'] = true;
          await _supabase.from(DBConstants.technicianProfiles).insert(profileData);
        } else {
          await _supabase.from(DBConstants.technicianProfiles).update(profileData).eq('user_id', userId);
        }
      }
      AppLogger.p('✅ Pre-populated user & technician profile on verification submission for: $userId');
    } catch (e) {
      AppLogger.p('⚠️ Could not pre-populate profile on submission: $e');
    }
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
    final request = await _supabase
        .from(DBConstants.verificationRequests)
        .select()
        .eq('id', requestId)
        .single();
    final userId = request['user_id'];
    await _supabase.from(DBConstants.verificationRequests).update({
      'status': AppConstants.verificationApproved,
      'admin_notes': notes,
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': adminId,
    }).eq('id', requestId);
    final userUpdates = <String, dynamic>{
      'verified': true,
    };
    if (request['full_name'] != null) {
      userUpdates['full_name'] = request['full_name'];
    }
    if (request['contact_number'] != null) {
      userUpdates['contact_number'] = request['contact_number'];
    }
    if (request['address'] != null) {
      userUpdates['address'] = request['address'];
    }
    if (request['bio'] != null) {
      userUpdates['bio'] = request['bio'];
    }
    await _supabase
        .from(DBConstants.users)
        .update(userUpdates)
        .eq('id', userId);
    if (request['years_experience'] != null || 
        request['shop_name'] != null || 
        request['bio'] != null || 
        request['specialties'] != null) {
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
        profileData['id'] = _uuid.v4();
        profileData['rating'] = 0.0;
        profileData['total_jobs'] = 0;
        profileData['is_available'] = true;
        await _supabase
            .from(DBConstants.technicianProfiles)
            .insert(profileData);
      } else {
        await _supabase
            .from(DBConstants.technicianProfiles)
            .update(profileData)
            .eq('user_id', userId);
      }
    }
    final rawSpecialties = request['specialties'];
    if (rawSpecialties != null && rawSpecialties is List && rawSpecialties.isNotEmpty) {
      try {
        await _supabase
            .from('technician_specialties')
            .delete()
            .eq('technician_id', userId);
        final inserts = rawSpecialties
            .map((s) => {'technician_id': userId, 'specialty_name': s.toString()})
            .toList();
        await _supabase.from('technician_specialties').insert(inserts);
        AppLogger.p('✅ Specialties synced to technician_specialties for user: $userId');
      } catch (e) {
        AppLogger.p('⚠️ Could not sync specialties: $e');
      }
    }
    AppLogger.p('✅ User profile updated with verification data for user: $userId');
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
  Stream<List<VerificationRequestModel>> watchPendingVerifications() async* {
    while (true) {
      try {
        final data = await _supabase
            .from(DBConstants.verificationRequests)
            .select()
            .eq('status', AppConstants.verificationPending)
            .order('submitted_at', ascending: true);
        yield (data as List).map((e) => VerificationRequestModel.fromJson(e)).toList();
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 5));
    }
  }
  Stream<List<VerificationRequestModel>> watchVerificationsByStatus(String status) async* {
    while (true) {
      try {
        final data = await _supabase
            .from(DBConstants.verificationRequests)
            .select()
            .eq('status', status)
            .order('submitted_at', ascending: false);
        yield (data as List).map((e) => VerificationRequestModel.fromJson(e)).toList();
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}