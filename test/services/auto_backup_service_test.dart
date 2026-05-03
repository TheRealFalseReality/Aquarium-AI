import 'package:fish_ai/providers/purchase_provider.dart';
import 'package:fish_ai/services/auto_backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A minimal [WidgetRef] stand-in for tests that only exercise early-exit
/// code paths in [AutoBackupService.checkAndRun]. Those paths return before
/// ever calling [read], so no method overrides are necessary.
class _FakeWidgetRef extends Fake implements WidgetRef {}

void main() {
  group('AutoBackupService — scheduling logic', () {
    final fakeRef = _FakeWidgetRef();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // ── getLastAutoBackupTime ───────────────────────────────────────────────

    test('getLastAutoBackupTime returns null when no key is stored', () async {
      final result = await AutoBackupService.getLastAutoBackupTime();
      expect(result, isNull);
    });

    test('getLastAutoBackupTime returns stored DateTime', () async {
      final stored = DateTime(2025, 6, 15, 12, 0, 0);
      SharedPreferences.setMockInitialValues({
        lastAutoBackupKey: stored.toIso8601String(),
      });

      final result = await AutoBackupService.getLastAutoBackupTime();
      expect(result, isNotNull);
      // Allow for rounding differences from ISO 8601 parsing.
      expect(result!.difference(stored).inSeconds.abs(), lessThan(2));
    });

    test('getLastAutoBackupTime returns null for corrupt stored value', () async {
      SharedPreferences.setMockInitialValues({
        lastAutoBackupKey: 'not-a-valid-date',
      });

      final result = await AutoBackupService.getLastAutoBackupTime();
      expect(result, isNull);
    });

    // ── checkAndRun — enabled gate ──────────────────────────────────────────

    test('checkAndRun skips silently when autoCloudBackupEnabled is false',
        () async {
      // Enabled = false with founder status set — should skip.
      SharedPreferences.setMockInitialValues({
        autoCloudBackupEnabledKey: false,
        adsRemovedKey: true,
      });

      // Should complete without error and without writing a backup timestamp.
      await expectLater(AutoBackupService.checkAndRun(fakeRef), completes);

      final lastRun = await AutoBackupService.getLastAutoBackupTime();
      expect(lastRun, isNull, reason: 'No backup should run when disabled');
    });

    test('checkAndRun skips when both enabled and founder flags are absent',
        () async {
      // Completely empty prefs — all gates short-circuit at enabled=false.
      await expectLater(AutoBackupService.checkAndRun(fakeRef), completes);

      final lastRun = await AutoBackupService.getLastAutoBackupTime();
      expect(lastRun, isNull);
    });

    // ── checkAndRun — founder gate ──────────────────────────────────────────

    test('checkAndRun skips when adsRemovedKey is false (non-founder)', () async {
      SharedPreferences.setMockInitialValues({
        autoCloudBackupEnabledKey: true,
        adsRemovedKey: false,
      });

      await expectLater(AutoBackupService.checkAndRun(fakeRef), completes);

      final lastRun = await AutoBackupService.getLastAutoBackupTime();
      expect(lastRun, isNull, reason: 'No backup should run for non-founders');
    });

    // ── checkAndRun — not-yet-due gate ─────────────────────────────────────

    test('checkAndRun skips when last backup is within weekly interval', () async {
      // 2 hours ago — well within a 7-day weekly interval.
      final recent = DateTime.now().subtract(const Duration(hours: 2));
      SharedPreferences.setMockInitialValues({
        autoCloudBackupEnabledKey: true,
        adsRemovedKey: true,
        autoCloudBackupFrequencyKey: autoBackupFrequencyWeekly,
        lastAutoBackupKey: recent.toIso8601String(),
      });

      // Reaches the interval check and returns early; fakeRef is never called.
      await expectLater(AutoBackupService.checkAndRun(fakeRef), completes);

      // Timestamp must not have been updated.
      final lastRun = await AutoBackupService.getLastAutoBackupTime();
      expect(lastRun, isNotNull);
      expect(
        lastRun!.difference(recent).inSeconds.abs(),
        lessThan(2),
        reason: 'Timestamp should not be updated when backup is not yet due',
      );
    });

    test('checkAndRun skips when last backup is within daily interval', () async {
      // 30 minutes ago — within a 1-day interval.
      final recent = DateTime.now().subtract(const Duration(minutes: 30));
      SharedPreferences.setMockInitialValues({
        autoCloudBackupEnabledKey: true,
        adsRemovedKey: true,
        autoCloudBackupFrequencyKey: autoBackupFrequencyDaily,
        lastAutoBackupKey: recent.toIso8601String(),
      });

      await expectLater(AutoBackupService.checkAndRun(fakeRef), completes);

      final lastRun = await AutoBackupService.getLastAutoBackupTime();
      expect(lastRun, isNotNull);
      expect(
        lastRun!.difference(recent).inSeconds.abs(),
        lessThan(2),
        reason: 'Timestamp should not be updated when daily backup is not yet due',
      );
    });

    test('checkAndRun skips when last backup is within monthly interval', () async {
      // 10 days ago — well within a 30-day monthly interval.
      final recent = DateTime.now().subtract(const Duration(days: 10));
      SharedPreferences.setMockInitialValues({
        autoCloudBackupEnabledKey: true,
        adsRemovedKey: true,
        autoCloudBackupFrequencyKey: autoBackupFrequencyMonthly,
        lastAutoBackupKey: recent.toIso8601String(),
      });

      await expectLater(AutoBackupService.checkAndRun(fakeRef), completes);

      final lastRun = await AutoBackupService.getLastAutoBackupTime();
      expect(lastRun, isNotNull);
      expect(
        lastRun!.difference(recent).inSeconds.abs(),
        lessThan(2),
        reason: 'Timestamp should not be updated when monthly backup is not yet due',
      );
    });

    // ── checkAndRun — not signed in (Firebase absent in unit tests) ─────────

    test(
        'checkAndRun does not update timestamp when Firebase is not initialised '
        '(not signed in)', () async {
      // Backup is overdue (8 days ago on weekly schedule) and user is a founder,
      // but Firebase is not initialised in unit tests → currentUser == null.
      // The method swallows all errors; the timestamp must not be updated.
      final old = DateTime.now().subtract(const Duration(days: 8));
      SharedPreferences.setMockInitialValues({
        autoCloudBackupEnabledKey: true,
        adsRemovedKey: true,
        autoCloudBackupFrequencyKey: autoBackupFrequencyWeekly,
        lastAutoBackupKey: old.toIso8601String(),
      });

      // This will reach the Firebase check; Firebase is absent in unit tests
      // so it will either return null (not signed in) or throw (caught by the
      // service's internal try/catch). Either way, the timestamp must not advance.
      await expectLater(AutoBackupService.checkAndRun(fakeRef), completes);

      final lastRun = await AutoBackupService.getLastAutoBackupTime();
      if (lastRun != null) {
        expect(
          lastRun.difference(old).inSeconds.abs(),
          lessThan(2),
          reason: 'Timestamp must not advance when not signed in',
        );
      }
    });
  });
}
