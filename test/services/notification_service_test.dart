import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/tank_notification.dart';
import 'package:fish_ai/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    test('should accept optional navigatorKey in initialize', () {
      final service = NotificationService();
      final navigatorKey = GlobalKey<NavigatorState>();
      
      // Verify the method can be called with navigatorKey parameter
      expect(
        () => service.initialize(navigatorKey: navigatorKey),
        returnsNormally,
      );
    });

    test('should accept initialize without navigatorKey (backward compatibility)', () {
      final service = NotificationService();
      
      // Verify the method can still be called without navigatorKey
      expect(
        () => service.initialize(),
        returnsNormally,
      );
    });

    test('should have sendTestNotification method with correct signature', () {
      final service = NotificationService();
      
      // Verify the method exists and can be called with required parameters
      expect(
        () => service.sendTestNotification(
          tankName: 'Test Tank',
          type: NotificationType.feeding,
        ),
        returnsNormally,
      );
    });

    test('should accept all notification types for test notifications', () {
      final service = NotificationService();
      
      // Test with each notification type
      for (final type in NotificationType.values) {
        expect(
          () => service.sendTestNotification(
            tankName: 'Test Tank',
            type: type,
          ),
          returnsNormally,
        );
      }
    });

    test('should handle different tank names', () {
      final service = NotificationService();
      
      // Test with various tank names
      final tankNames = [
        'Reef Tank',
        'Freshwater Aquarium',
        'Planted Tank 123',
        'Community Tank',
      ];
      
      for (final name in tankNames) {
        expect(
          () => service.sendTestNotification(
            tankName: name,
            type: NotificationType.feeding,
          ),
          returnsNormally,
        );
      }
    });

    test('should schedule non-repeating notifications', () async {
      final service = NotificationService();
      await service.initialize();
      
      // Create a non-repeating notification in the future
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: futureDate,
        repeatFrequency: RepeatFrequency.none,
        enabled: true,
      );
      
      // Schedule the notification
      final nextDate = await service.scheduleNotification(
        tankId: 'test-tank-id',
        tankName: 'Test Tank',
        notification: notification,
      );
      
      // Verify that a next date was returned (indicating it was scheduled)
      expect(nextDate, isNotNull);
      expect(nextDate, equals(futureDate));
    });

    test('should schedule repeating notifications', () async {
      final service = NotificationService();
      await service.initialize();
      
      // Create a repeating notification
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: pastDate,
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        enabled: true,
      );
      
      // Schedule the notification
      final nextDate = await service.scheduleNotification(
        tankId: 'test-tank-id',
        tankName: 'Test Tank',
        notification: notification,
      );
      
      // Verify that a next date was returned and it's in the future
      expect(nextDate, isNotNull);
      expect(nextDate!.isAfter(DateTime.now()), isTrue);
    });

    test('should not schedule disabled non-repeating notifications', () async {
      final service = NotificationService();
      await service.initialize();
      
      // Create a disabled non-repeating notification
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: futureDate,
        repeatFrequency: RepeatFrequency.none,
        enabled: false,
      );
      
      // Attempt to schedule the notification
      final nextDate = await service.scheduleNotification(
        tankId: 'test-tank-id',
        tankName: 'Test Tank',
        notification: notification,
      );
      
      // nextDate should still be returned (for updating the model),
      // but the actual platform notification won't be scheduled due to the disabled flag
      expect(nextDate, equals(futureDate));
    });

    group('notification action payload handling', () {
      test('parses preferred payload format tankId::notificationId', () {
        final service = NotificationService();
        final payload = service.parseNotificationPayloadForTesting(
          'tank-1::notif-1',
        );

        expect(payload, isNotNull);
        expect(payload!.tankId, equals('tank-1'));
        expect(payload.notificationId, equals('notif-1'));
      });

      test('parses legacy payload format tankId_notificationId', () {
        final service = NotificationService();
        final payload = service.parseNotificationPayloadForTesting(
          'tank-legacy_notif-legacy',
        );

        expect(payload, isNotNull);
        expect(payload!.tankId, equals('tank-legacy'));
        expect(payload.notificationId, equals('notif-legacy'));
      });

      test('returns null for invalid payload formats', () {
        final service = NotificationService();

        expect(
          service.parseNotificationPayloadForTesting('missing-separator'),
          isNull,
        );
        expect(
          service.parseNotificationPayloadForTesting('tank::notification::extra'),
          isNull,
        );
        expect(
          service.parseNotificationPayloadForTesting('_notification-only'),
          isNull,
        );
      });

      test('supports only known action IDs when payload is valid', () {
        final service = NotificationService();

        expect(
          service.canHandleNotificationActionForTesting(
            actionId: NotificationService.actionDone,
            payload: 'tank-1::notif-1',
          ),
          isTrue,
        );
        expect(
          service.canHandleNotificationActionForTesting(
            actionId: NotificationService.actionSnoozeDay,
            payload: 'tank-1::notif-1',
          ),
          isTrue,
        );
        expect(
          service.canHandleNotificationActionForTesting(
            actionId: NotificationService.actionSnoozeWeek,
            payload: 'tank-1::notif-1',
          ),
          isTrue,
        );
      });

      test('rejects non-action taps, empty payload, and invalid payload', () {
        final service = NotificationService();

        expect(
          service.canHandleNotificationActionForTesting(
            actionId: null,
            payload: 'tank-1::notif-1',
          ),
          isFalse,
        );
        expect(
          service.canHandleNotificationActionForTesting(
            actionId: 'unsupported-action',
            payload: 'tank-1::notif-1',
          ),
          isFalse,
        );
        expect(
          service.canHandleNotificationActionForTesting(
            actionId: NotificationService.actionDone,
            payload: '',
          ),
          isFalse,
        );
        expect(
          service.canHandleNotificationActionForTesting(
            actionId: NotificationService.actionDone,
            payload: 'invalid-payload',
          ),
          isFalse,
        );
      });

      test('returns true for supported actions with preferred payload format', () async {
        final service = NotificationService();
        service.setActionApplierOverrideForTesting(({
          required String tankId,
          required String notificationId,
          required String actionId,
        }) async {});

        final handled = await service.handleNotificationActionForTesting(
          actionId: NotificationService.actionDone,
          payload: 'tank-1::notif-1',
        );

        expect(handled, isTrue);
        service.clearActionApplierOverrideForTesting();
      });

      test('returns true for supported actions with legacy payload format', () async {
        final service = NotificationService();
        service.setActionApplierOverrideForTesting(({
          required String tankId,
          required String notificationId,
          required String actionId,
        }) async {});

        final handled = await service.handleNotificationActionForTesting(
          actionId: NotificationService.actionSnoozeDay,
          payload: 'tank-1_notif-1',
        );

        expect(handled, isTrue);
        service.clearActionApplierOverrideForTesting();
      });

      test('returns false for unsupported action ids', () async {
        final service = NotificationService();

        final handled = await service.handleNotificationActionForTesting(
          actionId: 'tap_action',
          payload: 'tank-1::notif-1',
        );

        expect(handled, isFalse);
      });
    });
  });
}
