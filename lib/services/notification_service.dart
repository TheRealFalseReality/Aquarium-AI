import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_log.dart';
import '../models/tank_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  
  /// Navigator key for app-wide navigation from notification taps
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the notification service
  /// [navigatorKey] is optional and used for navigating when notifications are tapped.
  /// Note: The navigatorKey should be passed on the first call (typically from main.dart).
  /// Subsequent calls (e.g., from requestPermissions()) will return early due to _initialized check,
  /// preserving the originally set navigatorKey.
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;
    
    _navigatorKey = navigatorKey;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
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
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap - navigates to tank management screen
  void _onNotificationTapped(NotificationResponse response) {
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
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permissions for Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    
    // Request exact alarm permission for Android 12+ (API 31+)
    // This is required for scheduled notifications to work properly
    final exactAlarmGranted = await androidPlugin?.requestExactAlarmsPermission();

    return granted ?? exactAlarmGranted ?? true;
  }
  
  /// Check if exact alarms permission is granted (Android 12+)
  Future<bool> canScheduleExactNotifications() async {
    if (!_initialized) {
      await initialize();
    }

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    // Check if exact alarms are allowed
    final canScheduleExact = await androidPlugin?.canScheduleExactNotifications() ?? true;
    
    return canScheduleExact;
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
  /// If [useCurrentTime] is true and [activityLogs] is provided, the notification
  /// will use the time from the activity log instead of the original notification
  /// time. This is used for "Reschedule from Now" to schedule at the current time.
  /// 
  /// Returns the calculated next notification date, or null if the notification
  /// is disabled or non-repeating. This can be used to update the notification
  /// model's scheduledNextDate field.
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

    // Generate unique ID from notification ID hash
    final int notificationId = notification.id.hashCode;

    // Create notification details
    final androidDetails = AndroidNotificationDetails(
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

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Get notification title and body
    final title = notification.customTitle ?? _getNotificationTitle(notification.type, tankName);
    final body = notification.notes ?? _getDefaultBody(notification.type);

    // Determine the next notification date
    DateTime? nextDate;
    if (useExactDateTime) {
      // Use the exact date/time specified in the notification, ignoring any calculations
      nextDate = notification.notificationDateTime;
    } else if (activityLogs != null) {
      // Calculate based on activity logs, optionally using current time
      nextDate = notification.getNextNotificationDateWithActivity(activityLogs, useCurrentTime: useCurrentTime);
    } else {
      // Fall back to standard calculation
      nextDate = notification.getNextNotificationDate();
    }
    
    if (nextDate != null && notification.enabled) {
      final scheduledDate = tz.TZDateTime.from(nextDate, tz.local);
      
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '${tankId}_${notification.id}',
      );
    }
    
    // Return the calculated next date so callers can update the model
    return nextDate;
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(TankNotification notification) async {
    final int notificationId = notification.id.hashCode;
    await _notifications.cancel(notificationId);
  }

  /// Cancel all notifications for a tank
  Future<void> cancelTankNotifications(String tankId, List<TankNotification> notifications) async {
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
    // Filter to repeating notifications that match the activity type
    // Note: Include both enabled and disabled notifications so we can update
    // the scheduledNextDate even when device notifications are off
    final matchingNotifications = notifications.where((notification) => 
      notification.repeatFrequency != RepeatFrequency.none &&
      notification.matchesActivityLog(activityType, activityCustomCategory)
    ).toList();

    // Early return if no notifications match
    if (matchingNotifications.isEmpty) {
      return [];
    }

    final updatedNotifications = <TankNotification>[];

    // Cancel and reschedule each matching notification
    for (final notification in matchingNotifications) {
      // Cancel any existing platform notification. For disabled notifications,
      // this is a no-op but safe to call to ensure cleanup.
      await cancelNotification(notification);
      
      // Calculate the next notification date. The scheduleNotification method will:
      // - Always return the calculated nextDate for updating scheduledNextDate
      // - Only create a platform push notification if notification.enabled is true
      final nextDate = await scheduleNotification(
        tankId: tankId,
        tankName: tankName,
        notification: notification,
        activityLogs: activityLogs,
        useCurrentTime: useCurrentTime,
      );
      
      // Create updated notification with the new scheduledNextDate
      if (nextDate != null) {
        updatedNotifications.add(notification.copyWith(
          scheduledNextDate: nextDate,
          updatedAt: DateTime.now(),
        ));
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

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidEnabled = await androidPlugin?.areNotificationsEnabled() ?? false;

    return androidEnabled;
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
      testNotificationId,
      title,
      body,
      details,
      payload: 'test_notification',
    );
  }
}
