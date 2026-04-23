import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/tank.dart';
import '../providers/purchase_provider.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/cloud_backup_service.dart';
import '../widgets/accessible_feedback.dart';
import '../widgets/remove_ads_dialog.dart';

class BackupRestoreUtils {
  ///
  /// [context] - BuildContext for showing dialogs and messages
  /// [ref] - WidgetRef for accessing providers
  /// [source] - Optional string to identify where the backup was initiated from (for analytics)
  static Future<void> exportData(
    BuildContext context,
    WidgetRef ref, {
    String? source,
  }) async {
    final tankNotifier = ref.read(tankProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    // Show confirmation dialog with backup info
    final backupInfo = tankNotifier.createBackupInfo();
    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.backup, color: Colors.blue),
            const SizedBox(width: 8),
            Text(l10n.backupDialogTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.backupDialogContent),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.tanksCount(backupInfo['tankCount'] as int)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.allFishAndConfigurations),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.speciesTags),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.notificationsExperimental),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.activityLogs),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.tankNotes),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.reschedulePreferences),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.manageDosingPresets),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.exportDateLabel(DateTime.now().toString().split('.')[0]),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.backupFileNote,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.backup),
            label: Text(l10n.createBackupButton),
          ),
        ],
      ),
    );

    if (shouldExport == true && context.mounted) {
      final filePath = await tankNotifier.exportTanksToFile();

      if (context.mounted) {
        if (filePath != null) {
          // Save backup timestamp
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_backup_time',
            DateTime.now().toIso8601String(),
          );
          await prefs.setInt(
            'last_backup_tank_count',
            backupInfo['tankCount'] as int,
          );

          if (!context.mounted) return;
          context.showAccessibleMessage(
            '${l10n.backupCreatedSuccess}\n${l10n.savedToFile(filePath.split('/').last)}',
            duration: const Duration(seconds: 4),
          );

          // Log backup action
          AnalyticsService.logFeatureUsed(
            featureName: 'backup_data',
            parameters: {
              'tank_count': backupInfo['tankCount'],
              'source': source ?? 'unknown',
            },
          );
        } else {
          final error = ref.read(tankProvider).error;
          if (error != null) {
            context.showAccessibleMessage(
              l10n.failedToCreateBackup(error),
              duration: const Duration(seconds: 4),
            );
          }
        }
      }
    }
  }

  /// Import data (tanks and species tags) from a backup file
  ///
  /// Shows a warning dialog and handles the import process.
  /// Can be called from any screen in the app.
  ///
  /// [context] - BuildContext for showing dialogs and messages
  /// [ref] - WidgetRef for accessing providers
  /// [source] - Optional string to identify where the restore was initiated from (for analytics)
  static Future<void> importData(
    BuildContext context,
    WidgetRef ref, {
    String? source,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    // Show warning dialog first
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.restore, color: Colors.green),
            const SizedBox(width: 8),
            Text(l10n.restoreDialogTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.importantWarning,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.restoreWarningIntro),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(l10n.replaceAllTanks)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(l10n.replaceAllSpeciesTags)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(l10n.replaceAllNotifications)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(l10n.replaceAllActivityLogs)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(l10n.tankNotes)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(l10n.replaceAllReschedulePreferences)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(l10n.manageDosingPresets)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(l10n.cannotBeUndone)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.backupBeforeRestoreNote,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restore),
            label: Text(l10n.chooseFileButton),
          ),
        ],
      ),
    );

    if (shouldImport == true && context.mounted) {
      final success = await ref
          .read(tankProvider.notifier)
          .importTanksFromFile();

      if (context.mounted) {
        if (success) {
          // Save restore timestamp
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_restore_time',
            DateTime.now().toIso8601String(),
          );

          if (!context.mounted) return;
          context.showAccessibleMessage(
            l10n.dataRestoredSuccess,
            duration: const Duration(seconds: 3),
          );

          // Log restore action
          AnalyticsService.logFeatureUsed(
            featureName: 'restore_data',
            parameters: {'source': source ?? 'unknown'},
          );
        } else {
          final error = ref.read(tankProvider).error;
          if (error != null) {
            context.showAccessibleMessage(
              error,
              duration: const Duration(seconds: 4),
            );
          }
        }
      }
    }
  }

  /// Share / export a single [tank] so another user can import it.
  ///
  /// Shows a brief confirmation dialog, then hands off to
  /// [TankNotifier.exportSingleTank].
  static Future<void> shareTank(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final shouldShare = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.share, color: Colors.teal),
            const SizedBox(width: 8),
            Text(l10n.shareTankDialogTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shareTankDialogContent),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tank.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.allFishAndConfigurations),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.waterParameters),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.tankNotes),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.shareTankFileNote,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.share),
            label: Text(l10n.shareTankButton),
          ),
        ],
      ),
    );

    if (shouldShare == true && context.mounted) {
      final success = await ref
          .read(tankProvider.notifier)
          .exportSingleTank(tank);

      if (context.mounted) {
        if (!success) {
          final error = ref.read(tankProvider).error;
          if (error != null) {
            context.showAccessibleMessage(
              error,
              duration: const Duration(seconds: 4),
            );
          }
        }
        // On mobile the OS share sheet handles feedback; on web/desktop the
        // file download is immediate, so show a brief confirmation.
        else {
          context.showAccessibleMessage(
            l10n.tankSharedSuccess,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  /// Import a single tank from a tank-share file.
  ///
  /// Shows a warning/info dialog, picks a file, then adds the imported tank
  /// to the existing tank list (does NOT replace existing tanks).
  static Future<void> importTankShare(
    BuildContext context,
    WidgetRef ref, {
    String? source,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.download, color: Colors.teal),
            const SizedBox(width: 8),
            Text(l10n.importTankDialogTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.importTankDialogContent),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.importTankAddsToExisting)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.importTankNewId)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.file_open),
            label: Text(l10n.chooseFileButton),
          ),
        ],
      ),
    );

    if (shouldImport == true && context.mounted) {
      final importedTank = await ref
          .read(tankProvider.notifier)
          .importSingleTankFromFile();

      if (context.mounted) {
        if (importedTank != null) {
          context.showAccessibleMessage(
            l10n.tankImportedSuccess(importedTank.name),
            duration: const Duration(seconds: 3),
          );

          AnalyticsService.logFeatureUsed(
            featureName: 'import_tank_share',
            parameters: {'source': source ?? 'unknown'},
          );
        } else {
          final error = ref.read(tankProvider).error;
          if (error != null) {
            context.showAccessibleMessage(
              error,
              duration: const Duration(seconds: 4),
            );
          }
        }
      }
    }
  }

  /// Backs up all aquarium data to Firebase Firestore (Founder Aquarist only).
  ///
  /// If the user is not a Founder, shows the purchase dialog. If the user is
  /// not signed in, shows an informational dialog.
  static Future<void> exportDataOnline(
    BuildContext context,
    WidgetRef ref, {
    String? source,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    // Founder gate
    final isFounder = ref.read(isFounderProvider);
    if (!isFounder) {
      showRemoveAdsDialog(context);
      return;
    }

    // Sign-in gate
    if (FirebaseAuth.instance.currentUser == null) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.cloudBackupDialogTitle),
          content: Text(l10n.cloudBackupRequiresSignIn),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
      return;
    }

    final tankNotifier = ref.read(tankProvider.notifier);
    final backupInfo = tankNotifier.createBackupInfo();

    // Confirmation dialog
    final shouldBackup = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_upload, color: Colors.purple),
            const SizedBox(width: 8),
            Text(l10n.cloudBackupDialogTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cloudBackupDialogContent),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(l10n.tanksCount(backupInfo['tankCount'] as int)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.cloud_upload),
            label: Text(l10n.cloudBackupButtonLabel),
          ),
        ],
      ),
    );

    if (shouldBackup != true || !context.mounted) return;

    try {
      final payload = await tankNotifier.buildBackupPayload();
      final jsonString = json.encode(payload);
      final tankCount = backupInfo['tankCount'] as int;
      final appVersion = payload['version'] as String? ?? '';

      final success = await CloudBackupService.saveBackup(
        jsonString,
        tankCount: tankCount,
        appVersion: appVersion,
      );

      if (!context.mounted) return;

      if (success) {
        context.showAccessibleMessage(
          l10n.cloudBackupSuccess,
          duration: const Duration(seconds: 3),
        );
        AnalyticsService.logFeatureUsed(
          featureName: 'cloud_backup',
          parameters: {
            'tank_count': tankCount,
            'source': source ?? 'unknown',
          },
        );
      } else {
        context.showAccessibleMessage(
          l10n.cloudBackupFailed('unknown error'),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      context.showAccessibleMessage(
        l10n.cloudBackupFailed(e.toString()),
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Restores all aquarium data from Firebase Firestore (Founder Aquarist only).
  ///
  /// If the user is not a Founder, shows the purchase dialog. If the user is
  /// not signed in, shows an informational dialog.
  static Future<void> importDataOnline(
    BuildContext context,
    WidgetRef ref, {
    String? source,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    // Founder gate
    final isFounder = ref.read(isFounderProvider);
    if (!isFounder) {
      showRemoveAdsDialog(context);
      return;
    }

    // Sign-in gate
    if (FirebaseAuth.instance.currentUser == null) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.cloudRestoreDialogTitle),
          content: Text(l10n.cloudBackupRequiresSignIn),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
      return;
    }

    // Fetch backup metadata
    final backupInfo = await CloudBackupService.getBackupInfo();

    if (!context.mounted) return;

    if (backupInfo == null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.cloudRestoreDialogTitle),
          content: Text(l10n.noCloudBackupFound),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
      return;
    }

    final backedUpAt = backupInfo['backedUpAt'] as DateTime?;
    final tankCount = backupInfo['tankCount'] as int? ?? 0;
    final dateStr = backedUpAt != null
        ? backedUpAt.toString().split('.')[0]
        : '?';

    // Warning / confirmation dialog
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_download, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text(l10n.cloudRestoreDialogTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.importantWarning,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.cloudRestoreDialogContent(dateStr, tankCount),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.cloud_download),
            label: Text(l10n.cloudRestoreButtonLabel),
          ),
        ],
      ),
    );

    if (shouldRestore != true || !context.mounted) return;

    try {
      final jsonString = await CloudBackupService.loadBackup();

      if (!context.mounted) return;

      if (jsonString == null) {
        context.showAccessibleMessage(
          l10n.cloudRestoreFailed('backup data not found'),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      final backupData = json.decode(jsonString) as Map<String, dynamic>;
      final success = await ref
          .read(tankProvider.notifier)
          .applyBackupPayload(backupData);

      if (!context.mounted) return;

      if (success) {
        // Save restore timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'last_restore_time',
          DateTime.now().toIso8601String(),
        );

        if (!context.mounted) return;
        context.showAccessibleMessage(
          l10n.cloudRestoreSuccess,
          duration: const Duration(seconds: 3),
        );
        AnalyticsService.logFeatureUsed(
          featureName: 'cloud_restore',
          parameters: {
            'tank_count': tankCount,
            'source': source ?? 'unknown',
          },
        );
      } else {
        final error = ref.read(tankProvider).error;
        context.showAccessibleMessage(
          l10n.cloudRestoreFailed(error ?? 'unknown error'),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      context.showAccessibleMessage(
        l10n.cloudRestoreFailed(e.toString()),
        duration: const Duration(seconds: 4),
      );
    }
  }
}
