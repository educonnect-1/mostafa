import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

// PostgrestException, AuthException, and StorageException are all
// re-exported by package:supabase_flutter/supabase_flutter.dart, so no
// separate `postgrest`/`gotrue`/`storage_client` imports are needed here.

/// Every repository method should run its Supabase call through this,
/// e.g. `return runGuarded(() => _client.from('groups').select());`
/// so the UI layer only ever sees typed [AppException]s.
Future<T> runGuarded<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } on AuthException catch (e) {
    throw AuthAppException(_friendlyAuthMessage(e));
  } on PostgrestException catch (e) {
    throw _mapPostgrestException(e);
  } on StorageException catch (_) {
    throw const StorageAppException();
  } on SocketException catch (_) {
    throw const NetworkException();
  } on TimeoutException catch (_) {
    throw const TimeoutAppException();
  } catch (_) {
    throw const UnknownAppException();
  }
}

String _friendlyAuthMessage(AuthException e) {
  final msg = e.message.toLowerCase();
  if (msg.contains('invalid login credentials')) {
    return 'Incorrect email or password.';
  }
  if (msg.contains('email not confirmed')) {
    return 'Please confirm your email before signing in.';
  }
  if (msg.contains('rate limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  return 'We couldn\'t sign you in. Please check your details and try again.';
}

AppException _mapPostgrestException(PostgrestException e) {
  // Postgres error codes: https://www.postgresql.org/docs/current/errcodes-appendix.html
  switch (e.code) {
    case '42501': // insufficient_privilege (RLS denial)
      return const PermissionAppException();
    case 'PGRST116': // no rows found on .single()
      return const NotFoundAppException();
    default:
      final msg = e.message.toLowerCase();
      if (msg.contains('closed') || msg.contains('deadline')) {
        return DeadlinePassedException(e.message);
      }
      if (msg.contains('jwt') || msg.contains('session')) {
        return const SessionExpiredException();
      }
      return UnknownAppException(e.message);
  }
}
