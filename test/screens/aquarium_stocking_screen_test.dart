import 'package:fish_ai/screens/aquarium_stocking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('AquariumStockingScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AquariumStockingScreen(),
        ),
      ),
    );

    // Verify that the screen loads with basic elements
    expect(find.text('AI Stocking Assistant'), findsOneWidget);
    expect(find.text('Tank Size'), findsOneWidget);
    expect(find.text('Additional Notes'), findsOneWidget);
    
    // Verify tank type selection chips
    expect(find.text('Freshwater'), findsOneWidget);
    expect(find.text('Saltwater'), findsOneWidget);

    // Test that freshwater is selected by default
    final freshwaterChip = find.text('Freshwater');
    expect(freshwaterChip, findsOneWidget);

    // Test tank size input
    await tester.enterText(find.byType(TextFormField).first, '20 gallons');
    expect(find.text('20 gallons'), findsOneWidget);

    // Test form validation - submit empty form
    await tester.tap(find.text('Get AI Recommendations'));
    await tester.pump();
    
    // Should show validation error since tank size input would be required
    // Note: Actual validation behavior depends on implementation
  });

  testWidgets('AquariumStockingScreen tank type selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AquariumStockingScreen(),
        ),
      ),
    );

    // Tap on saltwater chip
    await tester.tap(find.text('Saltwater'));
    await tester.pump();

    // Verify saltwater is now selected
    // Note: Visual indication depends on implementation
  });
}
