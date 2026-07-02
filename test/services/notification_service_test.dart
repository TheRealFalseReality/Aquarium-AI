import 'package:cloud_firestore/cloud_firestore.dart';
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

    test(
      'should sanitize invalid repeat interval values when scheduling repeating notifications',
      () async {
        final service = NotificationService();
        await service.initialize();

        final baselineNow = DateTime.now();
        final pastDate = baselineNow.subtract(const Duration(days: 1));
        final notification = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: pastDate,
          repeatFrequency: RepeatFrequency.daily,
          repeatInterval: 0,
          enabled: true,
        );

        final nextDate = await service.scheduleNotification(
          tankId: 'test-tank-id',
          tankName: 'Test Tank',
          notification: notification,
        );

        expect(nextDate, isNotNull);
        expect(nextDate!.isAfter(baselineNow), isTrue);
      },
    );

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

    test(
      'coerceStrictlyFutureDateForTesting returns null for past non-repeating enabled notifications',
      () {
        final service = NotificationService();
        final pastDate = DateTime.now().subtract(const Duration(minutes: 1));
        final notification = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: pastDate,
          repeatFrequency: RepeatFrequency.none,
          enabled: true,
        );

        final coerced = service.coerceStrictlyFutureDateForTesting(
          candidate: pastDate,
          notification: notification,
        );

        expect(coerced, isNull);
      },
    );

    test(
      'coerceStrictlyFutureDateForTesting advances repeating notifications to strict future',
      () {
        final service = NotificationService();
        final baselineNow = DateTime.now();
        final pastDate = baselineNow.subtract(const Duration(minutes: 1));
        final notification = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: pastDate,
          repeatFrequency: RepeatFrequency.daily,
          repeatInterval: 0,
          enabled: true,
        );

        final coerced = service.coerceStrictlyFutureDateForTesting(
          candidate: pastDate,
          notification: notification,
        );

        expect(coerced, isNotNull);
        expect(coerced!.isAfter(baselineNow), isTrue);
      },
    );

    test(
      'getMissedTaskReminderDateForTesting returns one day later at the original scheduled time',
      () {
        final service = NotificationService();
        final scheduledDate = DateTime(2026, 6, 6, 9, 30);
        final notification = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: scheduledDate,
          repeatFrequency: RepeatFrequency.daily,
          enabled: true,
        );

        final reminderDate = service.getMissedTaskReminderDateForTesting(
          scheduledDate: scheduledDate,
          notification: notification,
        );

        expect(reminderDate, equals(DateTime(2026, 6, 7, 9, 30)));
      },
    );

    test(
      'getMissedTaskReminderDateForTesting offsets by overdue day count',
      () {
        final service = NotificationService();
        final scheduledDate = DateTime(2026, 6, 6, 9, 30);
        final notification = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: scheduledDate,
          repeatFrequency: RepeatFrequency.daily,
          enabled: true,
        );

        final reminderDate = service.getMissedTaskReminderDateForTesting(
          scheduledDate: scheduledDate,
          notification: notification,
          overdueDays: 3,
        );

        expect(reminderDate, equals(DateTime(2026, 6, 9, 9, 30)));
      },
    );

    test(
      'getMissedTaskReminderDateForTesting skips disabled notifications',
      () {
        final service = NotificationService();
        final scheduledDate = DateTime(2026, 6, 6, 9, 30);
        final notification = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: scheduledDate,
          enabled: false,
        );

        final reminderDate = service.getMissedTaskReminderDateForTesting(
          scheduledDate: scheduledDate,
          notification: notification,
        );

        expect(reminderDate, isNull);
      },
    );

    test('missed-task reminder uses a stable per-day secondary notification ID', () {
      final service = NotificationService();
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2026, 6, 6, 9, 30),
      );

      final primaryId = notification.id.hashCode;
      final reminderDayOneId = service.getMissedTaskReminderIdForTesting(
        notification,
        overdueDays: 1,
      );
      final reminderDayTwoId = service.getMissedTaskReminderIdForTesting(
        notification,
        overdueDays: 2,
      );

      expect(reminderDayOneId, isNot(equals(primaryId)));
      expect(reminderDayTwoId, isNot(equals(primaryId)));
      expect(reminderDayOneId, isNot(equals(reminderDayTwoId)));
      expect(
        reminderDayOneId,
        equals(
          service.getMissedTaskReminderIdForTesting(
            notification,
            overdueDays: 1,
          ),
        ),
      );
    });

    test(
      'rescheduling a task clears previously queued overdue reminders for that task',
      () async {
        final service = NotificationService();
        await service.initialize();
        await service.cancelAllNotifications();

        final baseDate = DateTime.now().add(const Duration(minutes: 5));
        final notification = TankNotification.create(
          type: NotificationType.feeding,
          notificationDateTime: baseDate,
          repeatFrequency: RepeatFrequency.daily,
          enabled: true,
        );

        await service.scheduleNotification(
          tankId: 'tank-1',
          tankName: 'Tank One',
          notification: notification,
        );

        final rescheduledDate = DateTime.now().add(const Duration(days: 1));
        final updatedNotification = notification.copyWith(
          scheduledNextDate: rescheduledDate,
          updatedAt: DateTime.now(),
        );

        await service.scheduleNotification(
          tankId: 'tank-1',
          tankName: 'Tank One',
          notification: updatedNotification,
          useScheduledNextDate: true,
        );

        final pending = await service.pendingNotificationRequestsForTesting();
        final matching = pending.where((request) {
          final payload = request.payload;
          if (payload == null || payload.isEmpty) {
            return false;
          }
          final parsed = service.parseNotificationPayloadForTesting(payload);
          return parsed?.notificationId == notification.id;
        }).toList();

        expect(
          matching.length,
          equals(1 + service.getMaxScheduledOverdueReminderDaysForTesting()),
        );
      },
    );

    test(
      'caps scheduled overdue reminder days on Apple platforms',
      () {
        final service = NotificationService();

        expect(
          service.getMaxScheduledOverdueReminderDaysForTesting(
            platform: TargetPlatform.iOS,
          ),
          equals(7),
        );
        expect(
          service.getMaxScheduledOverdueReminderDaysForTesting(
            platform: TargetPlatform.macOS,
          ),
          equals(7),
        );
        expect(
          service.getMaxScheduledOverdueReminderDaysForTesting(
            platform: TargetPlatform.android,
          ),
          equals(30),
        );
      },
    );

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

    group('community interaction listener behavior', () {
      Map<String, dynamic> baseData({
        required String interactionType,
        String actorDisplayName = 'Alex',
        String previewText = 'Preview text',
        String postTitle = 'My Post Title',
      }) {
        return {
          'interactionType': interactionType,
          'actorDisplayName': actorDisplayName,
          'previewText': previewText,
          'postTitle': postTitle,
          'postId': 'post-1',
          'createdAt': Timestamp.fromMillisecondsSinceEpoch(1730000000000),
        };
      }

      test('ignores initial snapshot and marks listener as initialized', () async {
        final service = NotificationService();
        final shown = await service.processCommunitySnapshotChangesForTesting([
          (id: 'doc-1', type: 'added', data: baseData(interactionType: 'like')),
        ]);

        expect(shown, equals(0));
        expect(service.hasLoadedInitialCommunitySnapshotForTesting, isTrue);
      });

      test('processes only added changes after initial snapshot', () async {
        final service = NotificationService();
        final shownPreviews = <CommunityNotificationPreview>[];
        service.setCommunityNotificationPresenterOverrideForTesting((preview) async {
          shownPreviews.add(preview);
        });

        await service.processCommunitySnapshotChangesForTesting([]);
        final shown = await service.processCommunitySnapshotChangesForTesting([
          (id: 'doc-mod', type: 'modified', data: baseData(interactionType: 'like')),
          (id: 'doc-del', type: 'removed', data: baseData(interactionType: 'bookmark')),
          (id: 'doc-add', type: 'added', data: baseData(interactionType: 'comment')),
        ]);

        expect(shown, equals(1));
        expect(shownPreviews.length, equals(1));
        expect(shownPreviews.single.title, contains('Alex'));
        expect(shownPreviews.single.title, isNotEmpty);
        service.clearCommunityNotificationPresenterOverrideForTesting();
      });

      test('builds titles and body for like, bookmark, comment, and unknown actor', () async {
        final service = NotificationService();

        final like = await service.buildCommunityNotificationPreviewForTesting(
          docId: 'doc-like',
          data: baseData(interactionType: 'like'),
        );
        final bookmark = await service.buildCommunityNotificationPreviewForTesting(
          docId: 'doc-bookmark',
          data: baseData(interactionType: 'bookmark'),
        );
        final comment = await service.buildCommunityNotificationPreviewForTesting(
          docId: 'doc-comment',
          data: baseData(interactionType: 'comment', previewText: 'Nice tank!'),
        );
        final unknownActor = await service.buildCommunityNotificationPreviewForTesting(
          docId: 'doc-unknown',
          data: baseData(
            interactionType: 'mystery',
            actorDisplayName: '',
            previewText: '',
            postTitle: 'Fallback Post',
          ),
        );

        expect(like, isNotNull);
        expect(bookmark, isNotNull);
        expect(comment, isNotNull);
        expect(unknownActor, isNotNull);
        expect(like!.title, contains('Alex'));
        expect(bookmark!.title, contains('Alex'));
        expect(comment!.title, contains('Alex'));
        expect(like.title, isNot(equals(bookmark.title)));
        expect(bookmark.title, isNot(equals(comment.title)));
        expect(comment.body, equals('Nice tank!'));
        expect(unknownActor!.title, isNot(contains('Alex')));
        expect(unknownActor.title, isNot(contains('{actorName}')));
        expect(unknownActor.body, equals('Fallback Post'));
      });

      test('notification id is non-zero and stable for same doc/timestamp', () async {
        final service = NotificationService();
        final data = baseData(interactionType: 'like');
        final first = await service.buildCommunityNotificationPreviewForTesting(
          docId: 'stable-doc',
          data: data,
        );

        await service.processCommunitySnapshotChangesForTesting([]);
        await service.processCommunitySnapshotChangesForTesting([
          (id: 'other-doc', type: 'added', data: baseData(interactionType: 'comment')),
        ]);

        final second = await service.buildCommunityNotificationPreviewForTesting(
          docId: 'stable-doc',
          data: data,
        );

        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(first!.id, isNot(equals(0)));
        expect(first.id, equals(second!.id));
      });

      test('community payload detection supports post-specific payloads', () {
        final service = NotificationService();
        expect(
          service.isCommunityNotificationPayloadForTesting('community_post::post-123'),
          isTrue,
        );
        expect(
          service.isCommunityNotificationPayloadForTesting('community_post'),
          isTrue,
        );
        expect(
          service.isCommunityNotificationPayloadForTesting('tank-123::notif-456'),
          isFalse,
        );
        expect(
          service.extractCommunityPostIdForTesting('community_post::post-123'),
          equals('post-123'),
        );
        expect(
          service.extractCommunityPostIdForTesting('community_post::'),
          isNull,
        );
      });

      test('falls back to legacy community payload when postId is missing', () async {
        final service = NotificationService();
        final preview = await service.buildCommunityNotificationPreviewForTesting(
          docId: 'doc-no-post',
          data: {
            ...baseData(interactionType: 'like'),
            'postId': '',
          },
        );

        expect(preview, isNotNull);
        expect(preview!.payload, equals('community_post'));
      });
    });
  });
}
