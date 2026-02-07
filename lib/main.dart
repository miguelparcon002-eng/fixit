import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'services/storage_service.dart';
import 'utils/booking_migration_utility.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service (uses Hive with IndexedDB for web)
  await StorageService.init();
  print('=== Storage initialized ===');

  await SupabaseConfig.initialize();

  // Auto-check and migrate bookings if needed
  await _checkAndMigrateBookings();

  print('=== APP STARTED ===');

  runApp(
    const ProviderScope(child: FixitApp()),
  );
}

/// Check if booking migration is needed and auto-migrate on startup
///
/// ONE-TIME FIX: Set this to true to clear all old local bookings
/// After running once with this true, set it back to false
const bool clearOldLocalStorage = false;

Future<void> _checkAndMigrateBookings() async {
  try {
    // ONE-TIME FIX: Clear old local storage if flag is enabled
    if (clearOldLocalStorage) {
      print('🧹 CLEARING OLD LOCAL STORAGE BOOKINGS...');
      await BookingMigrationUtility.clearAllBookings();
      print('✅ Local storage cleared! App now uses Supabase only.');
      print('⚠️ IMPORTANT: Set clearOldLocalStorage = false in main.dart');
      return; // Don't run migration after clearing
    }

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
    // Don't block app startup if migration fails
  }
}

class FixitApp extends StatelessWidget {
  const FixitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FIXIT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
