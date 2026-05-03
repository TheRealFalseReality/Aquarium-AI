import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/purchase_provider.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/cloud_backup_service.dart';

/// SharedPreferences key for the last auto cloud-backup timestamp.
const String lastAutoBackupKey = 'last_auto_cloud_backup_time';

/// SharedPreferences key for the auto-backup enabled flag.
const String autoCloudBackupEnabledKey = 'autoCloudBackupEnabled';

/// SharedPreferences key for the auto-backup frequency string.
const String autoCloudBackupFrequencyKey = 'autoCloudBackupFrequency';

/// Auto-backup frequency constants.
const String autoBackupFrequencyDaily = 'daily';
const String autoBackupFrequencyWeekly = 'weekly';
const String autoBackupFrequencyMonthly = 'monthly';

/// Maps a frequency string to the minimum [Duration] that must have elapsed
/// since the last backup before a new one is triggered.
Duration _intervalFor(String frequency) {
  switch (frequency) {
    case autoBackupFrequencyDaily:
      return const Duration(days: 1);
    case autoBackupFrequencyMonthly:
      return const Duration(days: 30);
    case autoBackupFrequencyWeekly:
    default:
      return const Duration(days: 7);
  }
}

/// Service that silently runs a cloud backup when the configured schedule
/// interval has elapsed. Only available to Founder Aquarists who are
/// signed in to Firebase.
class AutoBackupService {
  AutoBackupService._();

  /// Checks whether an automatic cloud backup is due and, if so, executes it
  /// silently. Should be called from the welcome screen `initState` on every
  /// cold start.
  ///
  /// The method is intentionally non-blocking and swallows all errors so that
  /// it never disrupts the normal app startup flow.
  static Future<void> checkAndRun(WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Read persisted auto-backup settings.
      final enabled = prefs.getBool(autoCloudBackupEnabledKey) ?? false;
      if (!enabled) return;

      // Founder gate: read the persisted flag directly from SharedPreferences
      // to avoid a race condition on cold start where the PurchaseNotifier
      // async _init() may not have completed yet.
      // The `?? kDebugMode` fallback mirrors PurchaseNotifier._init() so that
      // debug builds behave identically to the original isFounderProvider path.
      final isFounder = prefs.getBool(adsRemovedKey) ?? kDebugMode;
      if (!isFounder) return;

      // Sign-in gate.
      if (FirebaseAuth.instance.currentUser == null) return;

      // Determine frequency and check elapsed time.
      final frequency =
          prefs.getString(autoCloudBackupFrequencyKey) ?? autoBackupFrequencyWeekly;
      final interval = _intervalFor(frequency);

      final lastStr = prefs.getString(lastAutoBackupKey);
      if (lastStr != null) {
        final lastRun = DateTime.tryParse(lastStr);
        if (lastRun != null) {
          final elapsed = DateTime.now().difference(lastRun);
          if (elapsed < interval) return; // Not due yet.
        }
      }

      // Build and upload the backup.
      final tankNotifier = ref.read(tankProvider.notifier);
      final backupInfo = tankNotifier.createBackupInfo();
      final payload = await tankNotifier.buildBackupPayload();
      final jsonString = json.encode(payload);
      final tankCount = backupInfo['tankCount'] as int;
      final appVersion = payload['version'] as String? ?? '';

      final success = await CloudBackupService.saveBackup(
        jsonString,
        tankCount: tankCount,
        appVersion: appVersion,
      );

      if (success) {
        await prefs.setString(
          lastAutoBackupKey,
          DateTime.now().toIso8601String(),
        );

        if (kDebugMode) {
          debugPrint(
            'AutoBackupService: cloud backup completed '
            '($tankCount tank(s), frequency: $frequency)',
          );
        }

        AnalyticsService.logFeatureUsed(
          featureName: 'auto_cloud_backup',
          parameters: {
            'tank_count': tankCount,
            'frequency': frequency,
          },
        );
      } else {
        if (kDebugMode) {
          debugPrint('AutoBackupService: cloud backup failed');
        }
      }
    } catch (e) {
      // Swallow all errors – auto-backup must never crash the app.
      if (kDebugMode) {
        debugPrint('AutoBackupService.checkAndRun error: $e');
      }
    }
  }

  /// Returns the timestamp of the last successful auto cloud backup, or
  /// `null` if no auto backup has ever been performed.
  static Future<DateTime?> getLastAutoBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(lastAutoBackupKey);
      if (str == null) return null;
      return DateTime.tryParse(str);
    } catch (_) {
      return null;
    }
  }
}
