import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service (uses Hive with IndexedDB for web)
  await StorageService.init();
  print('=== Storage initialized ===');

  await SupabaseConfig.initialize();

  print('=== APP STARTED ===');

  runApp(
    const ProviderScope(child: FixitApp()),
  );
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
