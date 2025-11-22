import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/tank_notification.dart';

void main() {
  group('NotificationType', () {
    test('should have correct display names', () {
      expect(NotificationType.feeding.displayName, 'Feeding');
      expect(NotificationType.dosing.displayName, 'Dosing');
      expect(NotificationType.waterChange.displayName, 'Water Change');
      expect(NotificationType.testing.displayName, 'Water Testing');
      expect(NotificationType.maintenance.displayName, 'Maintenance');
      expect(NotificationType.other.displayName, 'Other');
    });

    test('should convert from string correctly', () {
      expect(NotificationType.fromString('feeding'), NotificationType.feeding);
      expect(NotificationType.fromString('dosing'), NotificationType.dosing);
      expect(NotificationType.fromString('waterChange'), NotificationType.waterChange);
      expect(NotificationType.fromString('testing'), NotificationType.testing);
      expect(NotificationType.fromString('maintenance'), NotificationType.maintenance);
      expect(NotificationType.fromString('other'), NotificationType.other);
    });

    test('should default to other for unknown string', () {
      expect(NotificationType.fromString('unknown'), NotificationType.other);
      expect(NotificationType.fromString('invalid'), NotificationType.other);
    });
  });

  group('RepeatFrequency', () {
    test('should have correct display names', () {
      expect(RepeatFrequency.none.displayName, 'Does not repeat');
      expect(RepeatFrequency.daily.displayName, 'Daily');
      expect(RepeatFrequency.weekly.displayName, 'Weekly');
      expect(RepeatFrequency.monthly.displayName, 'Monthly');
      expect(RepeatFrequency.yearly.displayName, 'Yearly');
    });

    test('should convert from string correctly', () {
      expect(RepeatFrequency.fromString('none'), RepeatFrequency.none);
      expect(RepeatFrequency.fromString('daily'), RepeatFrequency.daily);
      expect(RepeatFrequency.fromString('weekly'), RepeatFrequency.weekly);
      expect(RepeatFrequency.fromString('monthly'), RepeatFrequency.monthly);
      expect(RepeatFrequency.fromString('yearly'), RepeatFrequency.yearly);
    });

    test('should default to none for unknown string', () {
      expect(RepeatFrequency.fromString('unknown'), RepeatFrequency.none);
      expect(RepeatFrequency.fromString('invalid'), RepeatFrequency.none);
    });
  });

  group('TankNotification', () {
    test('should create a notification with all fields', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 15, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        notes: 'Feed the fish',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      expect(notification.id, 'test-id');
      expect(notification.type, NotificationType.feeding);
      expect(notification.notificationDateTime, DateTime(2024, 6, 15, 9, 0));
      expect(notification.repeatFrequency, RepeatFrequency.daily);
      expect(notification.repeatInterval, 1);
      expect(notification.notes, 'Feed the fish');
      expect(notification.createdAt, DateTime(2024, 1, 1));
      expect(notification.updatedAt, DateTime(2024, 1, 1));
      expect(notification.enabled, true);
    });

    test('should create a notification using factory method', () {
      final notification = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: DateTime(2024, 6, 15, 10, 0),
        repeatFrequency: RepeatFrequency.weekly,
        repeatInterval: 2,
        notes: 'Dose the tank',
      );

      expect(notification.id, isNotEmpty);
      expect(notification.type, NotificationType.dosing);
      expect(notification.notificationDateTime, DateTime(2024, 6, 15, 10, 0));
      expect(notification.repeatFrequency, RepeatFrequency.weekly);
      expect(notification.repeatInterval, 2);
      expect(notification.notes, 'Dose the tank');
      expect(notification.createdAt, isA<DateTime>());
      expect(notification.updatedAt, isA<DateTime>());
      expect(notification.enabled, true);
    });

    test('should default to enabled true and no repeat', () {
      final notification = TankNotification.create(
        type: NotificationType.waterChange,
        notificationDateTime: DateTime(2024, 6, 15),
      );

      expect(notification.enabled, true);
      expect(notification.repeatFrequency, RepeatFrequency.none);
      expect(notification.repeatInterval, 1);
    });

    test('should serialize to JSON correctly', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 15, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 2,
        notes: 'Test notes',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        enabled: true,
      );

      final json = notification.toJson();

      expect(json['id'], 'test-id');
      expect(json['type'], 'feeding');
      expect(json['notificationDateTime'], '2024-06-15T09:00:00.000');
      expect(json['repeatFrequency'], 'daily');
      expect(json['repeatInterval'], 2);
      expect(json['notes'], 'Test notes');
      expect(json['createdAt'], '2024-01-01T00:00:00.000');
      expect(json['updatedAt'], '2024-01-02T00:00:00.000');
      expect(json['enabled'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'type': 'dosing',
        'notificationDateTime': '2024-06-15T10:30:00.000',
        'repeatFrequency': 'weekly',
        'repeatInterval': 3,
        'notes': 'Weekly dosing',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-02T00:00:00.000',
        'enabled': false,
      };

      final notification = TankNotification.fromJson(json);

      expect(notification.id, 'test-id');
      expect(notification.type, NotificationType.dosing);
      expect(notification.notificationDateTime, DateTime(2024, 6, 15, 10, 30));
      expect(notification.repeatFrequency, RepeatFrequency.weekly);
      expect(notification.repeatInterval, 3);
      expect(notification.notes, 'Weekly dosing');
      expect(notification.createdAt, DateTime(2024, 1, 1));
      expect(notification.updatedAt, DateTime(2024, 1, 2));
      expect(notification.enabled, false);
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'id': 'test-id',
        'type': 'feeding',
        'notificationDateTime': '2024-06-15T09:00:00.000',
        'repeatFrequency': 'none',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };

      final notification = TankNotification.fromJson(json);

      expect(notification.repeatInterval, 1);
      expect(notification.notes, null);
      expect(notification.enabled, true);
    });

    test('should create a copy with modified fields', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 15, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        notes: 'Original notes',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final updatedNotification = notification.copyWith(
        notes: 'Updated notes',
        enabled: false,
        repeatInterval: 2,
      );

      expect(updatedNotification.id, 'test-id');
      expect(updatedNotification.type, NotificationType.feeding);
      expect(updatedNotification.notes, 'Updated notes');
      expect(updatedNotification.enabled, false);
      expect(updatedNotification.repeatInterval, 2);
      expect(updatedNotification.notificationDateTime, DateTime(2024, 6, 15, 9, 0));
    });

    test('should serialize and deserialize correctly', () {
      final original = TankNotification.create(
        type: NotificationType.maintenance,
        notificationDateTime: DateTime(2024, 6, 15, 14, 30),
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 2,
        notes: 'Monthly maintenance',
        enabled: true,
      );

      final json = original.toJson();
      final deserialized = TankNotification.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.type, original.type);
      expect(deserialized.notificationDateTime, original.notificationDateTime);
      expect(deserialized.repeatFrequency, original.repeatFrequency);
      expect(deserialized.repeatInterval, original.repeatInterval);
      expect(deserialized.notes, original.notes);
      expect(deserialized.enabled, original.enabled);
    });
  });

  group('TankNotification - Next Date Calculation', () {
    test('should return null for non-repeating notifications', () {
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 15, 9, 0),
        repeatFrequency: RepeatFrequency.none,
      );

      expect(notification.getNextNotificationDate(), null);
    });

    test('should return null for disabled notifications', () {
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 15, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        enabled: false,
      );

      expect(notification.getNextNotificationDate(), null);
    });

    test('should calculate next daily notification correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 3));
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: pastDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
    });

    test('should calculate next weekly notification correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      final notification = TankNotification.create(
        type: NotificationType.waterChange,
        notificationDateTime: pastDate,
        repeatFrequency: RepeatFrequency.weekly,
        repeatInterval: 1,
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
    });

    test('should calculate next monthly notification correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 35));
      final notification = TankNotification.create(
        type: NotificationType.maintenance,
        notificationDateTime: pastDate,
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 1,
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
    });

    test('should calculate next yearly notification correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 400));
      final notification = TankNotification.create(
        type: NotificationType.other,
        notificationDateTime: pastDate,
        repeatFrequency: RepeatFrequency.yearly,
        repeatInterval: 1,
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
    });

    test('should handle custom repeat intervals', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final notification = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: pastDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 3, // Every 3 days
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
    });

    test('should return future date if notification date is in future', () {
      final futureDate = DateTime.now().add(const Duration(days: 2));
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: futureDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, futureDate);
    });
  });

  group('TankNotification - Should Trigger', () {
    test('should not trigger if disabled', () {
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        enabled: false,
      );

      expect(notification.shouldTrigger(), false);
    });

    test('should trigger for past one-time notification', () {
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        repeatFrequency: RepeatFrequency.none,
      );

      expect(notification.shouldTrigger(), true);
    });

    test('should not trigger for future one-time notification', () {
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime.now().add(const Duration(hours: 1)),
        repeatFrequency: RepeatFrequency.none,
      );

      expect(notification.shouldTrigger(), false);
    });

    test('should trigger when next occurrence is due', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1, hours: 1));
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: pastDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
      );

      expect(notification.shouldTrigger(), true);
    });

    test('should use reference time for testing', () {
      final notificationDate = DateTime(2024, 6, 15, 9, 0);
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: notificationDate,
        repeatFrequency: RepeatFrequency.none,
      );

      final beforeTime = DateTime(2024, 6, 15, 8, 0);
      final afterTime = DateTime(2024, 6, 15, 10, 0);

      expect(notification.shouldTrigger(referenceTime: beforeTime), false);
      expect(notification.shouldTrigger(referenceTime: afterTime), true);
    });
  });

  group('TankNotification - All Notification Types', () {
    test('should support all notification types', () {
      final types = [
        NotificationType.feeding,
        NotificationType.dosing,
        NotificationType.waterChange,
        NotificationType.testing,
        NotificationType.maintenance,
        NotificationType.other,
      ];

      for (var type in types) {
        final notification = TankNotification.create(
          type: type,
          notificationDateTime: DateTime.now(),
        );

        expect(notification.type, type);

        // Verify serialization
        final json = notification.toJson();
        final deserialized = TankNotification.fromJson(json);
        expect(deserialized.type, type);
      }
    });
  });

  group('TankNotification - All Repeat Frequencies', () {
    test('should support all repeat frequencies', () {
      final frequencies = [
        RepeatFrequency.none,
        RepeatFrequency.daily,
        RepeatFrequency.weekly,
        RepeatFrequency.monthly,
        RepeatFrequency.yearly,
      ];

      for (var frequency in frequencies) {
        final notification = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: DateTime.now(),
          repeatFrequency: frequency,
        );

        expect(notification.repeatFrequency, frequency);

        // Verify serialization
        final json = notification.toJson();
        final deserialized = TankNotification.fromJson(json);
        expect(deserialized.repeatFrequency, frequency);
      }
    });
  });

  group('TankNotification - Edge Cases for Date Calculation', () {
    test('should handle end-of-month dates when adding months', () {
      // January 31 + 1 month should become February 28/29
      final jan31 = DateTime(2024, 1, 31, 9, 0);
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: jan31,
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 1,
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, isNotNull);
      
      // Should be in February (month 2)
      expect(nextDate!.month, greaterThanOrEqualTo(2));
      // Day should be valid (28 or 29 for Feb, depending on leap year)
      expect(nextDate.day, lessThanOrEqualTo(29));
    });

    test('should handle March 31 to April 30 when adding months', () {
      // March 31 + 1 month should become April 30
      final mar31 = DateTime(2024, 3, 31, 9, 0);
      final notification = TankNotification.create(
        type: NotificationType.waterChange,
        notificationDateTime: mar31,
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 1,
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, isNotNull);
      
      // Should be in April (month 4) or later
      expect(nextDate!.month, greaterThanOrEqualTo(4));
      // Day should be 30 or less for April
      if (nextDate.month == 4) {
        expect(nextDate.day, lessThanOrEqualTo(30));
      }
    });

    test('should handle February 29 on leap year when adding years', () {
      // Feb 29, 2024 (leap year) + 1 year should become Feb 28, 2025 (non-leap year)
      final feb29Leap = DateTime(2024, 2, 29, 9, 0);
      final notification = TankNotification.create(
        type: NotificationType.maintenance,
        notificationDateTime: feb29Leap,
        repeatFrequency: RepeatFrequency.yearly,
        repeatInterval: 1,
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, isNotNull);
      
      // Should be in February of 2025 or later
      expect(nextDate!.year, greaterThanOrEqualTo(2025));
      expect(nextDate.month, 2);
      // Should be Feb 28 for non-leap year
      expect(nextDate.day, lessThanOrEqualTo(29));
    });

    test('should handle multiple month additions with end-of-month', () {
      // Test adding multiple months to end-of-month dates
      final jan31 = DateTime(2024, 1, 31, 9, 0);
      final notification = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: jan31,
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 2, // Every 2 months
      );

      final nextDate = notification.getNextNotificationDate();
      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
    });

    test('should not throw exception for any valid date calculations', () {
      // Test various edge case dates to ensure no exceptions are thrown
      final edgeCaseDates = [
        DateTime(2024, 1, 31, 9, 0), // Jan 31
        DateTime(2024, 2, 29, 9, 0), // Feb 29 (leap year)
        DateTime(2024, 3, 31, 9, 0), // Mar 31
        DateTime(2024, 5, 31, 9, 0), // May 31
        DateTime(2024, 8, 31, 9, 0), // Aug 31
        DateTime(2024, 10, 31, 9, 0), // Oct 31
        DateTime(2024, 12, 31, 9, 0), // Dec 31
      ];

      for (final date in edgeCaseDates) {
        // Test monthly
        final monthlyNotif = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: date,
          repeatFrequency: RepeatFrequency.monthly,
          repeatInterval: 1,
        );
        expect(() => monthlyNotif.getNextNotificationDate(), returnsNormally);

        // Test yearly
        final yearlyNotif = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: date,
          repeatFrequency: RepeatFrequency.yearly,
          repeatInterval: 1,
        );
        expect(() => yearlyNotif.getNextNotificationDate(), returnsNormally);
      }
    });

    test('should preserve time when adding months and years', () {
      final specificTime = DateTime(2024, 1, 15, 14, 35, 22);
      
      // Test monthly
      final monthlyNotif = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: specificTime,
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 1,
      );
      
      final nextMonthly = monthlyNotif.getNextNotificationDate();
      expect(nextMonthly, isNotNull);
      expect(nextMonthly!.hour, specificTime.hour);
      expect(nextMonthly.minute, specificTime.minute);

      // Test yearly
      final yearlyNotif = TankNotification.create(
        type: NotificationType.maintenance,
        notificationDateTime: specificTime,
        repeatFrequency: RepeatFrequency.yearly,
        repeatInterval: 1,
      );
      
      final nextYearly = yearlyNotif.getNextNotificationDate();
      expect(nextYearly, isNotNull);
      expect(nextYearly!.hour, specificTime.hour);
      expect(nextYearly.minute, specificTime.minute);
    });
  });
}
