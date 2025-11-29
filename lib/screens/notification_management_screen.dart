import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/tank.dart';
import '../models/tank_notification.dart';
import '../models/notification_log.dart';
import '../providers/tank_provider.dart';
import '../services/notification_service.dart';
import '../widgets/accessible_feedback.dart';
import '../services/analytics_service.dart';
import '../l10n/app_localizations.dart';

class NotificationManagementScreen extends ConsumerStatefulWidget {
  final Tank tank;

  const NotificationManagementScreen({
    super.key,
    required this.tank,
  });

  @override
  ConsumerState<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends ConsumerState<NotificationManagementScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _checkNotificationPermissions();
  }

  /// Get the current tank state from the provider to avoid race conditions.
  /// 
  /// This method always fetches the latest tank state from the provider rather than
  /// using widget.tank, which is a snapshot from when the widget was created.
  /// This prevents race conditions where concurrent notification operations could
  /// overwrite each other's changes.
  /// 
  /// Falls back to widget.tank if the tank is not found in the provider, which could
  /// happen if the tank was deleted while this screen is still open. In practice,
  /// this fallback ensures the app doesn't crash, though the subsequent update
  /// operation would fail gracefully since the tank doesn't exist.
  Tank _getCurrentTank() {
    return ref.read(tankProvider).tanks
        .firstWhere((t) => t.id == widget.tank.id, orElse: () => widget.tank);
  }

  Future<void> _checkNotificationPermissions() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    if (!enabled && mounted) {
      _showPermissionDialog();
      return;
    }
    
    // Check if exact alarms are allowed (required for scheduled notifications)
    final canScheduleExact = await _notificationService.canScheduleExactNotifications();
    if (!canScheduleExact && mounted) {
      _showExactAlarmPermissionDialog();
    }
  }
  
  void _showExactAlarmPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.alarm, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.exactAlarmPermission),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.exactAlarmPermissionMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.maybeLater),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _notificationService.requestPermissions();
            },
            child: Text(AppLocalizations.of(context)!.grantPermission),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_off, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.enableNotifications),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.notificationPermissionMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.maybeLater),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _notificationService.requestPermissions();
            },
            child: Text(AppLocalizations.of(context)!.enable),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Watch the tank provider to get real-time updates
    final currentTank = ref.watch(tankProvider).tanks
        .firstWhere((t) => t.id == widget.tank.id, orElse: () => widget.tank);
    final notifications = currentTank.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentTank.name,
            ),
            Text(
                AppLocalizations.of(context)!.notifications,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNotificationDialog(),
        icon: const Icon(Icons.add_alert),
        label: Text(AppLocalizations.of(context)!.addNotification),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noNotificationsYet,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noNotificationsDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(TankNotification notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, y h:mm a');
    
    // Get the current tank to access activity logs
    final currentTank = _getCurrentTank();
    
    // Get next notification date for display, considering activity logs
    DateTime displayDate;
    if (notification.repeatFrequency != RepeatFrequency.none) {
      displayDate = notification.getNextNotificationDateWithActivity(currentTank.notificationLogs) 
          ?? notification.notificationDateTime;
    } else {
      displayDate = notification.notificationDateTime;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditNotificationDialog(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          notification.customTitle ?? notification.getDisplayName(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(displayDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: notification.enabled,
                    onChanged: (value) => _toggleNotification(notification, value),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showNotificationOptions(notification),
                  ),
                ],
              ),
            if (notification.notes != null && notification.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  notification.notes!,
                  style: theme.textTheme.bodyMedium,
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
                if (notification.enabled)
                  Builder(
                    builder: (context) {
                      // Get the current tank to access activity logs
                      final currentTank = _getCurrentTank();
                      
                      // For repeating notifications, use activity-based calculation
                      // For non-repeating notifications, use notificationDateTime if it's in the future
                      final DateTime? nextDate;
                      if (notification.repeatFrequency != RepeatFrequency.none) {
                        nextDate = notification.getNextNotificationDateWithActivity(currentTank.notificationLogs);
                      } else {
                        // Non-repeating: show if scheduled time is in the future
                        nextDate = notification.notificationDateTime.isAfter(DateTime.now())
                            ? notification.notificationDateTime
                            : null;
                      }
                      
                      if (nextDate == null) return const SizedBox.shrink();
                      
                      return Chip(
                        label: Text(
                          _getTimeFromNow(nextDate),
                          style: const TextStyle(fontSize: 12),
                        ),
                        avatar: const Icon(Icons.schedule, size: 16),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Quick Log button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _quickLogActivity(notification),
                icon: const Icon(Icons.add_task, size: 18),
                label: Text(AppLocalizations.of(context)!.quickLog),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _getNotificationColor(notification.type),
                  side: BorderSide(color: _getNotificationColor(notification.type).withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _getRepeatText(TankNotification notification) {
    final l10n = AppLocalizations.of(context)!;
    
    if (notification.repeatInterval == 1) {
      return notification.repeatFrequency.displayName;
    }
    
    // Get the appropriate unit name based on frequency
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

  String _getTimeFromNow(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    final l10n = AppLocalizations.of(context)!;
    
    if (difference.isNegative) {
      return l10n.overdue;
    }
    
    final days = difference.inDays;
    final hours = difference.inHours;
    final minutes = difference.inMinutes;
    
    if (days > 0) {
      if (days == 1) {
        return l10n.inOneDay;
      }
      return l10n.inXDays(days);
    } else if (hours > 0) {
      if (hours == 1) {
        return l10n.inOneHour;
      }
      return l10n.inXHours(hours);
    } else if (minutes > 0) {
      if (minutes == 1) {
        return l10n.inOneMinute;
      }
      return l10n.inXMinutes(minutes);
    } else {
      return l10n.inLessThanAMinute;
    }
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

  Future<void> _toggleNotification(TankNotification notification, bool enabled) async {
    final currentTank = _getCurrentTank();
    
    final updatedNotification = notification.copyWith(
      enabled: enabled,
      updatedAt: DateTime.now(),
    );

    final updatedNotifications = currentTank.notifications
        .map((n) => n.id == notification.id ? updatedNotification : n)
        .toList();

    final updatedTank = currentTank.copyWith(
      notifications: updatedNotifications,
      updatedAt: DateTime.now(),
    );

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    // Schedule or cancel notification
    if (enabled) {
      // Schedule with activity logs for activity-based scheduling
      await _notificationService.scheduleNotification(
        tankId: currentTank.id,
        tankName: currentTank.name,
        notification: updatedNotification,
        activityLogs: currentTank.notificationLogs,
      );
    } else {
      await _notificationService.cancelNotification(updatedNotification);
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showAccessibleMessage(
        enabled ? l10n.notificationEnabled : l10n.notificationDisabled,
      );
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'toggle_notification',
      parameters: {'enabled': enabled, 'type': notification.type.name},
    );
  }

  /// Quick log an activity based on a notification
  Future<void> _quickLogActivity(TankNotification notification) async {
    final currentTank = _getCurrentTank();
    
    // Create a new log entry based on the notification type and custom category
    final log = NotificationLog.create(
      type: notification.type,
      customCategory: notification.type == NotificationType.other
          ? (notification.customCategory ?? 'Other')
          : null,
      notes: notification.notes,
      notificationId: notification.id,
    );
    
    final updatedLogs = [...currentTank.notificationLogs, log];
    final updatedTank = currentTank.copyWith(
      notificationLogs: updatedLogs,
      updatedAt: DateTime.now(),
    );
    
    await ref.read(tankProvider.notifier).updateTank(updatedTank);
    
    // Reschedule matching notifications based on the new activity
    await _notificationService.rescheduleMatchingNotifications(
      tankId: currentTank.id,
      tankName: currentTank.name,
      notifications: currentTank.notifications,
      activityLogs: updatedLogs,
      activityType: log.type,
      activityCustomCategory: log.customCategory,
    );
    
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showAccessibleMessage(l10n.activityLogged);
    }
    
    AnalyticsService.logFeatureUsed(
      featureName: 'quick_log_activity',
      parameters: {
        'type': notification.type.name,
        'has_custom_category': notification.customCategory != null ? 'true' : 'false',
      },
    );
    
    AnalyticsService.logTankAction(
      action: 'quick_log_activity',
      tankType: currentTank.type,
    );
  }

  void _showNotificationOptions(TankNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppLocalizations.of(context)!.edit),
              onTap: () {
                Navigator.pop(context);
                _showEditNotificationDialog(notification);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: Text(AppLocalizations.of(context)!.sendTestNotification),
              onTap: () {
                Navigator.pop(context);
                _sendTestNotification(notification);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteNotification(notification);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteNotification(TankNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteNotification),
        content: Text(AppLocalizations.of(context)!.deleteNotificationConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteNotification(notification);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNotification(TankNotification notification) async {
    final currentTank = _getCurrentTank();
    
    final updatedNotifications = currentTank.notifications
        .where((n) => n.id != notification.id)
        .toList();

    final updatedTank = currentTank.copyWith(
      notifications: updatedNotifications,
      updatedAt: DateTime.now(),
    );

    await ref.read(tankProvider.notifier).updateTank(updatedTank);
    await _notificationService.cancelNotification(notification);

    if (mounted) {
      context.showAccessibleMessage(AppLocalizations.of(context)!.notificationDeleted);
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'delete_notification',
      parameters: {'type': notification.type.name},
    );
  }

  Future<void> _sendTestNotification(TankNotification notification) async {
    // Send test notification immediately using the notification's type and custom settings
    await _notificationService.sendTestNotification(
      tankName: widget.tank.name,
      type: notification.type,
      customTitle: notification.customTitle,
      customBody: notification.notes,
    );

    if (mounted) {
      context.showAccessibleMessage(AppLocalizations.of(context)!.testNotificationSent);
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'send_test_notification',
      parameters: {'type': notification.type.name},
    );
  }

  void _showAddNotificationDialog() {
    _showNotificationDialog(null);
  }

  void _showEditNotificationDialog(TankNotification notification) {
    _showNotificationDialog(notification);
  }

  void _showNotificationDialog(TankNotification? existingNotification) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _NotificationFormScreen(
          tank: widget.tank,
          existingNotification: existingNotification,
        ),
      ),
    );
  }
}

class _NotificationFormScreen extends ConsumerStatefulWidget {
  final Tank tank;
  final TankNotification? existingNotification;

  const _NotificationFormScreen({
    required this.tank,
    this.existingNotification,
  });

  @override
  ConsumerState<_NotificationFormScreen> createState() =>
      _NotificationFormScreenState();
}

class _NotificationFormScreenState
    extends ConsumerState<_NotificationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _titleController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final NotificationService _notificationService = NotificationService();

  late NotificationType _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late RepeatFrequency _repeatFrequency;
  late int _repeatInterval;
  late bool _enabled;

  /// Get the current tank state from the provider to avoid race conditions.
  /// 
  /// This method always fetches the latest tank state from the provider rather than
  /// using widget.tank, which is a snapshot from when the widget was created.
  /// This prevents race conditions where concurrent notification operations could
  /// overwrite each other's changes.
  /// 
  /// Falls back to widget.tank if the tank is not found in the provider, which could
  /// happen if the tank was deleted while this screen is still open. In practice,
  /// this fallback ensures the app doesn't crash, though the subsequent update
  /// operation would fail gracefully since the tank doesn't exist.
  Tank _getCurrentTank() {
    return ref.read(tankProvider).tanks
        .firstWhere((t) => t.id == widget.tank.id, orElse: () => widget.tank);
  }

  @override
  void initState() {
    super.initState();
    
    if (widget.existingNotification != null) {
      // When editing, use the existing notification's date and time
      final notif = widget.existingNotification!;
      final notifDateTime = notif.notificationDateTime;
      _selectedDate = DateTime(notifDateTime.year, notifDateTime.month, notifDateTime.day);
      _selectedTime = TimeOfDay.fromDateTime(notifDateTime);
      _selectedType = notif.type;
      _repeatFrequency = notif.repeatFrequency;
      _repeatInterval = notif.repeatInterval;
      _enabled = notif.enabled;
      _notesController.text = notif.notes ?? '';
      _titleController.text = notif.customTitle ?? '';
      _customCategoryController.text = notif.customCategory ?? '';
    } else {
      // For new notifications, use today's date and time as the starting point
      final now = DateTime.now();
      // Store date as midnight to ensure consistent date-only comparison
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.fromDateTime(now);
      _selectedType = NotificationType.feeding;
      _repeatFrequency = RepeatFrequency.none;
      _repeatInterval = 1;
      _enabled = true;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _titleController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingNotification != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppLocalizations.of(context)!.editNotification : AppLocalizations.of(context)!.addNotification),
        actions: [
          TextButton(
            onPressed: _saveNotification,
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Notification Type
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notificationType,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NotificationType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Text(type.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedType = type;
                                // Clear custom category when switching away from "Other"
                                if (type != NotificationType.other) {
                                  _customCategoryController.clear();
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    // Custom category field for "Other" type
                    if (_selectedType == NotificationType.other) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customCategoryController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.customCategoryOptional,
                          hintText: AppLocalizations.of(context)!.customCategoryHint,
                          helperText: AppLocalizations.of(context)!.customCategoryHelper,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.category),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.dateAndTime,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              DateFormat('MMM d, y').format(_selectedDate),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_selectedTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Repeat Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.repeat,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RepeatFrequency>(
                      value: _repeatFrequency,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.frequency,
                        border: const OutlineInputBorder(),
                      ),
                      items: RepeatFrequency.values.map((freq) {
                        return DropdownMenuItem(
                          value: freq,
                          child: Text(freq.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _repeatFrequency = value);
                        }
                      },
                    ),
                    if (_repeatFrequency != RepeatFrequency.none) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _repeatInterval.toString(),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.repeatEvery,
                          border: const OutlineInputBorder(),
                          suffixText: _repeatFrequency.name,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.enterInterval;
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 1) {
                            return AppLocalizations.of(context)!.enterValidNumber;
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _repeatInterval = int.parse(value!);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Custom Title
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.customTitleOptional,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.customTitleHint,
                        helperText: AppLocalizations.of(context)!.customTitleHelper,
                        border: const OutlineInputBorder(),
                      ),
                      maxLength: 50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.notesOptional,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.addNotesPlaceholder,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Enabled Switch
            Card(
              child: SwitchListTile(
                title: Text(AppLocalizations.of(context)!.enableNotification),
                subtitle: Text(AppLocalizations.of(context)!.receiveReminders),
                value: _enabled,
                onChanged: (value) {
                  setState(() => _enabled = value);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Test Notification Button
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.sendTestNotification,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.testNotificationDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _sendTestNotificationForPreview,
                      icon: const Icon(Icons.send),
                      label: Text(AppLocalizations.of(context)!.sendTestNotification),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    // Use the start of today (midnight) as firstDate to allow selecting any time today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Ensure initialDate is not before firstDate
    // Use today if _selectedDate is in the past, otherwise use _selectedDate
    final initialDate = _selectedDate.isBefore(today) ? today : _selectedDate;
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 10)),
    );

    if (date != null) {
      // Normalize to midnight to ensure consistent date-only storage
      setState(() => _selectedDate = DateTime(date.year, date.month, date.day));
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _sendTestNotificationForPreview() async {
    // Send test notification with current form settings
    await _notificationService.sendTestNotification(
      tankName: widget.tank.name,
      type: _selectedType,
      customTitle: _titleController.text.isNotEmpty ? _titleController.text : null,
      customBody: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (mounted) {
      context.showAccessibleMessage(AppLocalizations.of(context)!.testNotificationSent);
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'send_test_notification_preview',
      parameters: {'type': _selectedType.name},
    );
  }

  Future<void> _saveNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    final currentTank = _getCurrentTank();
    
    // Capture current time once to avoid race conditions
    final now = DateTime.now();

    // Combine date and time
    final notificationDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Check if the selected date/time is in the past
    if (notificationDateTime.isBefore(now)) {
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        AccessibleFeedback.showMessage(
          context,
          message: AppLocalizations.of(context)!.dateTimeInPast,
          backgroundColor: colorScheme.error,
          textColor: colorScheme.onError,
        );
      }
      return;
    }

    final TankNotification notification;
    
    // Get custom category for 'other' type, defaulting to 'Other' if empty
    final trimmedCustomCategory = _customCategoryController.text.trim();
    final customCategory = _selectedType == NotificationType.other
        ? (trimmedCustomCategory.isNotEmpty ? trimmedCustomCategory : 'Other')
        : null;
    
    if (widget.existingNotification != null) {
      // Update existing notification
      // Use clear flags to explicitly set notes/title to null when empty
      final notesIsEmpty = _notesController.text.isEmpty;
      final titleIsEmpty = _titleController.text.isEmpty;
      
      notification = widget.existingNotification!.copyWith(
        type: _selectedType,
        notificationDateTime: notificationDateTime,
        repeatFrequency: _repeatFrequency,
        repeatInterval: _repeatInterval,
        notes: notesIsEmpty ? null : _notesController.text,
        customTitle: titleIsEmpty ? null : _titleController.text,
        customCategory: customCategory,
        enabled: _enabled,
        updatedAt: DateTime.now(),
        clearNotes: notesIsEmpty && widget.existingNotification!.notes != null,
        clearCustomTitle: titleIsEmpty && widget.existingNotification!.customTitle != null,
      );
    } else {
      // Create new notification
      notification = TankNotification.create(
        type: _selectedType,
        notificationDateTime: notificationDateTime,
        repeatFrequency: _repeatFrequency,
        repeatInterval: _repeatInterval,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        customTitle: _titleController.text.isEmpty ? null : _titleController.text,
        customCategory: customCategory,
        enabled: _enabled,
      );
    }

    // Update tank with new/updated notification using current tank state
    final updatedNotifications = widget.existingNotification != null
        ? currentTank.notifications
            .map((n) => n.id == notification.id ? notification : n)
            .toList()
        : [...currentTank.notifications, notification];

    final updatedTank = currentTank.copyWith(
      notifications: updatedNotifications,
      updatedAt: DateTime.now(),
    );

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    // Schedule notification if enabled, using activity logs for activity-based scheduling
    if (_enabled) {
      await _notificationService.scheduleNotification(
        tankId: currentTank.id,
        tankName: currentTank.name,
        notification: notification,
        activityLogs: currentTank.notificationLogs,
      );
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showAccessibleMessage(
        widget.existingNotification != null
            ? l10n.notificationUpdated
            : l10n.notificationAdded,
      );
      Navigator.of(context).pop();

      AnalyticsService.logFeatureUsed(
        featureName: widget.existingNotification != null
            ? 'edit_notification'
            : 'add_notification',
        parameters: {
          'type': _selectedType.name,
          'repeat': _repeatFrequency.name,
        },
      );
    }
  }
}
