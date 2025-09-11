import 'package:fish_ai/screens/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A helper function to build the screen for each test
  Future<void> pumpCalculatorsScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalculatorsScreen()));
  }

  group('CalculatorsScreen', () {
    testWidgets('defaults to Salinity and calculates correctly', (WidgetTester tester) async {
      await pumpCalculatorsScreen(tester);

      // Verify that the SalinityConverter is displayed by default.
      expect(find.byType(SalinityConverter), findsOneWidget);

      // Enter values for salinity conversion
      await tester.enterText(find.widgetWithText(TextField, 'Enter value (ppt)'), '35');
      await tester.enterText(find.widgetWithText(TextField, 'Temp (°C)'), '25');
      
      // Tap the button and verify the result
      await tester.tap(find.text('Convert Salinity'));
      await tester.pump();
      expect(find.text('1.026'), findsOneWidget); // Specific Gravity
    });

    testWidgets('switches to and calculates CO₂ correctly', (WidgetTester tester) async {
      await pumpCalculatorsScreen(tester);

      // Tap on the 'CO₂' chip
      await tester.tap(find.text('CO₂'));
      await tester.pump();

      // Verify that the CarbonDioxideCalculator is displayed.
      expect(find.byType(CarbonDioxideCalculator), findsOneWidget);

      // Enter values for CO₂ calculation
      await tester.enterText(find.widgetWithText(TextField, 'Enter pH'), '7.0');
      await tester.enterText(find.widgetWithText(TextField, 'Enter dKH'), '8');

      // Tap the button and verify the result
      await tester.tap(find.text('Calculate CO₂ (ppm)'));
      await tester.pump();
      expect(find.text('24.08 ppm'), findsOneWidget);
    });

    testWidgets('switches to and calculates Alkalinity correctly', (WidgetTester tester) async {
      await pumpCalculatorsScreen(tester);

      // Tap on the 'Alkalinity' chip
      await tester.tap(find.text('Alkalinity'));
      await tester.pump();

      // Verify that the AlkalinityConverter is displayed.
      expect(find.byType(AlkalinityConverter), findsOneWidget);

      // Enter a value for Alkalinity conversion
      await tester.enterText(find.widgetWithText(TextField, 'Enter value in dKH'), '8');
      
      // Tap the button and verify the results
      await tester.tap(find.text('Convert Alkalinity'));
      await tester.pump();
      expect(find.text('142.86'), findsOneWidget); // ppm
      expect(find.text('2.86'), findsOneWidget); // meq/L
    });

    testWidgets('switches to and calculates Temperature correctly', (WidgetTester tester) async {
      await pumpCalculatorsScreen(tester);

      // Tap on the 'Temperature' chip
      await tester.tap(find.text('Temperature'));
      await tester.pump();

      // Verify that the TemperatureConverter is displayed.
      expect(find.byType(TemperatureConverter), findsOneWidget);

      // Enter a value for Temperature conversion
      await tester.enterText(find.widgetWithText(TextField, 'Enter temp in °F'), '77');
      
      // Tap the button and verify the results
      await tester.tap(find.text('Convert Temperature'));
      await tester.pump();
      expect(find.text('25.00 °C'), findsOneWidget); // Celsius
      expect(find.text('298.15 K'), findsOneWidget); // Kelvin
    });
  });
}