import 'package:uuid/uuid.dart';
import 'tank_notification.dart';

/// Model for notification log entries
/// Tracks when users complete notification actions
class NotificationLog {
  final String id;
  final NotificationType type;
  final String? customCategory; // For 'other' type notifications
  final DateTime loggedAt;
  final String? notes;
  final String? notificationId; // Reference to the notification that triggered this log

  NotificationLog({
    required this.id,
    required this.type,
    this.customCategory,
    required this.loggedAt,
    this.notes,
    this.notificationId,
  });

  /// Factory method to create a new log entry
  factory NotificationLog.create({
    required NotificationType type,
    String? customCategory,
    String? notes,
    String? notificationId,
  }) {
    return NotificationLog(
      id: const Uuid().v4(),
      type: type,
      customCategory: customCategory,
      loggedAt: DateTime.now(),
      notes: notes,
      notificationId: notificationId,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'customCategory': customCategory,
      'loggedAt': loggedAt.toIso8601String(),
      'notes': notes,
      'notificationId': notificationId,
    };
  }

  /// Deserialize from JSON
  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      id: json['id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      customCategory: json['customCategory'] as String?,
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      notes: json['notes'] as String?,
      notificationId: json['notificationId'] as String?,
    );
  }

  /// Create a copy with modifications
  NotificationLog copyWith({
    String? id,
    NotificationType? type,
    String? customCategory,
    DateTime? loggedAt,
    String? notes,
    String? notificationId,
  }) {
    return NotificationLog(
      id: id ?? this.id,
      type: type ?? this.type,
      customCategory: customCategory ?? this.customCategory,
      loggedAt: loggedAt ?? this.loggedAt,
      notes: notes ?? this.notes,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  /// Get display name for the log entry
  String getDisplayName() {
    if (type == NotificationType.other && customCategory != null && customCategory!.isNotEmpty) {
      return customCategory!;
    }
    return type.displayName;
  }
}
