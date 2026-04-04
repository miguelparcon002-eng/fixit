import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/fcm_service.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FCMService.initialize();
    } catch (e) {
      debugPrint('FCM init failed (non-fatal): $e');
    }
  }
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