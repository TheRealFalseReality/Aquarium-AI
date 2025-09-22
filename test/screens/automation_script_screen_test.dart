import 'package:fish_ai/screens/automation_script_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('AutomationScriptScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AutomationScriptScreen(),
        ),
      ),
    );

    // Verify that the screen loads with proper title and elements
    expect(find.text('AI Automation Script Generator'), findsOneWidget);
    expect(find.text('Script Generator'), findsOneWidget);
    
    // Verify description text
    expect(find.textContaining('Describe the automation you want to create'), findsOneWidget);
    expect(find.textContaining('Home Assistant or ESPHome'), findsOneWidget);

    // Verify form elements
    expect(find.text('Automation Description'), findsOneWidget);
    expect(find.text('Generate Script'), findsOneWidget);
    
    // Verify close button
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Verify text field with hint
    expect(find.textContaining('turn on a pump for 30 seconds'), findsOneWidget);
  });

  testWidgets('AutomationScriptScreen form validation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AutomationScriptScreen(),
        ),
      ),
    );

    // Try to submit empty form
    await tester.tap(find.text('Generate Script'));
    await tester.pump();
    
    // Should show validation error
    expect(find.text('Please enter a description'), findsOneWidget);
  });

  testWidgets('AutomationScriptScreen form submission', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AutomationScriptScreen(),
        ),
      ),
    );

    // Enter valid description
    await tester.enterText(
      find.byType(TextFormField),
      'Turn on aquarium lights at 8 AM and turn off at 10 PM daily'
    );

    // Submit form
    await tester.tap(find.text('Generate Script'));
    await tester.pump();
    
    // Button should show loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AutomationScriptScreen close button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AutomationScriptScreen(),
          ),
        ),
      ),
    );

    // Tap close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    
    // Should navigate back (in real app context)
  });
}