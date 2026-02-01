import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/notification_log.dart';
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

    test('should trigger on scheduled daily occurrences', () {
      // Set notification for 9:00 AM yesterday
      final yesterday9am = DateTime.now().subtract(const Duration(days: 1))
          .copyWith(hour: 9, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: yesterday9am,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
      );

      // Should trigger now (we're past today's 9:00 AM)
      final now = DateTime.now();
      final today9am = DateTime(now.year, now.month, now.day, 9, 0);
      
      if (now.isAfter(today9am)) {
        expect(notification.shouldTrigger(), true);
      }
    });

    test('should trigger on scheduled weekly occurrences', () {
      // Set notification for 1 week + 1 day ago
      final pastDate = DateTime.now().subtract(const Duration(days: 8))
          .copyWith(hour: 10, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      
      final notification = TankNotification.create(
        type: NotificationType.waterChange,
        notificationDateTime: pastDate,
        repeatFrequency: RepeatFrequency.weekly,
        repeatInterval: 1,
      );

      expect(notification.shouldTrigger(), true);
    });

    test('should not trigger before first occurrence', () {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: futureDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
      );

      expect(notification.shouldTrigger(), false);
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

  group('TankNotification - Performance Tests', () {
    test('should efficiently handle dates far in the past (daily)', () {
      // Test notification from 5 years ago
      final veryOldDate = DateTime.now().subtract(const Duration(days: 365 * 5));
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: veryOldDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
      );

      // Should calculate next date quickly without looping 1800+ times
      final stopwatch = Stopwatch()..start();
      final nextDate = notification.getNextNotificationDate();
      stopwatch.stop();

      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
      // Should complete in less than 10ms (was looping ~1800 times before)
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('should efficiently handle dates far in the past (weekly)', () {
      // Test notification from 3 years ago
      final veryOldDate = DateTime.now().subtract(const Duration(days: 365 * 3));
      final notification = TankNotification.create(
        type: NotificationType.waterChange,
        notificationDateTime: veryOldDate,
        repeatFrequency: RepeatFrequency.weekly,
        repeatInterval: 1,
      );

      final stopwatch = Stopwatch()..start();
      final nextDate = notification.getNextNotificationDate();
      stopwatch.stop();

      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('should efficiently handle dates far in the past (monthly)', () {
      // Test notification from 10 years ago
      final veryOldDate = DateTime.now().subtract(const Duration(days: 365 * 10));
      final notification = TankNotification.create(
        type: NotificationType.maintenance,
        notificationDateTime: veryOldDate,
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 1,
      );

      final stopwatch = Stopwatch()..start();
      final nextDate = notification.getNextNotificationDate();
      stopwatch.stop();

      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('should efficiently handle dates far in the past (yearly)', () {
      // Test notification from 20 years ago
      final veryOldDate = DateTime.now().subtract(const Duration(days: 365 * 20));
      final notification = TankNotification.create(
        type: NotificationType.other,
        notificationDateTime: veryOldDate,
        repeatFrequency: RepeatFrequency.yearly,
        repeatInterval: 1,
      );

      final stopwatch = Stopwatch()..start();
      final nextDate = notification.getNextNotificationDate();
      stopwatch.stop();

      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('should handle custom intervals efficiently', () {
      // Test with every 3 days, notification from 2 years ago
      final oldDate = DateTime.now().subtract(const Duration(days: 730));
      final notification = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: oldDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 3,
      );

      final stopwatch = Stopwatch()..start();
      final nextDate = notification.getNextNotificationDate();
      stopwatch.stop();

      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), true);
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('should return notification date immediately if in future', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: futureDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
      );

      final stopwatch = Stopwatch()..start();
      final nextDate = notification.getNextNotificationDate();
      stopwatch.stop();

      expect(nextDate, futureDate);
      // Should be nearly instant
      expect(stopwatch.elapsedMilliseconds, lessThan(5));
    });
  });

  group('TankNotification - Activity-Based Scheduling', () {
    test('should calculate next date from base date for daily frequency', () {
      final baseDate = DateTime(2024, 6, 15, 10, 0); // Activity at 10am
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0), // Original at 9am
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 2, // Every 2 days
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final nextDate = notification.getNextNotificationDateFromBase(baseDate);

      expect(nextDate, isNotNull);
      // Should be 2 days after base date, at the original time (9am)
      expect(nextDate, DateTime(2024, 6, 17, 9, 0));
    });

    test('should calculate next date from base date for weekly frequency', () {
      final baseDate = DateTime(2024, 6, 15);
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.waterChange,
        notificationDateTime: DateTime(2024, 6, 1, 10, 30),
        repeatFrequency: RepeatFrequency.weekly,
        repeatInterval: 1, // Every week
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final nextDate = notification.getNextNotificationDateFromBase(baseDate);

      expect(nextDate, isNotNull);
      // Should be 7 days after base date, at the original time (10:30am)
      expect(nextDate, DateTime(2024, 6, 22, 10, 30));
    });

    test('should calculate next date from base date for monthly frequency', () {
      final baseDate = DateTime(2024, 6, 15, 14, 0);
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.maintenance,
        notificationDateTime: DateTime(2024, 5, 1, 9, 0),
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final nextDate = notification.getNextNotificationDateFromBase(baseDate);

      expect(nextDate, isNotNull);
      // Should be 1 month after base date
      expect(nextDate!.year, 2024);
      expect(nextDate.month, 7);
      expect(nextDate.day, 15);
      expect(nextDate.hour, 9); // Preserves original time
    });

    test('should calculate next date from base date for yearly frequency', () {
      final baseDate = DateTime(2024, 6, 15);
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.other,
        notificationDateTime: DateTime(2023, 1, 1, 12, 0),
        repeatFrequency: RepeatFrequency.yearly,
        repeatInterval: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final nextDate = notification.getNextNotificationDateFromBase(baseDate);

      expect(nextDate, isNotNull);
      // Should be 1 year after base date
      expect(nextDate!.year, 2025);
      expect(nextDate.month, 6);
      expect(nextDate.day, 15);
    });

    test('should return null for non-repeating notifications from base', () {
      final baseDate = DateTime(2024, 6, 15);
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.none,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final nextDate = notification.getNextNotificationDateFromBase(baseDate);

      expect(nextDate, isNull);
    });

    test('should return null for disabled notifications from base', () {
      final baseDate = DateTime(2024, 6, 15);
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: false,
      );

      final nextDate = notification.getNextNotificationDateFromBase(baseDate);

      expect(nextDate, isNull);
    });

    test('should preserve original notification time when calculating from base', () {
      final baseDate = DateTime(2024, 6, 15, 14, 30, 45); // Different time
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 8, 15, 30), // Specific time
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final nextDate = notification.getNextNotificationDateFromBase(baseDate);

      expect(nextDate, isNotNull);
      expect(nextDate!.hour, 8);
      expect(nextDate.minute, 15);
      expect(nextDate.second, 30);
    });

    test('should handle custom repeat intervals from base', () {
      final baseDate = DateTime(2024, 6, 15);
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.dosing,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 3, // Every 3 days
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final nextDate = notification.getNextNotificationDateFromBase(baseDate);

      expect(nextDate, isNotNull);
      expect(nextDate, DateTime(2024, 6, 18, 9, 0)); // 3 days after base
    });
  });

  group('TankNotification - Activity Log Matching', () {
    test('should match feeding activity log', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      expect(notification.matchesActivityLog(NotificationType.feeding, null), true);
      expect(notification.matchesActivityLog(NotificationType.dosing, null), false);
    });

    test('should match other type with same custom category', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.other,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        customCategory: 'Filter Cleaning',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      expect(notification.matchesActivityLog(NotificationType.other, 'Filter Cleaning'), true);
      expect(notification.matchesActivityLog(NotificationType.other, 'filter cleaning'), true); // Case insensitive
      expect(notification.matchesActivityLog(NotificationType.other, ' Filter Cleaning '), true); // Trims whitespace
      expect(notification.matchesActivityLog(NotificationType.other, 'Something Else'), false);
    });

    test('should not match other type with different custom category', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.other,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        customCategory: 'Filter Cleaning',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      expect(notification.matchesActivityLog(NotificationType.other, 'Coral Dipping'), false);
    });

    test('should not match different notification type', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.waterChange,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.weekly,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      expect(notification.matchesActivityLog(NotificationType.feeding, null), false);
      expect(notification.matchesActivityLog(NotificationType.waterChange, null), true);
    });

    test('should match other type with null custom categories on both sides', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.other,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        customCategory: null,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      expect(notification.matchesActivityLog(NotificationType.other, null), true);
      expect(notification.matchesActivityLog(NotificationType.other, ''), true); // Empty = null
    });
  });

  group('TankNotification - getNextNotificationDateWithActivity', () {
    test('should calculate next date from most recent matching activity', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 2, // Every 2 days
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final activityLogs = [
        NotificationLog(
          id: 'log-1',
          type: NotificationType.feeding,
          loggedAt: DateTime(2024, 6, 10, 10, 0),
          customCategory: null,
          notes: null,
          notificationId: null,
        ),
        NotificationLog(
          id: 'log-2',
          type: NotificationType.feeding,
          loggedAt: DateTime(2024, 6, 15, 14, 0), // Most recent
          customCategory: null,
          notes: null,
          notificationId: null,
        ),
      ];

      final nextDate = notification.getNextNotificationDateWithActivity(activityLogs);

      expect(nextDate, isNotNull);
      // Should be 2 days after most recent activity (June 15), at original time (9am)
      expect(nextDate, DateTime(2024, 6, 17, 9, 0));
    });

    test('should fall back to standard calculation when no matching activities', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      // Activity logs with different type
      final activityLogs = [
        NotificationLog(
          id: 'log-1',
          type: NotificationType.waterChange, // Different type
          loggedAt: DateTime(2024, 6, 15, 14, 0),
          customCategory: null,
          notes: null,
          notificationId: null,
        ),
      ];

      final nextDate = notification.getNextNotificationDateWithActivity(activityLogs);

      // Should fall back to standard calculation (getNextNotificationDate)
      expect(nextDate, isNotNull);
      expect(nextDate, notification.getNextNotificationDate());
    });

    test('should return null for disabled notifications', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: false,
      );

      final activityLogs = [
        NotificationLog(
          id: 'log-1',
          type: NotificationType.feeding,
          loggedAt: DateTime(2024, 6, 15, 14, 0),
          customCategory: null,
          notes: null,
          notificationId: null,
        ),
      ];

      expect(notification.getNextNotificationDateWithActivity(activityLogs), isNull);
    });

    test('should return null for non-repeating notifications', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.none,
        repeatInterval: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final activityLogs = [
        NotificationLog(
          id: 'log-1',
          type: NotificationType.feeding,
          loggedAt: DateTime(2024, 6, 15, 14, 0),
          customCategory: null,
          notes: null,
          notificationId: null,
        ),
      ];

      expect(notification.getNextNotificationDateWithActivity(activityLogs), isNull);
    });

    test('should work with empty activity logs', () {
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 1, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      final nextDate = notification.getNextNotificationDateWithActivity([]);

      // Should fall back to standard calculation
      expect(nextDate, notification.getNextNotificationDate());
    });

    test('should return notificationDateTime directly when it is in the future', () {
      // Create a notification with a date/time in the future
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final notification = TankNotification(
        id: 'test-id',
        type: NotificationType.feeding,
        notificationDateTime: futureDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        enabled: true,
      );

      // Activity logs exist but should be ignored since notificationDateTime is in the future
      final activityLogs = [
        NotificationLog(
          id: 'log-1',
          type: NotificationType.feeding,
          loggedAt: DateTime.now().subtract(const Duration(hours: 1)),
          customCategory: null,
          notes: null,
          notificationId: null,
        ),
      ];

      final nextDate = notification.getNextNotificationDateWithActivity(activityLogs);

      // Should return the notificationDateTime directly, ignoring activity logs
      expect(nextDate, futureDate);
    });
  });
}

