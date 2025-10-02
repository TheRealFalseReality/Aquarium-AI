import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/models/tank.dart';

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
  });
}
