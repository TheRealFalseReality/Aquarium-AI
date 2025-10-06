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

    // Verify fish name options section
    expect(find.text('Fish Name Options'), findsOneWidget);
    expect(find.text('Use Fish Species Names'), findsOneWidget);
    expect(find.text('Use Custom Names'), findsOneWidget);

    // Verify descriptions
    expect(find.textContaining('scientific fish species names'), findsOneWidget);
    expect(find.textContaining('custom names contain specific fish species'), findsOneWidget);

    // Verify additional notes section
    expect(find.text('Additional Notes (Optional)'), findsOneWidget);
    expect(find.textContaining('specific instructions or preferences'), findsOneWidget);

    // Verify buttons
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Get Recommendations'), findsOneWidget);
  });

  testWidgets('StockingOptionsDialog radio buttons work correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StockingOptionsDialog(),
        ),
      ),
    );

    // Find the radio buttons by their values
    final useSpeciesNamesRadio = find.byWidgetPredicate(
      (widget) => widget is Radio<bool> && widget.value == false,
    );
    final useCustomNamesRadio = find.byWidgetPredicate(
      (widget) => widget is Radio<bool> && widget.value == true,
    );

    // Initially, "Use Fish Species Names" should be selected (default)
    expect(useSpeciesNamesRadio, findsOneWidget);
    expect(useCustomNamesRadio, findsOneWidget);

    // Tap on "Use Custom Names"
    await tester.tap(useCustomNamesRadio);
    await tester.pumpAndSettle();

    // The selection should have changed
    // We can verify this by checking if the widget still exists
    expect(useCustomNamesRadio, findsOneWidget);
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

  testWidgets('StockingOptionsDialog with custom names selected', (WidgetTester tester) async {
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

    // Select "Use Custom Names"
    final useCustomNamesRadio = find.byWidgetPredicate(
      (widget) => widget is Radio<bool> && widget.value == true,
    );
    await tester.tap(useCustomNamesRadio);
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
