import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/db_constants.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import '../core/utils/app_logger.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) {
      StorageService.setCurrentUser(null);
      AppLogger.p('AuthService: No current user in auth');
      return null;
    }

    AppLogger.p('AuthService: Getting profile for user ${user.id} (${user.email})');

    // Set current user for storage isolation
    StorageService.setCurrentUser(user.id);

    try {
      // Fetch user profile from database
      final response = await _supabase
          .from(DBConstants.users)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      AppLogger.p('AuthService: DB response = $response');

      if (response == null) {
        // User exists in auth but not in users table - create profile from metadata
        AppLogger.p('AuthService: User profile not found in DB, creating from metadata...');
        final email = user.email ?? '';
        final metadata = user.userMetadata ?? {};
        AppLogger.p('AuthService: User metadata = $metadata');
        final fullName = metadata['full_name'] as String? ?? email.split('@').first;
        final role = metadata['role'] as String? ?? AppConstants.roleCustomer;
        final contactNumber = metadata['contact_number'] as String?;

        AppLogger.p('AuthService: Creating profile with role: $role');

        await _createUserProfile(
          userId: user.id,
          email: email,
          fullName: fullName,
          role: role,
          contactNumber: contactNumber,
        );

        // Fetch the newly created profile
        final newResponse = await _supabase
            .from(DBConstants.users)
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (newResponse != null) {
          final newUser = UserModel.fromJson(newResponse);
          AppLogger.p('AuthService: Created new profile - role: ${newUser.role}');
          return newUser;
        }
        return null;
      }

      final userModel = UserModel.fromJson(response);
      AppLogger.p('AuthService: Found existing profile - role: ${userModel.role}, email: ${userModel.email}');
      return userModel;
    } catch (e) {
      AppLogger.p('AuthService: Error getting user profile - $e');
      return null;
    }
  }

  // Helper method to create user profile in the users table
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    required String role,
    String? contactNumber,
  }) async {
    try {
      await _supabase.from(DBConstants.users).upsert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'role': role,
        'contact_number': contactNumber,
        'verified': role == AppConstants.roleCustomer ? true : false,
        'created_at': DateTime.now().toIso8601String(),
      });
      AppLogger.p('AuthService: Created/updated user profile for $email with role $role');
    } catch (e) {
      AppLogger.p('AuthService: Error creating user profile - $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? contactNumber,
  }) async {
    // Sign up with metadata so we can recover user info if profile creation fails
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
        'contact_number': contactNumber,
      },
    );

    if (authResponse.user != null) {
      try {
        // Insert user profile into users table
        await _createUserProfile(
          userId: authResponse.user!.id,
          email: email,
          fullName: fullName,
          role: role,
          contactNumber: contactNumber,
        );
        AppLogger.p('AuthService: Successfully created account for $email as $role');
      } catch (e) {
        AppLogger.p('AuthService: Failed to create user profile in DB - $e');
        // Don't throw here - the auth user was created, profile can be created on first login
      }
    }

    return authResponse;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Set current user for storage isolation
    if (response.user != null) {
      StorageService.setCurrentUser(response.user!.id);

      // Ensure user profile exists in DB (will create from metadata if missing)
      try {
        await getCurrentUserProfile();
      } catch (e) {
        AppLogger.p('AuthService: Error ensuring user profile on login - $e');
      }
    }

    return response;
  }

  Future<void> signOut() async {
    // Clear user from storage service before signing out
    StorageService.setCurrentUser(null);
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? contactNumber,
    String? address,
    String? profilePicture,
    double? latitude,
    double? longitude,
    String? city,
    String? neighborhood,
  }) async {
    final updates = <String, dynamic>{};

    if (fullName != null) updates['full_name'] = fullName;
    if (contactNumber != null) updates['contact_number'] = contactNumber;
    if (address != null) updates['address'] = address;
    if (profilePicture != null) updates['profile_picture'] = profilePicture;
    if (latitude != null) updates['latitude'] = latitude;
    if (longitude != null) updates['longitude'] = longitude;
    if (city != null) updates['city'] = city;
    if (neighborhood != null) updates['neighborhood'] = neighborhood;

    if (updates.isNotEmpty) {
      await _supabase
          .from(DBConstants.users)
          .update(updates)
          .eq('id', userId);
    }
  }

  Future<String?> uploadProfilePicture(String userId, Uint8List fileBytes, String fileName) async {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage
        .from(AppConstants.bucketProfiles)
        .uploadBinary(path, fileBytes);

    return _supabase.storage
        .from(AppConstants.bucketProfiles)
        .getPublicUrl(path);
  }

  Future<bool> checkUserRole(String role) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from(DBConstants.users)
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response?['role'] == role;
    } catch (e) {
      AppLogger.p('AuthService: Error checking user role - $e');
      return false;
    }
  }

  Future<bool> isUserVerified() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from(DBConstants.users)
          .select('verified')
          .eq('id', user.id)
          .maybeSingle();

      return response?['verified'] == true;
    } catch (e) {
      AppLogger.p('AuthService: Error checking verification status - $e');
      return false;
    }
  }

  // Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from(DBConstants.users)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.p('AuthService: Error getting all users - $e');
      return [];
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final response = await _supabase
          .from(DBConstants.users)
          .select()
          .eq('role', role)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.p('AuthService: Error getting users by role - $e');
      return [];
    }
  }

  // Verify/unverify a technician (admin only)
  Future<void> setTechnicianVerification(String userId, bool verified) async {
    try {
      await _supabase
          .from(DBConstants.users)
          .update({'verified': verified})
          .eq('id', userId);
      AppLogger.p('AuthService: Set technician $userId verification to $verified');
    } catch (e) {
      AppLogger.p('AuthService: Error setting technician verification - $e');
      rethrow;
    }
  }
}
