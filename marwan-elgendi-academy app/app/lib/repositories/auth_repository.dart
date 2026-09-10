import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/exception_mapper.dart';

/// Wraps Supabase Auth. The Student App never exposes a public
/// registration screen (spec §4) — accounts are created via the
/// separate Student Registration Website after the teacher sends an
/// invitation. This repository only handles login/logout/password
/// reset/session for accounts that already exist.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  Session? get currentSession => _auth.currentSession;
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentSession != null;
  String? get currentUserId => currentUser?.id;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return runGuarded(() async {
      final res = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.session == null) {
        throw const AuthAppException();
      }
    });
  }

  Future<void> sendPasswordResetEmail(String email) {
    return runGuarded(() => _auth.resetPasswordForEmail(email.trim()));
  }

  /// Called after the user follows the password-reset deep link and the
  /// recovery session is established.
  Future<void> updatePassword(String newPassword) {
    return runGuarded(
      () => _auth.updateUser(UserAttributes(password: newPassword)),
    );
  }

  Future<void> signOut() {
    return runGuarded(() => _auth.signOut());
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(SupabaseConfig.client);
});
