// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/notification_log.dart';
import '../models/tank.dart';
import '../models/tank_notification.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../widgets/accessible_feedback.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Data helpers
// ──────────────────────────────────────────────────────────────────────────────

/// A flat entry pairing a [TankNotification] with its parent [Tank].
class _DashboardEntry {
  final Tank tank;
  final TankNotification notification;

  const _DashboardEntry({required this.tank, required this.notification});

  DateTime get nextDate => notification.getImmediateNextDate();
}

/// How each dashboard entry is bucketed by urgency.
enum _DashboardGroup { overdue, dueToday, thisWeek, upcoming }

_DashboardGroup _groupForEntry(_DashboardEntry e) {
  final now = DateTime.now();
  final next = e.nextDate;
  if (next.isBefore(now)) return _DashboardGroup.overdue;
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
  if (!next.isAfter(endOfToday)) return _DashboardGroup.dueToday;
  final endOfWeek = now.add(const Duration(days: 7));
  if (!next.isAfter(endOfWeek)) return _DashboardGroup.thisWeek;
  return _DashboardGroup.upcoming;
}

// ──────────────────────────────────────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────────────────────────────────────

class NotificationDashboardScreen extends ConsumerStatefulWidget {
  const NotificationDashboardScreen({super.key});

  @override
  ConsumerState<NotificationDashboardScreen> createState() =>
      _NotificationDashboardScreenState();
}

class _NotificationDashboardScreenState
    extends ConsumerState<NotificationDashboardScreen>
    with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.logScreenView(screenName: 'notification_dashboard_screen');
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() => _notificationsEnabled = enabled);
    }
  }

  Future<void> _requestPermissions() async {
    await _notificationService.requestPermissions();
    await _checkPermissions();
  }

  Future<void> _resyncAll() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final tanks = ref.read(tankProvider).tanks;
      await _notificationService.resyncAllTankNotifications(tanks: tanks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.resyncReminders),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      AnalyticsService.logFeatureUsed(featureName: 'resync_all_notifications');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _quickLogDone(_DashboardEntry entry) async {
    final currentTank = ref.read(tankProvider).tanks.firstWhere(
      (t) => t.id == entry.tank.id,
      orElse: () => entry.tank,
    );

    final log = NotificationLog.create(
      type: entry.notification.type,
      customCategory: entry.notification.type == NotificationType.other
          ? (entry.notification.customCategory ?? 'Other')
          : null,
      notificationId: entry.notification.id,
    );

    final updatedLogs = [...currentTank.notificationLogs, log];

    final updatedNotifications =
        await _notificationService.rescheduleMatchingNotifications(
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
      final notifList = updatedTank.notifications.map((n) {
        return updatedNotifications.firstWhere(
          (u) => u.id == n.id,
          orElse: () => n,
        );
      }).toList();
      updatedTank = updatedTank.copyWith(notifications: notifList);
    }

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    if (mounted) {
      context.showAccessibleMessage(
        AppLocalizations.of(context)!.activityLogged,
      );
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'dashboard_quick_log_done',
      parameters: {'type': entry.notification.type.name},
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tanks = ref.watch(tankProvider).tanks;

    // Gather all notifications across all tanks (enabled only for dashboard).
    final allEntries = <_DashboardEntry>[];
    for (final tank in tanks) {
      for (final notif in tank.notifications) {
        allEntries.add(_DashboardEntry(tank: tank, notification: notif));
      }
    }

    // Sort by next date.
    allEntries.sort((a, b) => a.nextDate.compareTo(b.nextDate));

    // Group.
    final groups = <_DashboardGroup, List<_DashboardEntry>>{};
    for (final entry in allEntries) {
      groups.putIfAbsent(_groupForEntry(entry), () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationDashboard),
      ),
      body: Column(
        children: [
          // Permission warning banner
          if (!_notificationsEnabled)
            _buildPermissionBanner(l10n),
          // Content
          Expanded(
            child: allEntries.isEmpty
                ? _buildEmptyState(l10n)
                : _buildGroupedList(l10n, groups),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSyncing ? null : _resyncAll,
        tooltip: l10n.resyncReminders,
        child: _isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync),
      ),
    );
  }

  Widget _buildPermissionBanner(AppLocalizations l10n) {
    return MaterialBanner(
      content: Flexible(
        child: Text(l10n.notificationsPermissionBanner),
      ),
      actions: [
        TextButton(
          onPressed: _requestPermissions,
          child: Text(l10n.enable),
        ),
      ],
      backgroundColor:
          Theme.of(context).colorScheme.errorContainer.withOpacity(0.6),
      contentTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
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
              l10n.noNotificationsAcrossTanks,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noNotificationsAcrossTanksDesc,
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

  Widget _buildGroupedList(
    AppLocalizations l10n,
    Map<_DashboardGroup, List<_DashboardEntry>> groups,
  ) {
    final orderedGroups = [
      _DashboardGroup.overdue,
      _DashboardGroup.dueToday,
      _DashboardGroup.thisWeek,
      _DashboardGroup.upcoming,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        for (final group in orderedGroups)
          if (groups.containsKey(group)) ...[
            _buildGroupHeader(l10n, group),
            const SizedBox(height: 4),
            ...groups[group]!.map(
              (entry) => _buildEntryCard(l10n, entry, group),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildGroupHeader(AppLocalizations l10n, _DashboardGroup group) {
    final (label, color) = switch (group) {
      _DashboardGroup.overdue => (l10n.overdueGroup, Colors.red),
      _DashboardGroup.dueToday => (l10n.dueTodayGroup, Colors.orange),
      _DashboardGroup.thisWeek => (l10n.thisWeekGroup, Colors.amber.shade700),
      _DashboardGroup.upcoming => (
        l10n.upcomingGroup,
        Theme.of(context).colorScheme.primary,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(
    AppLocalizations l10n,
    _DashboardEntry entry,
    _DashboardGroup group,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final notif = entry.notification;
    final isEnabled = notif.enabled;
    final dateFormat = DateFormat('MMM d, y h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForType(notif.type),
                  color: _colorForType(notif.type),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.customTitle ?? notif.getDisplayName(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? null : cs.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        entry.tank.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isEnabled)
                  Chip(
                    label: Text(
                      l10n.notificationDisabled,
                      style: const TextStyle(fontSize: 11),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Next date
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    dateFormat.format(entry.nextDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: group == _DashboardGroup.overdue
                          ? Colors.red
                          : cs.onSurfaceVariant,
                      fontWeight: group == _DashboardGroup.overdue
                          ? FontWeight.bold
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            // Smart last-activity insight
            _buildSmartInsight(l10n, entry),
            const SizedBox(height: 10),
            // Log Done button (only for enabled notifications)
            if (isEnabled)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => _quickLogDone(entry),
                  icon: const Icon(Icons.task_alt, size: 16),
                  label: Text(l10n.logDone),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the smart "last X on date → next suggested date" insight row.
  Widget _buildSmartInsight(AppLocalizations l10n, _DashboardEntry entry) {
    final tank = ref.watch(tankProvider).tanks.firstWhere(
      (t) => t.id == entry.tank.id,
      orElse: () => entry.tank,
    );
    final logs = tank.notificationLogs;
    final notif = entry.notification;

    // Find the most recent matching activity log.
    final matchingLogs = logs
        .where((log) => notif.matchesActivityLog(log.type, log.customCategory))
        .toList();

    if (matchingLogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l10n.noActivityLoggedYet,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    matchingLogs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final lastLog = matchingLogs.first;
    final dateFormat = DateFormat('MMM d');
    final lastDateStr = dateFormat.format(lastLog.loggedAt);
    final typeName = notif.getDisplayName().toLowerCase();

    final nextSuggested = notif.getNextNotificationDateWithActivity(logs);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                size: 13,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.lastActivityOn(typeName, lastDateStr),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (nextSuggested != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward,
                  size: 13,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.nextSuggested(dateFormat.format(nextSuggested)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Icon / colour helpers (mirrors notification_management_screen.dart) ───

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
}
