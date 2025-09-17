import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/screens/tank_management_screen.dart';
import 'package:fish_ai/screens/tank_creation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Tank Model Tests', () {
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