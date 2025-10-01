import 'package:fish_ai/models/tank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tank Model with Tags Tests', () {
    test('Tank.create with tags', () {
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        tags: ['planted', 'community', 'beginner'],
      );
      
      expect(tank.tags, equals(['planted', 'community', 'beginner']));
      expect(tank.name, equals('Test Tank'));
      expect(tank.type, equals('freshwater'));
    });

    test('Tank.create without tags defaults to empty list', () {
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'marine',
      );
      
      expect(tank.tags, isEmpty);
    });

    test('Tank toJson and fromJson with tags', () {
      final originalTank = Tank.create(
        name: 'Reef Tank',
        type: 'marine',
        sizeGallons: 75.0,
        sizeLiters: 283.9,
        tags: ['reef', 'saltwater', 'advanced'],
      );
      
      final json = originalTank.toJson();
      expect(json['tags'], equals(['reef', 'saltwater', 'advanced']));
      
      final restoredTank = Tank.fromJson(json);
      expect(restoredTank.tags, equals(['reef', 'saltwater', 'advanced']));
      expect(restoredTank.name, equals('Reef Tank'));
      expect(restoredTank.type, equals('marine'));
    });

    test('Tank fromJson handles missing tags field', () {
      final json = {
        'id': 'test-id',
        'name': 'Old Tank',
        'type': 'freshwater',
        'inhabitants': [],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      final tank = Tank.fromJson(json);
      expect(tank.tags, isEmpty);
    });

    test('Tank copyWith updates tags', () {
      final originalTank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        tags: ['planted'],
      );
      
      final updatedTank = originalTank.copyWith(
        tags: ['planted', 'community'],
      );
      
      expect(updatedTank.tags, equals(['planted', 'community']));
      expect(originalTank.tags, equals(['planted'])); // Original unchanged
    });
  });
}
