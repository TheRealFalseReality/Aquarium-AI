import 'package:fish_ai/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppDrawer UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(),
          body: Container(),
        ),
      ),
    );

    // Open the drawer and verify that the 'AI Chatbot' item is displayed.
    await tester.dragFrom(tester.getTopLeft(find.byType(MaterialApp)), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('AI Chatbot'), findsOneWidget);
  });
}