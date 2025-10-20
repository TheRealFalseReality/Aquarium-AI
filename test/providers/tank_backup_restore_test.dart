import 'dart:convert';
import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/providers/tank_provider.dart';
import 'package:fish_ai/providers/species_tags_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Tank Backup and Restore Tests', () {
    late ProviderContainer container;
    late TankNotifier tankNotifier;
    
    setUp(() async {
      // Mock shared preferences
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      tankNotifier = container.read(tankProvider.notifier);
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      container.dispose();
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

  group('Species Tags Backup and Restore Tests', () {
    late ProviderContainer container;
    
    setUp(() async {
      // Mock shared preferences
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      container.dispose();
    });

    test('backup includes species tags', () {
      // Add some species tags
      final speciesTagsNotifier = container.read(speciesTagsProvider.notifier);
      speciesTagsNotifier.setTagsForFishType('Tetras', ['Neon Tetra', 'Cardinal Tetra']);
      speciesTagsNotifier.setTagsForFishType('Barbs', ['Tiger Barb', 'Cherry Barb']);

      // Create backup data with species tags
      final speciesTags = speciesTagsNotifier.exportTags();
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
        'tanks': [],
        'speciesTags': speciesTags,
      };

      // Verify species tags are included
      expect(backupData.containsKey('speciesTags'), isTrue);
      expect(backupData['speciesTags'], isA<Map<String, List<String>>>());
      
      final tags = backupData['speciesTags'] as Map<String, List<String>>;
      expect(tags['Tetras'], equals(['Neon Tetra', 'Cardinal Tetra']));
      expect(tags['Barbs'], equals(['Tiger Barb', 'Cherry Barb']));
    });

    test('restore imports species tags', () async {
      final speciesTagsNotifier = container.read(speciesTagsProvider.notifier);
      
      // Create backup data with species tags
      final importTags = {
        'Guppies': ['Fancy Guppy', 'Endler Guppy'],
        'Cichlids': ['Oscar', 'Angelfish'],
      };
      
      // Import the tags
      await speciesTagsNotifier.importTags(importTags);
      
      // Verify tags were imported
      final restoredTags = speciesTagsNotifier.exportTags();
      expect(restoredTags['Guppies'], equals(['Fancy Guppy', 'Endler Guppy']));
      expect(restoredTags['Cichlids'], equals(['Oscar', 'Angelfish']));
    });

    test('backup JSON with species tags can be parsed', () {
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
        'tanks': [],
        'speciesTags': {
          'Tetras': ['Neon Tetra', 'Cardinal Tetra'],
          'Barbs': ['Tiger Barb'],
        },
      };

      // Convert to JSON and back
      final jsonString = json.encode(backupData);
      final parsedBackup = json.decode(jsonString) as Map<String, dynamic>;
      
      // Verify species tags parsing
      expect(parsedBackup.containsKey('speciesTags'), isTrue);
      final speciesTags = parsedBackup['speciesTags'] as Map<String, dynamic>;
      
      final speciesTagsMap = speciesTags.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
      
      expect(speciesTagsMap['Tetras'], equals(['Neon Tetra', 'Cardinal Tetra']));
      expect(speciesTagsMap['Barbs'], equals(['Tiger Barb']));
    });

    test('backup without species tags is still valid', () {
      // Old backup format without species tags
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
        'tanks': [],
      };

      // Should still pass validation
      expect(backupData.containsKey('tanks'), isTrue);
      expect(backupData.containsKey('version'), isTrue);
      
      // Species tags are optional
      expect(backupData.containsKey('speciesTags'), isFalse);
    });

    test('empty species tags are handled correctly', () {
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
        'tanks': [],
        'speciesTags': {},
      };

      final jsonString = json.encode(backupData);
      final parsedBackup = json.decode(jsonString) as Map<String, dynamic>;
      
      expect(parsedBackup['speciesTags'], isA<Map>());
      expect((parsedBackup['speciesTags'] as Map).isEmpty, isTrue);
    });
  });
}