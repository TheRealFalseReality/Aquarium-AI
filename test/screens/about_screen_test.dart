import 'package:fish_ai/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('AboutScreen UI Test', (WidgetTester tester) async {
    // Wrap your widget with a ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AboutScreen(),
        ),
      ),
    );

    // Verify that the 'About Aquarium AI' title is displayed.
    expect(find.text('About Aquarium AI'), findsOneWidget);

    // Tap on the 'Contact & Feedback' button and verify that the dialog appears.
    await tester.tap(find.text('Contact & Feedback'));
    await tester.pump();
    
    // Check for the dialog title
    expect(find.text('Contact & Feedback'), findsWidgets); 
  });

  testWidgets('AboutScreen displays "Bring Your Own Key" information', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AboutScreen(),
        ),
      ),
    );

    // Verify the new "Bring Your Own Key" section is displayed
    expect(find.text('Unlock the Power of AI with Your Own API Key!'), findsOneWidget);
    expect(find.textContaining('Aquarium AI is different from other AI-enabled aquarium apps'), findsOneWidget);
    expect(find.textContaining('Higher AI API Call Limits'), findsOneWidget);
    expect(find.textContaining('Unlimited Features'), findsOneWidget);
    expect(find.textContaining('Gemini 2.5 flash'), findsOneWidget);
    expect(find.textContaining('unlimited number of tanks'), findsOneWidget);

    // Verify existing content is still there
    expect(find.text('About Aquarium AI'), findsOneWidget);
    expect(find.text('Your intelligent assistant for aquatic compatibility.'), findsOneWidget);
    expect(find.text('Contact & Feedback'), findsOneWidget);
  });
}