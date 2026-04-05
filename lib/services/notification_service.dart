// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_log.dart';
import '../models/tank.dart';
import '../models/tank_notification.dart';
import '../providers/tank_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Background / action handler (must be a top-level function)
// ──────────────────────────────────────────────────────────────────────────────

/// Top-level background handler for notification actions (snooze / done).
///
/// Runs in a separate isolate on Android when the user taps an action button
/// while the app is in the background.  Only SharedPreferences and a minimal
/// FlutterLocalNotificationsPlugin instance are available here.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  _handleNotificationAction(response);
}

/// Shared handler for both foreground (tap) and background (action) responses.
Future<void> _handleNotificationAction(NotificationResponse response) async {
  final actionId = response.actionId;
  final payload = response.payload ?? '';

  if (actionId == NotificationService.actionSnooze1Day ||
      actionId == NotificationService.actionSnooze1Week) {
    final delay = actionId == NotificationService.actionSnooze1Day
        ? const Duration(days: 1)
        : const Duration(days: 7);
    await _snoozeNotification(
      payload: payload,
      delay: delay,
      originalId: response.id ?? 0,
    );
  } else if (actionId == NotificationService.actionDone) {
    await _enqueuePendingDone(payload: payload);
  }
}

/// Re-schedule a snoozed notification using a minimal plugin instance.
Future<void> _snoozeNotification({
  required String payload,
  required Duration delay,
  required int originalId,
}) async {
  try {
    tz.initializeTimeZones();
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Load cached metadata so we can restore title/body.
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? meta;
    if (payload.isNotEmpty) {
      final parts = payload.split('_');
      if (parts.length >= 2) {
        final notifId = parts.sublist(1).join('_');
        final metaJson =
            prefs.getString('${NotificationService.metaKeyPrefix}$notifId');
        if (metaJson != null) {
          meta = jsonDecode(metaJson) as Map<String, dynamic>;
        }
      }
    }

    final title = (meta?['title'] as String?) ?? 'Tank Reminder';
    final body = (meta?['body'] as String?) ?? 'You have a tank reminder.';

    final scheduledDate = tz.TZDateTime.from(
      DateTime.now().add(delay),
      tz.local,
    );

    final snoozeId = '${originalId}_snooze'.hashCode;

    const androidDetails = AndroidNotificationDetails(
      'tank_notifications',
      'Tank Maintenance',
      channelDescription: 'Notifications for tank maintenance tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          NotificationService.actionDone,
          '✓ Done',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationService.actionSnooze1Day,
          '⏸ Snooze 1 Day',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationService.actionSnooze1Week,
          '⏸ Snooze 1 Week',
          showsUserInterface: false,
        ),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await plugin.cancel(id: originalId);

    await plugin.zonedSchedule(
      id: snoozeId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails:
          const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  } catch (e) {
    debugPrint('NotificationService: snooze failed: $e');
  }
}

/// Add a "done" payload to the pending queue for processing when app opens.
Future<void> _enqueuePendingDone({required String payload}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final existing =
        prefs.getStringList(NotificationService.pendingDoneQueueKey) ?? [];
    existing.add(payload);
    await prefs.setStringList(
      NotificationService.pendingDoneQueueKey,
      existing,
    );
  } catch (e) {
    debugPrint('NotificationService: enqueuePendingDone failed: $e');
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// NotificationService
// ──────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  // ── Action IDs ────────────────────────────────────────────────────────────
  static const String actionDone = 'done';
  static const String actionSnooze1Day = 'snooze_1d';
  static const String actionSnooze1Week = 'snooze_1w';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String metaKeyPrefix = 'notif_meta_';
  static const String pendingDoneQueueKey = 'pending_notification_done_queue';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Navigator key for app-wide navigation from notification taps
  GlobalKey<NavigatorState>? _navigatorKey;

  // ── Initialization ────────────────────────────────────────────────────────

  /// Initialize the notification service.
  ///
  /// [navigatorKey] is optional and used for navigating when notifications are
  /// tapped.  Should only be passed on the first call (from main.dart).
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;

    _navigatorKey = navigatorKey;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    _initialized = true;
  }

  // ── Tap / action handler (foreground) ────────────────────────────────────

  void _onNotificationTapped(NotificationResponse response) {
    if (response.actionId != null) {
      // Delegate action handling (snooze / done) to the shared handler.
      _handleNotificationAction(response);
      return;
    }
    // Plain tap → navigate to the notification dashboard.
    try {
      _navigatorKey?.currentState?.pushNamed('/notification-dashboard');
    } catch (e) {
      debugPrint('NotificationService: navigation failed: $e');
    }
  }

  // ── Permissions ──────────────────────────────────────────────────────────

  /// Request notification permissions (especially important for iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) {
      await initialize();
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted =
        await androidPlugin?.requestNotificationsPermission();

    return granted ?? androidGranted ?? true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) {
      await initialize();
    }

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }

  // ── Metadata helpers ──────────────────────────────────────────────────────

  /// Persist lightweight notification metadata to SharedPreferences so the
  /// background isolate can reconstruct title/body without the provider.
  Future<void> _saveNotificationMeta({
    required String notificationId,
    required String title,
    required String body,
    required String tankId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final meta = jsonEncode({
        'title': title,
        'body': body,
        'tankId': tankId,
        'notificationId': notificationId,
      });
      await prefs.setString('$metaKeyPrefix$notificationId', meta);
    } catch (e) {
      debugPrint('NotificationService: saveNotificationMeta failed: $e');
    }
  }

  /// Remove cached metadata when a notification is deleted.
  Future<void> clearNotificationMeta(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$metaKeyPrefix$notificationId');
    } catch (e) {
      debugPrint('NotificationService: clearNotificationMeta failed: $e');
    }
  }

  /// Remove metadata entries whose notification IDs are no longer active.
  Future<void> clearOrphanedMeta(List<String> activeNotificationIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs
          .getKeys()
          .where(
            (k) =>
                k.startsWith(metaKeyPrefix) &&
                !activeNotificationIds.any((id) => k == '$metaKeyPrefix$id'),
          )
          .toList();
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('NotificationService: clearOrphanedMeta failed: $e');
    }
  }

  // ── Schedule / cancel ─────────────────────────────────────────────────────

  /// Schedule a notification from a [TankNotification].
  ///
  /// If [activityLogs] is provided, the next date is calculated from the last
  /// matching activity log.  If [useExactDateTime] is true, [notification.notificationDateTime]
  /// is used directly.
  ///
  /// Returns the calculated next notification date, or null if the notification
  /// is disabled.
  Future<DateTime?> scheduleNotification({
    required String tankId,
    required String tankName,
    required TankNotification notification,
    List<NotificationLog>? activityLogs,
    bool useExactDateTime = false,
    bool useCurrentTime = false,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final int notificationId = notification.id.hashCode;

    const androidActions = [
      AndroidNotificationAction(
        actionDone,
        '✓ Done',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        actionSnooze1Day,
        '⏸ Snooze 1 Day',
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        actionSnooze1Week,
        '⏸ Snooze 1 Week',
        showsUserInterface: false,
      ),
    ];

    final androidDetails = AndroidNotificationDetails(
      'tank_notifications',
      'Tank Maintenance',
      channelDescription: 'Notifications for tank maintenance tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: androidActions,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title =
        notification.customTitle ??
        _getNotificationTitle(notification.type, tankName);
    final body = notification.notes ?? _getDefaultBody(notification.type);

    DateTime? nextDate;
    if (useExactDateTime ||
        notification.repeatFrequency == RepeatFrequency.none) {
      nextDate = notification.notificationDateTime;
    } else if (activityLogs != null) {
      nextDate = notification.getNextNotificationDateWithActivity(
        activityLogs,
        useCurrentTime: useCurrentTime,
      );
    } else {
      nextDate = notification.getNextNotificationDate();
    }

    if (nextDate != null && notification.enabled) {
      final scheduledDate = tz.TZDateTime.from(nextDate, tz.local);

      await _notifications.zonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '${tankId}_${notification.id}',
      );

      // Cache metadata for background isolate use.
      await _saveNotificationMeta(
        notificationId: notification.id,
        title: title,
        body: body,
        tankId: tankId,
      );
    }

    return nextDate;
  }

  /// Cancel a scheduled notification and clear its cached metadata.
  Future<void> cancelNotification(TankNotification notification) async {
    final int notificationId = notification.id.hashCode;
    await _notifications.cancel(id: notificationId);
    await clearNotificationMeta(notification.id);
  }

  /// Cancel all notifications for a tank
  Future<void> cancelTankNotifications(
    String tankId,
    List<TankNotification> notifications,
  ) async {
    for (final notification in notifications) {
      await cancelNotification(notification);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Reschedule all tank notifications (useful after a notification fires)
  Future<void> rescheduleTankNotifications({
    required String tankId,
    required String tankName,
    required List<TankNotification> notifications,
    List<NotificationLog>? activityLogs,
  }) async {
    await cancelTankNotifications(tankId, notifications);

    for (final notification in notifications) {
      if (notification.enabled) {
        await scheduleNotification(
          tankId: tankId,
          tankName: tankName,
          notification: notification,
          activityLogs: activityLogs,
        );
      }
    }
  }

  /// Reschedule notifications that match a specific activity type.
  ///
  /// Returns a list of updated notifications with their scheduledNextDate set.
  Future<List<TankNotification>> rescheduleMatchingNotifications({
    required String tankId,
    required String tankName,
    required List<TankNotification> notifications,
    required List<NotificationLog> activityLogs,
    required NotificationType activityType,
    String? activityCustomCategory,
    bool useCurrentTime = false,
  }) async {
    final matchingNotifications = notifications
        .where(
          (notification) =>
              notification.enabled &&
              notification.repeatFrequency != RepeatFrequency.none &&
              notification.matchesActivityLog(
                activityType,
                activityCustomCategory,
              ),
        )
        .toList();

    if (matchingNotifications.isEmpty) {
      return [];
    }

    final updatedNotifications = <TankNotification>[];

    for (final notification in matchingNotifications) {
      await cancelNotification(notification);
      final nextDate = await scheduleNotification(
        tankId: tankId,
        tankName: tankName,
        notification: notification,
        activityLogs: activityLogs,
        useCurrentTime: useCurrentTime,
      );

      if (nextDate != null) {
        updatedNotifications.add(
          notification.copyWith(
            scheduledNextDate: nextDate,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    return updatedNotifications;
  }

  // ── Pending done-action processing ────────────────────────────────────────

  /// Process any "done" actions that were queued by the background handler.
  ///
  /// Called from [main.dart] once the app is fully initialized so that the
  /// Riverpod container and tank provider are available.
  Future<void> processPendingActions(WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(pendingDoneQueueKey);
      if (queue == null || queue.isEmpty) return;

      // Clear the queue immediately to avoid duplicate processing.
      await prefs.remove(pendingDoneQueueKey);

      final tankState = ref.read(tankProvider);

      for (final payload in queue) {
        // Payload format: "${tankId}_${notificationId}"
        final underscoreIdx = payload.indexOf('_');
        if (underscoreIdx < 0) continue;

        final tankId = payload.substring(0, underscoreIdx);
        final notifId = payload.substring(underscoreIdx + 1);

        Tank? tank;
        try {
          tank = tankState.tanks.firstWhere((t) => t.id == tankId);
        } catch (_) {
          continue; // Tank not found
        }

        TankNotification? notification;
        try {
          notification = tank.notifications.firstWhere((n) => n.id == notifId);
        } catch (_) {
          continue; // Notification not found
        }

        final log = NotificationLog.create(
          type: notification.type,
          customCategory: notification.type == NotificationType.other
              ? (notification.customCategory ?? 'Other')
              : null,
          notificationId: notification.id,
        );

        final updatedLogs = [...tank.notificationLogs, log];

        final updatedNotifications = await rescheduleMatchingNotifications(
          tankId: tank.id,
          tankName: tank.name,
          notifications: tank.notifications,
          activityLogs: updatedLogs,
          activityType: log.type,
          activityCustomCategory: log.customCategory,
        );

        var updatedTank = tank.copyWith(
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
      }
    } catch (e) {
      debugPrint('NotificationService: processPendingActions failed: $e');
    }
  }

  // ── Resync ────────────────────────────────────────────────────────────────

  /// Re-schedule all enabled notifications across every provided tank.
  ///
  /// Called on app resume to ensure past-due notifications are refreshed.
  Future<void> resyncAllTankNotifications({
    required List<Tank> tanks,
  }) async {
    if (!_initialized) await initialize();

    for (final tank in tanks) {
      if (tank.notifications.isEmpty) continue;
      await rescheduleTankNotifications(
        tankId: tank.id,
        tankName: tank.name,
        notifications: tank.notifications,
        activityLogs: tank.notificationLogs,
      );
    }
  }

  // ── Test notification ─────────────────────────────────────────────────────

  /// Send a test notification immediately (for debugging)
  Future<void> sendTestNotification({
    required String tankName,
    NotificationType type = NotificationType.feeding,
    String? customTitle,
    String? customBody,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'tank_notifications',
      'Tank Maintenance',
      channelDescription: 'Notifications for tank maintenance tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = customTitle ?? _getNotificationTitle(type, tankName);
    final defaultBody = customBody ?? _getDefaultBody(type);
    final body = '$defaultBody (Test notification)';

    const int testNotificationId = 999999;

    await _notifications.show(
      id: testNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'test_notification',
    );
  }

  // ── Title / body helpers ──────────────────────────────────────────────────

  /// Get notification title based on type
  String _getNotificationTitle(NotificationType type, String tankName) {
    switch (type) {
      case NotificationType.feeding:
        return '🐠 Time to Feed - $tankName';
      case NotificationType.dosing:
        return '💧 Dosing Reminder - $tankName';
      case NotificationType.waterChange:
        return '🔄 Water Change - $tankName';
      case NotificationType.testing:
        return '🧪 Test Water Parameters - $tankName';
      case NotificationType.maintenance:
        return '🔧 Maintenance Due - $tankName';
      case NotificationType.other:
        return '⏰ Tank Reminder - $tankName';
    }
  }

  /// Get default notification body based on type
  String _getDefaultBody(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return 'Time to feed your fish!';
      case NotificationType.dosing:
        return 'Don\'t forget to dose your tank.';
      case NotificationType.waterChange:
        return 'It\'s time for a water change.';
      case NotificationType.testing:
        return 'Test your water parameters.';
      case NotificationType.maintenance:
        return 'Tank maintenance is due.';
      case NotificationType.other:
        return 'You have a tank reminder.';
    }
  }
}
