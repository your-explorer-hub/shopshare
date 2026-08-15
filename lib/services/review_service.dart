import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles the native Google Play in-app review prompt.
/// Shows at most once every [_intervalDays] days.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const String _prefKey = 'last_review_prompt_ms';
  static const int _intervalDays = 7;

  /// Call this after the user has been in the app for ~10 seconds.
  /// On web / unsupported platforms this is a no-op.
  Future<void> maybeRequestReview() async {
    // Skip on web — in_app_review is not supported there.
    if (kIsWeb) return;

    try {
      final inAppReview = InAppReview.instance;
      final isAvailable = await inAppReview.isAvailable();
      if (!isAvailable) return;

      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_prefKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceLast =
          (now - lastMs) / Duration.millisecondsPerDay;

      if (daysSinceLast >= _intervalDays) {
        await inAppReview.requestReview();
        await prefs.setInt(_prefKey, now);
      }
    } catch (_) {
      // Never crash the app over a review prompt.
    }
  }
}