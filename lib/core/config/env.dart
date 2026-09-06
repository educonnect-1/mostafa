import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized runtime configuration.
///
/// Values are read from a bundled `.env` file (see `.env.example` for the
/// required keys). If a key is missing from `.env` — for example in a CI
/// build that injects secrets via `--dart-define` instead — this falls back
/// to compile-time environment variables so existing build pipelines keep
/// working without changes.
class Env {
  static String _read(String key, String dartDefineFallback) {
    final fromDotEnv = dotenv.maybeGet(key);
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;
    return dartDefineFallback;
  }

  static String get supabaseUrl =>
      _read('SUPABASE_URL', const String.fromEnvironment('SUPABASE_URL'));

  static String get supabaseAnonKey => _read(
    'SUPABASE_ANON_KEY',
    const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static bool get configured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
