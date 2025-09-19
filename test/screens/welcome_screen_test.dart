import 'package:fish_ai/screens/fish_compatibility_screen.dart';
import 'package:fish_ai/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('WelcomeScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          routes: {
            '/compat-ai': (context) => const FishCompatibilityScreen(),
          },
          home: const WelcomeScreen(),
        ),
      ),
    );

    // Verify that the 'Aquarium AI' title is displayed.
    expect(find.text('Aquarium AI'), findsOneWidget);

    // Tap on the 'AI Compatibility Calculator' card and verify that it navigates to the correct screen.
    await tester.tap(find.text('AI Compatibility Calculator'));
    await tester.pumpAndSettle();
    expect(find.byType(FishCompatibilityScreen), findsOneWidget);
  });
}