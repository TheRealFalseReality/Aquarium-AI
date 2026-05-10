import 'dart:convert';
import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/models/tank_notification.dart';
import 'package:fish_ai/providers/tank_provider.dart';
import 'package:fish_ai/providers/species_tags_provider.dart';
import 'package:fish_ai/providers/tank_tags_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  group('Notifications Backup and Restore Tests', () {
    test('backup includes tank notifications', () {
      // Create a tank with notifications
      final feedingNotif = TankNotification.create(
        type: NotificationType.feeding,
        notificationDateTime: DateTime(2024, 6, 15, 9, 0),
        repeatFrequency: RepeatFrequency.daily,
        repeatInterval: 1,
        notes: 'Feed the fish',
      );

      final dosingNotif = TankNotification.create(
        type: NotificationType.dosing,
        notificationDateTime: DateTime(2024, 6, 15, 10, 0),
        repeatFrequency: RepeatFrequency.weekly,
        repeatInterval: 2,
        notes: 'Dose the tank',
      );

      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        notifications: [feedingNotif, dosingNotif],
      );

      // Create backup data
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson()],
      };

      // Verify notifications are included
      final tankData = (backupData['tanks'] as List)[0] as Map<String, dynamic>;
      expect(tankData.containsKey('notifications'), isTrue);
      expect(tankData['notifications'], isA<List>());
      
      final notifications = tankData['notifications'] as List;
      expect(notifications.length, equals(2));
      expect(notifications[0]['type'], equals('feeding'));
      expect(notifications[0]['repeatFrequency'], equals('daily'));
      expect(notifications[0]['notes'], equals('Feed the fish'));
      expect(notifications[1]['type'], equals('dosing'));
      expect(notifications[1]['repeatFrequency'], equals('weekly'));
      expect(notifications[1]['notes'], equals('Dose the tank'));
    });

    test('backup JSON with notifications can be parsed and restored', () {
      // Create original tank with notifications
      final waterChangeNotif = TankNotification.create(
        type: NotificationType.waterChange,
        notificationDateTime: DateTime(2024, 6, 20, 14, 0),
        repeatFrequency: RepeatFrequency.weekly,
        repeatInterval: 1,
        notes: 'Weekly water change',
      );

      final maintenanceNotif = TankNotification.create(
        type: NotificationType.maintenance,
        notificationDateTime: DateTime(2024, 7, 1, 10, 0),
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 1,
        notes: 'Monthly filter cleaning',
        enabled: true,
      );

      final originalTank = Tank.create(
        name: 'Notification Test Tank',
        type: 'freshwater',
        sizeGallons: 40.0,
        notifications: [waterChangeNotif, maintenanceNotif],
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
      
      // Restore the tank
      final tanksList = parsedBackup['tanks'] as List;
      final restoredTank = Tank.fromJson(tanksList[0]);
      
      // Verify notifications were restored correctly
      expect(restoredTank.notifications.length, equals(2));
      
      final restoredWaterChange = restoredTank.notifications[0];
      expect(restoredWaterChange.type, equals(NotificationType.waterChange));
      expect(restoredWaterChange.repeatFrequency, equals(RepeatFrequency.weekly));
      expect(restoredWaterChange.repeatInterval, equals(1));
      expect(restoredWaterChange.notes, equals('Weekly water change'));
      expect(restoredWaterChange.notificationDateTime, equals(DateTime(2024, 6, 20, 14, 0)));
      
      final restoredMaintenance = restoredTank.notifications[1];
      expect(restoredMaintenance.type, equals(NotificationType.maintenance));
      expect(restoredMaintenance.repeatFrequency, equals(RepeatFrequency.monthly));
      expect(restoredMaintenance.repeatInterval, equals(1));
      expect(restoredMaintenance.notes, equals('Monthly filter cleaning'));
      expect(restoredMaintenance.enabled, isTrue);
      expect(restoredMaintenance.notificationDateTime, equals(DateTime(2024, 7, 1, 10, 0)));
    });

    test('backup handles tank without notifications (backwards compatibility)', () {
      // Old tank format without notifications
      final tankJson = {
        'id': 'tank-1',
        'name': 'Old Tank',
        'type': 'freshwater',
        'inhabitants': [],
        'sizeGallons': null,
        'sizeLiters': null,
        'notes': null,
        'harmonyScore': null,
        'calculationBreakdown': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'photos': [],
        'waterParameters': [],
        'dosingEntries': [],
        // Note: 'notifications' field is missing
      };

      // Should still parse successfully
      final restoredTank = Tank.fromJson(tankJson);
      
      expect(restoredTank.notifications, isEmpty);
      expect(restoredTank.name, equals('Old Tank'));
    });

    test('backup with empty notifications list', () {
      final tank = Tank.create(
        name: 'Empty Notifications Tank',
        type: 'marine',
        notifications: [],
      );

      final backupData = {
        'version': '1.0.0',
        'tanks': [tank.toJson()],
      };

      final jsonString = json.encode(backupData);
      final parsedBackup = json.decode(jsonString) as Map<String, dynamic>;
      
      final tanksList = parsedBackup['tanks'] as List;
      final restoredTank = Tank.fromJson(tanksList[0]);
      
      expect(restoredTank.notifications, isEmpty);
    });

    test('backup preserves all notification properties', () {
      final notification = TankNotification.create(
        type: NotificationType.testing,
        notificationDateTime: DateTime(2024, 6, 15, 16, 30),
        repeatFrequency: RepeatFrequency.monthly,
        repeatInterval: 3,
        notes: 'Test water parameters every 3 months',
        enabled: false,
      );

      final tank = Tank.create(
        name: 'Full Properties Tank',
        type: 'freshwater',
        notifications: [notification],
      );

      // Serialize and deserialize
      final json = tank.toJson();
      final restoredTank = Tank.fromJson(json);
      
      final restoredNotif = restoredTank.notifications[0];
      expect(restoredNotif.id, equals(notification.id));
      expect(restoredNotif.type, equals(notification.type));
      expect(restoredNotif.notificationDateTime, equals(notification.notificationDateTime));
      expect(restoredNotif.repeatFrequency, equals(notification.repeatFrequency));
      expect(restoredNotif.repeatInterval, equals(notification.repeatInterval));
      expect(restoredNotif.notes, equals(notification.notes));
      expect(restoredNotif.enabled, equals(notification.enabled));
      expect(restoredNotif.createdAt, equals(notification.createdAt));
      expect(restoredNotif.updatedAt, equals(notification.updatedAt));
    });

    test('backup with multiple tanks with different notifications', () {
      final tank1 = Tank.create(
        name: 'Tank 1',
        type: 'freshwater',
        notifications: [
          TankNotification.create(
            type: NotificationType.feeding,
            notificationDateTime: DateTime(2024, 6, 15, 9, 0),
            repeatFrequency: RepeatFrequency.daily,
          ),
        ],
      );

      final tank2 = Tank.create(
        name: 'Tank 2',
        type: 'marine',
        notifications: [
          TankNotification.create(
            type: NotificationType.dosing,
            notificationDateTime: DateTime(2024, 6, 15, 10, 0),
            repeatFrequency: RepeatFrequency.weekly,
          ),
          TankNotification.create(
            type: NotificationType.waterChange,
            notificationDateTime: DateTime(2024, 6, 20, 14, 0),
            repeatFrequency: RepeatFrequency.weekly,
          ),
        ],
      );

      final backupData = {
        'version': '1.0.0',
        'tanks': [tank1.toJson(), tank2.toJson()],
      };

      final jsonString = json.encode(backupData);
      final parsedBackup = json.decode(jsonString) as Map<String, dynamic>;
      
      final tanksList = parsedBackup['tanks'] as List;
      expect(tanksList.length, equals(2));
      
      final restoredTank1 = Tank.fromJson(tanksList[0]);
      expect(restoredTank1.notifications.length, equals(1));
      expect(restoredTank1.notifications[0].type, equals(NotificationType.feeding));
      
      final restoredTank2 = Tank.fromJson(tanksList[1]);
      expect(restoredTank2.notifications.length, equals(2));
      expect(restoredTank2.notifications[0].type, equals(NotificationType.dosing));
      expect(restoredTank2.notifications[1].type, equals(NotificationType.waterChange));
    });

    test('backup preserves notification datetime precision', () {
      final specificDateTime = DateTime(2024, 6, 15, 14, 35, 22, 123);
      final notification = TankNotification.create(
        type: NotificationType.other,
        notificationDateTime: specificDateTime,
        notes: 'Precise time notification',
      );

      final tank = Tank.create(
        name: 'Precision Tank',
        type: 'freshwater',
        notifications: [notification],
      );

      final json = tank.toJson();
      final restoredTank = Tank.fromJson(json);
      
      final restoredNotif = restoredTank.notifications[0];
      expect(restoredNotif.notificationDateTime.year, equals(specificDateTime.year));
      expect(restoredNotif.notificationDateTime.month, equals(specificDateTime.month));
      expect(restoredNotif.notificationDateTime.day, equals(specificDateTime.day));
      expect(restoredNotif.notificationDateTime.hour, equals(specificDateTime.hour));
      expect(restoredNotif.notificationDateTime.minute, equals(specificDateTime.minute));
    });
  });

  group('TankTag (user-created tank labels) Backup and Restore Tests', () {
    test('tank toJson includes tags with name and color', () {
      final tag1 = TankTag(name: 'Planted', color: 0xFF4CAF50);
      final tag2 = TankTag(name: 'Quarantine'); // null color (theme default)
      final tank = Tank.create(
        name: 'Tagged Tank',
        type: 'freshwater',
        tags: [tag1, tag2],
      );

      final tankJson = tank.toJson();

      expect(tankJson.containsKey('tags'), isTrue);
      final tagsData = tankJson['tags'] as List;
      expect(tagsData.length, equals(2));
      expect(tagsData[0]['name'], equals('Planted'));
      expect(tagsData[0]['color'], equals(0xFF4CAF50));
      expect(tagsData[1]['name'], equals('Quarantine'));
      expect(tagsData[1].containsKey('color'), isFalse); // null color omitted
    });

    test('tank fromJson restores tags with name and color', () {
      const argbColor = 0xFF4CAF50;
      final originalTank = Tank.create(
        name: 'Tagged Tank',
        type: 'freshwater',
        tags: [
          TankTag(name: 'Planted', color: argbColor),
          TankTag(name: 'FOWLR'),
        ],
      );

      final restoredTank = Tank.fromJson(originalTank.toJson());

      expect(restoredTank.tags.length, equals(2));
      expect(restoredTank.tags[0].name, equals('Planted'));
      expect(restoredTank.tags[0].color, equals(argbColor));
      expect(restoredTank.tags[1].name, equals('FOWLR'));
      expect(restoredTank.tags[1].color, isNull);
    });

    test('tank tags survive JSON roundtrip in full backup format', () {
      final tank = Tank.create(
        name: 'Reef Tank',
        type: 'marine',
        tags: [
          TankTag(name: 'SPS', color: 0xFF2196F3),
          TankTag(name: 'Display'),
        ],
      );

      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson(includeLocalPaths: false)],
      };

      final jsonString = json.encode(backupData);
      final parsed = json.decode(jsonString) as Map<String, dynamic>;
      final tanksList = parsed['tanks'] as List;
      final restoredTank = Tank.fromJson(tanksList[0]);

      expect(restoredTank.tags.length, equals(2));
      expect(restoredTank.tags[0].name, equals('SPS'));
      expect(restoredTank.tags[0].color, equals(0xFF2196F3));
      expect(restoredTank.tags[1].name, equals('Display'));
      expect(restoredTank.tags[1].color, isNull);
    });

    test('backup without tags field restores to empty tag list (backwards compat)', () {
      final tankJson = {
        'id': 'tank-1',
        'name': 'Old Tank',
        'type': 'freshwater',
        'inhabitants': [],
        'sizeGallons': null,
        'sizeLiters': null,
        'notes': null,
        'harmonyScore': null,
        'calculationBreakdown': null,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
        'photos': [],
        'waterParameters': [],
        'dosingEntries': [],
        // 'tags' field absent (legacy backup)
      };

      final restoredTank = Tank.fromJson(tankJson);

      expect(restoredTank.tags, isEmpty);
    });

    test('TankTagsNotifier exports and imports tags correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tankTagsProvider.notifier);

      // Seed some tags
      await notifier.importTags([
        TankTag(name: 'Planted', color: 0xFF4CAF50),
        TankTag(name: 'FOWLR'),
      ]);

      final exported = notifier.exportTags();
      expect(exported.length, equals(2));
      expect(exported[0]['name'], equals('Planted'));
      expect(exported[0]['color'], equals(0xFF4CAF50));
      expect(exported[1]['name'], equals('FOWLR'));
      expect(exported[1].containsKey('color'), isFalse);

      // Restore via importTags
      final restored = exported
          .map((e) => TankTag.fromJson(e))
          .toList();
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      final notifier2 = container2.read(tankTagsProvider.notifier);
      await notifier2.importTags(restored);

      final state = container2.read(tankTagsProvider);
      expect(state.length, equals(2));
      expect(state[0].name, equals('Planted'));
      expect(state[0].color, equals(0xFF4CAF50));
      expect(state[1].name, equals('FOWLR'));
      expect(state[1].color, isNull);
    });

    test('TankTagsNotifier syncFromTanks merges tags from multiple tanks', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tankTagsProvider.notifier);

      final tanks = [
        Tank.create(
          name: 'Tank A',
          type: 'freshwater',
          tags: [TankTag(name: 'Planted', color: 0xFF4CAF50)],
        ),
        Tank.create(
          name: 'Tank B',
          type: 'marine',
          tags: [
            TankTag(name: 'FOWLR'),
            TankTag(name: 'Display', color: 0xFF9C27B0),
          ],
        ),
      ];

      await notifier.syncFromTanks(tanks);

      final state = container.read(tankTagsProvider);
      expect(state.length, equals(3));
      final names = state.map((t) => t.name).toSet();
      expect(names, containsAll(['Planted', 'FOWLR', 'Display']));
    });

    test('TankTagsNotifier syncFromTanks preserves existing registry entries', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tankTagsProvider.notifier);

      // Pre-populate registry with a tag that has a specific color
      await notifier.importTags([TankTag(name: 'Planted', color: 0xFF4CAF50)]);

      // Sync from a tank that also has 'Planted' but with a different color
      await notifier.syncFromTanks([
        Tank.create(
          name: 'Tank A',
          type: 'freshwater',
          tags: [TankTag(name: 'Planted', color: 0xFFFF0000)],
        ),
      ]);

      // Registry colour should be preserved (registry wins)
      final state = container.read(tankTagsProvider);
      final planted = state.firstWhere((t) => t.name == 'Planted');
      expect(planted.color, equals(0xFF4CAF50));
    });

    test('backup tankTags section round-trips correctly', () {
      final tags = [
        TankTag(name: 'Planted', color: 0xFF4CAF50),
        TankTag(name: 'FOWLR'),
        TankTag(name: 'Display', color: 0xFF9C27B0),
      ];

      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
        'tanks': [],
        'tankTags': tags.map((t) => t.toJson()).toList(),
      };

      final jsonString = json.encode(backupData);
      final parsed = json.decode(jsonString) as Map<String, dynamic>;

      expect(parsed.containsKey('tankTags'), isTrue);
      final restoredList =
          (parsed['tankTags'] as List).map((e) => TankTag.fromJson(e)).toList();

      expect(restoredList.length, equals(3));
      expect(restoredList[0].name, equals('Planted'));
      expect(restoredList[0].color, equals(0xFF4CAF50));
      expect(restoredList[1].name, equals('FOWLR'));
      expect(restoredList[1].color, isNull);
      expect(restoredList[2].name, equals('Display'));
      expect(restoredList[2].color, equals(0xFF9C27B0));
    });

    test('backup without tankTags section is still valid (backwards compat)', () {
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
        'tanks': [],
      };

      expect(backupData.containsKey('tanks'), isTrue);
      expect(backupData.containsKey('version'), isTrue);
      // tankTags is optional — its absence must not break validation
      expect(backupData.containsKey('tankTags'), isFalse);
    });
  });

  group('buildBackupPayload and applyBackupPayload Tests', () {
    late ProviderContainer container;
    late TankNotifier tankNotifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Aquarium AI',
        packageName: 'com.example.fish_ai',
        version: '3.0.0',
        buildNumber: '300',
        buildSignature: '',
      );
      container = ProviderContainer();
      tankNotifier = container.read(tankProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      container.dispose();
    });

    test('buildBackupPayload returns correct structure with tanks', () async {
      final tank1 = Tank.create(name: 'Tank A', type: 'freshwater');
      final tank2 = Tank.create(name: 'Tank B', type: 'marine');
      tankNotifier.addTank(tank1);
      tankNotifier.addTank(tank2);

      final payload = await tankNotifier.buildBackupPayload();

      expect(payload['version'], equals('3.0.0'));
      expect(payload['appName'], equals('Aquarium AI'));
      expect(payload['exportDate'], isA<String>());
      expect(() => DateTime.parse(payload['exportDate'] as String), returnsNormally);
      expect(payload['tankCount'], equals(2));
      expect(payload['tanks'], isA<List>());
      expect((payload['tanks'] as List).length, equals(2));
      expect(payload.containsKey('speciesTags'), isTrue);
      expect(payload.containsKey('tankTags'), isTrue);
      expect(payload.containsKey('reschedulePreferences'), isTrue);
      expect(payload.containsKey('dosingPresets'), isTrue);
    });

    test('buildBackupPayload with no tanks returns empty tanks list', () async {
      final payload = await tankNotifier.buildBackupPayload();

      expect(payload['tankCount'], equals(0));
      expect((payload['tanks'] as List).isEmpty, isTrue);
    });

    test('collectLocalTankPhotoPathsForCloudBackup includes only local tank photos', () async {
      final localPhotoTank = Tank.create(
        name: 'Photo Tank',
        type: 'freshwater',
        photos: [
          TankPhoto(
            id: 'local-photo-1',
            imagePath: '/tmp/local-photo.jpg',
            dateTaken: DateTime(2025, 1, 1),
          ),
          TankPhoto(
            id: 'url-photo-1',
            imageUrl: 'https://example.com/photo.jpg',
            dateTaken: DateTime(2025, 1, 2),
          ),
        ],
      );

      final noPhotoTank = Tank.create(name: 'No Photo Tank', type: 'marine');
      await tankNotifier.addTank(localPhotoTank);
      await tankNotifier.addTank(noPhotoTank);

      final localPaths = tankNotifier.collectLocalTankPhotoPathsForCloudBackup();

      expect(localPaths.length, equals(1));
      expect(localPaths.first['tankId'], equals(localPhotoTank.id));
      expect(localPaths.first['photoId'], equals('local-photo-1'));
      expect(localPaths.first['imagePath'], equals('/tmp/local-photo.jpg'));
    });

    test('buildBackupPayload payload is JSON-serializable', () async {
      tankNotifier.addTank(Tank.create(name: 'Reef', type: 'marine'));

      final payload = await tankNotifier.buildBackupPayload();

      expect(() => json.encode(payload), returnsNormally);
      final jsonString = json.encode(payload);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      expect(decoded['version'], equals('3.0.0'));
      expect(decoded['tanks'], isA<List>());
    });

    test('applyBackupPayload restores tanks from payload', () async {
      final tank = Tank.create(name: 'Restored Tank', type: 'freshwater', sizeGallons: 55.0);
      final payload = {
        'version': '3.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson()],
      };

      final success = await tankNotifier.applyBackupPayload(payload);

      expect(success, isTrue);
      final tanks = container.read(tankProvider).tanks;
      expect(tanks.length, equals(1));
      expect(tanks.first.name, equals('Restored Tank'));
      expect(tanks.first.type, equals('freshwater'));
      expect(tanks.first.sizeGallons, equals(55.0));
    });

    test('applyBackupPayload restores species tags when present', () async {
      final payload = {
        'version': '3.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
        'tanks': [],
        'speciesTags': {
          'Tetras': ['Neon Tetra', 'Cardinal Tetra'],
        },
      };

      final success = await tankNotifier.applyBackupPayload(payload);

      expect(success, isTrue);
      final tags = container.read(speciesTagsProvider.notifier).exportTags();
      expect(tags['Tetras'], equals(['Neon Tetra', 'Cardinal Tetra']));
    });

    test('applyBackupPayload restores tank tags when present', () async {
      final payload = {
        'version': '3.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
        'tanks': [],
        'tankTags': [
          {'name': 'Planted', 'color': null},
          {'name': 'Reef', 'color': null},
        ],
      };

      final success = await tankNotifier.applyBackupPayload(payload);

      expect(success, isTrue);
      final tankTags = container.read(tankTagsProvider.notifier).exportTags();
      expect(tankTags.any((t) => t.name == 'Planted'), isTrue);
      expect(tankTags.any((t) => t.name == 'Reef'), isTrue);
    });

    test('applyBackupPayload succeeds without optional fields', () async {
      // Payload without speciesTags, tankTags, reschedulePreferences, dosingPresets
      final tank = Tank.create(name: 'Basic Tank', type: 'freshwater');
      final payload = {
        'version': '2.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson()],
      };

      final success = await tankNotifier.applyBackupPayload(payload);

      expect(success, isTrue);
      expect(container.read(tankProvider).tanks.length, equals(1));
    });

    test('applyBackupPayload fails gracefully on missing required fields', () async {
      final invalidPayloads = [
        <String, dynamic>{},
        {'tanks': []},
        {'version': '1.0.0'},
        {'version': '1.0.0', 'tanks': 'not-a-list'},
      ];

      for (final payload in invalidPayloads) {
        final success = await tankNotifier.applyBackupPayload(payload);
        expect(success, isFalse, reason: 'Should fail for payload: $payload');
      }
    });

    test('applyBackupPayload replaces existing tanks', () async {
      tankNotifier.addTank(Tank.create(name: 'Old Tank', type: 'freshwater'));
      await Future.delayed(const Duration(milliseconds: 50));

      final newTank = Tank.create(name: 'New Tank', type: 'marine');
      final payload = {
        'version': '3.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [newTank.toJson()],
      };

      final success = await tankNotifier.applyBackupPayload(payload);

      expect(success, isTrue);
      final tanks = container.read(tankProvider).tanks;
      expect(tanks.length, equals(1));
      expect(tanks.first.name, equals('New Tank'));
    });

    test('buildBackupPayload then applyBackupPayload roundtrip', () async {
      final original = Tank.create(
        name: 'Roundtrip Tank',
        type: 'freshwater',
        sizeGallons: 75.0,
        notes: 'Test notes',
      );
      tankNotifier.addTank(original);

      final payload = await tankNotifier.buildBackupPayload();

      // Clear tanks and restore via applyBackupPayload
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      SharedPreferences.setMockInitialValues({});
      await Future.delayed(const Duration(milliseconds: 100));
      final success = await container2.read(tankProvider.notifier).applyBackupPayload(payload);

      expect(success, isTrue);
      final restored = container2.read(tankProvider).tanks;
      expect(restored.length, equals(1));
      expect(restored.first.name, equals('Roundtrip Tank'));
      expect(restored.first.sizeGallons, equals(75.0));
      expect(restored.first.notes, equals('Test notes'));
    });
  });
}
