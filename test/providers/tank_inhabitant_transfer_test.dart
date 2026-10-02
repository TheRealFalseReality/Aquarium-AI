import 'dart:convert';

import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/providers/tank_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Tank inhabitant transfer', () {
    late ProviderContainer container;
    late TankNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      notifier = container.read(tankProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      container.dispose();
    });

    test('moves the inhabitant and persists all of its details', () async {
      final inhabitant = TankInhabitant(
        id: 'fish-1',
        customName: 'Bubbles',
        fishUnit: 'Clownfish',
        fishUuid: 'species-1',
        quantity: 2,
        customImageUrl: 'https://example.com/fish.jpg',
        customImagePath: '/local/fish.jpg',
        dateAdded: DateTime(2024, 3, 4),
        speciesTags: ['ocellaris'],
        userNotes: 'Loves frozen food',
      );
      final source = Tank.create(
        name: 'Source',
        type: 'marine',
        inhabitants: [inhabitant],
      );
      final destination = Tank.create(name: 'Destination', type: 'marine');
      await notifier.addTank(source);
      await notifier.addTank(destination);

      expect(
        await notifier.moveInhabitant(
          inhabitantId: inhabitant.id,
          sourceTankId: source.id,
          destinationTankId: destination.id,
        ),
        isTrue,
      );

      final tanks = container.read(tankProvider).tanks;
      final updatedSource = tanks.firstWhere((tank) => tank.id == source.id);
      final updatedDestination =
          tanks.firstWhere((tank) => tank.id == destination.id);
      expect(updatedSource.inhabitants, isEmpty);
      expect(
        updatedDestination.inhabitants.single.toJson(),
        equals(inhabitant.toJson()),
      );

      final preferences = await SharedPreferences.getInstance();
      final persistedTanks =
          (jsonDecode(preferences.getString('user_tanks')!) as List)
              .map((json) => Tank.fromJson(json as Map<String, dynamic>))
              .toList();
      expect(
        persistedTanks
            .firstWhere((tank) => tank.id == destination.id)
            .inhabitants
            .single
            .toJson(),
        equals(inhabitant.toJson()),
      );
    });

    test('rejects invalid and memorialized inhabitant transfers', () async {
      final inhabitant = TankInhabitant(
        id: 'fish-1',
        customName: 'Bubbles',
        fishUnit: 'Clownfish',
        quantity: 1,
      );
      final source = Tank.create(name: 'Source', type: 'marine');
      final destination = Tank.create(name: 'Destination', type: 'marine');
      await notifier.addTank(source);
      await notifier.addTank(destination);

      expect(
        await notifier.moveInhabitant(
          inhabitantId: inhabitant.id,
          sourceTankId: source.id,
          destinationTankId: source.id,
        ),
        isFalse,
      );
      expect(
        await notifier.moveInhabitant(
          inhabitantId: inhabitant.id,
          sourceTankId: source.id,
          destinationTankId: destination.id,
        ),
        isFalse,
      );
      expect(
        await notifier.moveInhabitant(
          inhabitantId: inhabitant.id,
          sourceTankId: source.id,
          destinationTankId: 'missing-tank',
        ),
        isFalse,
      );
      expect(
        await notifier.moveInhabitant(
          inhabitantId: inhabitant.id,
          sourceTankId: 'missing-tank',
          destinationTankId: destination.id,
        ),
        isFalse,
      );

      final memorialTank = source.copyWith(
        inhabitants: const [],
        memorializedInhabitants: [inhabitant],
      );
      await notifier.updateTank(memorialTank);
      expect(
        await notifier.moveInhabitant(
          inhabitantId: inhabitant.id,
          sourceTankId: source.id,
          destinationTankId: destination.id,
        ),
        isFalse,
      );
    });
  });
}
