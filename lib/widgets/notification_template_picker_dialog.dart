// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/tank_notification.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Template data model
// ──────────────────────────────────────────────────────────────────────────────

/// A single entry in a notification template pack.
class _TemplateEntry {
  final NotificationType type;
  final RepeatFrequency frequency;
  final int interval;
  final TimeOfDay time;
  final String? customTitle;

  const _TemplateEntry({
    required this.type,
    required this.frequency,
    this.interval = 1,
    required this.time,
    this.customTitle,
  });

  TankNotification toNotification() {
    final now = DateTime.now();
    // Set first occurrence to tomorrow at the given time to avoid past-date errors.
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
      time.hour,
      time.minute,
    );
    return TankNotification.create(
      type: type,
      notificationDateTime: tomorrow,
      repeatFrequency: frequency,
      repeatInterval: interval,
      customTitle: customTitle,
      enabled: true,
      scheduledNextDate: tomorrow,
    );
  }
}

/// A pre-built pack of notifications.
class NotificationTemplatePack {
  final String Function(AppLocalizations) nameBuilder;
  final String Function(AppLocalizations) descBuilder;
  final List<_TemplateEntry> entries;

  const NotificationTemplatePack({
    required this.nameBuilder,
    required this.descBuilder,
    required this.entries,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Built-in template packs
// ──────────────────────────────────────────────────────────────────────────────

final List<NotificationTemplatePack> kNotificationTemplatePacks = [
  // 🐟 Freshwater Beginner
  NotificationTemplatePack(
    nameBuilder: (l10n) => l10n.templateFreshwaterBeginner,
    descBuilder: (l10n) => l10n.templateFreshwaterBeginnerDesc,
    entries: const [
      _TemplateEntry(
        type: NotificationType.feeding,
        frequency: RepeatFrequency.daily,
        time: TimeOfDay(hour: 8, minute: 0),
      ),
      _TemplateEntry(
        type: NotificationType.waterChange,
        frequency: RepeatFrequency.weekly,
        time: TimeOfDay(hour: 10, minute: 0),
      ),
      _TemplateEntry(
        type: NotificationType.testing,
        frequency: RepeatFrequency.weekly,
        time: TimeOfDay(hour: 10, minute: 30),
      ),
    ],
  ),
  // 🌊 Saltwater Starter
  NotificationTemplatePack(
    nameBuilder: (l10n) => l10n.templateSaltwaterStarter,
    descBuilder: (l10n) => l10n.templateSaltwaterStarterDesc,
    entries: const [
      _TemplateEntry(
        type: NotificationType.feeding,
        frequency: RepeatFrequency.daily,
        time: TimeOfDay(hour: 8, minute: 0),
      ),
      _TemplateEntry(
        type: NotificationType.waterChange,
        frequency: RepeatFrequency.daily,
        interval: 3, // every 3 days ≈ twice a week
        time: TimeOfDay(hour: 10, minute: 0),
      ),
      _TemplateEntry(
        type: NotificationType.testing,
        frequency: RepeatFrequency.weekly,
        time: TimeOfDay(hour: 10, minute: 30),
      ),
      _TemplateEntry(
        type: NotificationType.dosing,
        frequency: RepeatFrequency.weekly,
        time: TimeOfDay(hour: 9, minute: 0),
      ),
    ],
  ),
  // 🌿 Planted Tank
  NotificationTemplatePack(
    nameBuilder: (l10n) => l10n.templatePlantedTank,
    descBuilder: (l10n) => l10n.templatePlantedTankDesc,
    entries: const [
      _TemplateEntry(
        type: NotificationType.feeding,
        frequency: RepeatFrequency.daily,
        time: TimeOfDay(hour: 8, minute: 0),
      ),
      _TemplateEntry(
        type: NotificationType.dosing,
        frequency: RepeatFrequency.daily,
        time: TimeOfDay(hour: 9, minute: 0),
      ),
      _TemplateEntry(
        type: NotificationType.waterChange,
        frequency: RepeatFrequency.weekly,
        time: TimeOfDay(hour: 10, minute: 0),
      ),
      _TemplateEntry(
        type: NotificationType.maintenance,
        frequency: RepeatFrequency.monthly,
        time: TimeOfDay(hour: 11, minute: 0),
      ),
    ],
  ),
  // ⏰ Basic Care
  NotificationTemplatePack(
    nameBuilder: (l10n) => l10n.templateBasicCare,
    descBuilder: (l10n) => l10n.templateBasicCareDesc,
    entries: const [
      _TemplateEntry(
        type: NotificationType.feeding,
        frequency: RepeatFrequency.daily,
        time: TimeOfDay(hour: 8, minute: 0),
      ),
      _TemplateEntry(
        type: NotificationType.maintenance,
        frequency: RepeatFrequency.monthly,
        time: TimeOfDay(hour: 10, minute: 0),
      ),
    ],
  ),
];

// ──────────────────────────────────────────────────────────────────────────────
// Dialog
// ──────────────────────────────────────────────────────────────────────────────

/// Dialog for choosing a notification template pack.
///
/// Returns a list of [TankNotification] objects to add to the tank, or null if
/// the user cancels.  The caller is responsible for saving them.
class NotificationTemplatePickerDialog extends StatefulWidget {
  /// Whether the tank already has notifications.  When true, an add-or-replace
  /// prompt is shown before applying.
  final bool hasExistingNotifications;

  const NotificationTemplatePickerDialog({
    super.key,
    this.hasExistingNotifications = false,
  });

  /// Show the dialog and return the chosen notifications.
  ///
  /// [replaceExisting] is set to true if the user chose "Replace All".
  static Future<({List<TankNotification> notifications, bool replaceExisting})?> show(
    BuildContext context, {
    bool hasExistingNotifications = false,
  }) {
    return showDialog<({List<TankNotification> notifications, bool replaceExisting})>(
      context: context,
      builder: (_) => NotificationTemplatePickerDialog(
        hasExistingNotifications: hasExistingNotifications,
      ),
    );
  }

  @override
  State<NotificationTemplatePickerDialog> createState() =>
      _NotificationTemplatePickerDialogState();
}

class _NotificationTemplatePickerDialogState
    extends State<NotificationTemplatePickerDialog> {
  int? _selectedIndex;

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Icons.restaurant;
      case NotificationType.dosing:
        return Icons.medication_liquid;
      case NotificationType.waterChange:
        return Icons.water_drop;
      case NotificationType.testing:
        return Icons.science;
      case NotificationType.maintenance:
        return Icons.build;
      case NotificationType.other:
        return Icons.notifications;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Colors.orange;
      case NotificationType.dosing:
        return Colors.purple;
      case NotificationType.waterChange:
        return Colors.blue;
      case NotificationType.testing:
        return Colors.teal;
      case NotificationType.maintenance:
        return Colors.brown;
      case NotificationType.other:
        return Colors.grey;
    }
  }

  String _repeatText(_TemplateEntry entry, AppLocalizations l10n) {
    if (entry.interval == 1) {
      return entry.frequency.displayName;
    }
    // Reuse the existing everyXDays l10n string (e.g. "Every 3 daily")
    final unit = entry.frequency.name;
    return l10n.everyXDays(entry.interval, unit);
  }

  Future<void> _applyPack(AppLocalizations l10n) async {
    if (_selectedIndex == null) return;

    final pack = kNotificationTemplatePacks[_selectedIndex!];
    final notifications = pack.entries.map((e) => e.toNotification()).toList();

    bool replaceExisting = false;

    if (widget.hasExistingNotifications) {
      // Ask: add or replace?
      final choice = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.templateAddOrReplace),
          content: Text(l10n.templateAddOrReplaceDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.templateAddToExisting),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(l10n.templateReplaceAll),
            ),
          ],
        ),
      );
      if (choice == null) return; // user cancelled inner dialog
      replaceExisting = choice;
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      (notifications: notifications, replaceExisting: replaceExisting),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.notificationTemplates,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.notificationTemplatesDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Pack list
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: kNotificationTemplatePacks.length,
                itemBuilder: (context, index) {
                  final pack = kNotificationTemplatePacks[index];
                  final isSelected = _selectedIndex == index;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? cs.primary
                            : cs.outlineVariant.withOpacity(0.4),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    color: isSelected
                        ? cs.primaryContainer.withOpacity(0.3)
                        : null,
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isSelected)
                                  Icon(Icons.check_circle, color: cs.primary, size: 20)
                                else
                                  Icon(
                                    Icons.radio_button_unchecked,
                                    color: cs.outlineVariant,
                                    size: 20,
                                  ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    pack.nameBuilder(l10n),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Text(
                                pack.descBuilder(l10n),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.templatePreviewLabel,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    ...pack.entries.map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _iconForType(entry.type),
                                              size: 14,
                                              color: _colorForType(entry.type),
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                '${entry.type.displayName} — ${_repeatText(entry, l10n)}'
                                                ' at ${DateFormat.jm().format(DateTime(0, 0, 0, entry.time.hour, entry.time.minute))}',
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectedIndex != null
                        ? () => _applyPack(l10n)
                        : null,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(l10n.applyTemplate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
