class TechnicianSpecialty {
  final String id;
  final String technicianId;
  final String specialtyName;
  final DateTime createdAt;

  TechnicianSpecialty({
    required this.id,
    required this.technicianId,
    required this.specialtyName,
    required this.createdAt,
  });

  factory TechnicianSpecialty.fromJson(Map<String, dynamic> json) {
    return TechnicianSpecialty(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      specialtyName: json['specialty_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'specialty_name': specialtyName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TechnicianSpecialty copyWith({
    String? id,
    String? technicianId,
    String? specialtyName,
    DateTime? createdAt,
  }) {
    return TechnicianSpecialty(
      id: id ?? this.id,
      technicianId: technicianId ?? this.technicianId,
      specialtyName: specialtyName ?? this.specialtyName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
