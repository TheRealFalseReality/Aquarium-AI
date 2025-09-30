import 'package:fish_ai/screens/water_parameter_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('WaterParameterAnalysisScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WaterParameterAnalysisScreen(),
        ),
      ),
    );

    // Verify that the screen loads
    expect(find.text('Water Parameter Analysis'), findsOneWidget);
    
    // Verify form fields for water parameters
    expect(find.text('pH'), findsOneWidget);
    expect(find.text('Ammonia (ppm)'), findsOneWidget);
    expect(find.text('Nitrite (ppm)'), findsOneWidget);
    expect(find.text('Nitrate (ppm)'), findsOneWidget);
    expect(find.text('Temperature (°F)'), findsOneWidget);
    
    // Verify analyze button
    expect(find.text('Analyze Parameters'), findsOneWidget);
    
    // Verify close button
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('WaterParameterAnalysisScreen form validation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WaterParameterAnalysisScreen(),
        ),
      ),
    );

    // Try to submit empty form
    await tester.tap(find.text('Analyze Parameters'));
    await tester.pump();
    
    // Should show validation errors for required fields
    expect(find.text('Please enter pH value'), findsOneWidget);
    expect(find.text('Please enter ammonia level'), findsOneWidget);
  });

  testWidgets('WaterParameterAnalysisScreen form submission', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WaterParameterAnalysisScreen(),
        ),
      ),
    );

    // Fill out form with valid values
    await tester.enterText(find.widgetWithText(TextField, 'pH').first, '7.2');
    await tester.enterText(find.widgetWithText(TextField, 'Ammonia (ppm)').first, '0.0');
    await tester.enterText(find.widgetWithText(TextField, 'Nitrite (ppm)').first, '0.0');
    await tester.enterText(find.widgetWithText(TextField, 'Nitrate (ppm)').first, '10.0');
    await tester.enterText(find.widgetWithText(TextField, 'Temperature (°F)').first, '78.0');

    // Submit form
    await tester.tap(find.text('Analyze Parameters'));
    await tester.pump();
    
    // Button should show loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('WaterParameterAnalysisScreen close functionality', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WaterParameterAnalysisScreen(),
          ),
        ),
      ),
    );

    // Tap close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    
    // Should navigate back
  });

  testWidgets('WaterParameterAnalysisScreen numeric input validation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WaterParameterAnalysisScreen(),
        ),
      ),
    );

    // Test invalid pH value
    await tester.enterText(find.widgetWithText(TextField, 'pH').first, 'invalid');
    await tester.tap(find.text('Analyze Parameters'));
    await tester.pump();
    
    // Should show validation error for invalid numeric input
    expect(find.text('Please enter a valid number'), findsOneWidget);
  });
}