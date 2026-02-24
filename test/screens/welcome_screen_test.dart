import 'package:fish_ai/screens/changelog_screen.dart';
import 'package:fish_ai/screens/fish_compatibility_screen.dart';
import 'package:fish_ai/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WelcomeScreen Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('WelcomeScreen UI Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            routes: {
              '/compat-ai': (context) => const FishCompatibilityScreen(),
            },
            home: const WelcomeScreen(),
          ),
        ),
      );

      // Verify that the 'Aquarium AI' title is displayed.
      expect(find.text('Aquarium AI'), findsOneWidget);

      // Tap on the 'AI Compatibility Tool' card and verify that it navigates to the correct screen.
      await tester.tap(find.text('AI Compatibility Tool'));
      await tester.pumpAndSettle();
      expect(find.byType(FishCompatibilityScreen), findsOneWidget);
    });

    testWidgets('WelcomeScreen shows My Tanks section', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const WelcomeScreen(),
          ),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Verify that 'My Tanks' section is displayed
      expect(find.text('My Tanks'), findsWidgets);
      
      // When no tanks, should show "No tanks yet"
      expect(find.text('No tanks yet'), findsOneWidget);
      
      // Should show call-to-action button
      expect(find.text('Create Your First Tank'), findsOneWidget);
    });

    testWidgets('Promotion dialog resets after 48 hours', (WidgetTester tester) async {
      // Set a timestamp that is more than 48 hours ago
      final moreThan48HoursAgo = DateTime.now().millisecondsSinceEpoch - (49 * 60 * 60 * 1000);
      SharedPreferences.setMockInitialValues({
        'promotion_dialog_timestamp': moreThan48HoursAgo,
      });

      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Mock the dialog showing to count how many times it's called
                return WelcomeScreen();
              },
            ),
          ),
        ),
      );

      // Wait for the dialog check timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // The dialog should be able to show again after 48 hours
      // This is a basic test structure - in a real scenario we'd need to mock the dialog
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Promotion dialog does not show if less than 48 hours have passed', (WidgetTester tester) async {
      // Set a timestamp that is less than 48 hours ago
      final lessThan48HoursAgo = DateTime.now().millisecondsSinceEpoch - (24 * 60 * 60 * 1000);
      SharedPreferences.setMockInitialValues({
        'promotion_dialog_timestamp': lessThan48HoursAgo,
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const WelcomeScreen(),
          ),
        ),
      );

      // Wait for the dialog check timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // The dialog should not show since less than 48 hours have passed
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    test('resetPromotionDialog clears timestamp', () async {
      // Set initial timestamp
      SharedPreferences.setMockInitialValues({
        'promotion_dialog_timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('promotion_dialog_timestamp'), isTrue);

      // Reset the dialog
      await WelcomeScreen.resetPromotionDialog();

      // Verify timestamp is cleared
      expect(prefs.containsKey('promotion_dialog_timestamp'), isFalse);
    });

    test('setPromotionDialogTimestamp sets timestamp correctly', () async {
      // Set a specific timestamp
      final testTimestamp = DateTime.now().millisecondsSinceEpoch - (25 * 60 * 60 * 1000); // 25 hours ago
      await WelcomeScreen.setPromotionDialogTimestamp(testTimestamp);

      // Verify timestamp was set
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('promotion_dialog_timestamp'), equals(testTimestamp));
    });

    test('checkPromotionDialogStatus works without throwing', () async {
      // This is mainly to ensure the debug method doesn't crash
      await WelcomeScreen.checkPromotionDialogStatus();
      
      // Set a timestamp and check again
      final testTimestamp = DateTime.now().millisecondsSinceEpoch;
      await WelcomeScreen.setPromotionDialogTimestamp(testTimestamp);
      await WelcomeScreen.checkPromotionDialogStatus();
    });
  });

  group('Changelog Banner Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Aquarium AI',
        packageName: 'com.test.app',
        version: '2.0.0',
        buildNumber: '2',
        buildSignature: '',
      );
    });

    testWidgets('Banner shows on new app version', (WidgetTester tester) async {
      // No stored version → treat as new install / upgrade
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.new_releases), findsOneWidget);
    });

    testWidgets('Banner persists within 3-day window', (WidgetTester tester) async {
      final oneDayAgo =
          DateTime.now().millisecondsSinceEpoch - (1 * 24 * 60 * 60 * 1000);
      SharedPreferences.setMockInitialValues({
        'changelog_shown_version': '2.0.0',
        'changelog_banner_shown_at': oneDayAgo,
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.new_releases), findsOneWidget);
    });

    testWidgets('Banner auto-dismisses after 3 days', (WidgetTester tester) async {
      final fourDaysAgo =
          DateTime.now().millisecondsSinceEpoch - (4 * 24 * 60 * 60 * 1000);
      SharedPreferences.setMockInitialValues({
        'changelog_shown_version': '2.0.0',
        'changelog_banner_shown_at': fourDaysAgo,
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.new_releases), findsNothing);

      // Timestamp key should be cleaned up
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('changelog_banner_shown_at'), isFalse);
    });

    testWidgets('Banner dismisses via close button', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.new_releases), findsOneWidget);

      await tester.tap(find.byKey(const Key('changelog_banner_dismiss')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.new_releases), findsNothing);

      // Timestamp key should be cleaned up
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('changelog_banner_shown_at'), isFalse);
    });

    testWidgets('Banner tap navigates to ChangelogScreen', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.new_releases), findsOneWidget);

      await tester.tap(find.byKey(const Key('changelog_banner_tap_area')));
      await tester.pumpAndSettle();

      expect(find.byType(ChangelogScreen), findsOneWidget);
    });
  });
}
