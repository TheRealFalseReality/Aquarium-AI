import 'package:fish_ai/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('SettingsScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    // Verify that the settings screen loads
    expect(find.text('Settings'), findsOneWidget);
    
    // Verify AI Provider section
    expect(find.text('AI Provider'), findsOneWidget);
    expect(find.text('Gemini'), findsOneWidget);
    expect(find.text('ChatGPT'), findsOneWidget);
    expect(find.text('Groq'), findsOneWidget);

    // Verify API Key sections
    expect(find.text('Gemini API Key'), findsOneWidget);
    expect(find.text('OpenAI API Key'), findsOneWidget);
    expect(find.text('Groq API Key'), findsOneWidget);

    // Verify model configuration sections
    expect(find.text('Gemini Models'), findsOneWidget);
    expect(find.text('ChatGPT Models'), findsOneWidget);
    expect(find.text('Groq Models'), findsOneWidget);
  });

  testWidgets('SettingsScreen AI provider selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    // Test switching between AI providers
    await tester.tap(find.text('ChatGPT'));
    await tester.pump();

    await tester.tap(find.text('Groq'));
    await tester.pump();

    // Should be able to switch without errors
  });

  testWidgets('SettingsScreen API key visibility toggle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    // Find and tap visibility toggles for API keys
    final visibilityButtons = find.byIcon(Icons.visibility);
    if (visibilityButtons.evaluate().isNotEmpty) {
      await tester.tap(visibilityButtons.first);
      await tester.pump();
      
      // Should toggle to visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    }
  });

  testWidgets('SettingsScreen save functionality', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    // Find save button and tap it
    final saveButton = find.text('Save Settings');
    if (saveButton.evaluate().isNotEmpty) {
      await tester.tap(saveButton);
      await tester.pump();
      
      // Should complete without error
    }
  });
}