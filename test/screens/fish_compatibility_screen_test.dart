import 'package:fish_ai/screens/fish_compatibility_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('FishCompatibilityScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: FishCompatibilityScreen())));

    // Verify that the 'AI Fish Compatibility' title is displayed.
    expect(find.text('AI Fish Compatibility'), findsOneWidget);
  });
}