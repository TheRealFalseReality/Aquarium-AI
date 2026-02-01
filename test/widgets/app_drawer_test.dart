import 'package:fish_ai/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('AppDrawer UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            drawer: const AppDrawer(),
            appBar: AppBar(),
            body: Container(),
          ),
        ),
      ),
    );

    // Open the drawer and verify key navigation items are displayed
    await tester.dragFrom(tester.getTopLeft(find.byType(MaterialApp)), const Offset(300, 0));
    await tester.pumpAndSettle();
    
    // Verify main navigation items
    expect(find.text('AI Chatbot'), findsOneWidget);
    expect(find.text('My Tanks'), findsOneWidget);
    expect(find.text('AI Compatibility Tool'), findsOneWidget);
    expect(find.text('Stocking Assistant'), findsOneWidget);
    expect(find.text('Aquarium Calculators'), findsOneWidget);
    expect(find.text('Tank Volume'), findsOneWidget);
    
    // Verify appearance section
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('AppDrawer navigation tap test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          routes: {
            '/chatbot': (context) => const Scaffold(body: Text('Chatbot Screen')),
            '/tank-management': (context) => const Scaffold(body: Text('Tank Management Screen')),
          },
          home: Scaffold(
            drawer: const AppDrawer(),
            appBar: AppBar(),
            body: Container(),
          ),
        ),
      ),
    );

    // Open the drawer
    await tester.dragFrom(tester.getTopLeft(find.byType(MaterialApp)), const Offset(300, 0));
    await tester.pumpAndSettle();
    
    // Tap on AI Chatbot
    await tester.tap(find.text('AI Chatbot'));
    await tester.pumpAndSettle();
    
    // Should navigate to chatbot screen
    expect(find.text('Chatbot Screen'), findsOneWidget);
  });

  testWidgets('AppDrawer appearance expansion test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            drawer: const AppDrawer(),
            appBar: AppBar(),
            body: Container(),
          ),
        ),
      ),
    );

    // Open the drawer
    await tester.dragFrom(tester.getTopLeft(find.byType(MaterialApp)), const Offset(300, 0));
    await tester.pumpAndSettle();
    
    // Tap on Appearance to expand
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    
    // Should show theme options
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}
