import 'package:fish_ai/screens/chatbot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('ChatbotScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ChatbotScreen())));

    // Verify that the initial welcome message is displayed.
    expect(find.textContaining('Welcome to Aquarium AI!'), findsOneWidget);
    
    // Verify the main interface elements are present
    expect(find.byType(TextField), findsOneWidget); // Message input field
  });

  testWidgets('ChatbotScreen suggestion menu test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ChatbotScreen())));

    // Tap on the 'Aquarium Questions' button and verify that the suggestion chips appear.
    await tester.tap(find.byTooltip('Aquarium Questions'));
    await tester.pump();
    expect(find.text('How do I cycle my aquarium?'), findsOneWidget);
    expect(find.text('What are the best beginner fish?'), findsOneWidget);
    expect(find.text('How often should I change water?'), findsOneWidget);
  });

  testWidgets('ChatbotScreen AI Tools menu test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ChatbotScreen())));

    // Tap on the 'AI Tools' button
    await tester.tap(find.byTooltip('AI Tools'));
    await tester.pump();
    
    // Should show AI tools options
    expect(find.text('Water Parameter Analysis'), findsOneWidget);
    expect(find.text('Photo Analyzer'), findsOneWidget);
    expect(find.text('Automation Scripts'), findsOneWidget);
  });

  testWidgets('ChatbotScreen message input test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ChatbotScreen())));

    // Find the text input field and enter a message
    final messageField = find.byType(TextField);
    expect(messageField, findsOneWidget);
    
    await tester.enterText(messageField, 'Test message');
    expect(find.text('Test message'), findsOneWidget);
  });
}
