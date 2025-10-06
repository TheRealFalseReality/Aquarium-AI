import 'package:fish_ai/widgets/stocking_recommendation_options_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StockingRecommendationOptionsDialog displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StockingRecommendationOptionsDialog(),
        ),
      ),
    );

    // Verify the title is displayed
    expect(find.text('AI Stocking Recommendation Options'), findsOneWidget);

    // Verify the description is displayed
    expect(find.textContaining('Configure how the AI analyzes your tank'), findsOneWidget);

    // Verify the checkbox for custom names is present
    expect(find.text('Include Custom Names'), findsOneWidget);

    // Verify the additional notes field is present
    expect(find.text('Additional Notes (Optional)'), findsOneWidget);

    // Verify the buttons are present
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Get Recommendations'), findsOneWidget);
  });

  testWidgets('Checkbox toggles custom names option', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StockingRecommendationOptionsDialog(),
        ),
      ),
    );

    // Find the checkbox
    final checkbox = find.byType(Checkbox);
    expect(checkbox, findsOneWidget);

    // Initially, checkbox should be unchecked
    Checkbox checkboxWidget = tester.widget(checkbox);
    expect(checkboxWidget.value, isFalse);

    // Tap the checkbox to toggle it
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Now checkbox should be checked
    checkboxWidget = tester.widget(checkbox);
    expect(checkboxWidget.value, isTrue);

    // Verify the description changed
    expect(find.textContaining('The AI will consider both the database fish names AND your custom names'), findsOneWidget);
  });

  testWidgets('Additional notes field accepts text input', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StockingRecommendationOptionsDialog(),
        ),
      ),
    );

    // Find the text field
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Enter text
    await tester.enterText(textField, 'I want colorful fish');
    await tester.pumpAndSettle();

    // Verify text was entered
    expect(find.text('I want colorful fish'), findsOneWidget);
  });

  testWidgets('Cancel button closes dialog without returning options', (WidgetTester tester) async {
    StockingRecommendationOptions? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<StockingRecommendationOptions>(
                  context: context,
                  builder: (context) => const StockingRecommendationOptionsDialog(),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap cancel button
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Result should be null
    expect(result, isNull);
  });

  testWidgets('Get Recommendations button returns correct options', (WidgetTester tester) async {
    StockingRecommendationOptions? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<StockingRecommendationOptions>(
                  context: context,
                  builder: (context) => const StockingRecommendationOptionsDialog(),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Toggle the checkbox
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Enter additional notes
    await tester.enterText(find.byType(TextField), 'Looking for bottom dwellers');
    await tester.pumpAndSettle();

    // Tap Get Recommendations button
    await tester.tap(find.text('Get Recommendations'));
    await tester.pumpAndSettle();

    // Result should contain the correct options
    expect(result, isNotNull);
    expect(result!.includeCustomNames, isTrue);
    expect(result.additionalNotes, equals('Looking for bottom dwellers'));
  });

  testWidgets('Get Recommendations button returns default options when nothing is changed', (WidgetTester tester) async {
    StockingRecommendationOptions? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<StockingRecommendationOptions>(
                  context: context,
                  builder: (context) => const StockingRecommendationOptionsDialog(),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap Get Recommendations button without making changes
    await tester.tap(find.text('Get Recommendations'));
    await tester.pumpAndSettle();

    // Result should contain default options
    expect(result, isNotNull);
    expect(result!.includeCustomNames, isFalse);
    expect(result.additionalNotes, isEmpty);
  });
}
