import 'package:fish_ai/providers/app_settings_provider.dart';
import 'package:fish_ai/services/auto_backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Waits for [AppSettingsNotifier._loadSettings] to complete by polling until
/// [AppSettingsState.isLoading] becomes false.
Future<AppSettingsState> _loadedState(ProviderContainer container) async {
  for (var i = 0; i < 50; i++) {
    if (!container.read(appSettingsProvider).isLoading) break;
    await Future.delayed(const Duration(milliseconds: 20));
  }
  return container.read(appSettingsProvider);
}

void main() {
  group('AppSettingsNotifier — autoCloudBackup settings', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // ── Default values ─────────────────────────────────────────────────────

    test('autoCloudBackupEnabled defaults to false', () async {
      final state = await _loadedState(container);
      expect(state.autoCloudBackupEnabled, isFalse);
    });

    test('autoCloudBackupFrequency defaults to weekly', () async {
      final state = await _loadedState(container);
      expect(state.autoCloudBackupFrequency, autoBackupFrequencyWeekly);
    });

    // ── setAutoCloudBackupEnabled ──────────────────────────────────────────

    test('setAutoCloudBackupEnabled(true) updates state and persists', () async {
      final notifier = container.read(appSettingsProvider.notifier);
      await _loadedState(container);

      await notifier.setAutoCloudBackupEnabled(true);

      final state = container.read(appSettingsProvider);
      expect(state.autoCloudBackupEnabled, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(autoCloudBackupEnabledKey), isTrue);
    });

    test('setAutoCloudBackupEnabled(false) updates state and persists', () async {
      // Start with enabled = true in prefs.
      SharedPreferences.setMockInitialValues({
        autoCloudBackupEnabledKey: true,
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(appSettingsProvider.notifier);
      await _loadedState(c);

      await notifier.setAutoCloudBackupEnabled(false);

      final state = c.read(appSettingsProvider);
      expect(state.autoCloudBackupEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(autoCloudBackupEnabledKey), isFalse);
    });

    test('setAutoCloudBackupEnabled does not reset other fields', () async {
      SharedPreferences.setMockInitialValues({
        'showStockingButton': false,
        'welcomeGridLayout': true,
        autoCloudBackupFrequencyKey: autoBackupFrequencyDaily,
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(appSettingsProvider.notifier);
      await _loadedState(c);

      await notifier.setAutoCloudBackupEnabled(true);

      final state = c.read(appSettingsProvider);
      expect(state.showStockingButton, isFalse,
          reason: 'showStockingButton should not be reset');
      expect(state.welcomeGridLayout, isTrue,
          reason: 'welcomeGridLayout should not be reset');
      expect(state.autoCloudBackupFrequency, autoBackupFrequencyDaily,
          reason: 'autoCloudBackupFrequency should not be reset');
    });

    // ── setAutoCloudBackupFrequency ────────────────────────────────────────

    test('setAutoCloudBackupFrequency updates state and persists', () async {
      final notifier = container.read(appSettingsProvider.notifier);
      await _loadedState(container);

      await notifier.setAutoCloudBackupFrequency(autoBackupFrequencyDaily);

      final state = container.read(appSettingsProvider);
      expect(state.autoCloudBackupFrequency, autoBackupFrequencyDaily);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(autoCloudBackupFrequencyKey), autoBackupFrequencyDaily);
    });

    test('setAutoCloudBackupFrequency to monthly persists correctly', () async {
      final notifier = container.read(appSettingsProvider.notifier);
      await _loadedState(container);

      await notifier.setAutoCloudBackupFrequency(autoBackupFrequencyMonthly);

      final state = container.read(appSettingsProvider);
      expect(state.autoCloudBackupFrequency, autoBackupFrequencyMonthly);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(autoCloudBackupFrequencyKey), autoBackupFrequencyMonthly);
    });

    test('setAutoCloudBackupFrequency does not reset other fields', () async {
      SharedPreferences.setMockInitialValues({
        autoCloudBackupEnabledKey: true,
        'tankGridLayout': true,
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(appSettingsProvider.notifier);
      await _loadedState(c);

      await notifier.setAutoCloudBackupFrequency(autoBackupFrequencyWeekly);

      final state = c.read(appSettingsProvider);
      expect(state.autoCloudBackupEnabled, isTrue,
          reason: 'autoCloudBackupEnabled should not be reset');
      expect(state.tankGridLayout, isTrue,
          reason: 'tankGridLayout should not be reset');
    });

    // ── _loadSettings persists loaded values ───────────────────────────────

    test('_loadSettings reads persisted autoCloudBackupEnabled', () async {
      SharedPreferences.setMockInitialValues({
        autoCloudBackupEnabledKey: true,
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final state = await _loadedState(c);
      expect(state.autoCloudBackupEnabled, isTrue);
    });

    test('_loadSettings reads persisted autoCloudBackupFrequency', () async {
      SharedPreferences.setMockInitialValues({
        autoCloudBackupFrequencyKey: autoBackupFrequencyMonthly,
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final state = await _loadedState(c);
      expect(state.autoCloudBackupFrequency, autoBackupFrequencyMonthly);
    });
  });
}
