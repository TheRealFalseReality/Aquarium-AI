import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/models/tank_notification.dart';
import 'package:fish_ai/providers/tank_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Notification Race Condition Tests', () {
    late ProviderContainer container;
    late TankNotifier tankNotifier;
    
    setUp(() async {
      // Mock shared preferences
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      tankNotifier = container.read(tankProvider.notifier);
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      container.dispose();
    });

    test('multiple notification operations preserve all notifications', () async {
      // Create a tank with one notification
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        notifications: [
          TankNotification.create(
            type: NotificationType.feeding,
            notificationDateTime: DateTime.now().add(const Duration(hours: 1)),
            notes: 'Feed the fish',
          ),
        ],
      );
      
      await tankNotifier.addTank(tank);
      
      // Get the current state to simulate the fix behavior
      var currentTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      
      // Verify initial state
      expect(currentTank.notifications.length, equals(1));
      expect(currentTank.notifications[0].type, equals(NotificationType.feeding));
      
      // Add a second notification (simulating user action)
      final notification2 = TankNotification.create(
        type: NotificationType.waterChange,
        notificationDateTime: DateTime.now().add(const Duration(days: 1)),
        notes: 'Change water',
      );
      
      // Get fresh state before adding
      currentTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      
      final updatedTank1 = currentTank.copyWith(
        notifications: [...currentTank.notifications, notification2],
        updatedAt: DateTime.now(),
      );
      
      await tankNotifier.updateTank(updatedTank1);
      
      // Verify both notifications exist
      currentTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      expect(currentTank.notifications.length, equals(2));
      
      // Toggle the first notification (simulating another concurrent action)
      // Get fresh state before toggling
      currentTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      
      final firstNotification = currentTank.notifications[0];
      final toggledNotification = firstNotification.copyWith(
        enabled: false,
        updatedAt: DateTime.now(),
      );
      
      final updatedNotifications = currentTank.notifications
          .map((n) => n.id == firstNotification.id ? toggledNotification : n)
          .toList();
      
      final updatedTank2 = currentTank.copyWith(
        notifications: updatedNotifications,
        updatedAt: DateTime.now(),
      );
      
      await tankNotifier.updateTank(updatedTank2);
      
      // Verify both notifications still exist and first is disabled
      final finalTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      expect(finalTank.notifications.length, equals(2));
      expect(finalTank.notifications[0].enabled, equals(false));
      expect(finalTank.notifications[0].type, equals(NotificationType.feeding));
      expect(finalTank.notifications[1].enabled, equals(true));
      expect(finalTank.notifications[1].type, equals(NotificationType.waterChange));
    });
    
    test('editing notification preserves other notifications', () async {
      // Create a tank with multiple notifications
      final notification1 = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime.now().add(const Duration(hours: 1)),
        notes: 'Original feeding note',
      );
      
      final notification2 = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: DateTime.now().add(const Duration(hours: 2)),
        notes: 'Dose supplements',
      );
      
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        notifications: [notification1, notification2],
      );
      
      await tankNotifier.addTank(tank);
      
      // Edit the first notification
      var currentTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      
      final editedNotification = notification1.copyWith(
        notes: 'Updated feeding note',
        updatedAt: DateTime.now(),
      );
      
      final updatedNotifications = currentTank.notifications
          .map((n) => n.id == notification1.id ? editedNotification : n)
          .toList();
      
      final updatedTank = currentTank.copyWith(
        notifications: updatedNotifications,
        updatedAt: DateTime.now(),
      );
      
      await tankNotifier.updateTank(updatedTank);
      
      // Verify both notifications exist and edit was applied
      final finalTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      expect(finalTank.notifications.length, equals(2));
      expect(finalTank.notifications[0].notes, equals('Updated feeding note'));
      expect(finalTank.notifications[1].notes, equals('Dose supplements'));
    });
    
    test('deleting notification preserves other notifications', () async {
      // Create a tank with three notifications
      final notification1 = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime.now().add(const Duration(hours: 1)),
      );
      
      final notification2 = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: DateTime.now().add(const Duration(hours: 2)),
      );
      
      final notification3 = TankNotification.create(
        type: NotificationType.waterChange,
        notificationDateTime: DateTime.now().add(const Duration(days: 1)),
      );
      
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        notifications: [notification1, notification2, notification3],
      );
      
      await tankNotifier.addTank(tank);
      
      // Delete the middle notification
      var currentTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      
      final updatedNotifications = currentTank.notifications
          .where((n) => n.id != notification2.id)
          .toList();
      
      final updatedTank = currentTank.copyWith(
        notifications: updatedNotifications,
        updatedAt: DateTime.now(),
      );
      
      await tankNotifier.updateTank(updatedTank);
      
      // Verify only the deleted notification is gone
      final finalTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      expect(finalTank.notifications.length, equals(2));
      expect(finalTank.notifications.any((n) => n.id == notification1.id), isTrue);
      expect(finalTank.notifications.any((n) => n.id == notification2.id), isFalse);
      expect(finalTank.notifications.any((n) => n.id == notification3.id), isTrue);
    });
    
    test('rapid sequential updates preserve all changes', () async {
      // Create a tank with one notification
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        notifications: [],
      );
      
      await tankNotifier.addTank(tank);
      
      // Rapidly add three notifications
      for (int i = 0; i < 3; i++) {
        // Always get fresh state
        final currentTank = container.read(tankProvider).tanks
            .firstWhere((t) => t.id == tank.id);
        
        final newNotification = TankNotification.create(
          type: NotificationType.values[i],
          notificationDateTime: DateTime.now().add(Duration(hours: i + 1)),
          notes: 'Notification $i',
        );
        
        final updatedTank = currentTank.copyWith(
          notifications: [...currentTank.notifications, newNotification],
          updatedAt: DateTime.now(),
        );
        
        await tankNotifier.updateTank(updatedTank);
      }
      
      // Verify all three notifications were added
      final finalTank = container.read(tankProvider).tanks
          .firstWhere((t) => t.id == tank.id);
      expect(finalTank.notifications.length, equals(3));
      expect(finalTank.notifications[0].notes, equals('Notification 0'));
      expect(finalTank.notifications[1].notes, equals('Notification 1'));
      expect(finalTank.notifications[2].notes, equals('Notification 2'));
    });
  });
}
