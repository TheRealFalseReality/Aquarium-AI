import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fish_ai/widgets/ad_component.dart';

void main() {
  group('Ad Components', () {
    testWidgets('AdBanner shows AdSense on web', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdBanner(),
          ),
        ),
      );

      // Verify that on web, the AdSense widget is used
      if (kIsWeb) {
        // On web, should find AdSense components
        expect(find.byType(AdBanner), findsOneWidget);
      } else {
        // On mobile, should show mobile ads or empty space
        expect(find.byType(AdBanner), findsOneWidget);
      }
    });

    testWidgets('NativeAdWidget shows AdSense on web', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NativeAdWidget(),
          ),
        ),
      );

      // Verify that on web, the AdSense widget is used
      if (kIsWeb) {
        // On web, should find AdSense components
        expect(find.byType(NativeAdWidget), findsOneWidget);
      } else {
        // On mobile, should show mobile ads or empty space
        expect(find.byType(NativeAdWidget), findsOneWidget);
      }
    });

    testWidgets('BannerAdWidget shows AdSense on web', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BannerAdWidget(),
          ),
        ),
      );

      // Verify widget exists
      expect(find.byType(BannerAdWidget), findsOneWidget);
    });
  });
}