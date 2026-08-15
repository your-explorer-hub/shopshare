import 'package:flutter/material.dart';
import '../../services/auth_service.dart' show AuthException;
import 'exceptions.dart';
import '../utils/app_logger.dart';

/// Centralized error handling for the ShopShare application.
/// Provides consistent error display, logging, and user feedback.
class ErrorHandler {
  ErrorHandler._();

  /// Handles an error by showing a user-friendly message and logging details.
  ///
  /// [context]: BuildContext for showing SnackBar (optional - fallback to logging only)
  /// [error]: The error object (Exception, Error, or any dynamic type)
  /// [customMessage]: Optional custom message to override default error text
  /// [onRetry]: Optional callback for retry action in SnackBar
  static void handleError(
    dynamic error, {
    BuildContext? context,
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    // Log the error first
    _logError(error);

    // Get user-friendly message
    final message = customMessage ?? _getErrorMessage(error);

    // Show SnackBar if context is available
    if (context != null && context.mounted) {
      _showErrorSnackBar(context, message, onRetry: onRetry);
    }
  }

  /// Shows a success message to the user.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an info message to the user.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Private Methods ────────────────────────────────────────────────────────

  /// Shows an error SnackBar with optional retry action.
  static void _showErrorSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Converts an error object to a user-friendly message.
  static String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return error.message;
    }

    if (error is AppException) {
      return error.message;
    }

    if (error is NetworkException) {
      return 'Network error. Please check your internet connection.';
    }

    if (error is FirestoreException) {
      return _getFirestoreErrorMessage(error);
    }

    if (error is ValidationException) {
      return error.message;
    }

    if (error is SubscriptionException) {
      return error.message;
    }

    // Handle Firebase errors
    if (error.toString().contains('firebase')) {
      return _parseFirebaseError(error);
    }

    // Handle network errors
    if (error.toString().toLowerCase().contains('network') ||
        error.toString().toLowerCase().contains('socket') ||
        error.toString().toLowerCase().contains('timeout')) {
      return 'Network error. Please check your internet connection.';
    }

    // Fallback for unknown errors
    return 'Something went wrong. Please try again.';
  }

  /// Generates specific Firestore error messages.
  static String _getFirestoreErrorMessage(FirestoreException error) {
    if (error.code?.contains('permission-denied') ?? false) {
      return 'You don\'t have permission to perform this action.';
    }
    if (error.code?.contains('unavailable') ?? false) {
      return 'Service temporarily unavailable. Please try again.';
    }
    if (error.code?.contains('not-found') ?? false) {
      return 'Requested data not found.';
    }
    return error.message;
  }

  /// Parses generic Firebase error strings.
  static String _parseFirebaseError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission')) {
      return 'Permission denied. Please check your access rights.';
    }
    if (errorStr.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    if (errorStr.contains('not found')) {
      return 'Requested data not found.';
    }
    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    return 'Database error. Please try again.';
  }

  /// Logs error details for debugging and monitoring.
  static void _logError(dynamic error) {
    if (error is AuthException) {
      AppLogger.error(
        'AuthException: ${error.message}',
        {'type': error.runtimeType.toString()},
      );
    } else if (error is AppException) {
      AppLogger.error(
        'AppException: ${error.message}',
        {
          'type': error.runtimeType.toString(),
          'code': error.code,
          'originalError': error.originalError?.toString(),
        },
      );
    } else {
      AppLogger.error(
        'Unhandled error: ${error.toString()}',
        {'type': error.runtimeType.toString()},
      );
    }
  }
}
