import 'package:fish_ai/providers/purchase_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

    test('returns false when no founder signal in release mode', () {
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
