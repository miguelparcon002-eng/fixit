import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_request_model.dart';
import '../services/job_request_service.dart';
final jobRequestServiceProvider = Provider((ref) => JobRequestService());
final allJobRequestsProvider = StreamProvider<List<JobRequestModel>>((ref) {
  return ref.watch(jobRequestServiceProvider).watchAllRequests();
});
final openJobRequestsProvider = StreamProvider<List<JobRequestModel>>((ref) {
  return ref.watch(jobRequestServiceProvider).watchOpenRequests();
});
final customerJobRequestsProvider =
    StreamProvider.family<List<JobRequestModel>, String>((ref, customerId) {
  return ref.watch(jobRequestServiceProvider).watchCustomerRequests(customerId);
});
final techProposalsProvider =
    StreamProvider.family<List<JobRequestModel>, String>((ref, techId) {
  return ref.watch(jobRequestServiceProvider).watchTechProposals(techId);
});