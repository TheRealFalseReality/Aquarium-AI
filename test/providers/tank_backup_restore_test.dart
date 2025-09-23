import 'dart:convert';
import 'dart:io';
import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/providers/tank_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Tank Backup and Restore Tests', () {
    late TankNotifier tankNotifier;
    
    setUp(() async {
      // Mock shared preferences
      SharedPreferences.setMockInitialValues({});
      tankNotifier = TankNotifier();
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('createBackupInfo returns correct metadata', () {
      // Add some test tanks
      final tank1 = Tank.create(name: 'Test Tank 1', type: 'freshwater');
      final tank2 = Tank.create(name: 'Test Tank 2', type: 'marine');
      
      tankNotifier.addTank(tank1);
      tankNotifier.addTank(tank2);
      
      final backupInfo = tankNotifier.createBackupInfo();
      
      expect(backupInfo['tankCount'], equals(2));
      expect(backupInfo['version'], equals('1.0.0'));
      expect(backupInfo['exportDate'], isA<String>());
      
      // Verify the export date is a valid ISO 8601 string
      expect(() => DateTime.parse(backupInfo['exportDate']), returnsNormally);
    });

    test('backup data format validation', () {
      // Create test tanks with various configurations
      final tank1 = Tank.create(
        name: 'Community Tank',
        type: 'freshwater',
        sizeGallons: 55.0,
        sizeLiters: 208.2,
        notes: 'My first tank',
        inhabitants: [
          TankInhabitant(
            id: 'fish1',
            customName: 'Nemo',
            fishUnit: 'Clownfish',
            quantity: 2,
          ),
        ],
      );
      
      final tank2 = Tank.create(
        name: 'Reef Tank',
        type: 'marine',
        sizeGallons: 75.0,
      );

      // Simulate having tanks in the provider
      final mockTanks = [tank1, tank2];
      
      // Create backup data manually (simulating the export process)
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': mockTanks.length,
        'tanks': mockTanks.map((tank) => tank.toJson()).toList(),
      };

      // Verify backup structure
      expect(backupData['version'], equals('1.0.0'));
      expect(backupData['appName'], equals('Aquarium AI'));
      expect(backupData['tankCount'], equals(2));
      expect(backupData['tanks'], isA<List>());
      
      final tanksData = backupData['tanks'] as List;
      expect(tanksData.length, equals(2));
      
      // Verify first tank data
      final tank1Data = tanksData[0] as Map<String, dynamic>;
      expect(tank1Data['name'], equals('Community Tank'));
      expect(tank1Data['type'], equals('freshwater'));
      expect(tank1Data['sizeGallons'], equals(55.0));
      expect(tank1Data['notes'], equals('My first tank'));
      expect(tank1Data['inhabitants'], isA<List>());
      
      final inhabitants = tank1Data['inhabitants'] as List;
      expect(inhabitants.length, equals(1));
      expect(inhabitants[0]['customName'], equals('Nemo'));
      expect(inhabitants[0]['fishUnit'], equals('Clownfish'));
    });

    test('backup JSON can be parsed back to tanks', () {
      // Create test data
      final originalTank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        sizeGallons: 40.0,
        sizeLiters: 151.4,
        notes: 'Test notes',
        inhabitants: [
          TankInhabitant(
            id: 'test-fish',
            customName: 'Test Fish',
            fishUnit: 'Guppy',
            quantity: 5,
            customImageUrl: 'https://example.com/fish.jpg',
          ),
        ],
      );

      // Convert to JSON and back
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [originalTank.toJson()],
      };

      final jsonString = json.encode(backupData);
      final parsedBackup = json.decode(jsonString) as Map<String, dynamic>;
      
      // Verify parsing
      expect(parsedBackup['tanks'], isA<List>());
      
      final tanksList = parsedBackup['tanks'] as List;
      final restoredTank = Tank.fromJson(tanksList[0]);
      
      // Verify restored tank matches original
      expect(restoredTank.name, equals(originalTank.name));
      expect(restoredTank.type, equals(originalTank.type));
      expect(restoredTank.sizeGallons, equals(originalTank.sizeGallons));
      expect(restoredTank.sizeLiters, equals(originalTank.sizeLiters));
      expect(restoredTank.notes, equals(originalTank.notes));
      expect(restoredTank.inhabitants.length, equals(1));
      
      final restoredInhabitant = restoredTank.inhabitants[0];
      final originalInhabitant = originalTank.inhabitants[0];
      expect(restoredInhabitant.customName, equals(originalInhabitant.customName));
      expect(restoredInhabitant.fishUnit, equals(originalInhabitant.fishUnit));
      expect(restoredInhabitant.quantity, equals(originalInhabitant.quantity));
      expect(restoredInhabitant.customImageUrl, equals(originalInhabitant.customImageUrl));
    });

    test('backup format validation for invalid data', () {
      // Test invalid backup formats
      final invalidBackups = [
        {}, // Empty object
        {'tanks': []}, // Missing version
        {'version': '1.0.0'}, // Missing tanks
        {'version': '1.0.0', 'tanks': 'not-a-list'}, // Wrong tanks type
      ];

      for (final invalidBackup in invalidBackups) {
        expect(
          invalidBackup.containsKey('tanks') && invalidBackup.containsKey('version'),
          isFalse,
          reason: 'Invalid backup should fail validation: $invalidBackup',
        );
      }
    });

    test('empty tanks backup handling', () {
      final backupInfo = tankNotifier.createBackupInfo();
      
      expect(backupInfo['tankCount'], equals(0));
      expect(backupInfo['version'], equals('1.0.0'));
      expect(backupInfo['exportDate'], isA<String>());
    });
  });

  group('Backup File Format Tests', () {
    test('backup JSON is properly formatted', () {
      final tank = Tank.create(
        name: 'Formatted Tank',
        type: 'freshwater',
        inhabitants: [
          TankInhabitant(
            id: 'test-id',
            customName: 'Test Fish',
            fishUnit: 'Tetra',
            quantity: 10,
          ),
        ],
      );

      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson()],
      };

      // Test that the JSON can be formatted nicely
      final prettyJson = const JsonEncoder.withIndent('  ').convert(backupData);
      
      expect(prettyJson, contains('{\n  "version"'));
      expect(prettyJson, contains('"appName": "Aquarium AI"'));
      expect(prettyJson, contains('"tanks": ['));
      
      // Verify it can be parsed back
      final parsed = json.decode(prettyJson);
      expect(parsed['version'], equals('1.0.0'));
      expect(parsed['tanks'], isA<List>());
    });
  });
}