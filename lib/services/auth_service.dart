import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
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
    StorageService.setCurrentUser(user.id);
    try {
      final response = await _supabase
          .from(DBConstants.users)
          .select()
          .eq('id', user.id)
          .maybeSingle();
      AppLogger.p('AuthService: DB response = $response');
      if (response == null) {
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
    if (response.user != null) {
      StorageService.setCurrentUser(response.user!.id);
      try {
        await getCurrentUserProfile();
      } catch (e) {
        AppLogger.p('AuthService: Error ensuring user profile on login - $e');
      }
    }
    return response;
  }
  Future<UserModel?> signInWithGoogle({required String role}) async {
    const webClientId = '67598934942-6t3v0p8u4he36a8evftfva1nu7hsqffd.apps.googleusercontent.com';
    final googleSignIn = kIsWeb
        ? GoogleSignIn(clientId: webClientId)
        : GoogleSignIn(serverClientId: webClientId);
    await googleSignIn.signOut();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    if (idToken == null) {
      throw Exception('Google sign-in failed: no ID token received. '
          'Make sure your Web Client ID is correct and SHA-1 is registered.');
    }
    AppLogger.p('AuthService: Signing in with Google (role: $role)');
    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    if (response.user == null) {
      throw Exception('Supabase Google sign-in failed: no user returned');
    }
    StorageService.setCurrentUser(response.user!.id);
    final existing = await _supabase
        .from(DBConstants.users)
        .select()
        .eq('id', response.user!.id)
        .maybeSingle();
    if (existing == null) {
      final email = response.user!.email ?? '';
      final metadata = response.user!.userMetadata ?? {};
      final fullName = (metadata['full_name'] as String?)
          ?? (metadata['name'] as String?)
          ?? email.split('@').first;
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        fullName: fullName,
        role: role,
      );
      AppLogger.p('AuthService: Created new Google profile for $email as $role');
    }
    return getCurrentUserProfile();
  }
  Future<void> signOut() async {
    StorageService.setCurrentUser(null);
    await _supabase.auth.signOut();
  }
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  Future<void> sendOtp(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    if (response.session == null) {
      throw Exception('OTP verification failed. Please try again.');
    }
  }
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
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