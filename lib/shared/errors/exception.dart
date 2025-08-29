/// Base class for all application exceptions
abstract class AppException implements Exception {
  const AppException(this.message);
  
  final String message;
  
  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when API call fails
class ApiException extends AppException {
  const ApiException(super.message);
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  const NetworkException(super.message);
}