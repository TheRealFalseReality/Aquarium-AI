import 'package:fish_ai/models/tank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tank Model Tests', () {
    test('Tank creation with all properties', () {
      final tank = Tank(
        id: 'test-tank-1',
        name: 'My Aquarium',
        size: 20.0,
        type: 'freshwater',
        inhabitants: ['Angelfish', 'Tetras'],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(tank.id, equals('test-tank-1'));
      expect(tank.name, equals('My Aquarium'));
      expect(tank.size, equals(20.0));
      expect(tank.type, equals('freshwater'));
      expect(tank.inhabitants, contains('Angelfish'));
      expect(tank.inhabitants, contains('Tetras'));
      expect(tank.createdAt, equals(DateTime(2024, 1, 1)));
    });

    test('Tank creation with minimal properties', () {
      final tank = Tank(
        id: 'minimal-tank',
        name: 'Basic Tank',
        size: 10.0,
        type: 'saltwater',
        inhabitants: [],
        createdAt: DateTime.now(),
      );

      expect(tank.id, equals('minimal-tank'));
      expect(tank.name, equals('Basic Tank'));
      expect(tank.size, equals(10.0));
      expect(tank.type, equals('saltwater'));
      expect(tank.inhabitants, isEmpty);
      expect(tank.createdAt, isA<DateTime>());
    });

    test('Tank copyWith functionality', () {
      final originalTank = Tank(
        id: 'original-tank',
        name: 'Original Tank',
        size: 30.0,
        type: 'freshwater',
        inhabitants: ['Original Fish'],
        createdAt: DateTime(2024, 1, 1),
      );

      final updatedTank = originalTank.copyWith(
        name: 'Updated Tank',
        type: 'saltwater',
        inhabitants: ['New Fish', 'Another Fish'],
      );

      expect(updatedTank.id, equals(originalTank.id)); // Should remain same
      expect(updatedTank.name, equals('Updated Tank'));
      expect(updatedTank.type, equals('saltwater'));
      expect(updatedTank.inhabitants, contains('New Fish'));
      expect(updatedTank.inhabitants, contains('Another Fish'));
      expect(updatedTank.size, equals(originalTank.size)); // Should remain same
      expect(updatedTank.createdAt, equals(originalTank.createdAt)); // Should remain same
    });

    test('Tank equality comparison', () {
      final tank1 = Tank(
        id: 'same-tank',
        name: 'Same Tank',
        size: 20.0,
        type: 'freshwater',
        inhabitants: ['Fish'],
        createdAt: DateTime(2024, 1, 1),
      );

      final tank2 = Tank(
        id: 'same-tank',
        name: 'Same Tank',
        size: 20.0,
        type: 'freshwater',
        inhabitants: ['Fish'],
        createdAt: DateTime(2024, 1, 1),
      );

      final tank3 = Tank(
        id: 'different-tank',
        name: 'Different Tank',
        size: 20.0,
        type: 'freshwater',
        inhabitants: ['Fish'],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(tank1, equals(tank2));
      expect(tank1, isNot(equals(tank3)));
      expect(tank1.hashCode, equals(tank2.hashCode));
      expect(tank1.hashCode, isNot(equals(tank3.hashCode)));
    });
  });
}