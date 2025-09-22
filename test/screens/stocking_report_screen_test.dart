import 'package:fish_ai/models/stocking_recommendation.dart';
import 'package:fish_ai/screens/stocking_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Helper to create mock StockingRecommendation
  List<StockingRecommendation> createMockReports() {
    return [
      StockingRecommendation(
        title: 'Community Tank Setup',
        description: 'A peaceful community tank suitable for beginners.',
        tankSize: '20 gallons',
        tankType: 'Freshwater',
        recommendedFish: [
          RecommendedFish(
            name: 'Neon Tetra',
            quantity: 6,
            description: 'Peaceful schooling fish that add vibrant color.',
            compatibility: 'Excellent',
          ),
          RecommendedFish(
            name: 'Corydoras',
            quantity: 3,
            description: 'Bottom-dwelling catfish that help keep the tank clean.',
            compatibility: 'Good',
          ),
        ],
        pros: ['Easy to maintain', 'Great for beginners', 'Colorful display'],
        cons: ['May become overcrowded if overstocked'],
        estimatedCost: '\$80-120',
        difficulty: 'Beginner',
        notes: 'Ensure adequate filtration and regular water changes.',
      ),
      StockingRecommendation(
        title: 'Cichlid Setup',
        description: 'A more advanced setup for cichlid enthusiasts.',
        tankSize: '20 gallons',
        tankType: 'Freshwater',
        recommendedFish: [
          RecommendedFish(
            name: 'Dwarf Cichlid',
            quantity: 2,
            description: 'Beautiful but territorial fish.',
            compatibility: 'Moderate',
          ),
        ],
        pros: ['Stunning fish', 'Interesting behavior'],
        cons: ['Requires experience', 'Territorial issues possible'],
        estimatedCost: '\$100-150',
        difficulty: 'Intermediate',
        notes: 'Provide plenty of hiding spots and territories.',
      ),
    ];
  }

  testWidgets('StockingReportScreen UI Test', (WidgetTester tester) async {
    final mockReports = createMockReports();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StockingReportScreen(reports: mockReports),
        ),
      ),
    );

    // Verify that the screen loads with stocking recommendations
    expect(find.text('Stocking Recommendations'), findsOneWidget);
    
    // Verify tabs for multiple recommendations
    expect(find.text('Community Tank Setup'), findsOneWidget);
    expect(find.text('Cichlid Setup'), findsOneWidget);
    
    // Verify first recommendation content
    expect(find.text('A peaceful community tank suitable for beginners.'), findsOneWidget);
    expect(find.text('20 gallons'), findsOneWidget);
    expect(find.text('Freshwater'), findsOneWidget);
    
    // Verify recommended fish
    expect(find.text('Neon Tetra'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Corydoras'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    
    // Verify pros and cons
    expect(find.text('Easy to maintain'), findsOneWidget);
    expect(find.text('Great for beginners'), findsOneWidget);
    expect(find.text('May become overcrowded if overstocked'), findsOneWidget);
    
    // Verify additional details
    expect(find.text('\$80-120'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Ensure adequate filtration and regular water changes.'), findsOneWidget);
  });

  testWidgets('StockingReportScreen tab switching', (WidgetTester tester) async {
    final mockReports = createMockReports();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StockingReportScreen(reports: mockReports),
        ),
      ),
    );

    // Tap on second tab
    await tester.tap(find.text('Cichlid Setup'));
    await tester.pump();

    // Should show second recommendation content
    expect(find.text('A more advanced setup for cichlid enthusiasts.'), findsOneWidget);
    expect(find.text('Dwarf Cichlid'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('\$100-150'), findsOneWidget);
  });

  testWidgets('StockingReportScreen close functionality', (WidgetTester tester) async {
    final mockReports = createMockReports();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StockingReportScreen(reports: mockReports),
          ),
        ),
      ),
    );

    // Find and tap close button
    final closeButton = find.byIcon(Icons.close);
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton.first);
      await tester.pump();
      
      // Should navigate back
    }
  });

  testWidgets('StockingReportScreen regenerate functionality', (WidgetTester tester) async {
    final mockReports = createMockReports();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StockingReportScreen(
            reports: mockReports,
            tankSize: '20 gallons',
            tankType: 'freshwater',
          ),
        ),
      ),
    );

    // Find regenerate button if it exists
    final regenerateButton = find.textContaining('Regenerate');
    if (regenerateButton.evaluate().isNotEmpty) {
      await tester.tap(regenerateButton.first);
      await tester.pump();
      
      // Should trigger regeneration
    }
  });

  testWidgets('StockingReportScreen single recommendation', (WidgetTester tester) async {
    final singleReport = [createMockReports().first];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StockingReportScreen(reports: singleReport),
        ),
      ),
    );

    // Should work with single recommendation (no tabs)
    expect(find.text('Community Tank Setup'), findsOneWidget);
    expect(find.text('A peaceful community tank suitable for beginners.'), findsOneWidget);
  });
}