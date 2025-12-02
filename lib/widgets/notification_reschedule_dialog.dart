import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/tank_notification.dart';
import '../providers/app_settings_provider.dart' show rememberedRescheduleOptionKey;

/// Options for rescheduling a notification after logging an activity
enum RescheduleOption {
  /// Reschedule Date Only - same date as rescheduleFromNow but keeps original time
  keepOriginal,
  /// Reschedule from the current time/date - both date and time are based on now
  rescheduleFromNow,
  /// Don't reschedule - log the activity but keep existing notification schedule
  doNothing,
  /// Cancel - don't log the activity and don't reschedule
  cancelAll,
}

/// Result of the reschedule dialog containing the selected option and whether to remember it
class RescheduleDialogResult {
  final RescheduleOption option;
  final bool rememberChoice;

  RescheduleDialogResult({
    required this.option,
    required this.rememberChoice,
  });
}

/// Dialog to ask the user how they want to update a notification
/// after logging an activity that matches the notification type.
class NotificationRescheduleDialog extends StatefulWidget {
  final TankNotification notification;

  const NotificationRescheduleDialog({
    super.key,
    required this.notification,
  });

  /// Show the dialog and return the selected option
  /// If the user has a remembered preference, returns that directly
  static Future<RescheduleOption?> show(
    BuildContext context,
    TankNotification notification,
  ) async {
    // Check for remembered preference
    final prefs = await SharedPreferences.getInstance();
    final rememberedOptionIndex = prefs.getInt(rememberedRescheduleOptionKey);
    
    if (rememberedOptionIndex != null && 
        rememberedOptionIndex >= 0 && 
        rememberedOptionIndex < RescheduleOption.values.length) {
      // User has a remembered preference, return it directly
      return RescheduleOption.values[rememberedOptionIndex];
    }
    
    // No remembered preference, show the dialog
    if (!context.mounted) return null;
    
    final result = await showDialog<RescheduleDialogResult>(
      context: context,
      builder: (context) => NotificationRescheduleDialog(
        notification: notification,
      ),
    );
    
    if (result == null) return null;
    
    // Save the preference if requested
    if (result.rememberChoice) {
      await prefs.setInt(rememberedRescheduleOptionKey, result.option.index);
    }
    
    return result.option;
  }
  
  /// Clear the remembered reschedule option preference
  static Future<void> clearRememberedOption() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(rememberedRescheduleOptionKey);
  }
  
  /// Check if a reschedule option is currently remembered
  static Future<bool> hasRememberedOption() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(rememberedRescheduleOptionKey);
  }

  @override
  State<NotificationRescheduleDialog> createState() => _NotificationRescheduleDialogState();
}

class _NotificationRescheduleDialogState extends State<NotificationRescheduleDialog> {
  bool _rememberChoice = false;
  
  /// Get a formatted date and time string
  String _getFormattedDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('MMM d, y'); // e.g., "Dec 15, 2024"
    final timeFormat = DateFormat.jm(); // e.g., "2:30 PM"
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  void _selectOption(RescheduleOption option) {
    Navigator.of(context).pop(RescheduleDialogResult(
      option: option,
      rememberChoice: _rememberChoice,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final notificationName = widget.notification.getDisplayName();
    
    // Calculate the actual next dates for each option using the model's methods
    // "Reschedule Date Only" uses getNextNotificationDateFromBase with useCurrentTime: false
    //   → same date as "Reschedule Time & Date" but keeps original notification time
    // "Reschedule Time & Date" uses getNextNotificationDateFromBase with useCurrentTime: true
    //   → both date and time are based on now
    final nextDateWithOriginalTime = widget.notification.getNextNotificationDateFromBase(
      DateTime.now(), 
      useCurrentTime: false,  // Preserve original time
    );
    final nextDateWithCurrentTime = widget.notification.getNextNotificationDateFromBase(
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
    final rescheduleTimeAndDateDesc = widget.notification.repeatFrequency != RepeatFrequency.none
        ? currentDateTime
        : l10n.rescheduleFromNowDescription;
    
    final rescheduleDateOnlyDesc = widget.notification.repeatFrequency != RepeatFrequency.none
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
      content: SingleChildScrollView(
        child: Column(
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
              onTap: () => _selectOption(RescheduleOption.rescheduleFromNow),
            ),
            const SizedBox(height: 12),
            
            // Option 2: Reschedule Date Only (keeps original time)
            _buildOption(
              context,
              icon: Icons.schedule,
              iconColor: Colors.orange,
              title: l10n.rescheduleDateOnly,
              description: rescheduleDateOnlyDesc,
              onTap: () => _selectOption(RescheduleOption.keepOriginal),
            ),
            const SizedBox(height: 12),
            
            // Option 3: Don't Reschedule (log activity but keep existing schedule)
            _buildOption(
              context,
              icon: Icons.notifications_off,
              iconColor: Colors.grey,
              title: l10n.dontReschedule,
              description: l10n.dontRescheduleDescription,
              onTap: () => _selectOption(RescheduleOption.doNothing),
            ),
            const SizedBox(height: 12),
            
            // Option 4: Cancel (don't log activity and don't reschedule)
            _buildOption(
              context,
              icon: Icons.cancel_outlined,
              iconColor: Colors.red,
              title: l10n.cancelActivityLog,
              description: l10n.cancelActivityLogDescription,
              onTap: () => _selectOption(RescheduleOption.cancelAll),
            ),
            
            const SizedBox(height: 20),
            
            // Remember my choice checkbox
            InkWell(
              onTap: () {
                setState(() {
                  _rememberChoice = !_rememberChoice;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberChoice,
                      onChanged: (value) {
                        setState(() {
                          _rememberChoice = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        l10n.rememberMyChoice,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Settings hint text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.rememberChoiceSettingsHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
