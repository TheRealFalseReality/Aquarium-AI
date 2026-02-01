import 'package:fish_ai/widgets/aquapi_promotion_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AquaPiPromotionDialog displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AquaPiPromotionDialog(),
        ),
      ),
    );

    // Verify the title is displayed
    expect(find.text('Meet AquaPi!'), findsOneWidget);

    // Verify the main content is displayed
    expect(find.textContaining('Take your aquarium to the next level'), findsOneWidget);
    expect(find.textContaining('open-source smart'), findsOneWidget);

    // Verify feature items are displayed
    expect(find.text('Smart Monitoring'), findsOneWidget);
    expect(find.textContaining('Real-time monitoring of temperature'), findsOneWidget);
    
    expect(find.text('Home Assistant Integration'), findsOneWidget);
    expect(find.textContaining('Seamlessly integrates with your smart home'), findsOneWidget);
    
    expect(find.text('Fully Customizable'), findsOneWidget);
    expect(find.textContaining('Open-source design lets you add'), findsOneWidget);
    
    expect(find.text('Automated Alerts'), findsOneWidget);
    expect(find.textContaining('Get notified instantly about critical changes'), findsOneWidget);

    // Verify the highlight box
    expect(find.textContaining('Perfect for DIY enthusiasts'), findsOneWidget);

    // Verify the buttons are present
    expect(find.text('Maybe Later'), findsOneWidget);
    expect(find.text('Never Show Again'), findsOneWidget);
    expect(find.text('Learn More'), findsOneWidget);
  });

  testWidgets('AquaPiPromotionDialog Maybe Later button works', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AquaPiPromotionDialog(),
        ),
      ),
    );

    // Test dismiss button
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.byType(AquaPiPromotionDialog), findsNothing);
  });

  test('shouldShowDialog returns true when preference is not set', () async {
    final shouldShow = await AquaPiPromotionDialog.shouldShowDialog();
    expect(shouldShow, isTrue);
  });

  test('shouldShowDialog returns false after setNeverShowAgain', () async {
    await AquaPiPromotionDialog.setNeverShowAgain();
    final shouldShow = await AquaPiPromotionDialog.shouldShowDialog();
    expect(shouldShow, isFalse);
  });

  testWidgets('Never Show Again button sets preference', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AquaPiPromotionDialog(),
        ),
      ),
    );

    // Verify preference is not set initially
    bool shouldShow = await AquaPiPromotionDialog.shouldShowDialog();
    expect(shouldShow, isTrue);

    // Tap Never Show Again button
    await tester.tap(find.text('Never Show Again'));
    await tester.pumpAndSettle();

    // Verify preference is now set
    shouldShow = await AquaPiPromotionDialog.shouldShowDialog();
    expect(shouldShow, isFalse);

    // Dialog should be dismissed
    expect(find.byType(AquaPiPromotionDialog), findsNothing);
  });

  testWidgets('AquaPiPromotionDialog has correct icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AquaPiPromotionDialog(),
        ),
      ),
    );

    // Verify the settings_input_component icon is displayed
    expect(find.byIcon(Icons.settings_input_component), findsOneWidget);
    
    // Verify feature icons are displayed
    expect(find.byIcon(Icons.hub), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}

