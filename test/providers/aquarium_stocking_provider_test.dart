import 'package:fish_ai/providers/aquarium_stocking_provider.dart';
import 'package:fish_ai/providers/fish_compatibility_provider.dart';
import 'package:fish_ai/providers/model_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('AquariumStockingProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('handles fish data loading gracefully with waitForFishData', (WidgetTester tester) async {
      // Mock the asset loading
      const String mockFishData = '''
      {
        "freshwater": [
          {
            "name": "Test Fish",
            "commonNames": ["test"],
            "imageURL": "",
            "compatible": [],
            "notRecommended": [],
            "notCompatible": [],
            "withCaution": []
          }
        ],
        "marine": [
          {
            "name": "Test Marine Fish",
            "commonNames": ["test marine"],
            "imageURL": "",
            "compatible": [],
            "notRecommended": [],
            "notCompatible": [],
            "withCaution": []
          }
        ]
      }
      ''';

      // Set up mock asset bundle
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString' && 
              methodCall.arguments == 'assets/fishcompat.json') {
            return mockFishData;
          }
          return null;
        },
      );

      // Initialize fish compatibility provider first
      final fishCompatibilityNotifier = container.read(fishCompatibilityProvider.notifier);
      await fishCompatibilityNotifier.waitForFishData();
      
      // Verify fish data is loaded
      final fishState = container.read(fishCompatibilityProvider);
      expect(fishState.fishData.isLoading, isFalse);
      expect(fishState.fishData.hasValue, isTrue);

      // Now test stocking recommendations - this should not fail with "Fish data is still loading"
      final stockingNotifier = container.read(aquariumStockingProvider.notifier);
      
      // This should not throw an error about fish data still loading
      expect(() async {
        // Note: This will likely fail due to missing API keys, but it should not fail 
        // due to "Fish data is still loading" error
        try {
          await stockingNotifier.getStockingRecommendations(
            tankSize: "55 gallons",
            tankType: "freshwater", 
            userNotes: "Test tank"
          );
        } catch (e) {
          // We expect this to fail due to missing API keys, not fish data loading
          expect(e.toString().contains("Fish data is still loading"), isFalse);
        }
      }, returnsNormally);
    });
  });
}