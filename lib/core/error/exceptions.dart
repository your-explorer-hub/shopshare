/// Custom exception types for the ShopShare application.
/// Used by ErrorHandler to provide appropriate error messages and handling.
///
/// Note: AuthException is defined in auth_service.dart and used here via import.

/// Base class for all application-specific exceptions.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Network connectivity errors (no internet, timeout, server unreachable).
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Firebase/Firestore operation errors (read, write, permission denied).
class FirestoreException extends AppException {
  const FirestoreException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Validation errors (invalid input, missing required fields).
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Subscription/permission errors (feature not available, quota exceeded).
class SubscriptionException extends AppException {
  const SubscriptionException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Unknown or unexpected errors that don't fit other categories.
class UnknownException extends AppException {
  const UnknownException(
    super.message, {
    super.code,
    super.originalError,
  });
}

