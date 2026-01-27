import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/technician_profile_model.dart';
import '../services/technician_service.dart';

final technicianServiceProvider = Provider((ref) => TechnicianService());

final technicianProfileProvider = FutureProvider.family<TechnicianProfileModel?, String>((ref, userId) async {
  final technicianService = ref.watch(technicianServiceProvider);
  return await technicianService.getProfileByUserId(userId);
});

class SearchTechniciansParams {
  final String? specialty;
  final double? maxRate;
  final double? minRating;
  final bool? isAvailable;

  SearchTechniciansParams({
    this.specialty,
    this.maxRate,
    this.minRating,
    this.isAvailable,
  });
}

final searchTechniciansProvider = FutureProvider.family<List<TechnicianProfileModel>, SearchTechniciansParams>((ref, params) async {
  final technicianService = ref.watch(technicianServiceProvider);
  return await technicianService.searchTechnicians(
    specialty: params.specialty,
    maxRate: params.maxRate,
    minRating: params.minRating,
    isAvailable: params.isAvailable,
  );
});
