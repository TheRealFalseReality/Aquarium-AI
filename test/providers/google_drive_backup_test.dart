import 'dart:convert';
import 'dart:typed_data';
import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/providers/tank_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Tank Backup Data Creation Tests', () {
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

    test('createBackupData returns valid backup structure', () async {
      // Add test tanks
      final tank1 = Tank.create(name: 'Test Tank 1', type: 'freshwater');
      final tank2 = Tank.create(name: 'Test Tank 2', type: 'marine');
      
      await tankNotifier.addTank(tank1);
      await tankNotifier.addTank(tank2);
      
      final backupData = await tankNotifier.createBackupData();
      
      expect(backupData, isNotNull);
      expect(backupData!['version'], equals('1.0.0'));
      expect(backupData['appName'], equals('Aquarium AI'));
      expect(backupData['tankCount'], equals(2));
      expect(backupData['tanks'], isA<List>());
      expect(backupData.containsKey('speciesTags'), true);
      expect(backupData.containsKey('reschedulePreferences'), true);
    });

    test('createBackupData can be converted to JSON', () async {
      final tank = Tank.create(
        name: 'JSON Test Tank',
        type: 'freshwater',
        sizeGallons: 40.0,
      );
      
      await tankNotifier.addTank(tank);
      
      final backupData = await tankNotifier.createBackupData();
      expect(backupData, isNotNull);
      
      // Convert to JSON and verify it doesn't throw
      final jsonString = json.encode(backupData);
      expect(jsonString, isA<String>());
      expect(jsonString.length, greaterThan(0));
      
      // Verify it can be parsed back
      final parsed = json.decode(jsonString);
      expect(parsed, isA<Map>());
      expect(parsed['version'], equals('1.0.0'));
    });

    test('createBackupData creates proper formatted JSON', () async {
      final tank = Tank.create(name: 'Format Test', type: 'freshwater');
      await tankNotifier.addTank(tank);
      
      final backupData = await tankNotifier.createBackupData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // Verify formatted JSON
      expect(jsonString, contains('{\n  "version"'));
      expect(jsonString, contains('"appName": "Aquarium AI"'));
      expect(jsonString, contains('"tanks": ['));
    });

    test('backup data can be converted to bytes for upload', () async {
      final tank = Tank.create(name: 'Bytes Test', type: 'marine');
      await tankNotifier.addTank(tank);
      
      final backupData = await tankNotifier.createBackupData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(0));
      
      // Verify bytes can be converted back to string
      final decoded = utf8.decode(bytes);
      expect(decoded, equals(jsonString));
    });
  });

  group('Tank Restore From Backup Data Tests', () {
    late ProviderContainer container;
    late TankNotifier tankNotifier;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      tankNotifier = container.read(tankProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      container.dispose();
    });

    test('restoreFromBackupData successfully restores tanks', () async {
      // Create backup data
      final tank = Tank.create(
        name: 'Restore Test Tank',
        type: 'freshwater',
        sizeGallons: 55.0,
        notes: 'Test notes',
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
      
      final jsonString = json.encode(backupData);
      
      // Restore from backup
      final success = await tankNotifier.restoreFromBackupData(jsonString);
      
      expect(success, true);
      
      final state = container.read(tankProvider);
      expect(state.tanks.length, equals(1));
      expect(state.tanks[0].name, equals('Restore Test Tank'));
      expect(state.tanks[0].type, equals('freshwater'));
      expect(state.tanks[0].sizeGallons, equals(55.0));
    });

    test('restoreFromBackupData handles invalid JSON', () async {
      final invalidJson = 'not a valid json';
      
      final success = await tankNotifier.restoreFromBackupData(invalidJson);
      
      expect(success, false);
      
      final state = container.read(tankProvider);
      expect(state.error, isNotNull);
    });

    test('restoreFromBackupData handles missing version', () async {
      final backupData = {
        // Missing 'version' field
        'appName': 'Aquarium AI',
        'tanks': [],
      };
      
      final jsonString = json.encode(backupData);
      final success = await tankNotifier.restoreFromBackupData(jsonString);
      
      expect(success, false);
    });

    test('restoreFromBackupData handles missing tanks', () async {
      final backupData = {
        'version': '1.0.0',
        // Missing 'tanks' field
        'appName': 'Aquarium AI',
      };
      
      final jsonString = json.encode(backupData);
      final success = await tankNotifier.restoreFromBackupData(jsonString);
      
      expect(success, false);
    });

    test('restoreFromBackupData replaces existing tanks', () async {
      // Add some initial tanks
      await tankNotifier.addTank(Tank.create(name: 'Old Tank 1', type: 'freshwater'));
      await tankNotifier.addTank(Tank.create(name: 'Old Tank 2', type: 'marine'));
      
      var state = container.read(tankProvider);
      expect(state.tanks.length, equals(2));
      
      // Create new backup with different tanks
      final newTank = Tank.create(name: 'New Tank', type: 'brackish');
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [newTank.toJson()],
        'speciesTags': {},
        'reschedulePreferences': {},
      };
      
      final jsonString = json.encode(backupData);
      final success = await tankNotifier.restoreFromBackupData(jsonString);
      
      expect(success, true);
      
      state = container.read(tankProvider);
      expect(state.tanks.length, equals(1));
      expect(state.tanks[0].name, equals('New Tank'));
    });

    test('restoreFromBackupData handles empty tanks list', () async {
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
        'tanks': [],
        'speciesTags': {},
        'reschedulePreferences': {},
      };
      
      final jsonString = json.encode(backupData);
      final success = await tankNotifier.restoreFromBackupData(jsonString);
      
      expect(success, true);
      
      final state = container.read(tankProvider);
      expect(state.tanks.isEmpty, true);
    });
  });
}
