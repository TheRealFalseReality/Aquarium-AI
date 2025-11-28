import '../models/notification_log.dart';
import '../models/tank.dart';
import '../models/tank_notification.dart';
import '../services/notification_service.dart';

/// Utility class for recalculating notification schedules based on activity logs.
/// 
/// This utility finds the last relevant activity log for a notification and
/// recalculates when the next notification should fire, making the notification
/// system more robust by basing schedules on actual user activity.
class NotificationRecalculationUtils {
  /// Find the last activity log that matches a notification's category.
  /// 
  /// For 'other' type notifications, matches are based on custom category name.
  /// For standard types, matches are based on notification type.
  /// 
  /// [notification] - The notification to find matching activities for
  /// [logs] - The list of activity logs to search through
  /// 
  /// Returns the most recent matching activity log, or null if none found.
  static NotificationLog? findLastMatchingActivity(
    TankNotification notification,
    List<NotificationLog> logs,
  ) {
    if (logs.isEmpty) {
      return null;
    }

    // Filter logs that match this notification's category
    final matchingLogs = logs.where((log) {
      return notification.matchesActivityLog(log.type, log.customCategory);
    }).toList();

    if (matchingLogs.isEmpty) {
      return null;
    }

    // Sort by date (newest first) and return the most recent
    matchingLogs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return matchingLogs.first;
  }

  /// Calculate the next notification date based on the last activity.
  /// 
  /// If a matching activity log is found, the next notification date is
  /// calculated from that activity's date. Otherwise, the original
  /// notification date calculation is used.
  /// 
  /// [notification] - The notification to calculate the next date for
  /// [logs] - The list of activity logs to consider
  /// 
  /// Returns the calculated next notification date, or null if the
  /// notification is disabled or non-repeating.
  static DateTime? calculateNextDateFromActivity(
    TankNotification notification,
    List<NotificationLog> logs,
  ) {
    if (!notification.enabled || notification.repeatFrequency == RepeatFrequency.none) {
      return null;
    }

    final lastActivity = findLastMatchingActivity(notification, logs);
    
    if (lastActivity != null) {
      // Calculate next date from the last activity
      return notification.getNextNotificationDateFromBase(lastActivity.loggedAt);
    }
    
    // Fall back to original calculation if no matching activity found
    return notification.getNextNotificationDate();
  }

  /// Recalculate and reschedule a notification based on activity logs.
  /// 
  /// This method updates the notification's scheduled time based on the
  /// last matching activity log. If the recalculated date differs from
  /// the current schedule, it cancels the old notification and schedules
  /// a new one.
  /// 
  /// [tank] - The tank containing the notification
  /// [notification] - The notification to recalculate
  /// [notificationService] - The service used to schedule/cancel notifications
  /// 
  /// Returns true if the notification was rescheduled.
  static Future<bool> recalculateAndReschedule({
    required Tank tank,
    required TankNotification notification,
    required NotificationService notificationService,
  }) async {
    if (!notification.enabled || notification.repeatFrequency == RepeatFrequency.none) {
      return false;
    }

    final newNextDate = calculateNextDateFromActivity(
      notification,
      tank.notificationLogs,
    );

    if (newNextDate != null) {
      // Cancel existing notification and reschedule with new date
      await notificationService.cancelNotification(notification);
      await notificationService.scheduleNotification(
        tankId: tank.id,
        tankName: tank.name,
        notification: notification,
      );
      return true;
    }

    return false;
  }

  /// Recalculate and reschedule all notifications in a tank that match
  /// a specific activity type.
  /// 
  /// This is useful when an activity is logged - it finds all notifications
  /// that match that activity type and recalculates their schedules.
  /// 
  /// [tank] - The tank containing the notifications
  /// [activityType] - The type of activity that was logged
  /// [activityCustomCategory] - The custom category of the activity (for 'other' type)
  /// [notificationService] - The service used to schedule/cancel notifications
  /// 
  /// Returns the list of notification IDs that were rescheduled.
  static Future<List<String>> recalculateMatchingNotifications({
    required Tank tank,
    required NotificationType activityType,
    String? activityCustomCategory,
    required NotificationService notificationService,
  }) async {
    final rescheduledIds = <String>[];

    for (final notification in tank.notifications) {
      // Only process enabled, repeating notifications that match the activity
      if (!notification.enabled || notification.repeatFrequency == RepeatFrequency.none) {
        continue;
      }

      if (notification.matchesActivityLog(activityType, activityCustomCategory)) {
        final wasRescheduled = await recalculateAndReschedule(
          tank: tank,
          notification: notification,
          notificationService: notificationService,
        );
        
        if (wasRescheduled) {
          rescheduledIds.add(notification.id);
        }
      }
    }

    return rescheduledIds;
  }

  /// Recalculate and reschedule all enabled, repeating notifications in a tank.
  /// 
  /// This is useful after restoring from backup or when the app starts.
  /// 
  /// [tank] - The tank containing the notifications
  /// [notificationService] - The service used to schedule/cancel notifications
  /// 
  /// Returns the count of notifications that were rescheduled.
  static Future<int> recalculateAllNotifications({
    required Tank tank,
    required NotificationService notificationService,
  }) async {
    int count = 0;

    for (final notification in tank.notifications) {
      final wasRescheduled = await recalculateAndReschedule(
        tank: tank,
        notification: notification,
        notificationService: notificationService,
      );
      
      if (wasRescheduled) {
        count++;
      }
    }

    return count;
  }
}
