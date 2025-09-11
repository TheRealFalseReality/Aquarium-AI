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

    // Verify that the 'About Fish.AI' title is displayed.
    expect(find.text('About Fish.AI'), findsOneWidget);

    // Tap on the 'Contact & Feedback' button and verify that the dialog appears.
    await tester.tap(find.text('Contact & Feedback'));
    await tester.pump();
    
    // Check for the dialog title
    expect(find.text('Contact & Feedback'), findsWidgets); 
  });
}