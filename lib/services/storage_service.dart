import '../core/config/supabase_config.dart';

class StorageService {
  static const String _tableName = 'local_storage';

  // Current user ID for user-specific storage
  static String? _currentUserId;

  // Set the current user ID for data isolation
  static void setCurrentUser(String? userId) {
    _currentUserId = userId;
    print('StorageService: User set to ${userId ?? 'none'}');
  }

  // Get current user ID
  static String? get currentUserId => _currentUserId;

  // Generate user-specific storage key
  static String _getUserKey(String baseKey) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return baseKey; // Fallback for unauthenticated state
    }
    return '${_currentUserId}_$baseKey';
  }

  // Initialize storage (create table if needed)
  static Future<void> init() async {
    try {
      print('StorageService: Checking Supabase connection...');

      // Just verify connection works
      await SupabaseConfig.client
          .from(_tableName)
          .select()
          .limit(1);

      print('StorageService: Supabase ready');
    } catch (e) {
      print('StorageService: Init check - $e (this is OK if table doesn\'t exist yet)');
    }
  }

  // Generic save data method
  static Future<void> saveData(String key, String jsonData) async {
    final storageKey = _getUserKey(key);
    try {
      print('StorageService: Saving to key "$storageKey"...');

      // Check if record exists
      final existing = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('key', storageKey)
          .maybeSingle();

      if (existing != null) {
        // Update existing record
        await SupabaseConfig.client
            .from(_tableName)
            .update({'value': jsonData, 'updated_at': DateTime.now().toIso8601String()})
            .eq('key', storageKey);
        print('StorageService: Updated existing record for "$storageKey"');
      } else {
        // Insert new record
        await SupabaseConfig.client
            .from(_tableName)
            .insert({
              'key': storageKey,
              'value': jsonData,
              'updated_at': DateTime.now().toIso8601String()
            });
        print('StorageService: Inserted new record for "$storageKey"');
      }
    } catch (e) {
      print('StorageService: Error saving to "$storageKey" - $e');
    }
  }

  // Generic load data method
  static Future<String?> loadData(String key) async {
    final storageKey = _getUserKey(key);
    try {
      print('StorageService: Loading from key "$storageKey"...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('value')
          .eq('key', storageKey)
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final data = response['value'] as String;
        print('StorageService: Loaded ${data.length} chars from "$storageKey"');
        return data;
      } else {
        print('StorageService: No data found for "$storageKey"');
        return null;
      }
    } catch (e) {
      print('StorageService: Error loading from "$storageKey" - $e');
      return null;
    }
  }

  // Generic delete data method
  static Future<void> deleteData(String key) async {
    final storageKey = _getUserKey(key);
    try {
      await SupabaseConfig.client
          .from(_tableName)
          .delete()
          .eq('key', storageKey);
      print('StorageService: Deleted data for "$storageKey"');
    } catch (e) {
      print('StorageService: Error deleting "$storageKey" - $e');
    }
  }

  // ===== USER-SPECIFIC DATA ACCESS (for accessing other user's data) =====

  /// Save data for a specific user (used for cross-user operations like adding reward points)
  static Future<void> saveDataForUser(String userId, String key, String jsonData) async {
    final storageKey = '${userId}_$key';
    try {
      print('StorageService: Saving to key "$storageKey" for user $userId...');

      final existing = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('key', storageKey)
          .maybeSingle();

      if (existing != null) {
        await SupabaseConfig.client
            .from(_tableName)
            .update({'value': jsonData, 'updated_at': DateTime.now().toIso8601String()})
            .eq('key', storageKey);
        print('StorageService: Updated existing record for "$storageKey"');
      } else {
        await SupabaseConfig.client
            .from(_tableName)
            .insert({
              'key': storageKey,
              'value': jsonData,
              'updated_at': DateTime.now().toIso8601String()
            });
        print('StorageService: Inserted new record for "$storageKey"');
      }
    } catch (e) {
      print('StorageService: Error saving to "$storageKey" - $e');
    }
  }

  /// Load data for a specific user (used for cross-user operations)
  static Future<String?> loadDataForUser(String userId, String key) async {
    final storageKey = '${userId}_$key';
    try {
      print('StorageService: Loading from key "$storageKey" for user $userId...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('value')
          .eq('key', storageKey)
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final data = response['value'] as String;
        print('StorageService: Loaded ${data.length} chars from "$storageKey"');
        return data;
      } else {
        print('StorageService: No data found for "$storageKey"');
        return null;
      }
    } catch (e) {
      print('StorageService: Error loading from "$storageKey" - $e');
      return null;
    }
  }

  // ===== GLOBAL BOOKINGS (shared across all users) =====

  // Save global bookings as JSON string (NOT user-specific - shared across all users)
  static Future<void> saveGlobalBookings(String jsonData) async {
    await _saveGlobalData('global_bookings', jsonData);
  }

  // Load global bookings JSON string (shared across all users)
  static Future<String?> loadGlobalBookings() async {
    return await _loadGlobalData('global_bookings');
  }

  // Clear global bookings
  static Future<void> clearGlobalBookings() async {
    await _deleteGlobalData('global_bookings');
  }

  // Check if global bookings exist
  static Future<bool> hasGlobalBookings() async {
    final data = await _loadGlobalData('global_bookings');
    return data != null && data.isNotEmpty;
  }

  // Generic save data method for GLOBAL (non-user-specific) data
  static Future<void> _saveGlobalData(String key, String jsonData) async {
    try {
      print('StorageService: Saving to global key "$key"...');

      // Check if record exists
      final existing = await SupabaseConfig.client
          .from(_tableName)
          .select()
          .eq('key', key)
          .maybeSingle();

      if (existing != null) {
        // Update existing record
        await SupabaseConfig.client
            .from(_tableName)
            .update({'value': jsonData, 'updated_at': DateTime.now().toIso8601String()})
            .eq('key', key);
        print('StorageService: Updated existing global record for "$key"');
      } else {
        // Insert new record
        await SupabaseConfig.client
            .from(_tableName)
            .insert({
              'key': key,
              'value': jsonData,
              'updated_at': DateTime.now().toIso8601String()
            });
        print('StorageService: Inserted new global record for "$key"');
      }
    } catch (e) {
      print('StorageService: Error saving to global "$key" - $e');
    }
  }

  // Generic load data method for GLOBAL (non-user-specific) data
  static Future<String?> _loadGlobalData(String key) async {
    try {
      print('StorageService: Loading from global key "$key"...');

      final response = await SupabaseConfig.client
          .from(_tableName)
          .select('value')
          .eq('key', key)
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final data = response['value'] as String;
        print('StorageService: Loaded ${data.length} chars from global "$key"');
        return data;
      } else {
        print('StorageService: No data found for global "$key"');
        return null;
      }
    } catch (e) {
      print('StorageService: Error loading from global "$key" - $e');
      return null;
    }
  }

  // Generic delete data method for GLOBAL (non-user-specific) data
  static Future<void> _deleteGlobalData(String key) async {
    try {
      await SupabaseConfig.client
          .from(_tableName)
          .delete()
          .eq('key', key);
      print('StorageService: Deleted global data for "$key"');
    } catch (e) {
      print('StorageService: Error deleting global "$key" - $e');
    }
  }

  // ===== USER-SPECIFIC BOOKINGS (legacy - keeping for backwards compatibility) =====

  // Save bookings as JSON string (user-specific)
  static Future<void> saveBookings(String jsonData) async {
    await saveData('bookings', jsonData);
  }

  // Load bookings JSON string (user-specific)
  static Future<String?> loadBookings() async {
    return await loadData('bookings');
  }

  // Clear bookings (user-specific)
  static Future<void> clearBookings() async {
    await deleteData('bookings');
  }

  // Check if bookings exist (user-specific)
  static Future<bool> hasBookings() async {
    final data = await loadData('bookings');
    return data != null && data.isNotEmpty;
  }

  // Save addresses (user-specific)
  static Future<void> saveAddresses(String jsonData) async {
    await saveData('addresses', jsonData);
  }

  // Load addresses (user-specific)
  static Future<String?> loadAddresses() async {
    return await loadData('addresses');
  }

  // Save reward points (user-specific)
  static Future<void> saveRewardPoints(String jsonData) async {
    await saveData('reward_points', jsonData);
  }

  // Load reward points (user-specific)
  static Future<String?> loadRewardPoints() async {
    return await loadData('reward_points');
  }

  // Save redeemed vouchers (user-specific)
  static Future<void> saveRedeemedVouchers(String jsonData) async {
    await saveData('redeemed_vouchers', jsonData);
  }

  // Load redeemed vouchers (user-specific)
  static Future<String?> loadRedeemedVouchers() async {
    return await loadData('redeemed_vouchers');
  }

  // Save profile setup status (user-specific)
  static Future<void> saveProfileSetupComplete(bool complete) async {
    await saveData('profile_setup_complete', complete.toString());
  }

  // Load profile setup status (user-specific)
  static Future<bool> loadProfileSetupComplete() async {
    final data = await loadData('profile_setup_complete');
    return data == 'true';
  }

  // Save valid vouchers (user-specific)
  static Future<void> saveValidVouchers(String jsonData) async {
    await saveData('valid_vouchers', jsonData);
  }

  // Load valid vouchers (user-specific)
  static Future<String?> loadValidVouchers() async {
    return await loadData('valid_vouchers');
  }

  // Clear all user data on logout
  static Future<void> clearAllUserData() async {
    if (_currentUserId == null) return;

    try {
      // Clear user-specific data
      await clearBookings();
      await deleteData('addresses');
      await deleteData('rewards');
      await deleteData('earnings');
      await deleteData('reward_points');
      await deleteData('redeemed_vouchers');
      await deleteData('profile_setup_complete');
      await deleteData('valid_vouchers');
      print('StorageService: Cleared all data for user $_currentUserId');
    } catch (e) {
      print('StorageService: Error clearing user data - $e');
    }
  }
}
