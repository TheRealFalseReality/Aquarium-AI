import 'package:fish_ai/utils/tank_harmony_calculator.dart';
import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/tank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TankHarmonyCalculator Tests', () {
    // Helper to create test fish
    Fish createTestFish(String name, {
      List<String>? compatible,
      List<String>? notCompatible,
      List<String>? withCaution,
      List<String>? notRecommended,
    }) {
      return Fish(
        name: name,
        commonNames: [],
        imageURL: '',
        compatible: compatible ?? [],
        notCompatible: notCompatible ?? [],
        withCaution: withCaution ?? [],
        notRecommended: notRecommended ?? [],
      );
    }

    test('calculateHarmonyScore with compatible fish', () {
      final fishA = createTestFish('Fish A', compatible: ['Fish B']);
      final fishB = createTestFish('Fish B', compatible: ['Fish A']);
      
      final score = TankHarmonyCalculator.calculateHarmonyScore([fishA, fishB]);
      
      expect(score, greaterThan(0.7)); // Should be high compatibility
    });

    test('calculateHarmonyScore with incompatible fish', () {
      final fishA = createTestFish('Fish A', notCompatible: ['Fish B']);
      final fishB = createTestFish('Fish B', notCompatible: ['Fish A']);
      
      final score = TankHarmonyCalculator.calculateHarmonyScore([fishA, fishB]);
      
      expect(score, lessThan(0.3)); // Should be low compatibility
    });

    test('calculateHarmonyScore with mixed compatibility', () {
      final fishA = createTestFish('Fish A', compatible: ['Fish B'], withCaution: ['Fish C']);
      final fishB = createTestFish('Fish B', compatible: ['Fish A'], notRecommended: ['Fish C']);
      final fishC = createTestFish('Fish C', withCaution: ['Fish A'], notRecommended: ['Fish B']);
      
      final score = TankHarmonyCalculator.calculateHarmonyScore([fishA, fishB, fishC]);
      
      expect(score, greaterThan(0.3));
      expect(score, lessThan(0.8)); // Should be moderate compatibility
    });

    test('calculateHarmonyScore with single fish', () {
      final fishA = createTestFish('Fish A');
      
      final score = TankHarmonyCalculator.calculateHarmonyScore([fishA]);
      
      expect(score, greaterThanOrEqualTo(0.0)); // Single fish score depends on self-compatibility
    });

    test('calculateHarmonyScore with empty list', () {
      final score = TankHarmonyCalculator.calculateHarmonyScore([]);
      
      expect(score, equals(1.0)); // Empty tank should be perfectly compatible
    });

    test('getHarmonyLabel returns correct labels', () {
      expect(TankHarmonyCalculator.getHarmonyLabel(0.95), equals('Excellent'));
      expect(TankHarmonyCalculator.getHarmonyLabel(0.85), equals('Good'));
      expect(TankHarmonyCalculator.getHarmonyLabel(0.65), equals('Fair'));
      expect(TankHarmonyCalculator.getHarmonyLabel(0.45), equals('Caution'));
      expect(TankHarmonyCalculator.getHarmonyLabel(0.25), equals('Poor'));
      expect(TankHarmonyCalculator.getHarmonyLabel(0.05), equals('Poor'));
    });

    test('calculateTankHarmonyScore with tank and fish data', () {
      final fishData = {
        'freshwater': [
          createTestFish('Fish A', compatible: ['Fish B']),
          createTestFish('Fish B', compatible: ['Fish A']),
        ]
      };

      final inhabitant1 = TankInhabitant(
        id: '1',
        customName: 'My Fish A',
        fishUnit: 'Fish A',
        quantity: 1,
      );

      final inhabitant2 = TankInhabitant(
        id: '2',
        customName: 'My Fish B',
        fishUnit: 'Fish B',
        quantity: 2,
      );

      final tank = Tank(
        id: 'test-tank',
        name: 'Test Tank',
        size: 20.0,
        type: 'freshwater',
        inhabitants: [inhabitant1, inhabitant2],
        createdAt: DateTime.now(),
      );

      final score = TankHarmonyCalculator.calculateTankHarmonyScore(tank, fishData);
      
      expect(score, isNotNull);
      expect(score!, greaterThan(0.5)); // Compatible fish should score reasonably well
    });

    test('calculateTankHarmonyScore with unknown fish returns score', () {
      final fishData = {
        'freshwater': [
          createTestFish('Fish A'),
        ]
      };

      final inhabitant = TankInhabitant(
        id: '1',
        customName: 'Unknown Fish',
        fishUnit: 'Unknown Fish',
        quantity: 1,
      );

      final tank = Tank(
        id: 'test-tank',
        name: 'Test Tank',
        size: 20.0,
        type: 'freshwater',
        inhabitants: [inhabitant],
        createdAt: DateTime.now(),
      );

      final score = TankHarmonyCalculator.calculateTankHarmonyScore(tank, fishData);
      
      expect(score, isNotNull); // Should return a score even for unknown fish
    });

    test('calculateTankHarmonyScore with empty tank returns null', () {
      final fishData = {
        'freshwater': [
          createTestFish('Fish A'),
        ]
      };

      final tank = Tank(
        id: 'test-tank',
        name: 'Empty Tank',
        size: 20.0,
        type: 'freshwater',
        inhabitants: [],
        createdAt: DateTime.now(),
      );

      final score = TankHarmonyCalculator.calculateTankHarmonyScore(tank, fishData);
      
      expect(score, isNull); // Should return null for empty tank
    });
  });
}