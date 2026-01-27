import 'dart:typed_data';
import 'package:uuid/uuid.dart';
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

    await _supabase.storage
        .from(AppConstants.bucketDocuments)
        .uploadBinary(path, fileBytes);

    return _supabase.storage
        .from(AppConstants.bucketDocuments)
        .getPublicUrl(path);
  }

  Future<VerificationRequestModel> submitVerificationRequest({
    required String userId,
    required List<String> documentUrls,
  }) async {
    final requestId = _uuid.v4();

    final response = await _supabase.from(DBConstants.verificationRequests).insert({
      'id': requestId,
      'user_id': userId,
      'documents': documentUrls,
      'status': AppConstants.verificationPending,
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

    await _supabase
        .from(DBConstants.users)
        .update({'verified': true})
        .eq('id', userId);
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
