import 'dart:convert';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/notification_log.dart';
import '../models/tank.dart';
import '../models/tank_notification.dart';

class NotificationActionLabels {
  final String done;
  final String snoozeDay;
  final String snoozeWeek;

  const NotificationActionLabels({
    required this.done,
    required this.snoozeDay,
    required this.snoozeWeek,
  });
}

class NotificationActionUpdate {
  final String tankId;
  final String notificationId;
  final String actionId;

  const NotificationActionUpdate({
    required this.tankId,
    required this.notificationId,
    required this.actionId,
  });
}

class NotificationActionPayload {
  final String tankId;
  final String notificationId;

  const NotificationActionPayload({
    required this.tankId,
    required this.notificationId,
  });
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await NotificationService().handleNotificationResponse(response);
  } catch (e) {
    debugPrint('Failed to handle background notification action: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String _tanksKey = 'user_tanks';
  static const String _iosNotificationCategory = 'tank_maintenance_actions';
  static const String actionDone = 'done_action';
  static const String actionSnoozeDay = 'snooze_day_action';
  static const String actionSnoozeWeek = 'snooze_week_action';

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationActionUpdate> _actionUpdatesController =
      StreamController<NotificationActionUpdate>.broadcast();

  bool _initialized = false;
  NotificationActionLabels? _cachedActionLabels;
  String? _cachedActionLabelsLocale;
  Future<void> Function({
    required String tankId,
    required String notificationId,
    required String actionId,
  })?
  _actionApplierOverride;

  /// Navigator key for app-wide navigation from notification taps
  GlobalKey<NavigatorState>? _navigatorKey;

  Stream<NotificationActionUpdate> get actionUpdates =>
      _actionUpdatesController.stream;

  @visibleForTesting
  void setActionApplierOverrideForTesting(
    Future<void> Function({
      required String tankId,
      required String notificationId,
      required String actionId,
    })
    actionApplier,
  ) {
    _actionApplierOverride = actionApplier;
  }

  @visibleForTesting
  void clearActionApplierOverrideForTesting() {
    _actionApplierOverride = null;
  }

  bool _isSupportedActionId(String? actionId) {
    return actionId == actionDone ||
        actionId == actionSnoozeDay ||
        actionId == actionSnoozeWeek;
  }

  @visibleForTesting
  bool canHandleNotificationActionForTesting({
    required String? actionId,
    required String? payload,
  }) {
    if (payload == null || payload.isEmpty || !_isSupportedActionId(actionId)) {
      return false;
    }
    return parseNotificationPayloadForTesting(payload) != null;
  }

  @visibleForTesting
  NotificationActionPayload? parseNotificationPayloadForTesting(
    String payload,
  ) {
    return _parseNotificationPayload(payload);
  }

  /// Initialize the notification service
  /// [navigatorKey] is optional and used for navigating when notifications are tapped.
  /// Note: The navigatorKey should be passed on the first call (typically from main.dart).
  /// Subsequent calls (e.g., from requestPermissions()) will return early due to _initialized check,
  /// preserving the originally set navigatorKey.
  /// When initialization first happens in a background isolate, a later foreground
  /// initialize call may provide navigatorKey so tap navigation works in the UI isolate.
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) {
      if (_navigatorKey == null && navigatorKey != null) {
        _navigatorKey = navigatorKey;
        debugPrint(
          'NotificationService navigatorKey was set after background-first initialization.',
        );
      }
      return;
    }

    _navigatorKey = navigatorKey;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final actionLabels = await _getNotificationActionLabels();

    // iOS initialization settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: {
        DarwinNotificationCategory(_iosNotificationCategory, actions: [
          DarwinNotificationAction.plain(actionDone, actionLabels.done),
          DarwinNotificationAction.plain(
            actionSnoozeDay,
            actionLabels.snoozeDay,
          ),
          DarwinNotificationAction.plain(
            actionSnoozeWeek,
            actionLabels.snoozeWeek,
          ),
        ]),
      },
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _initialized = true;
  }

  /// Handle notification tap - navigates to tank management screen
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    final wasActionHandled = await handleNotificationResponse(response);
    if (wasActionHandled) {
      return;
    }

    // Default tap action opens app UI.
    if (response.actionId != null &&
        response.actionId != NotificationResponse.defaultActionId) {
      return;
    }

    // Navigate to tank management screen when notification is tapped
    try {
      _navigatorKey?.currentState?.pushNamed('/tank-management');
    } catch (e) {
      // Navigation failed - log but don't crash the app
      debugPrint('Failed to navigate from notification tap: $e');
    }
  }

  /// Request notification permissions (especially important for iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) {
      await initialize();
    }

    // Request permissions for iOS
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permissions for Android 13+
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await androidPlugin
        ?.requestNotificationsPermission();

    return granted ?? androidGranted ?? true;
  }

  /// Schedule a notification from a TankNotification
  ///
  /// If [activityLogs] is provided, the next notification date will be
  /// calculated based on the last matching activity log, making the
  /// notification schedule relative to when the user actually completed
  /// the task.
  ///
  /// If [useExactDateTime] is true, the notification will be scheduled for
  /// exactly [notification.notificationDateTime], ignoring any activity logs
  /// or repeat frequency calculations. This is useful when the user explicitly
  /// wants to schedule for a specific date/time.
  ///
  /// If [useScheduledNextDate] is true, the notification will be scheduled for
  /// [notification.scheduledNextDate] (falling back to [notification.notificationDateTime]).
  /// Use this for snooze actions after [scheduledNextDate] has been updated.
  ///
  /// In contrast, [useExactDateTime] schedules at [notification.notificationDateTime]
  /// (the configured reminder time) without recalculating from activity logs.
  ///
  /// If [useCurrentTime] is true and [activityLogs] is provided, the notification
  /// will use the time from the activity log instead of the original notification
  /// time. This is used for "Reschedule from Now" to schedule at the current time.
  ///
  /// Returns the calculated next notification date, or null if the notification
  /// is disabled. This can be used to update the notification model's scheduledNextDate field.
  Future<DateTime?> scheduleNotification({
    required String tankId,
    required String tankName,
    required TankNotification notification,
    List<NotificationLog>? activityLogs,
    bool useExactDateTime = false,
    bool useScheduledNextDate = false,
    bool useCurrentTime = false,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Generate unique ID from notification ID hash
    final int notificationId = notification.id.hashCode;
    final actionLabels = await _getNotificationActionLabels();

    // Create notification details
    final androidDetails = AndroidNotificationDetails(
      'tank_notifications',
      'Tank Maintenance',
      channelDescription: 'Notifications for tank maintenance tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionDone,
          actionLabels.done,
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          actionSnoozeDay,
          actionLabels.snoozeDay,
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          actionSnoozeWeek,
          actionLabels.snoozeWeek,
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: _iosNotificationCategory,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Get notification title and body
    final title =
        notification.customTitle ??
        _getNotificationTitle(notification.type, tankName);
    final body = notification.notes ?? _getDefaultBody(notification.type);

    // Determine the next notification date
    DateTime? nextDate;
    if (useScheduledNextDate) {
      nextDate = notification.getImmediateNextDate();
    } else if (useExactDateTime) {
      // Schedule exactly at the notification's explicitly configured date/time.
      nextDate = notification.notificationDateTime;
    } else if (notification.repeatFrequency == RepeatFrequency.none) {
      // Use the exact date/time specified in the notification for:
      // - Non-repeating notifications (getNextNotificationDate returns null for these)
      nextDate = notification.notificationDateTime;
    } else if (activityLogs != null) {
      // Calculate based on activity logs, optionally using current time
      nextDate = notification.getNextNotificationDateWithActivity(
        activityLogs,
        useCurrentTime: useCurrentTime,
      );
    } else {
      // Fall back to standard calculation
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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$tankId::${notification.id}',
      );
    }

    // Return the calculated next date so callers can update the model
    return nextDate;
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(TankNotification notification) async {
    final int notificationId = notification.id.hashCode;
    await _notifications.cancel(id: notificationId);
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
  ///
  /// If [activityLogs] is provided, notifications will be scheduled based on
  /// the last matching activity log for each notification type.
  Future<void> rescheduleTankNotifications({
    required String tankId,
    required String tankName,
    required List<TankNotification> notifications,
    List<NotificationLog>? activityLogs,
  }) async {
    // Cancel existing notifications first
    await cancelTankNotifications(tankId, notifications);

    // Schedule active notifications
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
  /// This is called when an activity is logged to update the schedule
  /// of matching notifications based on the new activity.
  ///
  /// If [useCurrentTime] is true, the notification will use the time from the
  /// activity log instead of the original notification time.
  ///
  /// Returns a list of updated notifications with their scheduledNextDate set.
  /// Callers should persist these updated notifications to the tank.
  Future<List<TankNotification>> rescheduleMatchingNotifications({
    required String tankId,
    required String tankName,
    required List<TankNotification> notifications,
    required List<NotificationLog> activityLogs,
    required NotificationType activityType,
    String? activityCustomCategory,
    bool useCurrentTime = false,
  }) async {
    // Filter to only enabled, repeating notifications that match the activity type
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

    // Early return if no notifications match
    if (matchingNotifications.isEmpty) {
      return [];
    }

    final updatedNotifications = <TankNotification>[];

    // Cancel and reschedule each matching notification
    for (final notification in matchingNotifications) {
      await cancelNotification(notification);
      final nextDate = await scheduleNotification(
        tankId: tankId,
        tankName: tankName,
        notification: notification,
        activityLogs: activityLogs,
        useCurrentTime: useCurrentTime,
      );

      // Create updated notification with the new scheduledNextDate
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

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) {
      await initialize();
    }

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidEnabled =
        await androidPlugin?.areNotificationsEnabled() ?? false;

    return androidEnabled;
  }

  Future<NotificationActionLabels> _getNotificationActionLabels() async {
    final languageCode = PlatformDispatcher.instance.locale.languageCode;
    if (_cachedActionLabels != null && _cachedActionLabelsLocale == languageCode) {
      return _cachedActionLabels!;
    }

    final locale = switch (languageCode) {
      'de' => const Locale('de'),
      'es' => const Locale('es'),
      'fr' => const Locale('fr'),
      _ => const Locale('en'),
    };
    final l10n = await AppLocalizations.delegate.load(locale);
    final labels = NotificationActionLabels(
      done: l10n.notificationActionDone,
      snoozeDay: l10n.notificationActionSnooze1Day,
      snoozeWeek: l10n.notificationActionSnooze1Week,
    );
    _cachedActionLabels = labels;
    _cachedActionLabelsLocale = languageCode;
    return labels;
  }

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

    // Create notification details
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

    // Get notification title and body - use custom values if provided
    final title = customTitle ?? _getNotificationTitle(type, tankName);
    final defaultBody = customBody ?? _getDefaultBody(type);
    final body = '$defaultBody (Test notification)';

    // Use a unique ID for test notifications
    const int testNotificationId = 999999;

    // Show notification immediately
    await _notifications.show(
      id: testNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'test_notification',
    );
  }

  /// Handles actionable notification responses.
  ///
  /// Returns `true` when this method consumed a supported action
  /// (`done_action`, `snooze_day_action`, `snooze_week_action`) and persisted
  /// the corresponding tank update. Returns `false` when the response should be
  /// treated as a normal tap/navigation event.
  Future<bool> handleNotificationResponse(NotificationResponse response) async {
    return handleNotificationActionForTesting(
      actionId: response.actionId,
      payload: response.payload,
    );
  }

  @visibleForTesting
  Future<bool> handleNotificationActionForTesting({
    required String? actionId,
    required String? payload,
  }) async {
    if (!canHandleNotificationActionForTesting(
      actionId: actionId,
      payload: payload,
    )) {
      return false;
    }

    final payloadData = _parseNotificationPayload(payload!)!;
    final resolvedActionId = actionId!;
    final actionApplier =
        _actionApplierOverride ?? _applyActionToStoredTankNotification;
    await actionApplier(
      tankId: payloadData.tankId,
      notificationId: payloadData.notificationId,
      actionId: resolvedActionId,
    );
    _actionUpdatesController.add(
      NotificationActionUpdate(
        tankId: payloadData.tankId,
        notificationId: payloadData.notificationId,
        actionId: resolvedActionId,
      ),
    );

    return true;
  }

  /// Parses notification payload to tank and notification IDs.
  ///
  /// Preferred format is `tankId::notificationId`.
  /// Legacy `tankId_notificationId` remains supported for already-scheduled
  /// notifications created before the separator migration.
  NotificationActionPayload? _parseNotificationPayload(String payload) {
    if (payload.contains('::')) {
      final parts = payload.split('::');
      if (parts.length == 2 &&
          parts[0].isNotEmpty &&
          parts[1].isNotEmpty) {
        return NotificationActionPayload(
          tankId: parts[0],
          notificationId: parts[1],
        );
      }
    }

    final separatorIndex = payload.indexOf('_');
    if (separatorIndex <= 0 || separatorIndex >= payload.length - 1) {
      return null;
    }

    return NotificationActionPayload(
      tankId: payload.substring(0, separatorIndex),
      notificationId: payload.substring(separatorIndex + 1),
    );
  }

  /// Applies a notification action directly to persisted tank data.
  ///
  /// This is used by foreground/background action handlers so users can mark
  /// reminders done or snooze without opening the app UI. The method updates
  /// SharedPreferences tank storage, appends activity logs for "done", and
  /// attempts rescheduling for repeating reminders.
  Future<void> _applyActionToStoredTankNotification({
    required String tankId,
    required String notificationId,
    required String actionId,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final prefs = await SharedPreferences.getInstance();
    final tanksJson = prefs.getString(_tanksKey);
    if (tanksJson == null) {
      return;
    }

    List<Tank> tanks;
    try {
      final tanksList = json.decode(tanksJson) as List;
      tanks = tanksList
          .map((tankData) => Tank.fromJson(tankData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to decode stored tanks for notification action: $e');
      return;
    }

    final tankIndex = tanks.indexWhere((tank) => tank.id == tankId);
    if (tankIndex == -1) {
      return;
    }

    final tank = tanks[tankIndex];
    final notificationIndex = tank.notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (notificationIndex == -1) {
      return;
    }

    final notification = tank.notifications[notificationIndex];
    final now = DateTime.now();
    List<TankNotification> updatedNotifications = List.from(tank.notifications);
    var updatedLogs = List<NotificationLog>.from(tank.notificationLogs);

    if (actionId == actionDone) {
      final log = NotificationLog(
        id: const Uuid().v4(),
        type: notification.type,
        customCategory: notification.type == NotificationType.other
            ? notification.customCategory
            : null,
        loggedAt: now,
        notes: notification.notes,
        notificationId: notification.id,
      );
      updatedLogs = [...updatedLogs, log];

      try {
        final rescheduled = await rescheduleMatchingNotifications(
          tankId: tank.id,
          tankName: tank.name,
          notifications: updatedNotifications,
          activityLogs: updatedLogs,
          activityType: log.type,
          activityCustomCategory: log.customCategory,
        );
        if (rescheduled.isNotEmpty) {
          final rescheduledById = {
            for (final item in rescheduled) item.id: item,
          };
          updatedNotifications = updatedNotifications.map((existing) {
            return rescheduledById[existing.id] ?? existing;
          }).toList();
        }
      } catch (e) {
        debugPrint('Failed to reschedule notifications after done action: $e');
      }
    } else {
      final snoozeDays = actionId == actionSnoozeWeek ? 7 : 1;
      final snoozedDate = now.add(Duration(days: snoozeDays));
      final updatedNotification = notification.copyWith(
        scheduledNextDate: snoozedDate,
        updatedAt: now,
      );
      updatedNotifications = updatedNotifications.map((existing) {
        return existing.id == notification.id ? updatedNotification : existing;
      }).toList();

      try {
        await scheduleNotification(
          tankId: tank.id,
          tankName: tank.name,
          notification: updatedNotification,
          useScheduledNextDate: true,
        );
      } catch (e) {
        debugPrint('Failed to schedule snoozed notification: $e');
      }
    }

    final updatedTank = tank.copyWith(
      notifications: updatedNotifications,
      notificationLogs: updatedLogs,
      updatedAt: now,
    );
    tanks[tankIndex] = updatedTank;

    final updatedJson = json.encode(tanks.map((item) => item.toJson()).toList());
    await prefs.setString(_tanksKey, updatedJson);
  }
}
