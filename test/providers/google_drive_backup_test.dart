import 'dart:convert';
import 'dart:typed_data';
import 'package:fish_ai/models/tank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tank Backup Data Structure Tests', () {
    test('backup data JSON structure is correct', () {
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        sizeGallons: 40.0,
      );
      
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson()],
        'speciesTags': {},
        'reschedulePreferences': {},
      };
      
      expect(backupData['version'], equals('1.0.0'));
      expect(backupData['appName'], equals('Aquarium AI'));
      expect(backupData['tankCount'], equals(1));
      expect(backupData['tanks'], isA<List>());
      expect(backupData.containsKey('speciesTags'), true);
      expect(backupData.containsKey('reschedulePreferences'), true);
    });

    test('backup data can be converted to JSON', () {
      final tank = Tank.create(
        name: 'JSON Test Tank',
        type: 'freshwater',
        sizeGallons: 40.0,
      );
      
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson()],
        'speciesTags': {},
        'reschedulePreferences': {},
      };
      
      // Convert to JSON and verify it doesn't throw
      final jsonString = json.encode(backupData);
      expect(jsonString, isA<String>());
      expect(jsonString.length, greaterThan(0));
      
      // Verify it can be parsed back
      final parsed = json.decode(jsonString);
      expect(parsed, isA<Map>());
      expect(parsed['version'], equals('1.0.0'));
    });

    test('backup data creates proper formatted JSON', () {
      final tank = Tank.create(name: 'Format Test', type: 'freshwater');
      
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson()],
        'speciesTags': {},
        'reschedulePreferences': {},
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // Verify formatted JSON
      expect(jsonString, contains('{\n  "version"'));
      expect(jsonString, contains('"appName": "Aquarium AI"'));
      expect(jsonString, contains('"tanks": ['));
    });

    test('backup data can be converted to bytes for upload', () {
      final tank = Tank.create(name: 'Bytes Test', type: 'marine');
      
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson()],
        'speciesTags': {},
        'reschedulePreferences': {},
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(0));
      
      // Verify bytes can be converted back to string
      final decoded = utf8.decode(bytes);
      expect(decoded, equals(jsonString));
    });

    test('backup data with multiple tanks', () {
      final tank1 = Tank.create(name: 'Tank 1', type: 'freshwater');
      final tank2 = Tank.create(name: 'Tank 2', type: 'marine');
      
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 2,
        'tanks': [tank1.toJson(), tank2.toJson()],
        'speciesTags': {},
        'reschedulePreferences': {},
      };
      
      expect(backupData['tankCount'], equals(2));
      expect((backupData['tanks'] as List).length, equals(2));
      
      final jsonString = json.encode(backupData);
      final parsed = json.decode(jsonString);
      expect((parsed['tanks'] as List).length, equals(2));
    });
  });

  group('Tank Restore Validation Tests', () {
    test('validate backup format requires version and tanks', () {
      // Valid backup
      final validBackup = {
        'version': '1.0.0',
        'tanks': [],
      };
      expect(validBackup.containsKey('tanks') && validBackup.containsKey('version'), true);
      
      // Invalid backups
      final invalidBackups = [
        {}, // Empty
        {'tanks': []}, // Missing version
        {'version': '1.0.0'}, // Missing tanks
      ];
      
      for (final invalid in invalidBackups) {
        expect(invalid.containsKey('tanks') && invalid.containsKey('version'), false);
      }
    });

    test('backup JSON can be parsed to tank objects', () {
      final originalTank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        sizeGallons: 40.0,
        notes: 'Test notes',
      );
      
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
      expect(restoredTank.notes, equals(originalTank.notes));
    });

    test('backup with species tags is valid', () {
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
      
      expect(backupData.containsKey('speciesTags'), true);
      
      final jsonString = json.encode(backupData);
      final parsed = json.decode(jsonString) as Map<String, dynamic>;
      
      final speciesTags = parsed['speciesTags'] as Map<String, dynamic>;
      final speciesTagsMap = speciesTags.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      );
      
      expect(speciesTagsMap['Tetras'], equals(['Neon Tetra', 'Cardinal Tetra']));
      expect(speciesTagsMap['Barbs'], equals(['Tiger Barb']));
    });

    test('backup without optional fields is still valid', () {
      final backupData = {
        'version': '1.0.0',
        'tanks': [],
      };
      
      expect(backupData.containsKey('tanks'), true);
      expect(backupData.containsKey('version'), true);
      expect(backupData.containsKey('speciesTags'), false);
    });
  });
}
