import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/tank_notification.dart';
import 'package:fish_ai/services/notification_service.dart';

void main() {
  group('NotificationService', () {
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
  });
}
