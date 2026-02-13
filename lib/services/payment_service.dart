import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/utils/app_logger.dart';

class PaymentService {
  static final _supabase = SupabaseConfig.client;
  static const String _bucketName = 'payments';

  /// Upload payment proof screenshot to Supabase Storage.
  static Future<String> uploadPaymentProof({
    required String bookingId,
    required String customerId,
    required XFile imageFile,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rawPath = imageFile.path;
    final ext = (rawPath.contains('.')
            ? rawPath.split('.').last.toLowerCase()
            : 'jpg')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final fileName = '$customerId/${bookingId}_$timestamp.$safeExt';

    final contentType = switch (safeExt) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final Uint8List imageBytes = await imageFile.readAsBytes();

    await _supabase.storage.from(_bucketName).uploadBinary(
          fileName,
          imageBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );

    return _supabase.storage.from(_bucketName).getPublicUrl(fileName);
  }

  /// Submit a payment record to the payments table.
  static Future<void> submitPayment({
    required String bookingId,
    required String customerId,
    required double amount,
    required String referenceNumber,
    required String senderName,
    required String proofImageUrl,
  }) async {
    await _supabase.from('payments').insert({
      'booking_id': bookingId,
      'customer_id': customerId,
      'amount': amount,
      'reference_number': referenceNumber,
      'sender_name': senderName,
      'proof_image_url': proofImageUrl,
      'status': 'pending_verification',
      'payment_method': 'gcash',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Also update the booking's payment status
    await _supabase.from('bookings').update({
      'payment_status': 'submitted',
      'payment_method': 'gcash',
    }).eq('id', bookingId);
  }

  /// Get payment for a booking.
  static Future<Map<String, dynamic>?> getPaymentForBooking(String bookingId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      AppLogger.e('PaymentService: Error getting payment', error: e);
      return null;
    }
  }

  /// Get all payments (for admin).
  static Future<List<Map<String, dynamic>>> getAllPayments() async {
    final response = await _supabase
        .from('payments')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Admin: Verify or reject a payment.
  static Future<void> updatePaymentStatus({
    required String paymentId,
    required String status, // 'verified' or 'rejected'
    String? adminNote,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'verified_at': DateTime.now().toIso8601String(),
    };
    if (adminNote != null) updates['admin_note'] = adminNote;

    await _supabase.from('payments').update(updates).eq('id', paymentId);

    // Update the booking's payment_status based on admin decision
    final payment = await _supabase
        .from('payments')
        .select('booking_id')
        .eq('id', paymentId)
        .single();

    if (status == 'verified') {
      await _supabase.from('bookings').update({
        'payment_status': 'completed',
      }).eq('id', payment['booking_id']);
    } else if (status == 'rejected') {
      // Reset so the customer can resubmit
      await _supabase.from('bookings').update({
        'payment_status': 'pending',
      }).eq('id', payment['booking_id']);
    }
  }

  /// Delete a payment record (used when customer resubmits).
  static Future<void> deletePayment(String paymentId) async {
    await _supabase.from('payments').delete().eq('id', paymentId);
  }

  /// Admin: Upload GCash QR code image.
  static Future<String> uploadAdminQrCode({
    required String adminId,
    required XFile imageFile,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rawPath = imageFile.path;
    final ext = (rawPath.contains('.')
            ? rawPath.split('.').last.toLowerCase()
            : 'jpg')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final fileName = 'qr_codes/${adminId}_$timestamp.$safeExt';

    final contentType = switch (safeExt) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final Uint8List imageBytes = await imageFile.readAsBytes();

    await _supabase.storage.from(_bucketName).uploadBinary(
          fileName,
          imageBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );

    return _supabase.storage.from(_bucketName).getPublicUrl(fileName);
  }

  /// Admin: Save/update the GCash QR code settings.
  static Future<void> saveAdminQrSettings({
    required String qrImageUrl,
    required String gcashName,
    required String gcashNumber,
  }) async {
    // Upsert into app_settings table
    await _supabase.from('app_settings').upsert({
      'setting_key': 'gcash_qr',
      'setting_value': {
        'qr_image_url': qrImageUrl,
        'gcash_name': gcashName,
        'gcash_number': gcashNumber,
        'updated_at': DateTime.now().toIso8601String(),
      },
    }, onConflict: 'setting_key');
  }

  /// Get admin's GCash QR code settings.
  static Future<Map<String, dynamic>?> getAdminQrSettings() async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select()
          .eq('setting_key', 'gcash_qr')
          .maybeSingle();
      if (response != null && response['setting_value'] != null) {
        return Map<String, dynamic>.from(response['setting_value'] as Map);
      }
      return null;
    } catch (e) {
      AppLogger.e('PaymentService: Error getting QR settings', error: e);
      return null;
    }
  }
}
