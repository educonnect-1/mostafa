import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized, typed access to non-secret client configuration.
///
/// Values are loaded from `.env` (see `.env.example`) at app startup via
/// `EnvConfig.load()`, called once in `main.dart` before `runApp`.
///
/// This app must NEVER hold a Supabase service-role key or any other
/// server-side secret — only the public anon key belongs here.
class EnvConfig {
  EnvConfig._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    _validate();
  }

  static void _validate() {
    final missing = <String>[];
    for (final key in ['SUPABASE_URL', 'SUPABASE_ANON_KEY']) {
      if ((dotenv.env[key] ?? '').isEmpty) missing.add(key);
    }
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required .env values: ${missing.join(', ')}. '
        'Copy .env.example to .env and fill it in.',
      );
    }
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;
  static String get jitsiServerUrl =>
      dotenv.env['JITSI_SERVER_URL'] ?? 'https://meet.jit.si';
}
