import 'package:fish_ai/widgets/stocking_options_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StockingOptionsDialog displays all elements correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StockingOptionsDialog(),
        ),
      ),
    );

    // Verify the title is displayed
    expect(find.text('AI Stocking Recommendations'), findsOneWidget);

    // Verify custom names checkbox
    expect(find.text('Include Custom Names'), findsOneWidget);

    // Verify description
    expect(find.textContaining('Fish types are always included'), findsOneWidget);
    expect(find.textContaining('better species-specific results'), findsOneWidget);

    // Verify additional notes section
    expect(find.text('Additional Notes (Optional)'), findsOneWidget);
    expect(find.textContaining('specific instructions or preferences'), findsOneWidget);

    // Verify buttons
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Get Recommendations'), findsOneWidget);
  });

  testWidgets('StockingOptionsDialog checkbox works correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StockingOptionsDialog(),
        ),
      ),
    );

    // Find the checkbox
    final checkbox = find.byType(Checkbox);

    // Initially, checkbox should be unchecked (default)
    expect(checkbox, findsOneWidget);
    
    // Get the checkbox widget to verify its state
    final checkboxWidget = tester.widget<Checkbox>(checkbox);
    expect(checkboxWidget.value, isFalse);

    // Tap on the checkbox
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // The checkbox should now be checked
    final updatedCheckboxWidget = tester.widget<Checkbox>(checkbox);
    expect(updatedCheckboxWidget.value, isTrue);
  });

  testWidgets('StockingOptionsDialog returns correct data when confirmed', (WidgetTester tester) async {
    Map<String, dynamic>? result;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const StockingOptionsDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Enter some text in the notes field
    await tester.enterText(find.byType(TextField), 'Looking for colorful fish');
    await tester.pumpAndSettle();

    // Tap the "Get Recommendations" button
    await tester.tap(find.text('Get Recommendations'));
    await tester.pumpAndSettle();

    // Verify the result
    expect(result, isNotNull);
    expect(result?['useCustomNames'], isFalse); // Default is false
    expect(result?['additionalNotes'], 'Looking for colorful fish');
  });

  testWidgets('StockingOptionsDialog returns null when cancelled', (WidgetTester tester) async {
    Map<String, dynamic>? result;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const StockingOptionsDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap the "Cancel" button
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify the result is null
    expect(result, isNull);
  });

  testWidgets('StockingOptionsDialog with custom names checked', (WidgetTester tester) async {
    Map<String, dynamic>? result;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const StockingOptionsDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Show the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Check the checkbox
    final checkbox = find.byType(Checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Tap the "Get Recommendations" button
    await tester.tap(find.text('Get Recommendations'));
    await tester.pumpAndSettle();

    // Verify the result
    expect(result, isNotNull);
    expect(result?['useCustomNames'], isTrue);
    expect(result?['additionalNotes'], ''); // Empty by default
  });
}
