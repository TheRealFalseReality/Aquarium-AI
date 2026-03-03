import 'package:uuid/uuid.dart';

import 'notification_log.dart';

/// Enum for notification types
enum NotificationType {
  feeding('Feeding'),
  dosing('Dosing'),
  waterChange('Water Change'),
  testing('Water Testing'),
  maintenance('Maintenance'),
  other('Other');

  final String displayName;

  const NotificationType(this.displayName);

  /// Convert string to enum
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.other,
    );
  }
}

/// Enum for repeat frequency
enum RepeatFrequency {
  none('Does not repeat'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  final String displayName;

  const RepeatFrequency(this.displayName);

  /// Convert string to enum
  static RepeatFrequency fromString(String value) {
    return RepeatFrequency.values.firstWhere(
      (freq) => freq.name == value,
      orElse: () => RepeatFrequency.none,
    );
  }
}

class TankNotification {
  final String id;
  final NotificationType type;
  final DateTime
  notificationDateTime; // The base/original notification time set by user
  final RepeatFrequency repeatFrequency; // How often to repeat
  final int
  repeatInterval; // Interval value (e.g., every X days/weeks/months/years)
  final String? notes; // Optional user notes
  final String? customTitle; // Optional custom notification title
  final String? customCategory; // For 'other' type - custom category name
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool enabled; // Whether the notification is active
  final DateTime?
  scheduledNextDate; // The actual next scheduled notification date (single source of truth)

  TankNotification({
    required this.id,
    required this.type,
    required this.notificationDateTime,
    this.repeatFrequency = RepeatFrequency.none,
    this.repeatInterval = 1,
    this.notes,
    this.customTitle,
    this.customCategory,
    required this.createdAt,
    required this.updatedAt,
    this.enabled = true,
    this.scheduledNextDate,
  });

  /// Get the immediate next notification date.
  /// This is the single source of truth for when the notification will fire.
  /// Returns scheduledNextDate if set, otherwise falls back to notificationDateTime.
  DateTime getImmediateNextDate() {
    return scheduledNextDate ?? notificationDateTime;
  }

  /// Factory method to create a new notification
  factory TankNotification.create({
    required NotificationType type,
    required DateTime notificationDateTime,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
    int repeatInterval = 1,
    String? notes,
    String? customTitle,
    String? customCategory,
    bool enabled = true,
    DateTime? scheduledNextDate,
  }) {
    final now = DateTime.now();
    return TankNotification(
      id: const Uuid().v4(),
      type: type,
      notificationDateTime: notificationDateTime,
      repeatFrequency: repeatFrequency,
      repeatInterval: repeatInterval,
      notes: notes,
      customTitle: customTitle,
      customCategory: customCategory,
      createdAt: now,
      updatedAt: now,
      enabled: enabled,
      // If no scheduledNextDate provided, use notificationDateTime as the initial schedule
      scheduledNextDate: scheduledNextDate ?? notificationDateTime,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'notificationDateTime': notificationDateTime.toIso8601String(),
      'repeatFrequency': repeatFrequency.name,
      'repeatInterval': repeatInterval,
      'notes': notes,
      'customTitle': customTitle,
      'customCategory': customCategory,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'enabled': enabled,
      'scheduledNextDate': scheduledNextDate?.toIso8601String(),
    };
  }

  /// Deserialize from JSON
  factory TankNotification.fromJson(Map<String, dynamic> json) {
    final notificationDateTime = DateTime.parse(
      json['notificationDateTime'] as String,
    );
    final scheduledNextDateStr = json['scheduledNextDate'] as String?;

    return TankNotification(
      id: json['id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      notificationDateTime: notificationDateTime,
      repeatFrequency: RepeatFrequency.fromString(
        json['repeatFrequency'] as String,
      ),
      repeatInterval: json['repeatInterval'] as int? ?? 1,
      notes: json['notes'] as String?,
      customTitle: json['customTitle'] as String?,
      customCategory: json['customCategory'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      enabled: json['enabled'] as bool? ?? true,
      // For backwards compatibility: if scheduledNextDate is not in JSON, use notificationDateTime
      scheduledNextDate: scheduledNextDateStr != null
          ? DateTime.parse(scheduledNextDateStr)
          : notificationDateTime,
    );
  }

  /// Create a copy with modified fields
  ///
  /// For nullable fields (notes, customTitle, customCategory, scheduledNextDate),
  /// set the corresponding clear flag to true to explicitly set them to null.
  TankNotification copyWith({
    String? id,
    NotificationType? type,
    DateTime? notificationDateTime,
    RepeatFrequency? repeatFrequency,
    int? repeatInterval,
    String? notes,
    String? customTitle,
    String? customCategory,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? enabled,
    DateTime? scheduledNextDate,
    bool clearNotes = false,
    bool clearCustomTitle = false,
    bool clearCustomCategory = false,
    bool clearScheduledNextDate = false,
  }) {
    return TankNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      notificationDateTime: notificationDateTime ?? this.notificationDateTime,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      notes: clearNotes ? null : (notes ?? this.notes),
      customTitle: clearCustomTitle ? null : (customTitle ?? this.customTitle),
      customCategory: clearCustomCategory
          ? null
          : (customCategory ?? this.customCategory),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enabled: enabled ?? this.enabled,
      scheduledNextDate: clearScheduledNextDate
          ? null
          : (scheduledNextDate ?? this.scheduledNextDate),
    );
  }

  /// Calculate the next notification date based on repeat settings
  /// Uses optimized math to avoid loops for dates far in the past
  DateTime? getNextNotificationDate() {
    if (!enabled || repeatFrequency == RepeatFrequency.none) {
      return null;
    }

    final now = DateTime.now();

    // If notification is in the future, return it
    if (!notificationDateTime.isBefore(now)) {
      return notificationDateTime;
    }

    // Calculate next occurrence based on frequency
    switch (repeatFrequency) {
      case RepeatFrequency.daily:
        return _getNextDailyDate(now);
      case RepeatFrequency.weekly:
        return _getNextWeeklyDate(now);
      case RepeatFrequency.monthly:
        return _getNextMonthlyDate(now);
      case RepeatFrequency.yearly:
        return _getNextYearlyDate(now);
      case RepeatFrequency.none:
        return null;
    }
  }

  /// Calculate the next notification date based on a specific base date
  /// (typically the last logged activity date).
  ///
  /// This allows the notification schedule to be relative to when the user
  /// actually completed the task, rather than the original notification time.
  ///
  /// For example, if a notification is set for "every 2 days" and the user
  /// logs an activity today, the next notification will be 2 days from today.
  ///
  /// [baseDate] - The date to calculate the next occurrence from (e.g., last activity date)
  /// [useCurrentTime] - If true, uses the time from baseDate instead of preserving
  ///                    the original notification time. Defaults to false.
  ///
  /// Returns the next notification date, or null if the notification is disabled
  /// or non-repeating.
  DateTime? getNextNotificationDateFromBase(
    DateTime baseDate, {
    bool useCurrentTime = false,
  }) {
    if (!enabled || repeatFrequency == RepeatFrequency.none) {
      return null;
    }

    // Determine which time to use for the notification
    final DateTime baseWithTime;
    if (useCurrentTime) {
      // Use the time from the baseDate (current time when activity was logged)
      baseWithTime = baseDate;
    } else {
      // Preserve the original time from the notification, but use the base date
      baseWithTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        notificationDateTime.hour,
        notificationDateTime.minute,
        notificationDateTime.second,
        notificationDateTime.millisecond,
        notificationDateTime.microsecond,
      );
    }

    // Calculate the next occurrence from the base date
    switch (repeatFrequency) {
      case RepeatFrequency.daily:
        return baseWithTime.add(Duration(days: repeatInterval));
      case RepeatFrequency.weekly:
        return baseWithTime.add(Duration(days: 7 * repeatInterval));
      case RepeatFrequency.monthly:
        return _addMonths(baseWithTime, repeatInterval);
      case RepeatFrequency.yearly:
        return _addYears(baseWithTime, repeatInterval);
      case RepeatFrequency.none:
        return null;
    }
  }

  /// Calculate the next notification date considering activity logs.
  ///
  /// This is the primary method for determining when the next notification
  /// should occur, as it considers the user's actual logged activities.
  ///
  /// Priority order:
  /// 1. If matching activities exist, calculate from most recent activity
  /// 2. If notificationDateTime is in the future, return it directly
  /// 3. Otherwise, fall back to standard calculation from notificationDateTime
  ///
  /// [activityLogs] - The list of activity logs to consider
  /// [useCurrentTime] - If true, uses the time from the activity log instead of
  ///                    preserving the original notification time. Defaults to false.
  ///
  /// Returns the next notification date, or null if the notification is disabled
  /// or non-repeating.
  DateTime? getNextNotificationDateWithActivity(
    List<NotificationLog> activityLogs, {
    bool useCurrentTime = false,
  }) {
    if (!enabled || repeatFrequency == RepeatFrequency.none) {
      return null;
    }

    final now = DateTime.now();

    // Find matching activity logs first - these take priority
    final matchingLogs = activityLogs.where((log) {
      return matchesActivityLog(log.type, log.customCategory);
    }).toList();

    if (matchingLogs.isNotEmpty) {
      // Sort by date (newest first) and get the most recent
      matchingLogs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      final lastActivity = matchingLogs.first;

      // Calculate next date from the last activity
      return getNextNotificationDateFromBase(
        lastActivity.loggedAt,
        useCurrentTime: useCurrentTime,
      );
    }

    // No matching activity logs - use the original notification date
    // If notification is in the future, return it directly
    if (!notificationDateTime.isBefore(now)) {
      return notificationDateTime;
    }

    // Fall back to the standard calculation based on original date
    return getNextNotificationDate();
  }

  /// Check if an activity log matches this notification's category.
  ///
  /// For 'other' type notifications, matches are based on the custom category name.
  /// For standard types, matches are based on the notification type.
  ///
  /// [logType] - The type of the activity log
  /// [logCustomCategory] - The custom category of the activity log (for 'other' type)
  ///
  /// Returns true if the activity log matches this notification's category.
  bool matchesActivityLog(NotificationType logType, String? logCustomCategory) {
    // Types must match
    if (type != logType) {
      return false;
    }

    // For 'other' type, also match custom category
    if (type == NotificationType.other) {
      // Both must have a custom category, or both must not have one
      final thisCategory = customCategory?.toLowerCase().trim() ?? '';
      final logCategory = logCustomCategory?.toLowerCase().trim() ?? '';
      return thisCategory == logCategory;
    }

    // For standard types, type match is sufficient
    return true;
  }

  /// Calculate next daily occurrence using optimized math
  DateTime _getNextDailyDate(DateTime now) {
    final daysSinceStart = now.difference(notificationDateTime).inDays;
    final intervalsPassed = (daysSinceStart / repeatInterval).floor();
    final nextInterval = intervalsPassed + 1;
    return notificationDateTime.add(
      Duration(days: repeatInterval * nextInterval),
    );
  }

  /// Calculate next weekly occurrence using optimized math
  DateTime _getNextWeeklyDate(DateTime now) {
    final daysSinceStart = now.difference(notificationDateTime).inDays;
    final weeksSinceStart = (daysSinceStart / 7).floor();
    final intervalsPassed = (weeksSinceStart / repeatInterval).floor();
    final nextInterval = intervalsPassed + 1;
    return notificationDateTime.add(
      Duration(days: 7 * repeatInterval * nextInterval),
    );
  }

  /// Calculate next monthly occurrence
  DateTime _getNextMonthlyDate(DateTime now) {
    // Calculate how many months have passed
    int monthsSinceStart =
        (now.year - notificationDateTime.year) * 12 +
        (now.month - notificationDateTime.month);

    // Calculate the next interval
    int intervalsPassed = (monthsSinceStart / repeatInterval).floor();
    DateTime candidate = _addMonths(
      notificationDateTime,
      repeatInterval * intervalsPassed,
    );

    // If candidate is still before now, add one more interval
    if (candidate.isBefore(now)) {
      candidate = _addMonths(
        notificationDateTime,
        repeatInterval * (intervalsPassed + 1),
      );
    }

    return candidate;
  }

  /// Calculate next yearly occurrence
  DateTime _getNextYearlyDate(DateTime now) {
    // Calculate how many years have passed
    int yearsSinceStart = now.year - notificationDateTime.year;

    // Calculate the next interval
    int intervalsPassed = (yearsSinceStart / repeatInterval).floor();
    DateTime candidate = _addYears(
      notificationDateTime,
      repeatInterval * intervalsPassed,
    );

    // If candidate is still before now, add one more interval
    if (candidate.isBefore(now)) {
      candidate = _addYears(
        notificationDateTime,
        repeatInterval * (intervalsPassed + 1),
      );
    }

    return candidate;
  }

  /// Check if the notification should trigger now
  /// For repeating notifications, checks if we're at or past a scheduled occurrence
  bool shouldTrigger({DateTime? referenceTime}) {
    if (!enabled) return false;

    final now = referenceTime ?? DateTime.now();

    // For non-repeating notifications, just check if time has passed
    if (repeatFrequency == RepeatFrequency.none) {
      return notificationDateTime.isBefore(now) ||
          notificationDateTime.isAtSameMomentAs(now);
    }

    // For repeating notifications, check if the original time has passed
    // (meaning at least one occurrence should have happened)
    if (notificationDateTime.isAfter(now)) {
      return false; // First occurrence hasn't happened yet
    }

    // Calculate how long since the last scheduled occurrence
    switch (repeatFrequency) {
      case RepeatFrequency.daily:
        final daysSinceStart = now.difference(notificationDateTime).inDays;
        final intervalsPassed = (daysSinceStart / repeatInterval).floor();
        final lastOccurrence = notificationDateTime.add(
          Duration(days: repeatInterval * intervalsPassed),
        );
        // Trigger if we're at or past the last occurrence time
        return !now.isBefore(lastOccurrence);

      case RepeatFrequency.weekly:
        final daysSinceStart = now.difference(notificationDateTime).inDays;
        final weeksSinceStart = (daysSinceStart / 7).floor();
        final intervalsPassed = (weeksSinceStart / repeatInterval).floor();
        final lastOccurrence = notificationDateTime.add(
          Duration(days: 7 * repeatInterval * intervalsPassed),
        );
        return !now.isBefore(lastOccurrence);

      case RepeatFrequency.monthly:
        // For monthly, we need to check if we've reached the day-of-month
        int monthsSinceStart =
            (now.year - notificationDateTime.year) * 12 +
            (now.month - notificationDateTime.month);
        if (monthsSinceStart >= 0 && (monthsSinceStart % repeatInterval == 0)) {
          // We're in a trigger month, check if we've passed the trigger day
          if (now.day > notificationDateTime.day) {
            return true;
          } else if (now.day == notificationDateTime.day) {
            // Same day, check time
            return now.hour >= notificationDateTime.hour &&
                now.minute >= notificationDateTime.minute;
          }
        }
        return false;

      case RepeatFrequency.yearly:
        // For yearly, check if we've reached the month and day
        int yearsSinceStart = now.year - notificationDateTime.year;
        if (yearsSinceStart >= 0 && (yearsSinceStart % repeatInterval == 0)) {
          // We're in a trigger year, check month and day
          if (now.month > notificationDateTime.month) {
            return true;
          } else if (now.month == notificationDateTime.month) {
            if (now.day > notificationDateTime.day) {
              return true;
            } else if (now.day == notificationDateTime.day) {
              return now.hour >= notificationDateTime.hour &&
                  now.minute >= notificationDateTime.minute;
            }
          }
        }
        return false;

      case RepeatFrequency.none:
        return false;
    }
  }

  /// Safely add months to a date, handling edge cases like end-of-month
  static DateTime _addMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;

    // Handle month overflow
    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear -= 1;
    }

    // Handle day overflow (e.g., Jan 31 + 1 month = Feb 28/29)
    int newDay = date.day;
    int maxDaysInMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > maxDaysInMonth) {
      newDay = maxDaysInMonth;
    }

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Safely add years to a date, handling leap year edge cases
  static DateTime _addYears(DateTime date, int years) {
    int newYear = date.year + years;
    int newMonth = date.month;
    int newDay = date.day;

    // Handle Feb 29 on leap year -> non-leap year
    if (newMonth == 2 && newDay == 29) {
      // Check if the target year is a leap year
      bool isLeapYear =
          (newYear % 4 == 0) && ((newYear % 100 != 0) || (newYear % 400 == 0));
      if (!isLeapYear) {
        newDay = 28; // Adjust to Feb 28
      }
    }

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  /// Get display name for the notification
  /// Shows custom category for 'other' type if available
  String getDisplayName() {
    if (type == NotificationType.other &&
        customCategory != null &&
        customCategory!.isNotEmpty) {
      return customCategory!;
    }
    return type.displayName;
  }
}
