import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/tank_provider.dart';
import '../providers/google_drive_provider.dart';
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

  /// Export data to Google Drive
  /// 
  /// Shows Google Drive sign-in if needed and uploads backup to Drive.
  /// [context] - BuildContext for showing dialogs and messages
  /// [ref] - WidgetRef for accessing providers
  /// [source] - Optional string to identify where the backup was initiated from (for analytics)
  static Future<void> exportToGoogleDrive(
    BuildContext context,
    WidgetRef ref, {
    String? source,
  }) async {
    final tankNotifier = ref.read(tankProvider.notifier);
    final googleDriveNotifier = ref.read(googleDriveProvider.notifier);
    final googleDriveState = ref.read(googleDriveProvider);
    final googleDriveService = ref.read(googleDriveServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    // Check if user is signed in to Google Drive
    if (!googleDriveState.isSignedIn) {
      // Show sign-in prompt
      final shouldSignIn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.cloud, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: const Text('Sign in to Google Drive'),
              ),
            ],
          ),
          content: const Text(
            'To back up to Google Drive, you need to sign in with your Google account. '
            'Your backup will be stored in your personal Google Drive.',
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
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
            ),
          ],
        ),
      );

      if (shouldSignIn != true) return;

      if (context.mounted) {
        // Attempt to sign in
        final signedIn = await googleDriveNotifier.signIn();
        if (!signedIn) {
          if (context.mounted) {
            final errorMessage = ref.read(googleDriveProvider).error ?? 
                'Failed to sign in to Google Drive. Please try again.';
            context.showAccessibleMessage(
              errorMessage,
              duration: const Duration(seconds: 5),
            );
          }
          return;
        }
      }
    }

    // Show confirmation dialog with backup info
    final backupInfo = tankNotifier.createBackupInfo();
    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_upload, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: const Text('Back Up to Google Drive'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload your aquarium data to Google Drive'),
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
            const SizedBox(height: 16),
            Text(
              l10n.exportDateLabel(DateTime.now().toString().split('.')[0]),
              style: TextStyle(
                fontSize: 12,
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
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Upload to Drive'),
          ),
        ],
      ),
    );

    if (shouldExport == true && context.mounted) {
      // Create backup data
      final backupData = await tankNotifier.createBackupData();
      if (backupData == null) {
        if (context.mounted) {
          context.showAccessibleMessage(
            'Failed to create backup data',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Convert to JSON bytes
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      // Create filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'aquarium_ai_backup_$timestamp.json';

      // Upload to Google Drive
      try {
        final fileId = await googleDriveService.uploadBackup(
          fileName: fileName,
          fileContent: bytes,
          description: 'Aquarium AI backup created on ${DateTime.now().toString().split('.')[0]}',
        );

        if (fileId != null && context.mounted) {
          // Save backup timestamp
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
          await prefs.setInt('last_backup_tank_count', backupInfo['tankCount'] as int);
          await prefs.setString('last_backup_location', 'google_drive');

          context.showAccessibleMessage(
            'Backup successfully uploaded to Google Drive!\n$fileName',
            duration: const Duration(seconds: 4),
          );

          // Log backup action
          AnalyticsService.logFeatureUsed(
            featureName: 'backup_to_google_drive',
            parameters: {
              'tank_count': backupInfo['tankCount'],
              'source': source ?? 'unknown',
            },
          );
        } else if (context.mounted) {
          context.showAccessibleMessage(
            'Failed to upload to Google Drive',
            duration: const Duration(seconds: 3),
          );
        }
      } catch (e) {
        if (context.mounted) {
          context.showAccessibleMessage(
            'Error uploading to Google Drive: $e',
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
  }

  /// Import data from Google Drive
  /// 
  /// Shows available backups from Google Drive and allows user to select one to restore.
  /// [context] - BuildContext for showing dialogs and messages
  /// [ref] - WidgetRef for accessing providers
  /// [source] - Optional string to identify where the restore was initiated from (for analytics)
  static Future<void> importFromGoogleDrive(
    BuildContext context,
    WidgetRef ref, {
    String? source,
  }) async {
    final tankNotifier = ref.read(tankProvider.notifier);
    final googleDriveNotifier = ref.read(googleDriveProvider.notifier);
    final googleDriveState = ref.read(googleDriveProvider);
    final googleDriveService = ref.read(googleDriveServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    // Check if user is signed in to Google Drive
    if (!googleDriveState.isSignedIn) {
      // Show sign-in prompt
      final shouldSignIn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.cloud, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: const Text('Sign in to Google Drive'),
              ),
            ],
          ),
          content: const Text(
            'To restore from Google Drive, you need to sign in with your Google account.',
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
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
            ),
          ],
        ),
      );

      if (shouldSignIn != true) return;

      if (context.mounted) {
        // Attempt to sign in
        final signedIn = await googleDriveNotifier.signIn();
        if (!signedIn) {
          if (context.mounted) {
            final errorMessage = ref.read(googleDriveProvider).error ?? 
                'Failed to sign in to Google Drive. Please try again.';
            context.showAccessibleMessage(
              errorMessage,
              duration: const Duration(seconds: 5),
            );
          }
          return;
        }
      }
    }

    // List available backups from Google Drive
    try {
      final backups = await googleDriveService.listBackups();

      if (backups.isEmpty && context.mounted) {
        context.showAccessibleMessage(
          'No backups found in Google Drive',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Show backup selection dialog
      final selectedBackup = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_download, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text('Select Backup to Restore'),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index];
                final modifiedDate = backup.modifiedTime != null
                    ? DateTime.parse(backup.modifiedTime.toString())
                        .toLocal()
                        .toString()
                        .split('.')[0]
                    : 'Unknown date';
                
                return ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(backup.name ?? 'Unnamed backup'),
                  subtitle: Text('Modified: $modifiedDate'),
                  onTap: () => Navigator.of(context).pop(backup.id),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );

      if (selectedBackup == null) return;

      // Show warning dialog before restore
      if (context.mounted) {
        final shouldRestore = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.restore, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.restoreDialogTitle),
                ),
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
                    Expanded(child: Text(l10n.cannotBeUndone)),
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
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.restore),
                label: const Text('Restore'),
              ),
            ],
          ),
        );

        if (shouldRestore != true) return;

        if (context.mounted) {
          // Download backup from Google Drive
          final backupContent = await googleDriveService.downloadBackup(selectedBackup);

          if (backupContent == null && context.mounted) {
            context.showAccessibleMessage(
              'Failed to download backup from Google Drive',
              duration: const Duration(seconds: 3),
            );
            return;
          }

          // Restore the backup
          final success = await tankNotifier.restoreFromBackupData(backupContent!);

          if (context.mounted) {
            if (success) {
              // Save restore timestamp
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('last_restore_time', DateTime.now().toIso8601String());
              await prefs.setString('last_restore_location', 'google_drive');

              context.showAccessibleMessage(
                l10n.dataRestoredSuccess,
                duration: const Duration(seconds: 3),
              );

              // Log restore action
              AnalyticsService.logFeatureUsed(
                featureName: 'restore_from_google_drive',
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
    } catch (e) {
      if (context.mounted) {
        context.showAccessibleMessage(
          'Error accessing Google Drive: $e',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }
}

