import '../core/config/supabase_config.dart';
import '../models/job_request_model.dart';
import '../services/notification_service.dart';
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
  Future<void> proposeRequest(String id, String technicianId) async {
    await SupabaseConfig.client.from(_table).update({
      'status': 'pending_customer_approval',
      'technician_id': technicianId,
    }).eq('id', id);
  }
  Future<void> acceptRequest(String id, String technicianId) async {
    await SupabaseConfig.client.from(_table).update({
      'status': 'accepted',
      'technician_id': technicianId,
    }).eq('id', id);
  }
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
  Future<void> cancelRequestByCustomer(JobRequestModel request) async {
    await SupabaseConfig.client
        .from(_table)
        .update({'status': 'cancelled'})
        .eq('id', request.id);
    if (request.technicianId != null) {
      await NotificationService().sendNotification(
        userId: request.technicianId!,
        type: 'job_request_cancelled',
        title: 'Job Request Cancelled',
        message:
            'The customer cancelled their ${request.deviceType} repair request.',
        data: {'route': '/tech-job-map'},
      );
    }
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
  Future<void> syncStaleStatuses() async {
    try {
      final staleRows = await SupabaseConfig.client
          .from(_table)
          .select('id, customer_id, technician_id')
          .eq('status', 'accepted');
      for (final jr in (staleRows as List)) {
        final jrId = jr['id'] as String;
        final cid = jr['customer_id'] as String?;
        final tid = jr['technician_id'] as String?;
        if (cid == null || tid == null) continue;
        final activeBooking = await SupabaseConfig.client
            .from('bookings')
            .select('id')
            .eq('customer_id', cid)
            .eq('technician_id', tid)
            .eq('booking_source', 'post_problem')
            .inFilter('status', [
              'accepted', 'scheduled', 'en_route', 'arrived', 'in_progress',
            ])
            .limit(1)
            .maybeSingle();
        if (activeBooking != null) continue; // booking still live — leave it
        final terminalBooking = await SupabaseConfig.client
            .from('bookings')
            .select('status')
            .eq('customer_id', cid)
            .eq('technician_id', tid)
            .eq('booking_source', 'post_problem')
            .inFilter('status', [
              'completed', 'paid', 'closed', 'cancelled', 'cancellation_pending',
            ])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (terminalBooking == null) continue; // nothing to go on — leave it
        final newStatus =
            ['completed', 'paid', 'closed'].contains(terminalBooking['status'])
                ? 'completed'
                : 'cancelled';
        await SupabaseConfig.client
            .from(_table)
            .update({'status': newStatus})
            .eq('id', jrId);
      }
    } catch (_) {
    }
  }
  Stream<List<JobRequestModel>> watchAllRequests() {
    return SupabaseConfig.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .map((e) => JobRequestModel.fromJson(Map<String, dynamic>.from(e)))
            .toList());
  }
  Future<void> notifyAllTechnicians({
    required String deviceType,
    required String address,
    required String requestId,
  }) async {
    try {
      final rows = await SupabaseConfig.client
          .from('technician_profiles')
          .select('user_id');
      final techIds = (rows as List)
          .map((r) => r['user_id'] as String)
          .toList();
      if (techIds.isEmpty) return;
      final notifService = NotificationService();
      await Future.wait(
        techIds.map((techId) => notifService.sendNotification(
              userId: techId,
              type: 'new_job_request',
              title: 'New Job Request Nearby!',
              message:
                  'A customer needs help with their $deviceType near $address.',
              data: {
                'route': '/tech-job-map',
                'request_id': requestId,
              },
            )),
      );
    } catch (_) {
    }
  }
  Stream<List<JobRequestModel>> watchOpenRequests() {
    return SupabaseConfig.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((e) => e['status'] == 'open')
            .map((e) => JobRequestModel.fromJson(Map<String, dynamic>.from(e)))
            .toList());
  }
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