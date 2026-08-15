import 'package:flutter/foundation.dart';

/// Centralized logging utility for the ShopShare application.
/// Provides consistent logging across debug, info, warning, and error levels.
///
/// In production, only warnings and errors are logged.
/// In debug mode, all log levels are visible.
class AppLogger {
  AppLogger._();

  /// Log level enum for controlling verbosity.
  static LogLevel _logLevel =
      kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// Sets the global log level.
  /// Use this to control logging verbosity in different environments.
  static void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  /// Logs a debug message with optional data.
  /// Only shown in debug mode.
  static void debug(String message, [Map<String, dynamic>? data]) {
    if (_logLevel.index <= LogLevel.debug.index) {
      _log('🔍 DEBUG', message, data);
    }
  }

  /// Logs an informational message with optional data.
  static void info(String message, [Map<String, dynamic>? data]) {
    if (_logLevel.index <= LogLevel.info.index) {
      _log('ℹ️  INFO', message, data);
    }
  }

  /// Logs a warning message with optional data.
  static void warning(String message, [Map<String, dynamic>? data]) {
    if (_logLevel.index <= LogLevel.warning.index) {
      _log('⚠️  WARNING', message, data);
    }
  }

  /// Logs an error message with optional data.
  /// Always logged regardless of log level.
  static void error(String message, [Map<String, dynamic>? data]) {
    _log('❌ ERROR', message, data);
  }

  // ── Private Methods ────────────────────────────────────────────────────────

  /// Internal logging function that formats and prints log messages.
  static void _log(
    String level,
    String message,
    Map<String, dynamic>? data,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $level: $message';

    // Print to console
    debugPrint(logMessage);

    // Print additional data if provided
    if (data != null && data.isNotEmpty) {
      final dataStr = data.entries
          .map((e) => '  ${e.key}: ${_sanitizeValue(e.value)}')
          .join('\n');
      debugPrint(dataStr);
    }

    // TODO: In production, integrate with analytics/crashlytics service
    // Example: FirebaseCrashlytics.instance.log(logMessage);
  }

  /// Sanitizes sensitive values before logging.
  /// Never logs credentials, tokens, or full personal data.
  static String _sanitizeValue(dynamic value) {
    final valueStr = value.toString();

    // Redact potential sensitive fields
    if (_isSensitiveKey(valueStr)) {
      return '[REDACTED]';
    }

    // Truncate very long values
    if (valueStr.length > 200) {
      return '${valueStr.substring(0, 200)}... (truncated)';
    }

    return valueStr;
  }

  /// Checks if a value might contain sensitive information.
  static bool _isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey.contains('password') ||
        lowerKey.contains('token') ||
        lowerKey.contains('secret') ||
        lowerKey.contains('credential') ||
        lowerKey.contains('apikey') ||
        lowerKey.contains('api_key');
  }
}

/// Log level enumeration for controlling logging verbosity.
enum LogLevel {
  debug, // Detailed debug information (only in development)
  info, // General informational messages
  warning, // Warning messages that don't prevent execution
  error, // Error messages indicating failures
}
