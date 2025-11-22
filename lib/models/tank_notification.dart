import 'package:uuid/uuid.dart';

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
  final DateTime notificationDateTime; // When to notify
  final RepeatFrequency repeatFrequency; // How often to repeat
  final int repeatInterval; // Interval value (e.g., every X days/weeks/months/years)
  final String? notes; // Optional user notes
  final String? customTitle; // Optional custom notification title
  final bool useTankIcon; // Whether to use tank's custom icon for notification
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool enabled; // Whether the notification is active

  TankNotification({
    required this.id,
    required this.type,
    required this.notificationDateTime,
    this.repeatFrequency = RepeatFrequency.none,
    this.repeatInterval = 1,
    this.notes,
    this.customTitle,
    this.useTankIcon = false,
    required this.createdAt,
    required this.updatedAt,
    this.enabled = true,
  });

  /// Factory method to create a new notification
  factory TankNotification.create({
    required NotificationType type,
    required DateTime notificationDateTime,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
    int repeatInterval = 1,
    String? notes,
    String? customTitle,
    bool useTankIcon = false,
    bool enabled = true,
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
      useTankIcon: useTankIcon,
      createdAt: now,
      updatedAt: now,
      enabled: enabled,
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
      'useTankIcon': useTankIcon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'enabled': enabled,
    };
  }

  /// Deserialize from JSON
  factory TankNotification.fromJson(Map<String, dynamic> json) {
    return TankNotification(
      id: json['id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      notificationDateTime: DateTime.parse(json['notificationDateTime'] as String),
      repeatFrequency: RepeatFrequency.fromString(json['repeatFrequency'] as String),
      repeatInterval: json['repeatInterval'] as int? ?? 1,
      notes: json['notes'] as String?,
      customTitle: json['customTitle'] as String?,
      useTankIcon: json['useTankIcon'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  /// Create a copy with modified fields
  TankNotification copyWith({
    String? id,
    NotificationType? type,
    DateTime? notificationDateTime,
    RepeatFrequency? repeatFrequency,
    int? repeatInterval,
    String? notes,
    String? customTitle,
    bool? useTankIcon,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? enabled,
  }) {
    return TankNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      notificationDateTime: notificationDateTime ?? this.notificationDateTime,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      notes: notes ?? this.notes,
      customTitle: customTitle ?? this.customTitle,
      useTankIcon: useTankIcon ?? this.useTankIcon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enabled: enabled ?? this.enabled,
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

  /// Calculate next daily occurrence using optimized math
  DateTime _getNextDailyDate(DateTime now) {
    final daysSinceStart = now.difference(notificationDateTime).inDays;
    final intervalsPassed = (daysSinceStart / repeatInterval).floor();
    final nextInterval = intervalsPassed + 1;
    return notificationDateTime.add(Duration(days: repeatInterval * nextInterval));
  }

  /// Calculate next weekly occurrence using optimized math
  DateTime _getNextWeeklyDate(DateTime now) {
    final daysSinceStart = now.difference(notificationDateTime).inDays;
    final weeksSinceStart = (daysSinceStart / 7).floor();
    final intervalsPassed = (weeksSinceStart / repeatInterval).floor();
    final nextInterval = intervalsPassed + 1;
    return notificationDateTime.add(Duration(days: 7 * repeatInterval * nextInterval));
  }

  /// Calculate next monthly occurrence
  DateTime _getNextMonthlyDate(DateTime now) {
    // Calculate how many months have passed
    int monthsSinceStart = (now.year - notificationDateTime.year) * 12 + 
                           (now.month - notificationDateTime.month);
    
    // Calculate the next interval
    int intervalsPassed = (monthsSinceStart / repeatInterval).floor();
    DateTime candidate = _addMonths(notificationDateTime, repeatInterval * intervalsPassed);
    
    // If candidate is still before now, add one more interval
    if (candidate.isBefore(now)) {
      candidate = _addMonths(notificationDateTime, repeatInterval * (intervalsPassed + 1));
    }
    
    return candidate;
  }

  /// Calculate next yearly occurrence
  DateTime _getNextYearlyDate(DateTime now) {
    // Calculate how many years have passed
    int yearsSinceStart = now.year - notificationDateTime.year;
    
    // Calculate the next interval
    int intervalsPassed = (yearsSinceStart / repeatInterval).floor();
    DateTime candidate = _addYears(notificationDateTime, repeatInterval * intervalsPassed);
    
    // If candidate is still before now, add one more interval
    if (candidate.isBefore(now)) {
      candidate = _addYears(notificationDateTime, repeatInterval * (intervalsPassed + 1));
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
          Duration(days: repeatInterval * intervalsPassed)
        );
        // Trigger if we're at or past the last occurrence time
        return !now.isBefore(lastOccurrence);
        
      case RepeatFrequency.weekly:
        final daysSinceStart = now.difference(notificationDateTime).inDays;
        final weeksSinceStart = (daysSinceStart / 7).floor();
        final intervalsPassed = (weeksSinceStart / repeatInterval).floor();
        final lastOccurrence = notificationDateTime.add(
          Duration(days: 7 * repeatInterval * intervalsPassed)
        );
        return !now.isBefore(lastOccurrence);
        
      case RepeatFrequency.monthly:
        // For monthly, we need to check if we've reached the day-of-month
        int monthsSinceStart = (now.year - notificationDateTime.year) * 12 + 
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
      bool isLeapYear = (newYear % 4 == 0) && 
                        ((newYear % 100 != 0) || (newYear % 400 == 0));
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
}
