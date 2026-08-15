import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Manages the web app email allowlist.
/// Only active on web — on Android/iOS this always returns allowed.
/// The allowlist is read from assets/web_allowlist.txt (one email per line).
/// Lines starting with '#' are treated as comments and ignored.
/// No limit on the number of emails in the file.
class WebAllowlistService {
  WebAllowlistService._();
  static final WebAllowlistService instance = WebAllowlistService._();

  Set<String>? _cachedAllowlist;

  /// Returns true if the email is allowed to access the web app.
  /// Always returns true on non-web platforms.
  Future<bool> isEmailAllowed(String? email) async {
    // On Android/iOS/desktop — no restriction
    if (!kIsWeb) return true;
    if (email == null || email.isEmpty) return false;

    final allowlist = await _loadAllowlist();

    // If the file is empty (no non-comment lines), allow everyone.
    // This lets you disable the restriction by clearing the file.
    if (allowlist.isEmpty) return true;

    // Exact match — case-sensitive as specified
    return allowlist.contains(email.trim());
  }

  Future<Set<String>> _loadAllowlist() async {
    if (_cachedAllowlist != null) return _cachedAllowlist!;

    try {
      final content =
          await rootBundle.loadString('assets/web_allowlist.txt');
      final lines = content
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('#'))
          .toSet();
      _cachedAllowlist = lines;
      return lines;
    } catch (_) {
      // If the file can't be read, allow everyone (fail open).
      _cachedAllowlist = {};
      return {};
    }
  }

  /// Call this to force a re-read of the allowlist file (e.g. after hot reload).
  void clearCache() => _cachedAllowlist = null;
}