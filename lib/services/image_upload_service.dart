import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';

class ImageUploadService {
  // Keep this aligned with AppConstants.bucketProfiles.
  static const String _bucketName = AppConstants.bucketProfiles;

  /// Upload a profile image to Supabase Storage
  /// Returns the public URL of the uploaded image
  static Future<String?> uploadProfileImage({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      // Generate unique filename with user ID and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '$userId/$timestamp.$extension';

      AppLogger.p('ImageUploadService: Uploading image to $fileName');

      // Get image bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await SupabaseConfig.client.storage
          .from(_bucketName)
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      // Get the public URL
      final publicUrl = SupabaseConfig.client.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      AppLogger.p('ImageUploadService: Upload successful, URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      AppLogger.p('ImageUploadService: Error uploading image - $e');
      return null;
    }
  }

  /// Upload profile image from file path (for mobile)
  static Future<String?> uploadProfileImageFromPath({
    required String userId,
    required String filePath,
  }) async {
    try {
      final xFile = XFile(filePath);
      return await uploadProfileImage(userId: userId, imageFile: xFile);
    } catch (e) {
      AppLogger.p('ImageUploadService: Error uploading from path - $e');
      return null;
    }
  }

  /// Delete old profile image from storage
  static Future<void> deleteProfileImage({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the index of the bucket name and get everything after it
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex >= 0 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        await SupabaseConfig.client.storage
            .from(_bucketName)
            .remove([filePath]);

        AppLogger.p('ImageUploadService: Deleted old image: $filePath');
      }
    } catch (e) {
      AppLogger.p('ImageUploadService: Error deleting image - $e');
    }
  }

  /// Update user's profile_picture in the database
  static Future<void> updateUserProfilePicture({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      await SupabaseConfig.client
          .from('users')
          .update({'profile_picture': imageUrl, 'profile_image_url': imageUrl})
          .eq('id', userId);

      AppLogger.p('ImageUploadService: Updated profile picture URL(s) in database');
    } catch (e) {
      AppLogger.p('ImageUploadService: Error updating database - $e');
      rethrow;
    }
  }

  /// Complete flow: Upload image and update database
  static Future<String?> uploadAndSaveProfileImage({
    required String userId,
    required XFile imageFile,
    String? oldImageUrl,
  }) async {
    try {
      // Upload new image
      final newUrl = await uploadProfileImage(
        userId: userId,
        imageFile: imageFile,
      );

      if (newUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Update database with new URL
      await updateUserProfilePicture(
        userId: userId,
        imageUrl: newUrl,
      );

      // Delete old image if exists (optional, to save storage)
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteProfileImage(userId: userId, imageUrl: oldImageUrl);
      }

      return newUrl;
    } catch (e) {
      AppLogger.p('ImageUploadService: Error in uploadAndSave - $e');
      return null;
    }
  }
}
