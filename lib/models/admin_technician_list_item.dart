import '../models/technician_profile_model.dart';

class AdminTechnicianListItem {
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? city;
  final String? address;
  final bool verified;
  final bool isSuspended;
  final DateTime? createdAt;
  final int completedBookings;
  final String? profilePicture;
  final TechnicianProfileModel? profile;

  const AdminTechnicianListItem({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    required this.address,
    required this.verified,
    required this.isSuspended,
    required this.createdAt,
    required this.completedBookings,
    required this.profilePicture,
    required this.profile,
  });
}
