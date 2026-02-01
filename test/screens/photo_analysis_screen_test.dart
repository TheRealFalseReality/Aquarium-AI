import 'package:fish_ai/screens/photo_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('PhotoAnalysisScreen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PhotoAnalysisScreen(),
        ),
      ),
    );

    // Verify that the screen loads
    expect(find.text('Photo Analysis'), findsOneWidget);
    
    // Verify main action buttons
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    
    // Verify description or instruction text
    expect(find.textContaining('aquarium'), findsAtLeastNWidgets(1));
  });

  testWidgets('PhotoAnalysisScreen button interactions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PhotoAnalysisScreen(),
        ),
      ),
    );

    // Test camera button tap
    await tester.tap(find.text('Camera'));
    await tester.pump();
    
    // Test gallery button tap
    await tester.tap(find.text('Gallery'));
    await tester.pump();
    
    // Should complete without errors (actual functionality depends on platform)
  });
}
