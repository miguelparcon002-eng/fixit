# Clear Local Storage - ONE TIME FIX

## Problem
The app was migrated to use Supabase, but old local storage data still exists and is interfering with the new system.

## Solution: Clear Local Storage (One-Time Operation)

### Option 1: Clear via Code (Recommended)

1. Open `lib/main.dart`
2. Find the `_checkAndMigrateBookings()` function (around line 28)
3. **TEMPORARILY** add this code at the START of the function:

```dart
Future<void> _checkAndMigrateBookings() async {
  try {
    // ONE-TIME FIX: Clear all old local storage bookings
    print('🧹 Clearing old local storage bookings...');
    await BookingMigrationUtility.clearAllBookings();
    print('✅ Local storage cleared - app now uses Supabase only');

    // OLD CODE BELOW - can be removed after clearing once
    final needsMigration = await BookingMigrationUtility.isMigrationNeeded();

    if (needsMigration) {
      print('⚠️ Booking migration needed - running auto-migration...');
      final result = await BookingMigrationUtility.migrateLocalBookings();
      print('✅ Auto-migration complete: ${result.toString()}');
    } else {
      print('✅ No booking migration needed');
    }
  } catch (e) {
    print('⚠️ Booking migration check failed: $e');
  }
}
```

4. Run the app ONCE
5. Check the console - you should see "✅ Local storage cleared"
6. **REMOVE the clearing code** after running once
7. Restart the app

### Option 2: Uninstall and Reinstall App

1. Completely uninstall the app from your device/emulator
2. Run `flutter clean`
3. Run `flutter pub get`
4. Reinstall the app
5. All local storage will be cleared

## Why This is Needed

The app used to store bookings in local storage (Hive). Now it uses Supabase. But the old local data is still there and might be causing conflicts or showing old information.

## After Clearing

Once local storage is cleared:
- ✅ App will ONLY use Supabase
- ✅ Technician screen will show real bookings from database
- ✅ Discount calculations will work correctly
- ✅ All changes will persist to database
