/// Base repository class providing common patterns for Firestore repositories.
///
/// All domain repositories extend this to inherit common functionality
/// and maintain consistent error handling patterns.
abstract class BaseRepository {
  /// Handles Firestore errors and converts them to user-friendly messages.
  String handleFirestoreError(dynamic error) {
    if (error.toString().contains('PERMISSION_DENIED')) {
      return 'You do not have permission to perform this action';
    }
    if (error.toString().contains('NOT_FOUND')) {
      return 'The requested resource was not found';
    }
    if (error.toString().contains('UNAVAILABLE')) {
      return 'Service temporarily unavailable. Please try again';
    }
    return 'An unexpected error occurred. Please try again';
  }

  /// Validates that a required string field is not empty.
  void validateNonEmpty(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError('$fieldName cannot be empty');
    }
  }

  /// Validates that a required list is not empty.
  void validateNonEmptyList<T>(List<T> list, String fieldName) {
    if (list.isEmpty) {
      throw ArgumentError('$fieldName cannot be empty');
    }
  }
}
