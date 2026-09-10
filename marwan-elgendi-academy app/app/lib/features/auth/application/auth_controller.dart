import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/app_exception.dart';
import '../../../repositories/auth_repository.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.error});

  final AuthStatus status;
  final AppException? error;

  static const initial = AuthState(status: AuthStatus.initial);

  AuthState copyWith({AuthStatus? status, AppException? error}) {
    return AuthState(status: status ?? this.status, error: error);
  }
}

/// Owns the app's authentication lifecycle. UI screens watch this via
/// [authControllerProvider] and never talk to Supabase Auth directly.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository) : super(AuthState.initial) {
    _init();
  }

  final AuthRepository _authRepository;
  StreamSubscription<sb.AuthState>? _authSub;

  void _init() {
    state = AuthState(
      status: _authRepository.isSignedIn
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
    );
    _authSub = _authRepository.onAuthStateChange.listen((event) {
      final signedIn = event.session != null;
      state = AuthState(
        status: signedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      );
    });
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      await _authRepository.signInWithPassword(email: email, password: password);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  Future<void> signOut() => _authRepository.signOut();

  void clearError() {
    state = state.copyWith(error: null);
  }

  String? get currentUserIdOrNull => _authRepository.currentUserId;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});
