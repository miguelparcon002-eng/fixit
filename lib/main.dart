import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/supabase_config.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase is required across the app (auth, storage, db)
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: FixItApp()));
}

class FixItApp extends StatelessWidget {
  const FixItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FixIt',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
