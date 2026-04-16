import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/notification_log.dart';
import '../models/tank.dart';
import '../models/tank_notification.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../widgets/accessible_feedback.dart';
import '../widgets/notification_reschedule_dialog.dart';
import 'notification_management_screen.dart';

/// Global notification screen showing upcoming notifications across all tanks.
///
/// Accessible from the welcome screen feature card and the tank management
/// header. Supports quick-log and reschedule actions inline.
class GlobalNotificationsScreen extends ConsumerStatefulWidget {
  const GlobalNotificationsScreen({super.key});

  @override
  ConsumerState<GlobalNotificationsScreen> createState() =>
      _GlobalNotificationsScreenState();
}

class _GlobalNotificationsScreenState
    extends ConsumerState<GlobalNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'global_notifications_screen');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tankState = ref.watch(tankProvider);
    final tanks = tankState.tanks;

    // Collect all enabled notifications across all tanks, paired with their tank
    final List<_TankNotificationEntry> entries = [];
    for (final tank in tanks) {
      for (final notification in tank.notifications) {
        if (notification.enabled) {
          entries.add(_TankNotificationEntry(tank: tank, notification: notification));
        }
      }
    }

    // Sort by next scheduled date
    entries.sort((a, b) {
      final aDate = a.notification.getImmediateNextDate();
      final bDate = b.notification.getImmediateNextDate();
      return aDate.compareTo(bDate);
    });

    return MainLayout(
      title: l10n.allNotifications,
      child: entries.isEmpty
          ? _buildEmptyState(context, tanks.isEmpty)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _buildNotificationCard(context, entry);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool noTanks) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noUpcomingNotifications,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              noTanks
                  ? l10n.globalNotificationsNoTanksDescription
                  : l10n.globalNotificationsEmptyDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    _TankNotificationEntry entry,
  ) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final notification = entry.notification;
    final tank = entry.tank;
    final dateFormat = DateFormat('MMM d, y h:mm a');
    final DateTime displayDate = notification.getImmediateNextDate();
    final now = DateTime.now();
    final isOverdue = displayDate.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NotificationManagementScreen(tank: tank),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tank name label
              Row(
                children: [
                  Icon(Icons.water, size: 14, color: cs.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      tank.name,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Notification info
              Row(
                children: [
                  Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.customTitle ??
                              notification.getDisplayName(),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(displayDate),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isOverdue
                                    ? cs.error
                                    : cs.onSurface.withOpacity(0.6),
                                fontWeight: isOverdue
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (notification.notes != null &&
                  notification.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (notification.repeatFrequency != RepeatFrequency.none)
                    Chip(
                      label: Text(
                        _getRepeatText(notification),
                        style: const TextStyle(fontSize: 12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (isOverdue)
                    Chip(
                      label: Text(
                        l10n.overdue,
                        style: TextStyle(fontSize: 12, color: cs.onError),
                      ),
                      backgroundColor: cs.error,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    Builder(
                      builder: (context) {
                        final timeText = _getTimeFromNow(displayDate);
                        if (timeText == null) return const SizedBox.shrink();
                        return Chip(
                          label: Text(
                            timeText,
                            style: const TextStyle(fontSize: 12),
                          ),
                          avatar: const Icon(Icons.schedule, size: 16),
                          backgroundColor: cs.secondaryContainer,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons: Quick Log + Reschedule
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _quickLog(entry),
                      icon: const Icon(Icons.add_task, size: 18),
                      label: Text(l10n.quickLog),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            _getNotificationColor(notification.type),
                        side: BorderSide(
                          color: _getNotificationColor(notification.type)
                              .withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reschedule(entry),
                      icon: const Icon(Icons.update, size: 18),
                      label: Text(l10n.reschedule),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(
                          color: cs.primary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick log an activity for a notification
  Future<void> _quickLog(_TankNotificationEntry entry) async {
    final notification = entry.notification;
    final notificationService = NotificationService();

    // Get latest tank state from provider
    final currentTank = ref
        .read(tankProvider)
        .tanks
        .firstWhere((t) => t.id == entry.tank.id, orElse: () => entry.tank);

    final log = NotificationLog.create(
      type: notification.type,
      customCategory: notification.type == NotificationType.other
          ? (notification.customCategory ?? 'Other')
          : null,
      notes: notification.notes,
      notificationId: notification.id,
    );

    final updatedLogs = [...currentTank.notificationLogs, log];

    final updatedNotifications = await notificationService
        .rescheduleMatchingNotifications(
          tankId: currentTank.id,
          tankName: currentTank.name,
          notifications: currentTank.notifications,
          activityLogs: updatedLogs,
          activityType: log.type,
          activityCustomCategory: log.customCategory,
        );

    var updatedTank = currentTank.copyWith(
      notificationLogs: updatedLogs,
      updatedAt: DateTime.now(),
    );

    if (updatedNotifications.isNotEmpty) {
      final notificationsList = updatedTank.notifications.map((n) {
        final updated = updatedNotifications.firstWhere(
          (u) => u.id == n.id,
          orElse: () => n,
        );
        return updated;
      }).toList();
      updatedTank = updatedTank.copyWith(notifications: notificationsList);
    }

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showAccessibleMessage(l10n.activityLogged);
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'quick_log_from_global_notifications',
      parameters: {'type': notification.type.name},
    );
  }

  /// Reschedule a notification via the reschedule dialog
  Future<void> _reschedule(_TankNotificationEntry entry) async {
    final notification = entry.notification;

    final option = await NotificationRescheduleDialog.show(
      context,
      notification,
    );

    if (option == null || !mounted) return;

    final notificationService = NotificationService();
    final currentTank = ref
        .read(tankProvider)
        .tanks
        .firstWhere((t) => t.id == entry.tank.id, orElse: () => entry.tank);

    TankNotification updatedNotification;
    switch (option) {
      case RescheduleOption.rescheduleFromNow:
        final nextDate = notification.getNextNotificationDateFromBase(
          DateTime.now(),
          useCurrentTime: true,
        );
        updatedNotification = notification.copyWith(
          scheduledNextDate: nextDate,
          updatedAt: DateTime.now(),
        );
        break;
      case RescheduleOption.keepOriginal:
        final nextDate = notification.getNextNotificationDateFromBase(
          DateTime.now(),
          useCurrentTime: false,
        );
        updatedNotification = notification.copyWith(
          scheduledNextDate: nextDate,
          updatedAt: DateTime.now(),
        );
        break;
      case RescheduleOption.doNothing:
      case RescheduleOption.cancelAll:
        return;
    }

    final updatedNotifications = currentTank.notifications
        .map((n) => n.id == notification.id ? updatedNotification : n)
        .toList();

    final updatedTank = currentTank.copyWith(
      notifications: updatedNotifications,
      updatedAt: DateTime.now(),
    );

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    await notificationService.scheduleNotification(
      tankId: currentTank.id,
      tankName: currentTank.name,
      notification: updatedNotification,
      activityLogs: currentTank.notificationLogs,
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showAccessibleMessage(l10n.notificationUpdated);
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'reschedule_from_global_notifications',
      parameters: {
        'type': notification.type.name,
        'option': option.name,
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
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

  Color _getNotificationColor(NotificationType type) {
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

  String _getRepeatText(TankNotification notification) {
    final l10n = AppLocalizations.of(context)!;

    if (notification.repeatInterval == 1) {
      return notification.repeatFrequency.displayName;
    }

    final String unitName;
    switch (notification.repeatFrequency) {
      case RepeatFrequency.daily:
        unitName = l10n.days;
        break;
      case RepeatFrequency.weekly:
        unitName = l10n.weeks;
        break;
      case RepeatFrequency.monthly:
        unitName = l10n.months;
        break;
      case RepeatFrequency.yearly:
        unitName = l10n.years;
        break;
      default:
        return notification.repeatFrequency.displayName;
    }

    return l10n.everyXDays(notification.repeatInterval, unitName);
  }

  String? _getTimeFromNow(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    final l10n = AppLocalizations.of(context)!;

    if (difference.isNegative) return null;

    final days = difference.inDays;
    final hours = difference.inHours;
    final minutes = difference.inMinutes;

    if (days > 0) {
      if (days == 1) return l10n.inLessThan2Days;
      return l10n.inXDays(days);
    } else if (hours > 0) {
      if (hours == 1) return l10n.inLessThan2Hours;
      return l10n.inXHours(hours);
    } else if (minutes > 0) {
      if (minutes == 1) return l10n.inOneMinute;
      return l10n.inXMinutes(minutes);
    } else {
      return l10n.inLessThanAMinute;
    }
  }
}

/// Pairs a notification with its parent tank for display and actions.
class _TankNotificationEntry {
  final Tank tank;
  final TankNotification notification;

  const _TankNotificationEntry({
    required this.tank,
    required this.notification,
  });
}
