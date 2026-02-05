/// Utility to migrate old bookings in local storage to include customerId
/// This ensures customers only see their own bookings after the security fix

import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../services/storage_service.dart';

class BookingMigrationUtility {
  /// Migrate all bookings in local storage
  /// - Remove bookings without customerId (orphaned/invalid bookings)
  /// - Log the migration results
  static Future<MigrationResult> migrateLocalBookings() async {
    try {
      print('=== Starting Booking Migration ===');
      
      // Load all bookings from local storage as JSON string
      final bookingsJson = await StorageService.loadGlobalBookings();
      
      if (bookingsJson == null || bookingsJson.isEmpty) {
        print('No bookings found in local storage');
        return MigrationResult(
          totalBookings: 0,
          validBookings: 0,
          removedBookings: 0,
          removedBookingIds: [],
        );
      }
      
      // Parse JSON
      final List<dynamic> allBookings = json.decode(bookingsJson);
      final totalBookings = allBookings.length;
      
      print('Found $totalBookings bookings in local storage');
      
      // Separate bookings with and without customerId
      final validBookings = <Map<String, dynamic>>[];
      final invalidBookings = <Map<String, dynamic>>[];
      
      for (final bookingData in allBookings) {
        final booking = bookingData as Map<String, dynamic>;
        final customerId = booking['customerId'] as String?;
        
        if (customerId != null && customerId.isNotEmpty) {
          validBookings.add(booking);
        } else {
          invalidBookings.add(booking);
          print('⚠️ Found booking without customerId: ${booking['id']} (${booking['customerName']})');
        }
      }
      
      print('Valid bookings (with customerId): ${validBookings.length}');
      print('Invalid bookings (without customerId): ${invalidBookings.length}');
      
      // Save only valid bookings back to storage
      final validBookingsJson = json.encode(validBookings);
      await StorageService.saveGlobalBookings(validBookingsJson);
      
      final result = MigrationResult(
        totalBookings: totalBookings,
        validBookings: validBookings.length,
        removedBookings: invalidBookings.length,
        removedBookingIds: invalidBookings.map((b) => b['id'] as String).toList(),
      );
      
      print('=== Migration Complete ===');
      print('Kept: ${result.validBookings} bookings');
      print('Removed: ${result.removedBookings} bookings');
      
      return result;
    } catch (e, stackTrace) {
      print('❌ Migration failed: $e');
      if (kDebugMode) {
        print(stackTrace);
      }
      rethrow;
    }
  }
  
  /// Check if migration is needed (returns true if there are bookings without customerId)
  static Future<bool> isMigrationNeeded() async {
    try {
      final bookingsJson = await StorageService.loadGlobalBookings();
      
      if (bookingsJson == null || bookingsJson.isEmpty) {
        return false;
      }
      
      final List<dynamic> allBookings = json.decode(bookingsJson);
      
      var needsMigration = false;
      var count = 0;
      
      for (final bookingData in allBookings) {
        final booking = bookingData as Map<String, dynamic>;
        final customerId = booking['customerId'] as String?;
        
        if (customerId == null || customerId.isEmpty) {
          needsMigration = true;
          count++;
        }
      }
      
      if (needsMigration) {
        print('⚠️ Migration needed: $count bookings without customerId');
      }
      
      return needsMigration;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }
  
  /// Get migration statistics without actually migrating
  static Future<MigrationStats> getMigrationStats() async {
    try {
      final bookingsJson = await StorageService.loadGlobalBookings();
      
      if (bookingsJson == null || bookingsJson.isEmpty) {
        return MigrationStats(
          totalBookings: 0,
          bookingsWithCustomerId: 0,
          bookingsWithoutCustomerId: 0,
          affectedBookingIds: [],
        );
      }
      
      final List<dynamic> allBookings = json.decode(bookingsJson);
      final bookingsWithoutCustomerId = <String>[];
      
      for (final bookingData in allBookings) {
        final booking = bookingData as Map<String, dynamic>;
        final customerId = booking['customerId'] as String?;
        
        if (customerId == null || customerId.isEmpty) {
          bookingsWithoutCustomerId.add(booking['id'] as String);
        }
      }
      
      return MigrationStats(
        totalBookings: allBookings.length,
        bookingsWithCustomerId: allBookings.length - bookingsWithoutCustomerId.length,
        bookingsWithoutCustomerId: bookingsWithoutCustomerId.length,
        affectedBookingIds: bookingsWithoutCustomerId,
      );
    } catch (e) {
      print('Error getting migration stats: $e');
      return MigrationStats(
        totalBookings: 0,
        bookingsWithCustomerId: 0,
        bookingsWithoutCustomerId: 0,
        affectedBookingIds: [],
      );
    }
  }
  
  /// Clear all bookings from local storage (use with caution!)
  static Future<void> clearAllBookings() async {
    await StorageService.saveGlobalBookings('[]');
    print('✅ Cleared all bookings from local storage');
  }
}

/// Result of a migration operation
class MigrationResult {
  final int totalBookings;
  final int validBookings;
  final int removedBookings;
  final List<String> removedBookingIds;
  
  MigrationResult({
    required this.totalBookings,
    required this.validBookings,
    required this.removedBookings,
    required this.removedBookingIds,
  });
  
  bool get wasSuccessful => validBookings + removedBookings == totalBookings;
  
  @override
  String toString() {
    return 'MigrationResult(total: $totalBookings, valid: $validBookings, removed: $removedBookings)';
  }
}

/// Statistics about bookings before migration
class MigrationStats {
  final int totalBookings;
  final int bookingsWithCustomerId;
  final int bookingsWithoutCustomerId;
  final List<String> affectedBookingIds;
  
  MigrationStats({
    required this.totalBookings,
    required this.bookingsWithCustomerId,
    required this.bookingsWithoutCustomerId,
    required this.affectedBookingIds,
  });
  
  bool get needsMigration => bookingsWithoutCustomerId > 0;
  
  @override
  String toString() {
    return 'MigrationStats(total: $totalBookings, valid: $bookingsWithCustomerId, invalid: $bookingsWithoutCustomerId)';
  }
}
