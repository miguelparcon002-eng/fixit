import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider((ref) => ProfileService());

class ProfileData {
  final String email;
  final String phone;
  final String location;
  final String memberSince;
  final List<String> specialties;
  final String? profileImagePath;

  ProfileData({
    required this.email,
    required this.phone,
    required this.location,
    required this.memberSince,
    List<String>? specialties,
    this.profileImagePath,
  }) : specialties = specialties ?? const [];

  ProfileData copyWith({
    String? email,
    String? phone,
    String? location,
    String? memberSince,
    List<String>? specialties,
    String? profileImagePath,
  }) {
    return ProfileData(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      memberSince: memberSince ?? this.memberSince,
      specialties: specialties ?? this.specialties,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileData>> {
  final ProfileService _profileService;

  ProfileNotifier(this._profileService) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _profileService.loadProfileData();
      final specialties = await _profileService.loadSpecialties();
      final profileImageUrl = await _profileService.loadProfileImageUrl();
      state = AsyncValue.data(ProfileData(
        email: data['email']!,
        phone: data['phone']!,
        location: data['location']!,
        memberSince: data['memberSince']!,
        specialties: specialties,
        profileImagePath: profileImageUrl,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateEmail(String email) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      await _profileService.updateEmail(email);
      state = AsyncValue.data(currentData.copyWith(email: email));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePhone(String phone) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      await _profileService.updatePhone(phone);
      state = AsyncValue.data(currentData.copyWith(phone: phone));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateLocation(String location) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      await _profileService.updateLocation(location);
      state = AsyncValue.data(currentData.copyWith(location: location));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSpecialties(List<String> specialties) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      await _profileService.updateSpecialties(specialties);

      // Reload specialties from Supabase to ensure they persist
      final reloadedSpecialties = await _profileService.loadSpecialties();
      state = AsyncValue.data(currentData.copyWith(specialties: reloadedSpecialties));

      print('ProfileNotifier: Specialties updated and reloaded from Supabase: $reloadedSpecialties');
    } catch (e, stack) {
      print('ProfileNotifier: Error updating specialties - $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Add reload method to force refresh from Supabase
  Future<void> reload() async {
    await _loadProfile();
  }

  Future<void> updateProfileImage(String imageUrl) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      await _profileService.updateProfileImageUrl(imageUrl);
      state = AsyncValue.data(currentData.copyWith(profileImagePath: imageUrl));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileData>>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return ProfileNotifier(profileService);
});
