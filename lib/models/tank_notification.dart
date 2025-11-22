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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Calculate the next notification date based on repeat settings
  DateTime? getNextNotificationDate() {
    if (!enabled || repeatFrequency == RepeatFrequency.none) {
      return null;
    }

    final now = DateTime.now();
    DateTime nextDate = notificationDateTime;

    // If the notification date is in the past, calculate the next occurrence
    while (nextDate.isBefore(now)) {
      switch (repeatFrequency) {
        case RepeatFrequency.daily:
          nextDate = nextDate.add(Duration(days: repeatInterval));
          break;
        case RepeatFrequency.weekly:
          nextDate = nextDate.add(Duration(days: 7 * repeatInterval));
          break;
        case RepeatFrequency.monthly:
          nextDate = DateTime(
            nextDate.year,
            nextDate.month + repeatInterval,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          break;
        case RepeatFrequency.yearly:
          nextDate = DateTime(
            nextDate.year + repeatInterval,
            nextDate.month,
            nextDate.day,
            nextDate.hour,
            nextDate.minute,
          );
          break;
        case RepeatFrequency.none:
          return null;
      }
    }

    return nextDate;
  }

  /// Check if the notification should trigger now
  bool shouldTrigger({DateTime? referenceTime}) {
    if (!enabled) return false;
    
    final now = referenceTime ?? DateTime.now();
    final nextDate = getNextNotificationDate();
    
    if (nextDate == null) {
      // One-time notification
      return notificationDateTime.isBefore(now) || 
             notificationDateTime.isAtSameMomentAs(now);
    }
    
    return nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now);
  }
}
