import 'package:fish_ai/providers/purchase_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldBackfillFounderProfile', () {
    test('returns true when local founder is true and cloud founder is false', () {
      final result = shouldBackfillFounderProfile(
        localFounder: true,
        cloudFounder: false,
      );

      expect(result, isTrue);
    });

    test('returns false when cloud founder is already true', () {
      final result = shouldBackfillFounderProfile(
        localFounder: true,
        cloudFounder: true,
      );

      expect(result, isFalse);
    });
  });

  group('computeFounderAccess', () {
    test('returns true when purchased founder in release mode', () {
      final result = computeFounderAccess(
        purchasedFounder: true,
        cloudFounder: false,
        debugForcedFounder: false,
        debugMode: false,
      );

      expect(result, isTrue);
    });

    test('returns true when cloud founder in release mode', () {
      final result = computeFounderAccess(
        purchasedFounder: false,
        cloudFounder: true,
        debugForcedFounder: false,
        debugMode: false,
      );

      expect(result, isTrue);
    });

    test('ignores debug forced flag in release mode', () {
      final result = computeFounderAccess(
        purchasedFounder: false,
        cloudFounder: false,
        debugForcedFounder: true,
        debugMode: false,
      );

      expect(result, isFalse);
    });

    test('returns true when debug forced in debug mode', () {
      final result = computeFounderAccess(
        purchasedFounder: false,
        cloudFounder: false,
        debugForcedFounder: true,
        debugMode: true,
      );

      expect(result, isTrue);
    });
  });
}
