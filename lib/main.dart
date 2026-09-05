import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.configured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
  runApp(const EduConnectApp());
}

class EduConnectApp extends StatelessWidget {
  const EduConnectApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'EduConnect',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: appRouter,
  );
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'EduConnect is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
