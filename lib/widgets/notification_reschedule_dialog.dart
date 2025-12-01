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
    
    // Calculate the actual next dates for each option using the model's methods
    // "Reschedule Date Only" uses getNextNotificationDateFromBase with useCurrentTime: false
    //   → same date as "Reschedule Time & Date" but keeps original notification time
    // "Reschedule Time & Date" uses getNextNotificationDateFromBase with useCurrentTime: true
    //   → both date and time are based on now
    final nextDateWithOriginalTime = notification.getNextNotificationDateFromBase(
      DateTime.now(), 
      useCurrentTime: false,  // Preserve original time
    );
    final nextDateWithCurrentTime = notification.getNextNotificationDateFromBase(
      DateTime.now(), 
      useCurrentTime: true,   // Use current time
    );
    
    // Format dates with full date and time
    final originalTimeDateTime = nextDateWithOriginalTime != null 
        ? _getFormattedDateTime(nextDateWithOriginalTime)
        : l10n.rescheduleFromOriginalDescription;
    final currentDateTime = nextDateWithCurrentTime != null 
        ? _getFormattedDateTime(nextDateWithCurrentTime)
        : l10n.rescheduleFromNowDescription;
    
    // Build the description strings with the actual calculated dates
    final rescheduleTimeAndDateDesc = notification.repeatFrequency != RepeatFrequency.none
        ? currentDateTime
        : l10n.rescheduleFromNowDescription;
    
    final rescheduleDateOnlyDesc = notification.repeatFrequency != RepeatFrequency.none
        ? originalTimeDateTime
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
          
          // Option 1: Reschedule Time & Date (uses current time)
          _buildOption(
            context,
            icon: Icons.update,
            iconColor: Colors.blue,
            title: l10n.rescheduleTimeAndDate,
            description: rescheduleTimeAndDateDesc,
            onTap: () => Navigator.of(context).pop(RescheduleOption.rescheduleFromNow),
          ),
          const SizedBox(height: 12),
          
          // Option 2: Reschedule Date Only (keeps original time)
          _buildOption(
            context,
            icon: Icons.schedule,
            iconColor: Colors.orange,
            title: l10n.rescheduleDateOnly,
            description: rescheduleDateOnlyDesc,
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
