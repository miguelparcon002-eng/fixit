import '../core/config/supabase_config.dart';
import '../core/constants/db_constants.dart';
import 'storage_service.dart';
import 'technician_specialty_service.dart';

class ProfileService {
  String? get _userId => StorageService.currentUserId;

  Future<Map<String, String>> loadProfileData() async {
    if (_userId == null) {
      return {
        'email': '',
        'phone': 'Not set',
        'location': 'Not set',
        'memberSince': 'New Member',
      };
    }

    try {
      final response = await SupabaseConfig.client
          .from(DBConstants.users)
          .select()
          .eq('id', _userId!)
          .single();

      final createdAt = DateTime.tryParse(response['created_at'] ?? '');
      final memberSince = createdAt != null
          ? _formatMemberSince(createdAt)
          : 'New Member';

      final location = response['address'] ??
          (response['city'] != null && response['neighborhood'] != null
              ? '${response['city']}, ${response['neighborhood']}'
              : 'Not set');

      return {
        'email': response['email'] ?? '',
        'phone': response['contact_number'] ?? 'Not set',
        'location': location,
        'memberSince': memberSince,
      };
    } catch (e) {
      print('ProfileService: Error loading from Supabase - $e');
      return {
        'email': '',
        'phone': 'Not set',
        'location': 'Not set',
        'memberSince': 'New Member',
      };
    }
  }

  String _formatMemberSince(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> updateEmail(String email) async {
    if (_userId == null) return;
    await SupabaseConfig.client
        .from(DBConstants.users)
        .update({'email': email})
        .eq('id', _userId!);
  }

  Future<void> updatePhone(String phone) async {
    if (_userId == null) return;
    await SupabaseConfig.client
        .from(DBConstants.users)
        .update({'contact_number': phone})
        .eq('id', _userId!);
  }

  Future<void> updateLocation(String location) async {
    if (_userId == null) return;
    await SupabaseConfig.client
        .from(DBConstants.users)
        .update({'address': location})
        .eq('id', _userId!);
  }

  Future<void> updateProfile({
    String? email,
    String? phone,
    String? address,
    String? city,
    String? neighborhood,
  }) async {
    if (_userId == null) return;

    final updates = <String, dynamic>{};
    if (email != null) updates['email'] = email;
    if (phone != null) updates['contact_number'] = phone;
    if (address != null) updates['address'] = address;
    if (city != null) updates['city'] = city;
    if (neighborhood != null) updates['neighborhood'] = neighborhood;

    if (updates.isNotEmpty) {
      await SupabaseConfig.client
          .from(DBConstants.users)
          .update(updates)
          .eq('id', _userId!);
    }
  }

  Future<void> updateSpecialties(List<String> specialties) async {
    if (_userId == null) return;
    final specialtyService = TechnicianSpecialtyService();
    await specialtyService.setSpecialties(
      technicianId: _userId!,
      specialtyNames: specialties,
    );
  }

  Future<List<String>> loadSpecialties() async {
    if (_userId == null) return <String>[];

    try {
      final specialtyService = TechnicianSpecialtyService();
      final specialties = await specialtyService.getTechnicianSpecialties(_userId!);
      return specialties.map((s) => s.specialtyName).toList();
    } catch (e) {
      print('ProfileService: Error loading specialties - $e');
      return <String>[];
    }
  }

  Future<void> updateProfileImageUrl(String imageUrl) async {
    if (_userId == null) return;
    await SupabaseConfig.client
        .from(DBConstants.users)
        .update({'profile_image_url': imageUrl})
        .eq('id', _userId!);
  }

  Future<String?> loadProfileImageUrl() async {
    if (_userId == null) return null;

    try {
      final response = await SupabaseConfig.client
          .from(DBConstants.users)
          .select('profile_image_url')
          .eq('id', _userId!)
          .single();
      return response['profile_image_url'] as String?;
    } catch (e) {
      print('ProfileService: Error loading profile image URL - $e');
      return null;
    }
  }
}
