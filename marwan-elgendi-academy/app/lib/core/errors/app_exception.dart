/// Base type for every error the repository/service layer can throw.
///
/// UI code catches `AppException` and shows `message` — never a raw
/// `PostgrestException`, `AuthException`, or `SocketException` (spec §32).
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No internet connection. Please check your network and try again.',
  ]);
}

class TimeoutAppException extends AppException {
  const TimeoutAppException([
    super.message = 'The request took too long. Please try again.',
  ]);
}

class AuthAppException extends AppException {
  const AuthAppException([
    super.message = 'We couldn\'t sign you in. Please check your details and try again.',
  ]);
}

class SessionExpiredException extends AppException {
  const SessionExpiredException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class PermissionAppException extends AppException {
  const PermissionAppException([
    super.message = 'You don\'t have permission to do that.',
  ]);
}

class DeadlinePassedException extends AppException {
  const DeadlinePassedException([
    super.message = 'The deadline for this has passed.',
  ]);
}

class ValidationAppException extends AppException {
  const ValidationAppException(super.message);
}

class StorageAppException extends AppException {
  const StorageAppException([
    super.message = 'We couldn\'t upload or access that file. Please try again.',
  ]);
}

class NotFoundAppException extends AppException {
  const NotFoundAppException([
    super.message = 'That item could not be found.',
  ]);
}

class UnknownAppException extends AppException {
  const UnknownAppException([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
