import 'dart:convert';
import '../core/config/supabase_config.dart';
import '../core/constants/db_constants.dart';
import 'storage_service.dart';

class ProfileService {
  // Get current user ID for user-specific profile data
  String? get _userId => StorageService.currentUserId;

  Future<void> saveProfileData({
    required String email,
    required String phone,
    required String location,
    required String memberSince,
  }) async {
    if (_userId == null) return;

    final data = json.encode({
      'email': email,
      'phone': phone,
      'location': location,
      'memberSince': memberSince,
    });
    await StorageService.saveData('profile', data);
  }

  Future<Map<String, String>> loadProfileData() async {
    // First try to load from storage
    final storedData = await StorageService.loadData('profile');
    if (storedData != null) {
      try {
        final decoded = json.decode(storedData) as Map<String, dynamic>;
        return {
          'email': decoded['email'] ?? '',
          'phone': decoded['phone'] ?? '',
          'location': decoded['location'] ?? '',
          'memberSince': decoded['memberSince'] ?? '',
        };
      } catch (e) {
        print('ProfileService: Error parsing stored profile - $e');
      }
    }

    // If no stored data, get from Supabase user profile
    if (_userId != null) {
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
      }
    }

    // Return empty defaults for new users
    return {
      'email': '',
      'phone': 'Not set',
      'location': 'Not set',
      'memberSince': 'New Member',
    };
  }

  String _formatMemberSince(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> updateEmail(String email) async {
    final currentData = await loadProfileData();
    await saveProfileData(
      email: email,
      phone: currentData['phone']!,
      location: currentData['location']!,
      memberSince: currentData['memberSince']!,
    );
  }

  Future<void> updatePhone(String phone) async {
    final currentData = await loadProfileData();
    await saveProfileData(
      email: currentData['email']!,
      phone: phone,
      location: currentData['location']!,
      memberSince: currentData['memberSince']!,
    );
  }

  Future<void> updateLocation(String location) async {
    final currentData = await loadProfileData();
    await saveProfileData(
      email: currentData['email']!,
      phone: currentData['phone']!,
      location: location,
      memberSince: currentData['memberSince']!,
    );
  }

  Future<void> updateMemberSince(String memberSince) async {
    final currentData = await loadProfileData();
    await saveProfileData(
      email: currentData['email']!,
      phone: currentData['phone']!,
      location: currentData['location']!,
      memberSince: memberSince,
    );
  }

  Future<void> updateSpecialties(List<String> specialties) async {
    if (_userId == null) return;
    final data = json.encode(specialties);
    await StorageService.saveData('specialties', data);
  }

  Future<List<String>> loadSpecialties() async {
    try {
      final data = await StorageService.loadData('specialties');
      if (data != null) {
        final decoded = json.decode(data) as List<dynamic>;
        return decoded.map((e) => e.toString()).toList();
      }
      return <String>[];
    } catch (e) {
      print('ProfileService: Error loading specialties - $e');
      return <String>[];
    }
  }

  Future<void> updateProfileImagePath(String imagePath) async {
    if (_userId == null) return;
    await StorageService.saveData('profile_image', imagePath);
  }

  Future<String?> loadProfileImagePath() async {
    return await StorageService.loadData('profile_image');
  }
}
