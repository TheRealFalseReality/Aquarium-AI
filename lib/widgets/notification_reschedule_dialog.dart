import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  /// Get the interval text based on the notification's repeat frequency and interval
  String _getIntervalText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final interval = notification.repeatInterval;
    
    switch (notification.repeatFrequency) {
      case RepeatFrequency.daily:
        if (interval == 1) {
          return l10n.oneDay;
        }
        return l10n.xDays(interval);
      case RepeatFrequency.weekly:
        if (interval == 1) {
          return l10n.oneWeek;
        }
        return l10n.xWeeks(interval);
      case RepeatFrequency.monthly:
        if (interval == 1) {
          return l10n.oneMonth;
        }
        return l10n.xMonths(interval);
      case RepeatFrequency.yearly:
        if (interval == 1) {
          return l10n.oneYear;
        }
        return l10n.xYears(interval);
      case RepeatFrequency.none:
        return '';
    }
  }

  /// Get the formatted time string from the notification's original time
  String _getOriginalTimeString(BuildContext context) {
    final timeFormat = DateFormat.jm(); // e.g., "2:30 PM"
    return timeFormat.format(notification.notificationDateTime);
  }

  /// Get the formatted current time string
  String _getCurrentTimeString(BuildContext context) {
    final timeFormat = DateFormat.jm(); // e.g., "2:30 PM"
    return timeFormat.format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final notificationName = notification.getDisplayName();
    
    // Build dynamic descriptions based on the notification's frequency
    final intervalText = _getIntervalText(context);
    final originalTime = _getOriginalTimeString(context);
    final currentTime = _getCurrentTimeString(context);
    
    // Build the description strings
    final rescheduleFromNowDesc = intervalText.isNotEmpty
        ? l10n.rescheduleFromNowDescriptionDetailed(intervalText, currentTime)
        : l10n.rescheduleFromNowDescription;
    
    final keepOriginalDesc = intervalText.isNotEmpty
        ? l10n.rescheduleFromOriginalDescriptionDetailed(intervalText, originalTime)
        : l10n.rescheduleFromOriginalDescription;

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
            description: rescheduleFromNowDesc,
            onTap: () => Navigator.of(context).pop(RescheduleOption.rescheduleFromNow),
          ),
          const SizedBox(height: 12),
          
          // Option 2: Keep original schedule
          _buildOption(
            context,
            icon: Icons.schedule,
            iconColor: Colors.orange,
            title: l10n.rescheduleFromOriginal,
            description: keepOriginalDesc,
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
