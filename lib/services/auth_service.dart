import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/app_exception.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Stream<AuthState> get authState => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AppException(e.message, e);
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );
    } on AuthException catch (e) {
      throw AppException(e.message, e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AppException(e.message, e);
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
