import 'package:fish_ai/l10n/app_localizations.dart';
import 'package:fish_ai/widgets/server_message_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const dismissedIdKey = 'server_message_dismissed_id';
  const remindAfterKey = 'server_message_remind_after';
  const remindAfterIdKey = 'server_message_remind_after_id';

  group('ServerMessageDialog.shouldShow', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns false when snoozed for same message ID', () async {
      final remindAfter = DateTime.now().add(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        remindAfterKey: remindAfter.millisecondsSinceEpoch,
        remindAfterIdKey: 'message_a',
      });

      final result = await ServerMessageDialog.shouldShow(
        id: 'message_a',
        body: 'Body',
      );

      expect(result, isFalse);
    });

    test('returns true when snoozed for different message ID', () async {
      final remindAfter = DateTime.now().add(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        remindAfterKey: remindAfter.millisecondsSinceEpoch,
        remindAfterIdKey: 'message_a',
      });

      final result = await ServerMessageDialog.shouldShow(
        id: 'message_b',
        body: 'Body',
      );

      expect(result, isTrue);
    });
  });

  group('ServerMessageDialog actions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<void> _showDialog(WidgetTester tester, GlobalKey<NavigatorState> key) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      showDialog<void>(
        context: key.currentContext!,
        barrierDismissible: true,
        builder: (_) => const ServerMessageDialog(
          messageId: 'message_a',
          title: 'Title',
          message: 'Body',
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('dismiss clears snooze keys and stores dismissed ID', (tester) async {
      final futureRemindAfter =
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        remindAfterKey: futureRemindAfter,
        remindAfterIdKey: 'message_a',
      });

      final navigatorKey = GlobalKey<NavigatorState>();
      await _showDialog(tester, navigatorKey);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(dismissedIdKey), 'message_a');
      expect(prefs.containsKey(remindAfterKey), isFalse);
      expect(prefs.containsKey(remindAfterIdKey), isFalse);
    });

    testWidgets('remind later stores snooze ID and timestamp', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await _showDialog(tester, navigatorKey);

      await tester.tap(find.text('Remind in 3 Days'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final remindAfter = prefs.getInt(remindAfterKey) ?? 0;
      expect(remindAfter, greaterThan(DateTime.now().millisecondsSinceEpoch));
      expect(prefs.getString(remindAfterIdKey), 'message_a');
    });

    testWidgets('barrier/back pop snoozes current message ID', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await _showDialog(tester, navigatorKey);

      await tester.pageBack();
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final remindAfter = prefs.getInt(remindAfterKey) ?? 0;
      expect(remindAfter, greaterThan(DateTime.now().millisecondsSinceEpoch));
      expect(prefs.getString(remindAfterIdKey), 'message_a');
    });
  });
}
