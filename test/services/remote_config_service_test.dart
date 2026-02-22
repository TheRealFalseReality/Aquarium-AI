import 'package:fish_ai/services/remote_config_service.dart';
import 'package:fish_ai/utils/dev_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteConfigService', () {
    group('defaults (no Firebase instance)', () {
      // Before any initialize() call the _instance is null, so all getters
      // must return the in-app defaults from dev_limits.dart.

      test('freeAiEnabled defaults to true', () {
        expect(RemoteConfigService.freeAiEnabled, isTrue);
      });

      test('maxRequestsPerMinute defaults to devMaxRequestsPerMinute', () {
        expect(
          RemoteConfigService.maxRequestsPerMinute,
          equals(devMaxRequestsPerMinute),
        );
      });

      test('maxRequestsPerDay defaults to devMaxRequestsPerDay', () {
        expect(
          RemoteConfigService.maxRequestsPerDay,
          equals(devMaxRequestsPerDay),
        );
      });

      test('maxPhotoAnalysesPerDay defaults to devMaxPhotoAnalysesPerDay', () {
        expect(
          RemoteConfigService.maxPhotoAnalysesPerDay,
          equals(devMaxPhotoAnalysesPerDay),
        );
      });
    });

    group('RemoteConfigKeys', () {
      test('key names match expected Remote Config parameter names', () {
        expect(RemoteConfigKeys.freeAiEnabled, equals('free_ai_enabled'));
        expect(RemoteConfigKeys.devMaxRequestsPerMinute,
            equals('dev_max_requests_per_minute'));
        expect(RemoteConfigKeys.devMaxRequestsPerDay,
            equals('dev_max_requests_per_day'));
        expect(RemoteConfigKeys.devMaxPhotoAnalysesPerDay,
            equals('dev_max_photo_analyses_per_day'));
      });
    });
  });
}
