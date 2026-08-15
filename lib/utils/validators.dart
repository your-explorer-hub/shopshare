import 'constants.dart';

/// Form validation helpers.
/// Extracted from constants.dart for single-responsibility.
class Validators {
  Validators._();

  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(email);
  }

  static bool isValidItemName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > AppConstants.maxItemNameLength) return false;
    return true;
  }

  static bool isValidDisplayName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > AppConstants.maxDisplayNameLength) return false;
    return true;
  }

  /// Validates list name.
  ///
  /// Returns null if valid, error message if invalid.
  static String? validateListName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'List name cannot be empty';
    }

    if (trimmed.length > AppConstants.maxListNameLength) {
      return 'List name must be ${AppConstants.maxListNameLength} characters or less';
    }

    return null;
  }
}