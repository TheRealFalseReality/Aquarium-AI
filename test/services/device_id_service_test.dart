import 'package:fish_ai/services/device_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DeviceIdService', () {
    setUp(() {
      // Reset in-memory cache and SharedPreferences mock before each test.
      DeviceIdService.resetForTesting();
      SharedPreferences.setMockInitialValues({});
    });

    test('getDeviceId returns a non-empty string', () async {
      final id = await DeviceIdService.getDeviceId();
      expect(id, isNotEmpty);
    });

    test('getDeviceId returns the same ID on subsequent calls (caching)', () async {
      final id1 = await DeviceIdService.getDeviceId();
      final id2 = await DeviceIdService.getDeviceId();
      expect(id1, equals(id2));
    });

    test('getDeviceId persists the UUID in SharedPreferences', () async {
      final id = await DeviceIdService.getDeviceId();

      // Reset in-memory cache to force a fresh resolution from SharedPreferences.
      DeviceIdService.resetForTesting();

      final id2 = await DeviceIdService.getDeviceId();
      expect(id2, equals(id));
    });

    test('getDeviceId generates a new UUID when SharedPreferences is empty', () async {
      final id = await DeviceIdService.getDeviceId();
      // UUID v4 format: 8-4-4-4-12 hex characters separated by hyphens.
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(id), isTrue,
          reason: 'Expected a UUID v4, got: $id');
    });

    test('different SharedPreferences instances return same persisted UUID', () async {
      final id1 = await DeviceIdService.getDeviceId();

      DeviceIdService.resetForTesting();
      // SharedPreferences mock retains values across getInstance() calls in tests.
      final id2 = await DeviceIdService.getDeviceId();

      expect(id2, equals(id1));
    });

    test('setDeviceIdForTesting overrides the cached ID', () async {
      const testId = 'test-device-id-12345';
      DeviceIdService.setDeviceIdForTesting(testId);

      final id = await DeviceIdService.getDeviceId();
      expect(id, equals(testId));
    });

    test('resetForTesting clears the cached ID so a new one is resolved', () async {
      const testId = 'test-device-id-abc';
      DeviceIdService.setDeviceIdForTesting(testId);
      expect(await DeviceIdService.getDeviceId(), equals(testId));

      DeviceIdService.resetForTesting();
      // Now it should resolve a fresh UUID (not the test ID).
      final newId = await DeviceIdService.getDeviceId();
      expect(newId, isNot(equals(testId)));
    });
  });
}
