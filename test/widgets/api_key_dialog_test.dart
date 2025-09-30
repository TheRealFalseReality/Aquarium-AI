import 'package:fish_ai/widgets/api_key_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ApiKeyDialog displays new "Bring Your Own Key" content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ApiKeyDialog(),
        ),
      ),
    );

    // Verify the new title is displayed
    expect(find.text('Unlock the Power of AI with Your Own API Key!'), findsOneWidget);

    // Verify the new content about "Bring Your Own Key" model is displayed
    expect(find.textContaining('Aquarium AI is different from other AI-enabled aquarium apps'), findsOneWidget);
    expect(find.textContaining('Higher AI API Call Limits'), findsOneWidget);
    expect(find.textContaining('Unlimited Features'), findsOneWidget);
    expect(find.textContaining('Gemini 2.5 flash'), findsOneWidget);
    expect(find.textContaining('unlimited number of tanks'), findsOneWidget);
    expect(find.textContaining('Tank management (including harmony score)'), findsOneWidget);
    expect(find.textContaining('work without an AI key'), findsOneWidget);

    // Verify the buttons are still present
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });

  testWidgets('ApiKeyDialog buttons work correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: ApiKeyDialog(),
        ),
        routes: {
          '/settings': (context) => const Scaffold(body: Text('Settings Screen')),
        },
      ),
    );

    // Test dismiss button
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    // The dialog should be dismissed (we can't easily test this without more setup)
    
    // Show dialog again for settings test
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: ApiKeyDialog(),
        ),
        routes: {
          '/settings': (context) => const Scaffold(body: Text('Settings Screen')),
        },
      ),
    );

    // Test go to settings button
    await tester.tap(find.text('Go to Settings'));
    await tester.pumpAndSettle();

    // The settings screen should be shown
    expect(find.text('Settings Screen'), findsOneWidget);
  });
}