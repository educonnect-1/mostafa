import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:marwan_elgendi_academy/core/errors/app_exception.dart';
import 'package:marwan_elgendi_academy/core/errors/exception_mapper.dart';

void main() {
  group('runGuarded', () {
    test('passes through a successful result unchanged', () async {
      final result = await runGuarded(() async => 42);
      expect(result, 42);
    });

    test('maps a RLS permission-denied Postgrest error to PermissionAppException', () async {
      expect(
        () => runGuarded(() async {
          throw const PostgrestException(message: 'denied', code: '42501');
        }),
        throwsA(isA<PermissionAppException>()),
      );
    });

    test('maps a "no rows" Postgrest error to NotFoundAppException', () async {
      expect(
        () => runGuarded(() async {
          throw const PostgrestException(message: 'no rows', code: 'PGRST116');
        }),
        throwsA(isA<NotFoundAppException>()),
      );
    });

    test('maps a deadline-related trigger error to DeadlinePassedException', () async {
      expect(
        () => runGuarded(() async {
          throw const PostgrestException(
            message: 'Assignment is closed; submission rejected.',
          );
        }),
        throwsA(isA<DeadlinePassedException>()),
      );
    });

    test('maps a SocketException to NetworkException', () async {
      expect(
        () => runGuarded(() async {
          throw const SocketException('no network');
        }),
        throwsA(isA<NetworkException>()),
      );
    });

    test('maps invalid-credentials AuthException to a friendly AuthAppException', () async {
      expect(
        () => runGuarded(() async {
          throw AuthException('Invalid login credentials');
        }),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            'Incorrect email or password.',
          ),
        ),
      );
    });

    test('never rethrows the raw exception type for unknown errors', () async {
      final result = runGuarded<int>(() async => throw Exception('boom'));
      await expectLater(result, throwsA(isA<UnknownAppException>()));
    });

    test('an already-typed AppException passes through unchanged', () async {
      expect(
        () => runGuarded(() async => throw const ValidationAppException('bad input')),
        throwsA(isA<ValidationAppException>()),
      );
    });
  });
}
