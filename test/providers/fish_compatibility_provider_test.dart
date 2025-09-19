import 'package:fish_ai/providers/fish_compatibility_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('FishCompatibilityProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('fish data loads properly without race condition', (WidgetTester tester) async {
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

      // Create provider and wait for initial load
      final notifier = container.read(fishCompatibilityProvider.notifier);
      
      // Initially should be loading
      var state = container.read(fishCompatibilityProvider);
      expect(state.fishData.isLoading, isTrue);

      // Wait for data to load using the new waitForFishData method
      await notifier.waitForFishData();
      
      // Check that data is loaded
      state = container.read(fishCompatibilityProvider);
      
      // Should no longer be loading and should have data
      expect(state.fishData.isLoading, isFalse);
      expect(state.fishData.hasValue, isTrue);
      
      final fishData = state.fishData.value!;
      expect(fishData.containsKey('freshwater'), isTrue);
      expect(fishData.containsKey('marine'), isTrue);
      expect(fishData['freshwater']!.length, equals(1));
      expect(fishData['marine']!.length, equals(1));
    });
  });
}