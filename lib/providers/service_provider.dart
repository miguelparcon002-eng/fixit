import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';
import '../services/service_service.dart';

final serviceServiceProvider = Provider((ref) => ServiceService());

final technicianServicesProvider = FutureProvider.family<List<ServiceModel>, String>((ref, technicianId) async {
  final serviceService = ref.watch(serviceServiceProvider);
  return await serviceService.getTechnicianServices(technicianId);
});

final servicesByCategoryProvider = FutureProvider.family<List<ServiceModel>, String>((ref, category) async {
  final serviceService = ref.watch(serviceServiceProvider);
  return await serviceService.getServicesByCategory(category);
});

final serviceByIdProvider = FutureProvider.family<ServiceModel?, String>((ref, serviceId) async {
  final serviceService = ref.watch(serviceServiceProvider);
  return await serviceService.getServiceById(serviceId);
});

class SearchServicesParams {
  final String? query;
  final String? category;
  final double? maxPrice;
  final String? partsAvailability;

  SearchServicesParams({
    this.query,
    this.category,
    this.maxPrice,
    this.partsAvailability,
  });
}

final searchServicesProvider = FutureProvider.family<List<ServiceModel>, SearchServicesParams>((ref, params) async {
  final serviceService = ref.watch(serviceServiceProvider);
  return await serviceService.searchServices(
    query: params.query,
    category: params.category,
    maxPrice: params.maxPrice,
    partsAvailability: params.partsAvailability,
  );
});
