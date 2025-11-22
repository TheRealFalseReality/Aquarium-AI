import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/models/tank_notification.dart';

void main() {
  group('TankPhoto', () {
    test('should create a TankPhoto with all fields', () {
      final photo = TankPhoto(
        id: 'test-id',
        imageUrl: 'https://example.com/image.jpg',
        imagePath: '/path/to/image.jpg',
        dateTaken: DateTime(2024, 1, 1),
      );

      expect(photo.id, 'test-id');
      expect(photo.imageUrl, 'https://example.com/image.jpg');
      expect(photo.imagePath, '/path/to/image.jpg');
      expect(photo.dateTaken, DateTime(2024, 1, 1));
    });

    test('should serialize to JSON correctly', () {
      final photo = TankPhoto(
        id: 'test-id',
        imageUrl: 'https://example.com/image.jpg',
        dateTaken: DateTime(2024, 1, 1),
      );

      final json = photo.toJson();

      expect(json['id'], 'test-id');
      expect(json['imageUrl'], 'https://example.com/image.jpg');
      expect(json['imagePath'], null);
      expect(json['dateTaken'], '2024-01-01T00:00:00.000');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'imageUrl': 'https://example.com/image.jpg',
        'imagePath': null,
        'dateTaken': '2024-01-01T00:00:00.000',
      };

      final photo = TankPhoto.fromJson(json);

      expect(photo.id, 'test-id');
      expect(photo.imageUrl, 'https://example.com/image.jpg');
      expect(photo.imagePath, null);
      expect(photo.dateTaken, DateTime(2024, 1, 1));
    });

    test('should create a copy with modified fields', () {
      final photo = TankPhoto(
        id: 'test-id',
        imageUrl: 'https://example.com/image.jpg',
        dateTaken: DateTime(2024, 1, 1),
      );

      final updatedPhoto = photo.copyWith(
        dateTaken: DateTime(2024, 2, 1),
      );

      expect(updatedPhoto.id, 'test-id');
      expect(updatedPhoto.imageUrl, 'https://example.com/image.jpg');
      expect(updatedPhoto.dateTaken, DateTime(2024, 2, 1));
    });
  });

  group('Tank with Photos', () {
    test('should create a Tank with photos', () {
      final photo = TankPhoto(
        id: 'photo-1',
        imageUrl: 'https://example.com/tank.jpg',
        dateTaken: DateTime(2024, 1, 1),
      );

      final tank = Tank.create(
        name: 'My Tank',
        type: 'freshwater',
        photos: [photo],
      );

      expect(tank.photos.length, 1);
      expect(tank.photos.first.id, 'photo-1');
    });

    test('should serialize Tank with photos to JSON correctly', () {
      final photo = TankPhoto(
        id: 'photo-1',
        imageUrl: 'https://example.com/tank.jpg',
        dateTaken: DateTime(2024, 1, 1),
      );

      final tank = Tank.create(
        name: 'My Tank',
        type: 'freshwater',
        photos: [photo],
      );

      final json = tank.toJson();

      expect(json['photos'], isA<List>());
      expect((json['photos'] as List).length, 1);
      expect((json['photos'] as List).first['id'], 'photo-1');
    });

    test('should deserialize Tank with photos from JSON correctly', () {
      final json = {
        'id': 'tank-1',
        'name': 'My Tank',
        'type': 'freshwater',
        'inhabitants': [],
        'sizeGallons': null,
        'sizeLiters': null,
        'notes': null,
        'harmonyScore': null,
        'calculationBreakdown': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'photos': [
          {
            'id': 'photo-1',
            'imageUrl': 'https://example.com/tank.jpg',
            'imagePath': null,
            'dateTaken': '2024-01-01T00:00:00.000',
          }
        ],
      };

      final tank = Tank.fromJson(json);

      expect(tank.photos.length, 1);
      expect(tank.photos.first.id, 'photo-1');
      expect(tank.photos.first.imageUrl, 'https://example.com/tank.jpg');
    });

    test('should handle Tank with no photos (backwards compatibility)', () {
      final json = {
        'id': 'tank-1',
        'name': 'My Tank',
        'type': 'freshwater',
        'inhabitants': [],
        'sizeGallons': null,
        'sizeLiters': null,
        'notes': null,
        'harmonyScore': null,
        'calculationBreakdown': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        // Note: 'photos' field is missing
      };

      final tank = Tank.fromJson(json);

      expect(tank.photos, isEmpty);
    });

    test('should handle Tank with no waterParameters (backwards compatibility)', () {
      final json = {
        'id': 'tank-1',
        'name': 'My Tank',
        'type': 'freshwater',
        'inhabitants': [],
        'sizeGallons': null,
        'sizeLiters': null,
        'notes': null,
        'harmonyScore': null,
        'calculationBreakdown': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'photos': [],
        // Note: 'waterParameters' field is missing
      };

      final tank = Tank.fromJson(json);

      expect(tank.waterParameters, isEmpty);
    });

    test('should handle Tank with no notifications (backwards compatibility)', () {
      final json = {
        'id': 'tank-1',
        'name': 'My Tank',
        'type': 'freshwater',
        'inhabitants': [],
        'sizeGallons': null,
        'sizeLiters': null,
        'notes': null,
        'harmonyScore': null,
        'calculationBreakdown': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'photos': [],
        'waterParameters': [],
        'dosingEntries': [],
        // Note: 'notifications' field is missing
      };

      final tank = Tank.fromJson(json);

      expect(tank.notifications, isEmpty);
    });
  });

  group('Tank with Notifications', () {
    test('should create a Tank with notifications', () {
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 15, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        notes: 'Feed the fish',
      );

      final tank = Tank.create(
        name: 'My Tank',
        type: 'freshwater',
        notifications: [notification],
      );

      expect(tank.notifications.length, 1);
      expect(tank.notifications.first.type, NotificationType.feeding);
    });

    test('should serialize Tank with notifications to JSON correctly', () {
      final notification = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: DateTime(2024, 6, 15, 10, 0),
        repeatFrequency: RepeatFrequency.weekly,
        notes: 'Dose the tank',
      );

      final tank = Tank.create(
        name: 'My Tank',
        type: 'freshwater',
        notifications: [notification],
      );

      final json = tank.toJson();

      expect(json['notifications'], isA<List>());
      expect((json['notifications'] as List).length, 1);
      expect((json['notifications'] as List).first['type'], 'dosing');
    });

    test('should deserialize Tank with notifications from JSON correctly', () {
      final json = {
        'id': 'tank-1',
        'name': 'My Tank',
        'type': 'freshwater',
        'inhabitants': [],
        'sizeGallons': null,
        'sizeLiters': null,
        'notes': null,
        'harmonyScore': null,
        'calculationBreakdown': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'photos': [],
        'waterParameters': [],
        'dosingEntries': [],
        'notifications': [
          {
            'id': 'notif-1',
            'type': 'feeding',
            'notificationDateTime': '2024-06-15T09:00:00.000',
            'repeatFrequency': 'daily',
            'repeatInterval': 1,
            'notes': 'Feed the fish',
            'createdAt': '2024-01-01T00:00:00.000',
            'updatedAt': '2024-01-01T00:00:00.000',
            'enabled': true,
          }
        ],
      };

      final tank = Tank.fromJson(json);

      expect(tank.notifications.length, 1);
      expect(tank.notifications.first.type, NotificationType.feeding);
      expect(tank.notifications.first.repeatFrequency, RepeatFrequency.daily);
      expect(tank.notifications.first.notes, 'Feed the fish');
    });

    test('should handle Tank with multiple notifications', () {
      final feedingNotif = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 15, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
      );

      final dosingNotif = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: DateTime(2024, 6, 15, 10, 0),
        repeatFrequency: RepeatFrequency.weekly,
      );

      final maintenanceNotif = TankNotification.create(
        type: NotificationType.maintenance,
        notificationDateTime: DateTime(2024, 6, 15, 14, 0),
        repeatFrequency: RepeatFrequency.monthly,
      );

      final tank = Tank.create(
        name: 'My Tank',
        type: 'freshwater',
        notifications: [feedingNotif, dosingNotif, maintenanceNotif],
      );

      expect(tank.notifications.length, 3);
      expect(tank.notifications[0].type, NotificationType.feeding);
      expect(tank.notifications[1].type, NotificationType.dosing);
      expect(tank.notifications[2].type, NotificationType.maintenance);

      // Test serialization
      final json = tank.toJson();
      final deserialized = Tank.fromJson(json);

      expect(deserialized.notifications.length, 3);
      expect(deserialized.notifications[0].type, NotificationType.feeding);
      expect(deserialized.notifications[1].type, NotificationType.dosing);
      expect(deserialized.notifications[2].type, NotificationType.maintenance);
    });

    test('should update notifications using copyWith', () {
      final notification = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 15, 9, 0),
      );

      final tank = Tank.create(
        name: 'My Tank',
        type: 'freshwater',
        notifications: [notification],
      );

      final newNotification = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: DateTime(2024, 6, 15, 10, 0),
      );

      final updatedTank = tank.copyWith(
        notifications: [notification, newNotification],
      );

      expect(updatedTank.notifications.length, 2);
      expect(updatedTank.notifications[0].type, NotificationType.feeding);
      expect(updatedTank.notifications[1].type, NotificationType.dosing);
    });
  });
}
