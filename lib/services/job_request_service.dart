import '../core/config/supabase_config.dart';
import '../models/job_request_model.dart';

class JobRequestService {
  static const _table = 'job_requests';

  Future<JobRequestModel> createRequest({
    required String customerId,
    required String deviceType,
    required String problemDescription,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final data = await SupabaseConfig.client.from(_table).insert({
      'customer_id': customerId,
      'device_type': deviceType,
      'problem_description': problemDescription,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': 'open',
    }).select().single();
    return JobRequestModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<JobRequestModel>> getCustomerRequests(String customerId) async {
    final data = await SupabaseConfig.client
        .from(_table)
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => JobRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<JobRequestModel>> getOpenRequests() async {
    final data = await SupabaseConfig.client
        .from(_table)
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => JobRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<JobRequestModel>> getAllRequests() async {
    final data = await SupabaseConfig.client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => JobRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Technician proposes to take the job — waits for customer confirmation.
  Future<void> proposeRequest(String id, String technicianId) async {
    await SupabaseConfig.client.from(_table).update({
      'status': 'pending_customer_approval',
      'technician_id': technicianId,
    }).eq('id', id);
  }

  /// Customer confirms the technician — marks request as accepted.
  Future<void> acceptRequest(String id, String technicianId) async {
    await SupabaseConfig.client.from(_table).update({
      'status': 'accepted',
      'technician_id': technicianId,
    }).eq('id', id);
  }

  /// Customer declines — puts the request back to open so another tech can claim it.
  Future<void> customerDeclineRequest(String id) async {
    await SupabaseConfig.client.from(_table).update({
      'status': 'open',
      'technician_id': null,
    }).eq('id', id);
  }

  Future<void> cancelRequest(String id) async {
    await SupabaseConfig.client
        .from(_table)
        .update({'status': 'cancelled'})
        .eq('id', id);
  }

  Future<void> completeRequest(String id) async {
    await SupabaseConfig.client
        .from(_table)
        .update({'status': 'completed'})
        .eq('id', id);
  }

  Future<void> reassignRequest(String id, String newTechnicianId) async {
    await SupabaseConfig.client.from(_table).update({
      'status': 'accepted',
      'technician_id': newTechnicianId,
    }).eq('id', id);
  }

  /// Real-time stream of ALL job_requests rows (Supabase Realtime).
  Stream<List<JobRequestModel>> watchAllRequests() {
    return SupabaseConfig.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map((e) => JobRequestModel.fromJson(Map<String, dynamic>.from(e)))
            .toList());
  }

  /// Real-time stream of only OPEN requests (for technician map).
  Stream<List<JobRequestModel>> watchOpenRequests() {
    return SupabaseConfig.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((e) => e['status'] == 'open') // re-filter: Realtime updates don't remove rows that no longer match the eq filter
            .map((e) => JobRequestModel.fromJson(Map<String, dynamic>.from(e)))
            .toList());
  }

  /// Real-time stream for a specific customer's requests.
  Stream<List<JobRequestModel>> watchCustomerRequests(String customerId) {
    return SupabaseConfig.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map((e) => JobRequestModel.fromJson(Map<String, dynamic>.from(e)))
            .toList());
  }

  /// Real-time stream of a technician's pending proposals (pending_customer_approval).
  Stream<List<JobRequestModel>> watchTechProposals(String techId) {
    return SupabaseConfig.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('technician_id', techId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((e) => e['status'] == 'pending_customer_approval')
            .map((e) => JobRequestModel.fromJson(Map<String, dynamic>.from(e)))
            .toList());
  }
}
