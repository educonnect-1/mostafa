import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:marwan_elgendi_academy/core/errors/app_exception.dart';
import 'package:marwan_elgendi_academy/features/auth/application/auth_controller.dart';
import 'package:marwan_elgendi_academy/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.isSignedIn).thenReturn(false);
    when(() => mockRepo.onAuthStateChange)
        .thenAnswer((_) => const Stream<sb.AuthState>.empty());
  });

  group('AuthController', () {
    test('starts unauthenticated when no session exists', () {
      final controller = AuthController(mockRepo);
      expect(controller.state.status, AuthStatus.unauthenticated);
      controller.dispose();
    });

    test('starts authenticated when a session already exists', () {
      when(() => mockRepo.isSignedIn).thenReturn(true);
      final controller = AuthController(mockRepo);
      expect(controller.state.status, AuthStatus.authenticated);
      controller.dispose();
    });

    test('signIn success returns true and clears error', () async {
      when(() => mockRepo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {});

      final controller = AuthController(mockRepo);
      final result = await controller.signIn(
        email: 'student@example.com',
        password: 'correct-password',
      );

      expect(result, isTrue);
      expect(controller.state.error, isNull);
      controller.dispose();
    });

    test('signIn failure returns false and surfaces AppException', () async {
      when(() => mockRepo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const AuthAppException('Incorrect email or password.'));

      final controller = AuthController(mockRepo);
      final result = await controller.signIn(
        email: 'student@example.com',
        password: 'wrong-password',
      );

      expect(result, isFalse);
      expect(controller.state.error, isA<AuthAppException>());
      controller.dispose();
    });

    test('signOut delegates to the repository', () async {
      when(() => mockRepo.signOut()).thenAnswer((_) async {});
      final controller = AuthController(mockRepo);

      await controller.signOut();

      verify(() => mockRepo.signOut()).called(1);
      controller.dispose();
    });
  });
}
