import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvConfig.load();
  await SupabaseConfig.initialize();

  // Firebase config files (google-services.json / GoogleService-Info.plist)
  // must be added to android/app and ios/Runner respectively — see
  // README "Firebase setup" for the one-time steps this environment
  // couldn't generate for you.
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: AcademyApp()));
}

class AcademyApp extends ConsumerWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppBrand.academyName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
