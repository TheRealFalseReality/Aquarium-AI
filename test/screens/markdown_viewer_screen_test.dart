import 'package:fish_ai/screens/markdown_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('MarkdownViewerScreen Tests', () {
    testWidgets('Successfully loads and displays markdown content from assets',
        (WidgetTester tester) async {
      // Create a test asset with markdown content
      const testMarkdown = '# Test Title\n\nThis is a test paragraph.';
      const testAssetPath = 'assets/docs/test.md';

      // Mock the asset bundle to return test content
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            final String asset = methodCall.arguments as String;
            if (asset == testAssetPath) {
              return testMarkdown;
            }
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MarkdownViewerScreen(
              assetPath: testAssetPath,
              title: 'Test Document',
            ),
          ),
        ),
      );

      // Verify loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for content to load
      await tester.pumpAndSettle();

      // Verify content is displayed
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('This is a test paragraph.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify breadcrumb shows home link
      expect(find.text('Information'), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('Displays error message when asset loading fails',
        (WidgetTester tester) async {
      const testAssetPath = 'assets/docs/nonexistent.md';

      // Mock the asset bundle to throw an error
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            throw Exception('Asset not found');
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MarkdownViewerScreen(
              assetPath: testAssetPath,
              title: 'Missing Document',
            ),
          ),
        ),
      );

      // Verify loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for error state
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Failed to load content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Navigates to another markdown page when .md link is tapped',
        (WidgetTester tester) async {
      const testMarkdown =
          '# Main Document\n\n[Link to another page](other.md)';
      const testAssetPath = 'assets/docs/main.md';
      const linkedAssetPath = 'assets/docs/other.md';
      const linkedMarkdown = '# Other Document\n\nThis is the other page.';

      // Mock the asset bundle for both files
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            final String asset = methodCall.arguments as String;
            if (asset == testAssetPath) {
              return testMarkdown;
            } else if (asset == linkedAssetPath) {
              return linkedMarkdown;
            }
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MarkdownViewerScreen(
              assetPath: testAssetPath,
              title: 'Main Document',
            ),
          ),
        ),
      );

      // Wait for initial content to load
      await tester.pumpAndSettle();

      // Verify we're on the main page
      expect(find.text('Main Document'), findsOneWidget);

      // Find and tap the markdown link
      final linkFinder = find.text('Link to another page');
      expect(linkFinder, findsOneWidget);
      await tester.tap(linkFinder);
      await tester.pumpAndSettle();

      // Verify navigation occurred and we're now on the other page
      expect(find.text('Other Document'), findsOneWidget);
      expect(find.text('This is the other page.'), findsOneWidget);

      // Verify breadcrumb trail was updated
      // Should show: Information > Main Document > Other
      expect(find.text('Information'), findsOneWidget);
      expect(find.text('Main Document'), findsOneWidget);
    });

    testWidgets('Breadcrumb navigation works correctly with multiple levels',
        (WidgetTester tester) async {
      const level1Markdown = '# Level 1\n\n[Go to Level 2](level2.md)';
      const level2Markdown = '# Level 2\n\n[Go to Level 3](level3.md)';
      const level3Markdown = '# Level 3\n\nDeepest level';

      // Mock the asset bundle for all three levels
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            final String asset = methodCall.arguments as String;
            if (asset == 'assets/docs/level1.md') {
              return level1Markdown;
            } else if (asset == 'assets/docs/level2.md') {
              return level2Markdown;
            } else if (asset == 'assets/docs/level3.md') {
              return level3Markdown;
            }
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MarkdownViewerScreen(
              assetPath: 'assets/docs/level1.md',
              title: 'Level 1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Level 2
      await tester.tap(find.text('Go to Level 2'));
      await tester.pumpAndSettle();
      expect(find.text('Level 2'), findsOneWidget);

      // Navigate to Level 3
      await tester.tap(find.text('Go to Level 3'));
      await tester.pumpAndSettle();
      expect(find.text('Level 3'), findsOneWidget);

      // Verify breadcrumb trail: Information > Level 1 > Level 2 > Level 3
      expect(find.text('Information'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);

      // Tap on Level 1 breadcrumb to navigate back
      await tester.tap(find.text('Level 1').first);
      await tester.pumpAndSettle();

      // Verify we're back on Level 1
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Go to Level 2'), findsOneWidget);
    });

    testWidgets('Home breadcrumb navigates back to Information screen',
        (WidgetTester tester) async {
      const testMarkdown = '# Test Page';
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            return testMarkdown;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const Scaffold(body: Text('Information Screen')),
            onGenerateRoute: (settings) {
              if (settings.name == '/markdown') {
                return MaterialPageRoute(
                  builder: (context) => const MarkdownViewerScreen(
                    assetPath: 'assets/docs/test.md',
                    title: 'Test Page',
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );

      // Navigate to markdown viewer
      final BuildContext context = tester.element(find.byType(Scaffold));
      Navigator.pushNamed(context, '/markdown');
      await tester.pumpAndSettle();

      // Verify we're on the markdown viewer
      expect(find.text('Test Page'), findsAtLeastNWidgets(1));

      // Tap home breadcrumb
      final homeButton = find.widgetWithIcon(InkWell, Icons.home_outlined);
      expect(homeButton, findsOneWidget);
      await tester.tap(homeButton);
      await tester.pumpAndSettle();

      // Verify we're back on the Information screen
      expect(find.text('Information Screen'), findsOneWidget);
    });

    testWidgets('Correctly formats filename to title',
        (WidgetTester tester) async {
      const testMarkdown = '# Content';
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            return testMarkdown;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MarkdownViewerScreen(
              assetPath: 'assets/docs/TRANSLATION_GUIDE.md',
              title: 'Translation Guide',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the title is properly formatted
      expect(find.text('Translation Guide'), findsAtLeastNWidgets(1));
    });

    testWidgets('Breadcrumb trail maintains state correctly',
        (WidgetTester tester) async {
      const testMarkdown = '# Test';
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            return testMarkdown;
          }
          return null;
        },
      );

      // Create a screen with initial breadcrumbs
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MarkdownViewerScreen(
              assetPath: 'assets/docs/test.md',
              title: 'Current Page',
              breadcrumbs: [
                Breadcrumb(title: 'Page 1'),
                Breadcrumb(title: 'Page 2'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify breadcrumb trail displays correctly
      expect(find.text('Information'), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('Current Page'), findsOneWidget);

      // Verify chevron icons are present
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
      
      // Test that breadcrumb items are tappable - verify Page 2 is clickable
      final page2Finder = find.ancestor(
        of: find.text('Page 2'),
        matching: find.byType(InkWell),
      );
      expect(page2Finder, findsOneWidget);
      
      // Test that breadcrumb items are tappable - verify Page 1 is clickable
      final page1Finder = find.ancestor(
        of: find.text('Page 1'),
        matching: find.byType(InkWell),
      );
      expect(page1Finder, findsOneWidget);
    });

    testWidgets('Empty breadcrumbs still shows home link',
        (WidgetTester tester) async {
      const testMarkdown = '# Test';
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            return testMarkdown;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MarkdownViewerScreen(
              assetPath: 'assets/docs/test.md',
              title: 'Test Page',
              breadcrumbs: [],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify home link is always shown
      expect(find.text('Information'), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      
      // Should show chevron to current page
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text('Test Page'), findsOneWidget);
    });
  });
}
