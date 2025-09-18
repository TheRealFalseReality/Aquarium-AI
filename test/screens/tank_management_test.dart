import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/utils/tank_harmony_calculator.dart';
import 'package:fish_ai/screens/tank_management_screen.dart';
import 'package:fish_ai/screens/tank_creation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Tank Model Tests', () {
    test('Tank creation with size', () {
      final tank = Tank.create(
        name: 'Test Tank with Size',
        type: 'freshwater',
        sizeGallons: 55.0,
        sizeLiters: 208.2,
      );

      expect(tank.name, equals('Test Tank with Size'));
      expect(tank.type, equals('freshwater'));
      expect(tank.sizeGallons, equals(55.0));
      expect(tank.sizeLiters, equals(208.2));
      expect(tank.id, isA<String>());
      expect(tank.inhabitants, isEmpty);
    });

    test('Tank creation with UUID', () {
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
      );

      expect(tank.name, equals('Test Tank'));
      expect(tank.type, equals('freshwater'));
      expect(tank.id, isA<String>());
      expect(tank.id.length, greaterThan(30)); // UUID should be long
      expect(tank.inhabitants, isEmpty);
      expect(tank.createdAt, isA<DateTime>());
      expect(tank.updatedAt, equals(tank.createdAt));
    });

    test('Tank JSON serialization with size', () {
      final tank = Tank.create(
        name: 'Saltwater Paradise',
        type: 'marine',
        sizeGallons: 120.0,
        sizeLiters: 454.2,
        inhabitants: [
          TankInhabitant(
            id: 'test-id',
            customName: 'My Clownfish',
            fishUnit: 'Clownfish',
            quantity: 2,
          ),
        ],
      );

      final json = tank.toJson();
      final recreatedTank = Tank.fromJson(json);

      expect(recreatedTank.name, equals(tank.name));
      expect(recreatedTank.type, equals(tank.type));
      expect(recreatedTank.sizeGallons, equals(tank.sizeGallons));
      expect(recreatedTank.sizeLiters, equals(tank.sizeLiters));
      expect(recreatedTank.id, equals(tank.id));
      expect(recreatedTank.inhabitants.length, equals(1));
      expect(recreatedTank.inhabitants.first.customName, equals('My Clownfish'));
    });

    test('Tank JSON serialization', () {
      final tank = Tank.create(
        name: 'Saltwater Paradise',
        type: 'marine',
        inhabitants: [
          TankInhabitant(
            id: 'test-id',
            customName: 'My Clownfish',
            fishUnit: 'Clownfish',
            quantity: 2,
          ),
        ],
      );

      final json = tank.toJson();
      final recreatedTank = Tank.fromJson(json);

      expect(recreatedTank.name, equals(tank.name));
      expect(recreatedTank.type, equals(tank.type));
      expect(recreatedTank.id, equals(tank.id));
      expect(recreatedTank.inhabitants.length, equals(1));
      expect(recreatedTank.inhabitants.first.customName, equals('My Clownfish'));
    });

    test('TankInhabitant creation and serialization', () {
      final inhabitant = TankInhabitant(
        id: 'test-inhabitant',
        customName: 'Pretty Angelfish',
        fishUnit: 'Angelfish (Female) ♀',
        quantity: 3,
      );

      final json = inhabitant.toJson();
      final recreated = TankInhabitant.fromJson(json);

      expect(recreated.id, equals(inhabitant.id));
      expect(recreated.customName, equals(inhabitant.customName));
      expect(recreated.fishUnit, equals(inhabitant.fishUnit));
      expect(recreated.quantity, equals(inhabitant.quantity));
    });

    test('Tank copyWith method', () {
      final original = Tank.create(
        name: 'Original Tank',
        type: 'freshwater',
      );

      final updated = original.copyWith(
        name: 'Updated Tank',
        type: 'marine',
      );

      expect(updated.id, equals(original.id)); // ID should remain the same
      expect(updated.name, equals('Updated Tank'));
      expect(updated.type, equals('marine'));
      expect(updated.createdAt, equals(original.createdAt)); // Created time should remain
    });
  });

  group('Tank Harmony Calculator Tests', () {
    test('Harmony score calculation with compatible fish', () {
      final fishA = Fish(
        name: 'Angelfish',
        commonNames: [],
        imageURL: '',
        compatible: ['Cory Cats'],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      final fishB = Fish(
        name: 'Cory Cats',
        commonNames: [],
        imageURL: '',
        compatible: ['Angelfish'],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );

      final score = TankHarmonyCalculator.calculateHarmonyScore([fishA, fishB]);
      expect(score, greaterThan(0.9)); // Should be high compatibility
    });

    test('Harmony score calculation with incompatible fish', () {
      final fishA = Fish(
        name: 'Aggressive Fish',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: ['Peaceful Fish'],
        withCaution: [],
      );
      final fishB = Fish(
        name: 'Peaceful Fish',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: ['Aggressive Fish'],
        withCaution: [],
      );

      final score = TankHarmonyCalculator.calculateHarmonyScore([fishA, fishB]);
      expect(score, lessThan(0.1)); // Should be very low compatibility
    });

    test('Harmony score with single fish returns 1.0', () {
      final fish = Fish(
        name: 'Solo Fish',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );

      final score = TankHarmonyCalculator.calculateHarmonyScore([fish]);
      expect(score, equals(1.0));
    });

    test('Tank harmony score calculation', () {
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        inhabitants: [
          TankInhabitant(
            id: 'id1',
            customName: 'My Angel',
            fishUnit: 'Angelfish',
            quantity: 2,
          ),
          TankInhabitant(
            id: 'id2',
            customName: 'My Cory',
            fishUnit: 'Cory Cats',
            quantity: 3,
          ),
        ],
      );

      final fishData = {
        'freshwater': [
          Fish(
            name: 'Angelfish',
            commonNames: [],
            imageURL: '',
            compatible: ['Cory Cats'],
            notRecommended: [],
            notCompatible: [],
            withCaution: [],
          ),
          Fish(
            name: 'Cory Cats',
            commonNames: [],
            imageURL: '',
            compatible: ['Angelfish'],
            notRecommended: [],
            notCompatible: [],
            withCaution: [],
          ),
        ]
      };

      final score = TankHarmonyCalculator.calculateTankHarmonyScore(tank, fishData);
      expect(score, isNotNull);
      expect(score!, greaterThan(0.9));
    });

    test('Harmony labels', () {
      expect(TankHarmonyCalculator.getHarmonyLabel(0.95), equals('Excellent'));
      expect(TankHarmonyCalculator.getHarmonyLabel(0.85), equals('Good'));
      expect(TankHarmonyCalculator.getHarmonyLabel(0.65), equals('Fair'));
      expect(TankHarmonyCalculator.getHarmonyLabel(0.45), equals('Caution'));
      expect(TankHarmonyCalculator.getHarmonyLabel(0.25), equals('Poor'));
    });
  });

  group('Tank UI Tests', () {
    testWidgets('TankManagementScreen empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const TankManagementScreen(),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No Tanks Yet'), findsOneWidget);
      expect(find.text('Create Your First Tank'), findsOneWidget);
      expect(find.byIcon(Icons.water), findsOneWidget);
    });

    testWidgets('TankCreationScreen form validation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const TankCreationScreen(),
          ),
        ),
      );

      // Wait for the screen to load
      await tester.pumpAndSettle();

      // Verify title is displayed
      expect(find.text('Create Your Tank'), findsOneWidget);

      // Try to save without entering tank name
      await tester.tap(find.text('Save Tank'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a tank name'), findsOneWidget);

      // Enter a tank name
      await tester.enterText(find.byType(TextFormField), 'My Test Tank');
      await tester.pump();

      // Verify tank type chips are present
      expect(find.text('Freshwater'), findsOneWidget);
      expect(find.text('Saltwater'), findsOneWidget);
    });

    testWidgets('Tank type selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const TankCreationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Freshwater should be selected by default
      final freshwaterChip = find.text('Freshwater');
      final saltwaterChip = find.text('Saltwater');
      
      expect(freshwaterChip, findsOneWidget);
      expect(saltwaterChip, findsOneWidget);

      // Tap on saltwater
      await tester.tap(saltwaterChip);
      await tester.pumpAndSettle();

      // The category should change (this will trigger fish data reload)
      // Note: Full test would require mocking the asset loading
    });
  });
}