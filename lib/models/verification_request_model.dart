class VerificationRequestModel {
  final String id;
  final String userId;
  final List<String> documents;
  final String status;
  final String? adminNotes;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  VerificationRequestModel({
    required this.id,
    required this.userId,
    required this.documents,
    required this.status,
    this.adminNotes,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory VerificationRequestModel.fromJson(Map<String, dynamic> json) {
    return VerificationRequestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      documents: List<String>.from(json['documents'] as List),
      status: json['status'] as String,
      adminNotes: json['admin_notes'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'documents': documents,
      'status': status,
      'admin_notes': adminNotes,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
    };
  }
}
