import 'package:uuid/uuid.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/db_constants.dart';
import '../models/service_model.dart';

class ServiceService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  Future<ServiceModel> createService({
    required String technicianId,
    required String serviceName,
    required String description,
    required String category,
    double? basePrice,
    double? priceRangeMin,
    double? priceRangeMax,
    required int estimatedDuration,
    List<String>? images,
    String? warrantyTerms,
    String partsAvailability = 'in_stock',
  }) async {
    final serviceId = _uuid.v4();

    final response = await _supabase.from(DBConstants.services).insert({
      'id': serviceId,
      'technician_id': technicianId,
      'service_name': serviceName,
      'description': description,
      'category': category,
      'base_price': basePrice,
      'price_range_min': priceRangeMin,
      'price_range_max': priceRangeMax,
      'estimated_duration': estimatedDuration,
      'images': images ?? [],
      'warranty_terms': warrantyTerms,
      'parts_availability': partsAvailability,
      'is_active': true,
    }).select().single();

    return ServiceModel.fromJson(response);
  }

  Future<void> updateService({
    required String serviceId,
    String? serviceName,
    String? description,
    String? category,
    double? basePrice,
    double? priceRangeMin,
    double? priceRangeMax,
    int? estimatedDuration,
    List<String>? images,
    String? warrantyTerms,
    String? partsAvailability,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};

    if (serviceName != null) updates['service_name'] = serviceName;
    if (description != null) updates['description'] = description;
    if (category != null) updates['category'] = category;
    if (basePrice != null) updates['base_price'] = basePrice;
    if (priceRangeMin != null) updates['price_range_min'] = priceRangeMin;
    if (priceRangeMax != null) updates['price_range_max'] = priceRangeMax;
    if (estimatedDuration != null) updates['estimated_duration'] = estimatedDuration;
    if (images != null) updates['images'] = images;
    if (warrantyTerms != null) updates['warranty_terms'] = warrantyTerms;
    if (partsAvailability != null) updates['parts_availability'] = partsAvailability;
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isNotEmpty) {
      await _supabase
          .from(DBConstants.services)
          .update(updates)
          .eq('id', serviceId);
    }
  }

  Future<void> deleteService(String serviceId) async {
    await _supabase
        .from(DBConstants.services)
        .delete()
        .eq('id', serviceId);
  }

  Future<List<ServiceModel>> getTechnicianServices(String technicianId) async {
    final response = await _supabase
        .from(DBConstants.services)
        .select()
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => ServiceModel.fromJson(e)).toList();
  }

  Future<List<ServiceModel>> searchServices({
    String? query,
    String? category,
    double? maxPrice,
    String? partsAvailability,
  }) async {
    var queryBuilder = _supabase
        .from(DBConstants.services)
        .select()
        .eq('is_active', true);

    if (query != null && query.isNotEmpty) {
      queryBuilder = queryBuilder.or('service_name.ilike.%$query%,description.ilike.%$query%');
    }

    if (category != null) {
      queryBuilder = queryBuilder.eq('category', category);
    }

    if (maxPrice != null) {
      queryBuilder = queryBuilder.lte('base_price', maxPrice);
    }

    if (partsAvailability != null) {
      queryBuilder = queryBuilder.eq('parts_availability', partsAvailability);
    }

    final response = await queryBuilder.order('created_at', ascending: false);

    return (response as List).map((e) => ServiceModel.fromJson(e)).toList();
  }

  Future<ServiceModel?> getServiceById(String serviceId) async {
    final response = await _supabase
        .from(DBConstants.services)
        .select()
        .eq('id', serviceId)
        .single();

    return ServiceModel.fromJson(response);
  }

  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    final response = await _supabase
        .from(DBConstants.services)
        .select()
        .eq('category', category)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List).map((e) => ServiceModel.fromJson(e)).toList();
  }
}
