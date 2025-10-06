import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/widgets/custom_markdown.dart';

/// Integration test to verify CustomMarkdown works correctly
/// in the context of the application's actual usage patterns
void main() {
  group('CustomMarkdown Integration Tests', () {
    testWidgets('handles real-world AI response with bold text',
        (WidgetTester tester) async {
      const responseText = '''
Your water parameters look good overall. However, there are a few things to note:

**pH Level**: Your pH is slightly high. Consider using pH down solution.

**Ammonia**: Perfect! Keep up the good work with water changes.

**Temperature**: The temperature is ideal for tropical fish.
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: responseText,
              selectable: true,
            ),
          ),
        ),
      );

      // Verify content is rendered
      expect(find.textContaining('pH Level'), findsOneWidget);
      expect(find.textContaining('Ammonia'), findsOneWidget);
      expect(find.textContaining('Temperature'), findsOneWidget);
    });

    testWidgets('handles markdown with links like in automation scripts',
        (WidgetTester tester) async {
      const explanationText =
          'This script automates water testing. For more information, '
          'visit [our documentation](https://example.com/docs) or '
          '[contact support](mailto:support@example.com).';

      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: explanationText,
              selectable: true,
              onTapLink: (url) {
                tappedUrl = url;
              },
            ),
          ),
        ),
      );

      // Verify text parts are present
      expect(find.textContaining('This script automates'), findsOneWidget);
      expect(find.textContaining('our documentation'), findsOneWidget);
      expect(find.textContaining('contact support'), findsOneWidget);
    });

    testWidgets('handles parameter advice with mixed formatting',
        (WidgetTester tester) async {
      const adviceText =
          'Your **ammonia** levels are elevated. '
          'Immediate action required: '
          '**Perform a 50% water change** and '
          'retest in 24 hours. '
          'Learn more about [ammonia toxicity](https://example.com/ammonia).';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: adviceText,
              selectable: true,
              onTapLink: (url) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('ammonia'), findsWidgets);
      expect(find.textContaining('Immediate action required'), findsOneWidget);
      expect(find.textContaining('Perform a 50% water change'), findsOneWidget);
      expect(find.textContaining('ammonia toxicity'), findsOneWidget);
    });

    testWidgets('handles analysis summary messages', (WidgetTester tester) async {
      const summaryText =
          'Water Analysis Complete: Your aquarium is in **excellent** condition! '
          'All parameters are within ideal ranges for your fish species.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: summaryText,
              selectable: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('Water Analysis Complete'), findsOneWidget);
      expect(find.textContaining('excellent'), findsOneWidget);
      expect(find.textContaining('ideal ranges'), findsOneWidget);
    });

    testWidgets('maintains text selectability', (WidgetTester tester) async {
      const text = 'This is **selectable** markdown text';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: text,
              selectable: true,
            ),
          ),
        ),
      );

      // Verify SelectableText widget is used
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('handles multi-line markdown with multiple bold sections',
        (WidgetTester tester) async {
      const multiLineText = '''
**Important**: Your fish need attention.

**Action Items**:
- Check water temperature
- Test pH levels
- Monitor fish behavior

**Resources**: Visit our [help center](https://example.com/help)
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: multiLineText,
              selectable: true,
              onTapLink: (url) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Important'), findsOneWidget);
      expect(find.textContaining('Action Items'), findsOneWidget);
      expect(find.textContaining('Resources'), findsOneWidget);
      expect(find.textContaining('help center'), findsOneWidget);
    });

    testWidgets('handles empty or whitespace-only markdown',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: '',
              selectable: true,
            ),
          ),
        ),
      );

      // Should render without error
      expect(find.byType(SelectableText), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: '   \n\n  ',
              selectable: true,
            ),
          ),
        ),
      );

      // Should render without error
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('preserves theme-based styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const Scaffold(
            body: CustomMarkdown(
              data: 'This has **bold** and [link](http://example.com)',
              selectable: true,
            ),
          ),
        ),
      );

      // Widget should build without errors and use theme
      expect(find.byType(SelectableText), findsOneWidget);
    });
  });
}
