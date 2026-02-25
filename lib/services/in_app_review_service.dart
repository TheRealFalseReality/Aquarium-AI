import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that manages the in-app review prompt.
///
/// The review is requested at most once, no sooner than [_minDaysSinceFirstLaunch]
/// days after the very first app launch.
class InAppReviewService {
  static const String _firstLaunchTimestampKey = 'first_launch_timestamp';
  static const String _reviewRequestedKey = 'in_app_review_requested';
  static const int _minDaysSinceFirstLaunch = 3;

  /// Records the first launch timestamp the very first time it is called.
  /// Subsequent calls are no-ops.
  static Future<void> recordFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_firstLaunchTimestampKey)) return;
      await prefs.setInt(
        _firstLaunchTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('InAppReviewService: first launch timestamp recorded');
    } catch (e) {
      debugPrint('InAppReviewService.recordFirstLaunch error: $e');
    }
  }

  /// Requests an in-app review if all conditions are met:
  /// - The device/store supports in-app reviews.
  /// - At least [_minDaysSinceFirstLaunch] days have elapsed since first launch.
  /// - The review has not been requested before.
  static Future<void> maybeRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Only request once per install
      if (prefs.getBool(_reviewRequestedKey) == true) {
        debugPrint('InAppReviewService: review already requested, skipping');
        return;
      }

      final firstLaunchTimestamp = prefs.getInt(_firstLaunchTimestampKey);
      if (firstLaunchTimestamp == null) {
        debugPrint('InAppReviewService: no first launch timestamp, skipping');
        return;
      }

      final daysSinceFirstLaunch =
          (DateTime.now().millisecondsSinceEpoch - firstLaunchTimestamp) /
              (1000 * 60 * 60 * 24);

      debugPrint(
        'InAppReviewService: days since first launch: '
        '${daysSinceFirstLaunch.toStringAsFixed(1)} '
        '(minimum: $_minDaysSinceFirstLaunch)',
      );

      if (daysSinceFirstLaunch < _minDaysSinceFirstLaunch) {
        debugPrint(
          'InAppReviewService: minimum days not elapsed, skipping',
        );
        return;
      }

      final inAppReview = InAppReview.instance;
      if (!await inAppReview.isAvailable()) {
        debugPrint('InAppReviewService: in-app review not available');
        return;
      }

      await prefs.setBool(_reviewRequestedKey, true);
      await inAppReview.requestReview();
      debugPrint('InAppReviewService: review requested');
    } catch (e) {
      debugPrint('InAppReviewService.maybeRequestReview error: $e');
    }
  }

  /// Removes all persisted review-related keys from SharedPreferences.
  /// For use in tests only.
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstLaunchTimestampKey);
    await prefs.remove(_reviewRequestedKey);
  }

  /// Bypasses all guards and immediately requests a review.
  /// For use in debug mode only.
  static Future<void> forceRequestReview() async {
    try {
      final inAppReview = InAppReview.instance;
      if (!await inAppReview.isAvailable()) {
        debugPrint('InAppReviewService: in-app review not available');
        return;
      }
      await inAppReview.requestReview();
      debugPrint('InAppReviewService: review force-requested (debug)');
    } catch (e) {
      debugPrint('InAppReviewService.forceRequestReview error: $e');
    }
  }
}
