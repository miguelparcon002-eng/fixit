import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_address.dart';
import '../services/address_service.dart';
import 'auth_provider.dart';
final addressServiceProvider = Provider((ref) => AddressService());
final userAddressesProvider = StreamProvider<List<UserAddress>>((ref) {
  final addressService = ref.watch(addressServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return addressService.watchUserAddresses(user.id);
});
final savedAddressCountProvider = Provider<int>((ref) {
  final addressesAsync = ref.watch(userAddressesProvider);
  return addressesAsync.when(
    data: (addresses) => addresses.length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});
final defaultAddressProvider = Provider<UserAddress?>(( ref) {
  final addressesAsync = ref.watch(userAddressesProvider);
  return addressesAsync.when(
    data: (addresses) {
      try {
        return addresses.firstWhere((addr) => addr.isDefault);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, _) => null,
  );
});