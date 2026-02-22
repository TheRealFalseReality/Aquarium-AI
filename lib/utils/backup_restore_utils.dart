import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/accessible_feedback.dart';
import '../l10n/app_localizations.dart';

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
          await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
          await prefs.setInt('last_backup_tank_count', backupInfo['tankCount'] as int);

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
      final success = await ref.read(tankProvider.notifier).importTanksFromFile();
      
      if (context.mounted) {
        if (success) {
          // Save restore timestamp
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_restore_time', DateTime.now().toIso8601String());

          if (!context.mounted) return;
          context.showAccessibleMessage(
            l10n.dataRestoredSuccess,
            duration: const Duration(seconds: 3),
          );
          
          // Log restore action
          AnalyticsService.logFeatureUsed(
            featureName: 'restore_data',
            parameters: {
              'source': source ?? 'unknown',
            },
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
}

