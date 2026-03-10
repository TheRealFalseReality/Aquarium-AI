import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

/// Service that manages the in-app review prompt.
///
/// The review is requested at most once, no sooner than [_minDaysSinceFirstLaunch]
/// days after the very first app launch.  A dismissible reminder banner is shown
/// on the welcome screen after [_minDaysSinceReviewBanner] days.
class InAppReviewService {
  static const String _firstLaunchTimestampKey = 'first_launch_timestamp';
  static const String _reviewRequestedKey = 'in_app_review_requested';
  static const String _reviewBannerDismissedKey = 'review_banner_dismissed';
  static const int _minDaysSinceFirstLaunch = 3;
  static const int _minDaysSinceReviewBanner = 7;
  static const int _msPerDay = 86400000; // 1000 * 60 * 60 * 24

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
  /// - At least [_minDaysSinceFirstLaunch] days have elapsed since first launch
  ///   (bypassed in debug mode).
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
          _msPerDay;

      debugPrint(
        'InAppReviewService: days since first launch: '
        '${daysSinceFirstLaunch.toStringAsFixed(1)} '
        '(minimum: $_minDaysSinceFirstLaunch)',
      );

      // In debug mode the cooldown is bypassed so developers can test the flow.
      if (!kDebugMode && daysSinceFirstLaunch < _minDaysSinceFirstLaunch) {
        debugPrint('InAppReviewService: minimum days not elapsed, skipping');
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

  /// Returns `true` when the review reminder banner should be shown on the
  /// welcome screen.
  ///
  /// Conditions (all must be true):
  /// - Running on Android (not web / iOS — the app is not yet on iOS).
  /// - The banner has not been manually dismissed.
  /// - At least [_minDaysSinceReviewBanner] days have elapsed since the first
  ///   launch.  This check is skipped in debug mode.
  /// - The in-app review was not already triggered automatically (skipped in
  ///   debug mode so the banner can be tested independently).
  static Future<bool> shouldShowReviewBanner() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Respect the user's explicit dismiss.
      if (prefs.getBool(_reviewBannerDismissedKey) == true) return false;

      final firstLaunchTimestamp = prefs.getInt(_firstLaunchTimestampKey);
      if (firstLaunchTimestamp == null) return false;

      if (kDebugMode) {
        // In debug mode: skip the time-delay and the auto-review guard so
        // developers can preview the banner without waiting 7 days.
        return true;
      }

      // Don't show if the in-app review dialog was already shown automatically.
      if (prefs.getBool(_reviewRequestedKey) == true) return false;

      final daysSinceFirstLaunch =
          (DateTime.now().millisecondsSinceEpoch - firstLaunchTimestamp) /
          _msPerDay;

      return daysSinceFirstLaunch >= _minDaysSinceReviewBanner;
    } catch (e) {
      debugPrint('InAppReviewService.shouldShowReviewBanner error: $e');
      return false;
    }
  }

  /// Persists the user's decision to dismiss the review reminder banner.
  static Future<void> dismissReviewBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reviewBannerDismissedKey, true);
    } catch (e) {
      debugPrint('InAppReviewService.dismissReviewBanner error: $e');
    }
  }

  /// Removes all persisted review-related keys from SharedPreferences.
  /// For use in tests only.
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstLaunchTimestampKey);
    await prefs.remove(_reviewRequestedKey);
    await prefs.remove(_reviewBannerDismissedKey);
  }

  /// Attempts to show the in-app review dialog.  If the API is unavailable
  /// (unsupported platform, Play Store quota exhausted, or no foreground
  /// activity), falls back to [openStoreListing].
  static Future<void> forceRequestReview() async {
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        try {
          await inAppReview.requestReview();
          debugPrint('InAppReviewService: review force-requested');
          return;
        } catch (e) {
          debugPrint(
            'InAppReviewService: in-app review failed ($e), '
            'opening store listing',
          );
        }
      } else {
        debugPrint(
          'InAppReviewService: in-app review not available, '
          'opening store listing',
        );
      }
      await openStoreListing();
    } catch (e) {
      debugPrint('InAppReviewService.forceRequestReview error: $e');
    }
  }

  /// Opens the Google Play Store listing for this app via [url_launcher].
  ///
  /// Always uses the production package URL so that debug builds (which have a
  /// `.dev` suffix in their package name) still open the correct store page.
  ///
  /// No-ops on web and iOS (the app is not yet published on iOS).
  static Future<void> openStoreListing() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;
    try {
      final uri = Uri.parse(googlePlayStoreUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('InAppReviewService: store listing opened');
    } catch (e) {
      debugPrint('InAppReviewService.openStoreListing error: $e');
    }
  }
}
