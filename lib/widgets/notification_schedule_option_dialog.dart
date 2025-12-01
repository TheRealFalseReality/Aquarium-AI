import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/tank_notification.dart';

/// Options for scheduling a notification when activity logs exist
enum ScheduleOption {
  /// Schedule based on the specified date/time in the notification form
  useSpecifiedTime,
  /// Schedule based on the last logged activity
  useLastActivity,
}

/// Dialog to ask the user how they want to schedule a notification
/// when there are existing activity logs that match the notification type.
/// 
/// This dialog is shown when adding or editing a notification to let the user
/// choose whether the next notification should be based on:
/// - The date/time specified in the notification form
/// - The most recent activity log of the same type
class NotificationScheduleOptionDialog extends StatelessWidget {
  final TankNotification notification;

  const NotificationScheduleOptionDialog({
    super.key,
    required this.notification,
  });

  /// Show the dialog and return the selected option
  static Future<ScheduleOption?> show(
    BuildContext context,
    TankNotification notification,
  ) {
    return showDialog<ScheduleOption>(
      context: context,
      builder: (context) => NotificationScheduleOptionDialog(
        notification: notification,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final activityType = notification.getDisplayName();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.schedule, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.scheduleNotificationTitle,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.scheduleNotificationMessage(activityType),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // Option 1: Use specified time
          _buildOption(
            context,
            icon: Icons.access_time,
            iconColor: cs.primary,
            title: l10n.useSpecifiedTime,
            description: l10n.useSpecifiedTimeDescription,
            onTap: () => Navigator.of(context).pop(ScheduleOption.useSpecifiedTime),
          ),
          const SizedBox(height: 12),
          
          // Option 2: Use last activity
          _buildOption(
            context,
            icon: Icons.history,
            iconColor: cs.tertiary,
            title: l10n.useLastActivity,
            description: l10n.useLastActivityDescription,
            onTap: () => Navigator.of(context).pop(ScheduleOption.useLastActivity),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
