import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/widgets/custom_markdown.dart';

void main() {
  group('CustomMarkdown', () {
    testWidgets('renders plain text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: 'This is plain text',
            ),
          ),
        ),
      );

      expect(find.text('This is plain text'), findsOneWidget);
    });

    testWidgets('renders bold text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: 'This is **bold** text',
            ),
          ),
        ),
      );

      // The text should be split into parts
      expect(find.textContaining('This is'), findsOneWidget);
      expect(find.textContaining('bold'), findsOneWidget);
      expect(find.textContaining('text'), findsOneWidget);
    });

    testWidgets('renders multiple bold segments', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: '**First** normal **second** text',
            ),
          ),
        ),
      );

      expect(find.textContaining('First'), findsOneWidget);
      expect(find.textContaining('normal'), findsOneWidget);
      expect(find.textContaining('second'), findsOneWidget);
      expect(find.textContaining('text'), findsOneWidget);
    });

    testWidgets('renders selectable text when selectable is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: 'Selectable text',
              selectable: true,
            ),
          ),
        ),
      );

      // Find SelectableText widget
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('renders non-selectable text when selectable is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: 'Non-selectable text',
              selectable: false,
            ),
          ),
        ),
      );

      // Find Text widget (not SelectableText)
      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);
    });

    testWidgets('handles links in markdown', (WidgetTester tester) async {
      String? capturedUrl;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: 'Click [here](https://example.com) for more',
              onTapLink: (url) {
                capturedUrl = url;
              },
            ),
          ),
        ),
      );

      // The text should contain parts of the link
      expect(find.textContaining('Click'), findsOneWidget);
      expect(find.textContaining('here'), findsOneWidget);
      expect(find.textContaining('for more'), findsOneWidget);
    });

    testWidgets('handles text with both bold and links',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: 'This is **bold** and [link](https://example.com) text',
              onTapLink: (url) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('This is'), findsOneWidget);
      expect(find.textContaining('bold'), findsOneWidget);
      expect(find.textContaining('and'), findsOneWidget);
      expect(find.textContaining('link'), findsOneWidget);
      expect(find.textContaining('text'), findsOneWidget);
    });

    testWidgets('handles empty string', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: '',
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('handles text without markdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMarkdown(
              data: 'Just plain text without any markdown',
            ),
          ),
        ),
      );

      expect(find.text('Just plain text without any markdown'), findsOneWidget);
    });
  });
}
