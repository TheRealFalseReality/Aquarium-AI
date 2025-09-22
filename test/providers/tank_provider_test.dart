import 'package:fish_ai/providers/tank_provider.dart';
import 'package:fish_ai/models/tank.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('TankProvider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be empty', () {
      final state = container.read(tankProvider);
      expect(state.tanks, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('addTank should add a tank to the list', () async {
      final notifier = container.read(tankProvider.notifier);
      
      final newTank = Tank(
        id: 'test-tank-1',
        name: 'Test Tank',
        size: 20.0,
        type: 'freshwater',
        inhabitants: [],
        createdAt: DateTime.now(),
      );

      await notifier.addTank(newTank);
      
      final state = container.read(tankProvider);
      expect(state.tanks, hasLength(1));
      expect(state.tanks.first.name, equals('Test Tank'));
      expect(state.tanks.first.size, equals(20.0));
      expect(state.tanks.first.type, equals('freshwater'));
    });

    test('updateTank should modify existing tank', () async {
      final notifier = container.read(tankProvider.notifier);
      
      final originalTank = Tank(
        id: 'test-tank-1',
        name: 'Original Tank',
        size: 20.0,
        type: 'freshwater',
        inhabitants: [],
        createdAt: DateTime.now(),
      );

      await notifier.addTank(originalTank);
      
      final updatedTank = originalTank.copyWith(
        name: 'Updated Tank',
        size: 30.0,
      );

      await notifier.updateTank(updatedTank);
      
      final state = container.read(tankProvider);
      expect(state.tanks, hasLength(1));
      expect(state.tanks.first.name, equals('Updated Tank'));
      expect(state.tanks.first.size, equals(30.0));
      expect(state.tanks.first.id, equals('test-tank-1')); // ID should remain same
    });

    test('deleteTank should remove tank from list', () async {
      final notifier = container.read(tankProvider.notifier);
      
      final tank1 = Tank(
        id: 'tank-1',
        name: 'Tank 1',
        size: 20.0,
        type: 'freshwater',
        inhabitants: [],
        createdAt: DateTime.now(),
      );

      final tank2 = Tank(
        id: 'tank-2',
        name: 'Tank 2',
        size: 30.0,
        type: 'saltwater',
        inhabitants: [],
        createdAt: DateTime.now(),
      );

      await notifier.addTank(tank1);
      await notifier.addTank(tank2);
      
      expect(container.read(tankProvider).tanks, hasLength(2));
      
      await notifier.deleteTank('tank-1');
      
      final state = container.read(tankProvider);
      expect(state.tanks, hasLength(1));
      expect(state.tanks.first.id, equals('tank-2'));
      expect(state.tanks.first.name, equals('Tank 2'));
    });
  });
}