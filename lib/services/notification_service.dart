import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/tank_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

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

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can be extended to navigate to specific screens
    // Payload format: ${tankId}_${notificationId}
    if (response.payload != null) {
      // Could navigate to tank details or notification screen here
      // For now, just silently handle it
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
  Future<void> scheduleNotification({
    required String tankId,
    required String tankName,
    required TankNotification notification,
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

    // Schedule the notification
    final nextDate = notification.getNextNotificationDate();
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
  Future<void> rescheduleTankNotifications({
    required String tankId,
    required String tankName,
    required List<TankNotification> notifications,
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
        );
      }
    }
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

    // Get notification title and body
    final title = _getNotificationTitle(type, tankName);
    final body = '${_getDefaultBody(type)} (Test notification)';

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
