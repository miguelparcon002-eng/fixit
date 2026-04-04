class JobRequestModel {
  final String id;
  final String customerId;
  final String deviceType;
  final String problemDescription;
  final double latitude;
  final double longitude;
  final String address;
  final String status; // open, accepted, completed, cancelled
  final String? technicianId;
  final DateTime createdAt;
  const JobRequestModel({
    required this.id,
    required this.customerId,
    required this.deviceType,
    required this.problemDescription,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.status,
    this.technicianId,
    required this.createdAt,
  });
  factory JobRequestModel.fromJson(Map<String, dynamic> json) {
    return JobRequestModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      deviceType: json['device_type'] as String,
      problemDescription: json['problem_description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      status: json['status'] as String,
      technicianId: json['technician_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'device_type': deviceType,
        'problem_description': problemDescription,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'status': status,
        if (technicianId != null) 'technician_id': technicianId,
      };
  JobRequestModel copyWith({
    String? status,
    String? technicianId,
  }) =>
      JobRequestModel(
        id: id,
        customerId: customerId,
        deviceType: deviceType,
        problemDescription: problemDescription,
        latitude: latitude,
        longitude: longitude,
        address: address,
        status: status ?? this.status,
        technicianId: technicianId ?? this.technicianId,
        createdAt: createdAt,
      );
}