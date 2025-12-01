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
  
  /// Calculate the next notification date using the original time
  DateTime _getNextDateWithOriginalTime() {
    final now = DateTime.now();
    final originalTime = notification.notificationDateTime;
    
    // Base date is today with the original notification time
    var nextDate = DateTime(
      now.year,
      now.month,
      now.day,
      originalTime.hour,
      originalTime.minute,
    );
    
    // Add the interval based on frequency
    switch (notification.repeatFrequency) {
      case RepeatFrequency.daily:
        nextDate = nextDate.add(Duration(days: notification.repeatInterval));
        break;
      case RepeatFrequency.weekly:
        nextDate = nextDate.add(Duration(days: 7 * notification.repeatInterval));
        break;
      case RepeatFrequency.monthly:
        nextDate = DateTime(
          nextDate.year,
          nextDate.month + notification.repeatInterval,
          nextDate.day,
          nextDate.hour,
          nextDate.minute,
        );
        break;
      case RepeatFrequency.yearly:
        nextDate = DateTime(
          nextDate.year + notification.repeatInterval,
          nextDate.month,
          nextDate.day,
          nextDate.hour,
          nextDate.minute,
        );
        break;
      case RepeatFrequency.none:
        break;
    }
    
    return nextDate;
  }
  
  /// Calculate the next notification date using the current time
  DateTime _getNextDateWithCurrentTime() {
    final now = DateTime.now();
    var nextDate = now;
    
    // Add the interval based on frequency
    switch (notification.repeatFrequency) {
      case RepeatFrequency.daily:
        nextDate = nextDate.add(Duration(days: notification.repeatInterval));
        break;
      case RepeatFrequency.weekly:
        nextDate = nextDate.add(Duration(days: 7 * notification.repeatInterval));
        break;
      case RepeatFrequency.monthly:
        nextDate = DateTime(
          nextDate.year,
          nextDate.month + notification.repeatInterval,
          nextDate.day,
          nextDate.hour,
          nextDate.minute,
        );
        break;
      case RepeatFrequency.yearly:
        nextDate = DateTime(
          nextDate.year + notification.repeatInterval,
          nextDate.month,
          nextDate.day,
          nextDate.hour,
          nextDate.minute,
        );
        break;
      case RepeatFrequency.none:
        break;
    }
    
    return nextDate;
  }
  
  /// Get a formatted date and time string
  String _getFormattedDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('MMM d, y'); // e.g., "Dec 15, 2024"
    final timeFormat = DateFormat.jm(); // e.g., "2:30 PM"
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final notificationName = notification.getDisplayName();
    
    // Calculate the actual next dates for each option
    final nextDateWithOriginalTime = _getNextDateWithOriginalTime();
    final nextDateWithCurrentTime = _getNextDateWithCurrentTime();
    
    // Format dates with full date and time
    final originalDateTime = _getFormattedDateTime(nextDateWithOriginalTime);
    final currentDateTime = _getFormattedDateTime(nextDateWithCurrentTime);
    
    // Build the description strings with the actual calculated dates
    final rescheduleFromNowDesc = notification.repeatFrequency != RepeatFrequency.none
        ? currentDateTime
        : l10n.rescheduleFromNowDescription;
    
    final keepOriginalDesc = notification.repeatFrequency != RepeatFrequency.none
        ? originalDateTime
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
