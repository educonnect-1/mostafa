import 'package:supabase_flutter/supabase_flutter.dart';

import 'env_config.dart';

/// Initializes the Supabase client once at app startup and exposes the
/// singleton client used throughout the repository layer.
///
/// Only the public anon key is used — RLS in the database (see
/// `schema.sql`) is what actually enforces access control, not this app.
class SupabaseConfig {
  SupabaseConfig._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
