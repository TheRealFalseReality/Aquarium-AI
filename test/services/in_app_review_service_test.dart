import 'package:fish_ai/services/in_app_review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InAppReviewService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await InAppReviewService.resetForTesting();
    });

    test('recordFirstLaunch saves a timestamp on first call', () async {
      await InAppReviewService.recordFirstLaunch();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('first_launch_timestamp'), isTrue);
      expect(prefs.getInt('first_launch_timestamp'), isNotNull);
    });

    test('recordFirstLaunch is a no-op on subsequent calls', () async {
      await InAppReviewService.recordFirstLaunch();
      final prefs = await SharedPreferences.getInstance();
      final first = prefs.getInt('first_launch_timestamp');

      // Simulate a later call
      await InAppReviewService.recordFirstLaunch();
      final second = prefs.getInt('first_launch_timestamp');

      expect(second, equals(first));
    });

    test('maybeRequestReview skips when no first launch timestamp exists',
        () async {
      // Should complete without throwing
      await expectLater(
        InAppReviewService.maybeRequestReview(),
        completes,
      );

      final prefs = await SharedPreferences.getInstance();
      // review_requested must remain unset because we returned early
      expect(prefs.getBool('in_app_review_requested'), isNull);
    });

    test(
        'maybeRequestReview skips when fewer than 3 days have elapsed since '
        'first launch', () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulate a first launch that happened 1 day ago
      final oneDayAgo = DateTime.now()
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch;
      await prefs.setInt('first_launch_timestamp', oneDayAgo);

      await InAppReviewService.maybeRequestReview();

      // review_requested must remain unset because the wait period hasn't elapsed
      expect(prefs.getBool('in_app_review_requested'), isNull);
    });

    test(
        'maybeRequestReview skips when review has already been requested',
        () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulate a first launch that happened 5 days ago
      final fiveDaysAgo = DateTime.now()
          .subtract(const Duration(days: 5))
          .millisecondsSinceEpoch;
      await prefs.setInt('first_launch_timestamp', fiveDaysAgo);
      await prefs.setBool('in_app_review_requested', true);

      // Should complete without throwing even though the plugin isn't available
      await expectLater(
        InAppReviewService.maybeRequestReview(),
        completes,
      );
    });

    test('resetForTesting clears all persisted keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'first_launch_timestamp', DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('in_app_review_requested', true);

      await InAppReviewService.resetForTesting();

      expect(prefs.containsKey('first_launch_timestamp'), isFalse);
      expect(prefs.containsKey('in_app_review_requested'), isFalse);
    });
  });
}
