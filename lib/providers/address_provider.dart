import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../services/storage_service.dart';

// Provider to manage saved addresses (user-specific)
class AddressNotifier extends StateNotifier<List<Address>> {
  String? _lastUserId;
  bool _isInitialized = false;

  AddressNotifier() : super([]) {
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final currentUserId = StorageService.currentUserId;

    // Check if user changed
    if (_isInitialized && _lastUserId == currentUserId) return;

    // Reset state if user changed
    if (_lastUserId != currentUserId) {
      state = [];
      _isInitialized = false;
    }
    _lastUserId = currentUserId;

    try {
      print('AddressNotifier: Loading addresses for user: $currentUserId...');
      final addressData = await StorageService.loadAddresses();

      if (addressData != null && addressData.isNotEmpty) {
        final List<dynamic> decoded = json.decode(addressData);
        state = decoded.map((item) => Address.fromJson(item)).toList();
        print('AddressNotifier: Loaded ${state.length} addresses');
      } else {
        // No addresses found - start with empty list for new users
        print('AddressNotifier: No addresses found for user: $currentUserId');
        state = [];
      }
      _isInitialized = true;
    } catch (e) {
      print('AddressNotifier: Error loading addresses - $e');
      state = [];
      _isInitialized = true;
    }
  }

  Future<void> _saveAddresses() async {
    try {
      final addressJson = json.encode(state.map((a) => a.toJson()).toList());
      await StorageService.saveAddresses(addressJson);
      print('AddressNotifier: Saved ${state.length} addresses');
    } catch (e) {
      print('AddressNotifier: Error saving addresses - $e');
    }
  }

  // Force reload (e.g., when user changes)
  Future<void> reload() async {
    _isInitialized = false;
    _lastUserId = null;
    state = [];
    await _loadAddresses();
  }

  Future<void> addAddress(Address address) async {
    state = [...state, address];
    await _saveAddresses();
  }

  Future<void> removeAddress(String id) async {
    state = state.where((address) => address.id != id).toList();
    await _saveAddresses();
  }

  Future<void> updateAddress(Address updatedAddress) async {
    state = [
      for (final address in state)
        if (address.id == updatedAddress.id) updatedAddress else address,
    ];
    await _saveAddresses();
  }

  Future<void> setDefaultAddress(String id) async {
    state = [
      for (final address in state)
        address.copyWith(isDefault: address.id == id),
    ];
    await _saveAddresses();
  }
}

final addressProvider = StateNotifierProvider<AddressNotifier, List<Address>>((ref) {
  return AddressNotifier();
});

// Provider to get the count of saved addresses
final savedAddressCountProvider = Provider<int>((ref) {
  final addresses = ref.watch(addressProvider);
  return addresses.length;
});
