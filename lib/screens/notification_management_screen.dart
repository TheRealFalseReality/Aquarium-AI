import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/tank.dart';
import '../models/tank_notification.dart';
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
            Text(AppLocalizations.of(context)!.notifications),
            Text(
              currentTank.name,
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
                          notification.customTitle ?? notification.type.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(notification.notificationDateTime),
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
                if (notification.getNextNotificationDate() != null && notification.enabled)
                  Chip(
                    label: Text(
                      _getTimeFromNow(notification.getNextNotificationDate()!),
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(Icons.schedule, size: 16),
                    backgroundColor: colorScheme.secondaryContainer,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _getRepeatText(TankNotification notification) {
    if (notification.repeatInterval == 1) {
      return notification.repeatFrequency.displayName;
    }
    
    // Get the appropriate unit name based on frequency
    final String unitName;
    switch (notification.repeatFrequency) {
      case RepeatFrequency.daily:
        unitName = 'days';
        break;
      case RepeatFrequency.weekly:
        unitName = 'weeks';
        break;
      case RepeatFrequency.monthly:
        unitName = 'months';
        break;
      case RepeatFrequency.yearly:
        unitName = 'years';
        break;
      default:
        return notification.repeatFrequency.displayName;
    }
    
    return 'Every ${notification.repeatInterval} $unitName';
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
    final updatedNotification = notification.copyWith(
      enabled: enabled,
      updatedAt: DateTime.now(),
    );

    final updatedNotifications = widget.tank.notifications
        .map((n) => n.id == notification.id ? updatedNotification : n)
        .toList();

    final updatedTank = widget.tank.copyWith(
      notifications: updatedNotifications,
      updatedAt: DateTime.now(),
    );

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    // Schedule or cancel notification
    if (enabled) {
      await _notificationService.scheduleNotification(
        tankId: widget.tank.id,
        tankName: widget.tank.name,
        notification: updatedNotification,
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
    final updatedNotifications = widget.tank.notifications
        .where((n) => n.id != notification.id)
        .toList();

    final updatedTank = widget.tank.copyWith(
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
  final NotificationService _notificationService = NotificationService();

  late NotificationType _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late RepeatFrequency _repeatFrequency;
  late int _repeatInterval;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    
    if (widget.existingNotification != null) {
      final notif = widget.existingNotification!;
      _selectedType = notif.type;
      _selectedDate = notif.notificationDateTime;
      _selectedTime = TimeOfDay.fromDateTime(notif.notificationDateTime);
      _repeatFrequency = notif.repeatFrequency;
      _repeatInterval = notif.repeatInterval;
      _enabled = notif.enabled;
      _notesController.text = notif.notes ?? '';
      _titleController.text = notif.customTitle ?? '';
    } else {
      _selectedType = NotificationType.feeding;
      final now = DateTime.now();
      _selectedDate = now;
      _selectedTime = TimeOfDay.fromDateTime(now);
      _repeatFrequency = RepeatFrequency.none;
      _repeatInterval = 1;
      _enabled = true;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _titleController.dispose();
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
                              setState(() => _selectedType = type);
                            }
                          },
                        );
                      }).toList(),
                    ),
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
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
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

  Future<void> _saveNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    // Combine date and time
    final notificationDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final TankNotification notification;
    if (widget.existingNotification != null) {
      // Update existing notification
      notification = widget.existingNotification!.copyWith(
        type: _selectedType,
        notificationDateTime: notificationDateTime,
        repeatFrequency: _repeatFrequency,
        repeatInterval: _repeatInterval,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        customTitle: _titleController.text.isEmpty ? null : _titleController.text,
        enabled: _enabled,
        updatedAt: DateTime.now(),
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
        enabled: _enabled,
      );
    }

    // Update tank with new/updated notification
    final updatedNotifications = widget.existingNotification != null
        ? widget.tank.notifications
            .map((n) => n.id == notification.id ? notification : n)
            .toList()
        : [...widget.tank.notifications, notification];

    final updatedTank = widget.tank.copyWith(
      notifications: updatedNotifications,
      updatedAt: DateTime.now(),
    );

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    // Schedule notification if enabled
    if (_enabled) {
      await _notificationService.scheduleNotification(
        tankId: widget.tank.id,
        tankName: widget.tank.name,
        notification: notification,
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
