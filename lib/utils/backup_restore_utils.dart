import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/accessible_feedback.dart';

/// Utility class for backup and restore operations
/// Provides shared methods that can be used across the app
class BackupRestoreUtils {
  /// Export data (tanks and species tags) to a backup file
  /// 
  /// Shows a confirmation dialog and handles the export process.
  /// Can be called from any screen in the app.
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
    final tankState = ref.read(tankProvider);

    // Show confirmation dialog with backup info
    final backupInfo = tankNotifier.createBackupInfo();
    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.blue),
            SizedBox(width: 8),
            Text('Backup Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will create a backup file containing:'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('${backupInfo['tankCount']} tank(s)'),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('All fish and configurations'),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Species tags'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Export date: ${DateTime.now().toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The backup file will be saved to your device.',
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
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.backup),
            label: const Text('Create Backup'),
          ),
        ],
      ),
    );

    if (shouldExport == true && context.mounted) {
      final filePath = await tankNotifier.exportTanksToFile();
      
      if (context.mounted) {
        if (filePath != null) {
          context.showAccessibleMessage(
            'Backup created successfully!\nSaved to: ${filePath.split('/').last}',
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
              'Failed to create backup: $error',
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
    // Show warning dialog first
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.green),
            SizedBox(width: 8),
            Text('Restore Data'),
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
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Important',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Restoring from backup will:'),
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text('Replace ALL current tanks')),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text('Replace ALL species tags')),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text('Cannot be undone')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Make sure you have a current backup before proceeding.',
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
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restore),
            label: const Text('Choose File'),
          ),
        ],
      ),
    );

    if (shouldImport == true && context.mounted) {
      final success = await ref.read(tankProvider.notifier).importTanksFromFile();
      
      if (context.mounted) {
        if (success) {
          context.showAccessibleMessage(
            'Data restored successfully!',
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
