import 'package:fish_ai/widgets/modern_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ModernChip displays text correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ModernChip(
            text: 'Test Chip',
            isSelected: false,
          ),
        ),
      ),
    );

    // Verify text is displayed
    expect(find.text('Test Chip'), findsOneWidget);
  });

  testWidgets('ModernChip handles selection state', (WidgetTester tester) async {
    bool isSelected = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ModernChip(
                text: 'Selectable Chip',
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    isSelected = !isSelected;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Selectable Chip'), findsOneWidget);

    // Tap the chip
    await tester.tap(find.text('Selectable Chip'));
    await tester.pump();

    // Should trigger the onTap callback
    expect(isSelected, isTrue);
  });

  testWidgets('ModernChip without onTap callback', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ModernChip(
            text: 'Static Chip',
            isSelected: true,
          ),
        ),
      ),
    );

    // Verify text is displayed
    expect(find.text('Static Chip'), findsOneWidget);

    // Tapping should not cause errors
    await tester.tap(find.text('Static Chip'));
    await tester.pump();
  });

  testWidgets('ModernChip with custom colors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ModernChip(
            text: 'Colored Chip',
            isSelected: true,
            selectedColor: Colors.blue,
            unselectedColor: Colors.grey,
          ),
        ),
      ),
    );

    // Verify text is displayed
    expect(find.text('Colored Chip'), findsOneWidget);
  });

  testWidgets('ModernChip with icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ModernChip(
            text: 'Chip with Icon',
            isSelected: false,
            icon: Icons.star,
          ),
        ),
      ),
    );

    // Verify text and icon are displayed
    expect(find.text('Chip with Icon'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}