import 'package:fish_ai/screens/information_screen.dart';
import 'package:fish_ai/screens/markdown_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('InformationScreen Tests', () {
    testWidgets('InformationScreen displays intro text and content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InformationScreen(),
          ),
        ),
      );

      // Verify that the main heading is displayed
      expect(find.text('Documentation & Guides'), findsOneWidget);

      // Verify that the intro text is displayed
      expect(
        find.text('Learn how to contribute to Aquarium AI and help make it available in your language.'),
        findsOneWidget,
      );

      // Verify the i18n card title is displayed
      expect(find.text('Internationalization (i18n)'), findsOneWidget);

      // Verify the i18n card subtitle is displayed
      expect(find.text('Help translate Aquarium AI into your language'), findsOneWidget);

      // Verify the info card text is displayed
      expect(
        find.text('The i18n guide contains links to additional resources including translation guides, testing documentation, and implementation details.'),
        findsOneWidget,
      );

      // Verify the icon is displayed
      expect(find.byIcon(Icons.language), findsOneWidget);

      // Verify the info icon is displayed
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // Verify the chevron icon is displayed
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('InformationScreen navigates to MarkdownViewerScreen when card is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InformationScreen(),
          ),
        ),
      );

      // Verify we're on the InformationScreen
      expect(find.text('Documentation & Guides'), findsOneWidget);

      // Tap on the i18n card
      await tester.tap(find.text('Internationalization (i18n)'));
      await tester.pumpAndSettle();

      // Verify navigation to MarkdownViewerScreen
      expect(find.byType(MarkdownViewerScreen), findsOneWidget);

      // Verify the title on the MarkdownViewerScreen
      expect(find.text('Internationalization Guide'), findsOneWidget);
    });

    testWidgets('InformationScreen card is tappable via InkWell', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InformationScreen(),
          ),
        ),
      );

      // Find the InkWell widget that contains the i18n card text
      final i18nTextFinder = find.text('Internationalization (i18n)');
      final inkWellFinder = find.ancestor(
        of: i18nTextFinder,
        matching: find.byType(InkWell),
      );

      expect(inkWellFinder, findsOneWidget);

      // Tap on the InkWell
      await tester.tap(inkWellFinder);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.byType(MarkdownViewerScreen), findsOneWidget);
    });
  });
}
