class ServiceModel {
  final String id;
  final String technicianId;
  final String serviceName;
  final String description;
  final String category;
  final double? basePrice;
  final double? priceRangeMin;
  final double? priceRangeMax;
  final int estimatedDuration;
  final List<String> images;
  final String partsAvailability;
  final String? warrantyTerms;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ServiceModel({
    required this.id,
    required this.technicianId,
    required this.serviceName,
    required this.description,
    required this.category,
    this.basePrice,
    this.priceRangeMin,
    this.priceRangeMax,
    required this.estimatedDuration,
    this.images = const [],
    this.partsAvailability = 'in_stock',
    this.warrantyTerms,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      serviceName: json['service_name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      basePrice: json['base_price'] as double?,
      priceRangeMin: json['price_range_min'] as double?,
      priceRangeMax: json['price_range_max'] as double?,
      estimatedDuration: json['estimated_duration'] as int,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
      partsAvailability: json['parts_availability'] as String? ?? 'in_stock',
      warrantyTerms: json['warranty_terms'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'service_name': serviceName,
      'description': description,
      'category': category,
      'base_price': basePrice,
      'price_range_min': priceRangeMin,
      'price_range_max': priceRangeMax,
      'estimated_duration': estimatedDuration,
      'images': images,
      'parts_availability': partsAvailability,
      'warranty_terms': warrantyTerms,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
