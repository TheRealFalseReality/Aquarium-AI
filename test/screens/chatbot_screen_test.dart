import 'package:fish_ai/screens/chatbot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('ChatbotScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ChatbotScreen())));

    // Verify that the initial welcome message is displayed.
    expect(find.textContaining('Welcome to Fish.AI!'), findsOneWidget);

    // Tap on the 'Aquarium Questions' button and verify that the suggestion chips appear.
    await tester.tap(find.byTooltip('Aquarium Questions'));
    await tester.pump();
    expect(find.text('How do I cycle my aquarium?'), findsOneWidget);
  });
}