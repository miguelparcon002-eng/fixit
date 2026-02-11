import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';

class ImageUploadService {
  // Keep this aligned with AppConstants.bucketProfiles.
  static const String _bucketName = AppConstants.bucketProfiles;

  static String _contentTypeFromExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Upload a profile image to Supabase Storage.
  ///
  /// Throws the underlying Supabase/storage error if upload fails.
  static Future<String> uploadProfileImage({
    required String userId,
    required XFile imageFile,
  }) async {
    // Generate unique filename with user ID and timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // On web, XFile.path can be empty; default to jpg.
    final rawPath = imageFile.path;
    final ext = (rawPath.contains('.')
            ? rawPath.split('.').last.toLowerCase()
            : 'jpg')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final fileName = '$userId/$timestamp.$safeExt';
    final contentType = _contentTypeFromExtension(safeExt);

    AppLogger.p('ImageUploadService: Uploading image to bucket=$_bucketName path=$fileName contentType=$contentType');

    final Uint8List imageBytes = await imageFile.readAsBytes();

    try {
      await SupabaseConfig.client.storage.from(_bucketName).uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
              cacheControl: '3600',
            ),
          );

      final publicUrl =
          SupabaseConfig.client.storage.from(_bucketName).getPublicUrl(fileName);

      AppLogger.p('ImageUploadService: Upload successful, URL: $publicUrl');
      return publicUrl;
    } catch (e, st) {
      // IMPORTANT: don't hide the real error; surface it to the UI.
      AppLogger.e('ImageUploadService: Upload failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Upload profile image from file path (for mobile)
  static Future<String> uploadProfileImageFromPath({
    required String userId,
    required String filePath,
  }) async {
    final xFile = XFile(filePath);
    return uploadProfileImage(userId: userId, imageFile: xFile);
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
  static Future<String> uploadAndSaveProfileImage({
    required String userId,
    required XFile imageFile,
    String? oldImageUrl,
  }) async {
    // Upload new image (throws on failure)
    final newUrl = await uploadProfileImage(
      userId: userId,
      imageFile: imageFile,
    );

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
  }
}
