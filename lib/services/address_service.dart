import '../core/config/supabase_config.dart';
import '../models/user_address.dart';
import '../core/utils/app_logger.dart';

class AddressService {
  final _supabase = SupabaseConfig.client;

  /// Get all addresses for the current user
  Future<List<UserAddress>> getUserAddresses(String userId) async {
    try {
      final response = await _supabase
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserAddress.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.p('AddressService: Error loading addresses - $e');
      return [];
    }
  }

  /// Add a new address
  Future<UserAddress?> addAddress({
    required String userId,
    required String label,
    required String address,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    try {
      final response = await _supabase
          .from('user_addresses')
          .insert({
            'user_id': userId,
            'label': label,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'is_default': isDefault,
          })
          .select()
          .single();

      AppLogger.p('AddressService: Address added successfully');
      return UserAddress.fromJson(response);
    } catch (e) {
      AppLogger.p('AddressService: Error adding address - $e');
      return null;
    }
  }

  /// Update an existing address
  Future<UserAddress?> updateAddress({
    required String addressId,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (label != null) updates['label'] = label;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (isDefault != null) updates['is_default'] = isDefault;

      if (updates.isEmpty) return null;

      final response = await _supabase
          .from('user_addresses')
          .update(updates)
          .eq('id', addressId)
          .select()
          .single();

      AppLogger.p('AddressService: Address updated successfully');
      return UserAddress.fromJson(response);
    } catch (e) {
      AppLogger.p('AddressService: Error updating address - $e');
      return null;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    try {
      await _supabase.from('user_addresses').delete().eq('id', addressId);

      AppLogger.p('AddressService: Address deleted successfully');
      return true;
    } catch (e) {
      AppLogger.p('AddressService: Error deleting address - $e');
      return false;
    }
  }

  /// Set an address as default (automatically unsets other defaults)
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      await _supabase
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', addressId);

      AppLogger.p('AddressService: Default address set successfully');
      return true;
    } catch (e) {
      AppLogger.p('AddressService: Error setting default address - $e');
      return false;
    }
  }

  /// Get the default address for a user
  Future<UserAddress?> getDefaultAddress(String userId) async {
    try {
      final response = await _supabase
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) return null;
      return UserAddress.fromJson(response);
    } catch (e) {
      AppLogger.p('AddressService: Error getting default address - $e');
      return null;
    }
  }

  /// Stream addresses for real-time updates
  Stream<List<UserAddress>> watchUserAddresses(String userId) {
    return _supabase
        .from('user_addresses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => UserAddress.fromJson(json)).toList());
  }
}
