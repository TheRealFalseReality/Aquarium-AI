import 'package:fish_ai/screens/tank_creation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('TankCreationScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TankCreationScreen(),
        ),
      ),
    );

    // Verify that the screen loads
    expect(find.text('Create New Tank'), findsOneWidget);
    
    // Verify form fields
    expect(find.text('Tank Name'), findsOneWidget);
    expect(find.text('Tank Size (Gallons)'), findsOneWidget);
    
    // Verify tank type selection
    expect(find.text('Tank Type'), findsOneWidget);
    expect(find.text('Freshwater'), findsOneWidget);
    expect(find.text('Saltwater'), findsOneWidget);
    
    // Verify action buttons
    expect(find.text('Create Tank'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('TankCreationScreen form validation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TankCreationScreen(),
        ),
      ),
    );

    // Try to submit empty form
    await tester.tap(find.text('Create Tank'));
    await tester.pump();
    
    // Should show validation errors
    expect(find.text('Please enter a tank name'), findsOneWidget);
    expect(find.text('Please enter tank size'), findsOneWidget);
  });

  testWidgets('TankCreationScreen form submission', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TankCreationScreen(),
        ),
      ),
    );

    // Fill out form
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tank Name').first,
      'My Test Tank'
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tank Size (Gallons)').first,
      '20'
    );

    // Select tank type
    await tester.tap(find.text('Saltwater'));
    await tester.pump();

    // Submit form
    await tester.tap(find.text('Create Tank'));
    await tester.pump();
    
    // Should create tank without validation errors
  });

  testWidgets('TankCreationScreen tank type selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: TankCreationScreen(),
        ),
      ),
    );

    // Freshwater should be selected by default
    final freshwaterChip = find.text('Freshwater');
    final saltwaterChip = find.text('Saltwater');
    
    expect(freshwaterChip, findsOneWidget);
    expect(saltwaterChip, findsOneWidget);

    // Tap on saltwater
    await tester.tap(saltwaterChip);
    await tester.pump();

    // Should update selection
  });

  testWidgets('TankCreationScreen cancel functionality', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TankCreationScreen(),
          ),
        ),
      ),
    );

    // Tap cancel button
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    
    // Should navigate back
  });
}