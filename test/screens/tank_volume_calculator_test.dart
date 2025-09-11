import 'package:fish_ai/screens/tank_volume_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TankVolumeCalculator UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TankVolumeCalculator()));

    // --- Rectangle Test ---
    await tester.enterText(find.widgetWithText(TextField, 'Length'), '20');
    await tester.enterText(find.widgetWithText(TextField, 'Width'), '10');
    await tester.enterText(find.widgetWithText(TextField, 'Height'), '12');
    await tester.tap(find.text('Calculate'));
    await tester.pump();
    expect(find.textContaining('10.39 gal'), findsOneWidget);
    expect(find.textContaining('39.33 L'), findsOneWidget);

    // --- Cube Test ---
    await tester.tap(find.text('Cube'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Side Length'), '20');
    await tester.tap(find.text('Calculate'));
    await tester.pump();
    expect(find.textContaining('34.63 gal'), findsOneWidget);
    expect(find.textContaining('131.10 L'), findsOneWidget);

    // --- Cylinder Test ---
    await tester.tap(find.text('Cylinder'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Diameter'), '15');
    await tester.enterText(find.widgetWithText(TextField, 'Height'), '12');
    await tester.tap(find.text('Calculate'));
    await tester.pump();
    expect(find.textContaining('9.20 gal'), findsOneWidget);
    expect(find.textContaining('34.83 L'), findsOneWidget);
  });
}