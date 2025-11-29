import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/tank_notification.dart';

/// Options for rescheduling a notification after logging an activity
enum RescheduleOption {
  /// Keep the original notification schedule (based on notification's original date)
  keepOriginal,
  /// Reschedule from the current time/date
  rescheduleFromNow,
  /// Do not change the notification schedule
  doNothing,
}

/// Dialog to ask the user how they want to update a notification
/// after logging an activity that matches the notification type.
class NotificationRescheduleDialog extends StatelessWidget {
  final TankNotification notification;

  const NotificationRescheduleDialog({
    super.key,
    required this.notification,
  });

  /// Show the dialog and return the selected option
  static Future<RescheduleOption?> show(
    BuildContext context,
    TankNotification notification,
  ) {
    return showDialog<RescheduleOption>(
      context: context,
      builder: (context) => NotificationRescheduleDialog(
        notification: notification,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final notificationName = notification.getDisplayName();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications_active, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.updateNotificationTitle,
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
            l10n.updateNotificationMessage(notificationName),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // Option 1: Reschedule from now
          _buildOption(
            context,
            icon: Icons.update,
            iconColor: Colors.blue,
            title: l10n.rescheduleFromNow,
            description: l10n.rescheduleFromNowDescription,
            onTap: () => Navigator.of(context).pop(RescheduleOption.rescheduleFromNow),
          ),
          const SizedBox(height: 12),
          
          // Option 2: Keep original schedule
          _buildOption(
            context,
            icon: Icons.schedule,
            iconColor: Colors.orange,
            title: l10n.rescheduleFromOriginal,
            description: l10n.rescheduleFromOriginalDescription,
            onTap: () => Navigator.of(context).pop(RescheduleOption.keepOriginal),
          ),
          const SizedBox(height: 12),
          
          // Option 3: Do nothing
          _buildOption(
            context,
            icon: Icons.block,
            iconColor: Colors.grey,
            title: l10n.doNothing,
            description: l10n.doNothingDescription,
            onTap: () => Navigator.of(context).pop(RescheduleOption.doNothing),
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
