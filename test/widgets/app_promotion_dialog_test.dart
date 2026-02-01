import 'package:fish_ai/widgets/app_promotion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AppPromotionDialog displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPromotionDialog(),
        ),
      ),
    );

    // Verify the title is displayed
    expect(find.text('Get Aquarium AI on Your Device!'), findsOneWidget);

    // Verify the content is displayed
    expect(find.textContaining('Experience the full power of Aquarium AI'), findsOneWidget);
    expect(find.textContaining('Offline Access'), findsOneWidget);
    expect(find.textContaining('Enhanced Camera'), findsOneWidget);
    expect(find.textContaining('Smart Notifications'), findsOneWidget);
    expect(find.textContaining('Native Performance'), findsOneWidget);

    // Verify the buttons are present
    expect(find.text('Maybe Later'), findsOneWidget);
    expect(find.text('Never Show Again'), findsOneWidget);
    expect(find.text('Get the App'), findsOneWidget);
  });

  testWidgets('AppPromotionDialog Maybe Later button works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPromotionDialog(),
        ),
      ),
    );

    // Test dismiss button
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.byType(AppPromotionDialog), findsNothing);
  });

  test('shouldShowDialog returns true when preference is not set', () async {
    final shouldShow = await AppPromotionDialog.shouldShowDialog();
    expect(shouldShow, isTrue);
  });

  test('shouldShowDialog returns false after setNeverShowAgain', () async {
    await AppPromotionDialog.setNeverShowAgain();
    final shouldShow = await AppPromotionDialog.shouldShowDialog();
    expect(shouldShow, isFalse);
  });

  testWidgets('Never Show Again button sets preference', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPromotionDialog(),
        ),
      ),
    );

    // Verify preference is not set initially
    bool shouldShow = await AppPromotionDialog.shouldShowDialog();
    expect(shouldShow, isTrue);

    // Tap Never Show Again button
    await tester.tap(find.text('Never Show Again'));
    await tester.pumpAndSettle();

    // Verify preference is now set
    shouldShow = await AppPromotionDialog.shouldShowDialog();
    expect(shouldShow, isFalse);

    // Dialog should be dismissed
    expect(find.byType(AppPromotionDialog), findsNothing);
  });
}

