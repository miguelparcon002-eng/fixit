import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_request_model.dart';
import '../services/job_request_service.dart';

final jobRequestServiceProvider = Provider((ref) => JobRequestService());

/// All requests — real-time (used by admin).
final allJobRequestsProvider = StreamProvider<List<JobRequestModel>>((ref) {
  return ref.watch(jobRequestServiceProvider).watchAllRequests();
});

/// Open requests only — real-time (used by technician map).
final openJobRequestsProvider = StreamProvider<List<JobRequestModel>>((ref) {
  return ref.watch(jobRequestServiceProvider).watchOpenRequests();
});

/// Customer's own requests — real-time.
final customerJobRequestsProvider =
    StreamProvider.family<List<JobRequestModel>, String>((ref, customerId) {
  return ref.watch(jobRequestServiceProvider).watchCustomerRequests(customerId);
});

/// Technician's pending proposals (pending_customer_approval) — real-time.
final techProposalsProvider =
    StreamProvider.family<List<JobRequestModel>, String>((ref, techId) {
  return ref.watch(jobRequestServiceProvider).watchTechProposals(techId);
});
