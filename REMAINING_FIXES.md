# Remaining Fixes for Supabase Migration

## Completed ✅
1. **booking_detail_screen.dart** - Now uses `customerBookingsProvider` (StreamProvider)
2. **addresses_screen.dart** - Now uses `userAddressesProvider` (StreamProvider)
3. **booking_provider.dart** - Removed legacy LocalBooking system
4. **address_provider.dart** - Converted to StreamProvider for Supabase

## Remaining Files to Fix

### 1. create_booking_screen.dart
**Error**: Uses old `addressProvider`
**Fix**: Change to `userAddressesProvider` and handle AsyncValue
```dart
// OLD:
final addresses = ref.read(addressProvider);

// NEW:
final addressesAsync = ref.watch(userAddressesProvider);
// Handle with .when() or .value
```

### 2. Admin Screens
**Files**:
- `admin_home_screen.dart`
- `admin_appointments_screen.dart`

**Error**: Use `localBookingsProvider` which was removed
**Fix**: Use `customerBookingsProvider` or `technicianBookingsProvider`
```dart
// OLD:
final bookings = ref.watch(localBookingsProvider);

// NEW:
final bookingsAsync = ref.watch(customerBookingsProvider);
// Or for admin viewing all:
final customerBookingsAsync = ref.watch(customerBookingsProvider);
final techBookingsAsync = ref.watch(technicianBookingsProvider);
```

### 3. user_session_service.dart
**Errors**:
- Uses `localBookingsProvider.notifier.reload()` - doesn't exist
- Uses `addressProvider.notifier.reload()` - doesn't exist
- Uses `redeemedVouchersProvider.notifier.reload()` - doesn't exist (it's StreamProvider)

**Fix**: Remove reload calls or use `ref.invalidate()` for StreamProviders
```dart
// OLD:
await _ref.read(localBookingsProvider.notifier).reload();
await _ref.read(addressProvider.notifier).reload();

// NEW:
_ref.invalidate(customerBookingsProvider);
_ref.invalidate(userAddressesProvider);
_ref.invalidate(redeemedVouchersProvider);
```

### 4. booking_dialog.dart
**Error**: Uses old `addressProvider`
**Fix**: Same as create_booking_screen.dart

### 5. rewards_screen.dart
**Error**: Treats `redeemedVouchersProvider` as List, but it's AsyncValue
**Fix**: Use `.when()` to handle AsyncValue
```dart
// OLD:
final vouchers = ref.watch(redeemedVouchersProvider);
if (vouchers.isEmpty) ...

// NEW:
final vouchersAsync = ref.watch(redeemedVouchersProvider);
return vouchersAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (e, s) => Text('Error: $e'),
  data: (vouchers) {
    if (vouchers.isEmpty) ...
    return ListView.builder(
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        ...
      },
    );
  },
);
```

### 6. profile_setup_dialog.dart
**Error**: Uses `addressProvider.notifier.addAddress()`
**Fix**: Use `addressServiceProvider`
```dart
// OLD:
await ref.read(addressProvider.notifier).addAddress(address);

// NEW:
final addressService = ref.read(addressServiceProvider);
final user = ref.read(currentUserProvider).value;
await addressService.addAddress(
  userId: user!.id,
  label: label,
  address: address,
  isDefault: true,
);
```

## Key Changes Summary

### Provider Name Changes
- `addressProvider` → `userAddressesProvider` (now StreamProvider)
- `localBookingsProvider` → `customerBookingsProvider` or `technicianBookingsProvider`
- `redeemedVouchersProvider` is now StreamProvider (no `.notifier`)

### Model Changes
- `Address` → `UserAddress` (different fields: `label`, `address` instead of `street`, `city`, `neighborhood`)
- `LocalBooking` → `BookingModel` (removed entirely)

### Service Usage
Direct service calls instead of notifier methods:
```dart
// Use service providers:
final addressService = ref.read(addressServiceProvider);
final bookingService = ref.read(bookingServiceProvider);
final voucherService = ref.read(redeemedVoucherServiceProvider);
```

## SQL Migration Required
Run this in Supabase SQL Editor: `supabase_migrations_new_tables.sql`

This creates:
- `user_addresses` table
- `user_redeemed_vouchers` table
- `technician_specialties` table
