import 'package:fish_ai/widgets/fish_card.dart';
import 'package:fish_ai/models/fish.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Helper to create a mock fish
  Fish createMockFish() {
    return Fish(
      name: 'Test Fish',
      commonNames: ['Common Test Fish', 'Test Species'],
      imageURL: 'https://example.com/test-fish.jpg',
      compatible: ['Compatible Fish 1', 'Compatible Fish 2'],
      notRecommended: ['Not Recommended Fish'],
      notCompatible: ['Incompatible Fish'],
      withCaution: ['Caution Fish'],
    );
  }

  testWidgets('FishCard displays fish information correctly', (WidgetTester tester) async {
    final mockFish = createMockFish();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FishCard(fish: mockFish, isSelected: false, category: 'freshwater'),
          ),
        ),
      ),
    );

    // Verify fish name is displayed
    expect(find.text('Test Fish'), findsOneWidget);
    
    // Verify common names are displayed
    expect(find.text('Common Test Fish, Test Species'), findsOneWidget);
  });

  testWidgets('FishCard handles fish with no common names', (WidgetTester tester) async {
    final fishWithoutCommonNames = Fish(
      name: 'Rare Fish',
      commonNames: [],
      imageURL: 'https://example.com/rare-fish.jpg',
      compatible: [],
      notRecommended: [],
      notCompatible: [],
      withCaution: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FishCard(fish: fishWithoutCommonNames, isSelected: false, category: 'marine'),
          ),
        ),
      ),
    );

    // Verify fish name is displayed
    expect(find.text('Rare Fish'), findsOneWidget);
    
    // Should handle empty compatibility lists gracefully
  });

  testWidgets('FishCard displays image when available', (WidgetTester tester) async {
    final mockFish = createMockFish();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FishCard(fish: mockFish, isSelected: false, category: 'freshwater'),
          ),
        ),
      ),
    );

    // Should display an image widget (actual loading depends on network)
    expect(find.byType(Image), findsAtLeastNWidgets(1));
  });

  testWidgets('FishCard handles missing compatibility data', (WidgetTester tester) async {
    final minimalFish = Fish(
      name: 'Minimal Fish',
      commonNames: ['Simple Fish'],
      imageURL: '',
      compatible: [],
      notRecommended: [],
      notCompatible: [],
      withCaution: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FishCard(fish: minimalFish, isSelected: false, category: 'freshwater'),
          ),
        ),
      ),
    );

    // Verify fish name is displayed
    expect(find.text('Minimal Fish'), findsOneWidget);
    
    // Should handle empty compatibility lists without errors
  });
}
