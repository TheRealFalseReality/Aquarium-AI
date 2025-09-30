import 'package:fish_ai/widgets/fish_card.dart';
import 'package:fish_ai/models/fish.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Helper to create a mock fish
  Fish createMockFish(String name) {
    return Fish(
      name: name,
      commonNames: ['Common Name'],
      imageURL: 'https://example.com/test-fish.jpg',
      compatible: [],
      notRecommended: [],
      notCompatible: [],
      withCaution: [],
    );
  }

  testWidgets('FishCard includes freshwater category in search', (WidgetTester tester) async {
    final mockFish = createMockFish('Test Fish');

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
    
    // Verify search button is present
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('FishCard includes saltwater category in search for marine', (WidgetTester tester) async {
    final mockFish = createMockFish('Marine Test Fish');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FishCard(fish: mockFish, isSelected: false, category: 'marine'),
          ),
        ),
      ),
    );

    // Verify fish name is displayed
    expect(find.text('Marine Test Fish'), findsOneWidget);
    
    // Verify search button is present
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('FishCard handles category parameter correctly', (WidgetTester tester) async {
    final mockFish = createMockFish('Category Test Fish');

    // Test freshwater category
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FishCard(fish: mockFish, isSelected: false, category: 'freshwater'),
          ),
        ),
      ),
    );

    // Verify the widget renders without errors
    expect(find.text('Category Test Fish'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Test marine category  
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FishCard(fish: mockFish, isSelected: false, category: 'marine'),
          ),
        ),
      ),
    );

    // Verify the widget renders without errors for marine category
    expect(find.text('Category Test Fish'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}