import 'package:fish_ai/services/device_id_service.dart';
import 'package:fish_ai/utils/dev_rate_limiter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DevRateLimiter', () {
    setUp(() {
      // Use a fixed device ID and clear SharedPreferences before each test.
      DeviceIdService.setDeviceIdForTesting('test-device-abc');
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      DeviceIdService.resetForTesting();
    });

    // -----------------------------------------------------------------------
    // Per-minute limit
    // -----------------------------------------------------------------------

    test('allows up to maxRequestsPerMinute requests', () async {
      // The in-app default is 4 requests per minute.
      expect(
        await DevRateLimiter.checkAndRecordRequest(),
        DevRateLimitResult.allowed,
        reason: 'request 1 should be allowed',
      );
      expect(
        await DevRateLimiter.checkAndRecordRequest(),
        DevRateLimitResult.allowed,
        reason: 'request 2 should be allowed',
      );
      expect(
        await DevRateLimiter.checkAndRecordRequest(),
        DevRateLimitResult.allowed,
        reason: 'request 3 should be allowed',
      );
      expect(
        await DevRateLimiter.checkAndRecordRequest(),
        DevRateLimitResult.allowed,
        reason: 'request 4 should be allowed',
      );
    });

    test('blocks the request after the per-minute limit is reached', () async {
      // Exhaust the default 4-per-minute allowance.
      for (var i = 0; i < 4; i++) {
        await DevRateLimiter.checkAndRecordRequest();
      }

      // The 5th request within the same minute must be blocked.
      final result = await DevRateLimiter.checkAndRecordRequest();
      expect(result, DevRateLimitResult.minuteLimitReached);
    });

    test('blocked request is not recorded as a used slot', () async {
      // Exhaust the limit.
      for (var i = 0; i < 4; i++) {
        await DevRateLimiter.checkAndRecordRequest();
      }
      // This call is rate-limited and must NOT be recorded.
      await DevRateLimiter.checkAndRecordRequest();

      // The stored timestamps should still only contain 4 entries.
      final remaining = await DevRateLimiter.remainingRequestsToday();
      // 50 - 4 = 46 remaining daily slots (the 5th blocked call was not counted).
      expect(remaining, equals(46));
    });

    test('secondsUntilNextSlot returns > 0 when limit is reached', () async {
      for (var i = 0; i < 4; i++) {
        await DevRateLimiter.checkAndRecordRequest();
      }

      final secs = await DevRateLimiter.secondsUntilNextSlot();
      expect(secs, greaterThan(0));
    });

    test('secondsUntilNextSlot returns 0 when a slot is available', () async {
      // Only 3 requests — one slot still free.
      for (var i = 0; i < 3; i++) {
        await DevRateLimiter.checkAndRecordRequest();
      }

      final secs = await DevRateLimiter.secondsUntilNextSlot();
      expect(secs, equals(0));
    });

    // -----------------------------------------------------------------------
    // Per-day limit
    // -----------------------------------------------------------------------

    test('daily remaining decrements with each allowed request', () async {
      expect(await DevRateLimiter.remainingRequestsToday(), equals(50));

      await DevRateLimiter.checkAndRecordRequest();
      expect(await DevRateLimiter.remainingRequestsToday(), equals(49));

      await DevRateLimiter.checkAndRecordRequest();
      expect(await DevRateLimiter.remainingRequestsToday(), equals(48));
    });

    // -----------------------------------------------------------------------
    // Undo helpers
    // -----------------------------------------------------------------------

    test('undoLastRequest refunds the most-recent per-minute slot', () async {
      await DevRateLimiter.checkAndRecordRequest(); // count = 1
      await DevRateLimiter.undoLastRequest(); // count = 0

      // After undo the slot should be available again and the next request allowed.
      final result = await DevRateLimiter.checkAndRecordRequest();
      expect(result, DevRateLimitResult.allowed);
    });

    test('undoLastRequest decrements the daily counter', () async {
      await DevRateLimiter.checkAndRecordRequest();
      expect(await DevRateLimiter.remainingRequestsToday(), equals(49));

      await DevRateLimiter.undoLastRequest();
      expect(await DevRateLimiter.remainingRequestsToday(), equals(50));
    });

    // -----------------------------------------------------------------------
    // Photo analysis limit
    // -----------------------------------------------------------------------

    test('checkAndRecordPhotoAnalysis allows up to the daily photo limit', () async {
      // Default limit is 3 photo analyses per day.
      expect(await DevRateLimiter.checkAndRecordPhotoAnalysis(), isTrue,
          reason: 'photo 1 should be allowed');
      expect(await DevRateLimiter.checkAndRecordPhotoAnalysis(), isTrue,
          reason: 'photo 2 should be allowed');
      expect(await DevRateLimiter.checkAndRecordPhotoAnalysis(), isTrue,
          reason: 'photo 3 should be allowed');
    });

    test('checkAndRecordPhotoAnalysis blocks once the daily limit is reached', () async {
      for (var i = 0; i < 3; i++) {
        await DevRateLimiter.checkAndRecordPhotoAnalysis();
      }
      expect(await DevRateLimiter.checkAndRecordPhotoAnalysis(), isFalse);
    });

    test('remainingPhotoAnalysesToday decrements with each allowed photo', () async {
      expect(await DevRateLimiter.remainingPhotoAnalysesToday(), equals(3));
      await DevRateLimiter.checkAndRecordPhotoAnalysis();
      expect(await DevRateLimiter.remainingPhotoAnalysesToday(), equals(2));
    });

    test('undoPhotoAnalysis refunds one photo slot', () async {
      await DevRateLimiter.checkAndRecordPhotoAnalysis();
      expect(await DevRateLimiter.remainingPhotoAnalysesToday(), equals(2));

      await DevRateLimiter.undoPhotoAnalysis();
      expect(await DevRateLimiter.remainingPhotoAnalysesToday(), equals(3));
    });
  });
}
