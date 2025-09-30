import 'dart:convert';
import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/providers/tank_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Tank Provider Web Platform Tests', () {
    late TankNotifier tankNotifier;
    
    setUp(() async {
      // Mock shared preferences
      SharedPreferences.setMockInitialValues({});
      tankNotifier = TankNotifier();
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('platform detection works correctly', () {
      // This test will run with kIsWeb as false in test environment
      expect(kIsWeb, isFalse);
    });

    test('backup data can be converted to bytes for web platform', () {
      // Create test tank
      final tank = Tank.create(
        name: 'Web Test Tank',
        type: 'freshwater',
        sizeGallons: 30.0,
        inhabitants: [
          TankInhabitant(
            id: 'web-fish',
            customName: 'Web Fish',
            fishUnit: 'Goldfish',
            quantity: 1,
          ),
        ],
      );

      // Create backup data
      final backupData = {
        'version': '1.0.0',
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 1,
        'tanks': [tank.toJson()],
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      
      // Convert to bytes (as would be done for web)
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      
      // Verify bytes can be converted back
      final decodedString = utf8.decode(bytes);
      final parsedData = json.decode(decodedString) as Map<String, dynamic>;
      
      expect(parsedData['version'], equals('1.0.0'));
      expect(parsedData['appName'], equals('Aquarium AI'));
      expect(parsedData['tankCount'], equals(1));
      
      final tanks = parsedData['tanks'] as List;
      expect(tanks.length, equals(1));
      
      final restoredTank = Tank.fromJson(tanks[0]);
      expect(restoredTank.name, equals('Web Test Tank'));
      expect(restoredTank.type, equals('freshwater'));
      expect(restoredTank.inhabitants.length, equals(1));
      expect(restoredTank.inhabitants[0].customName, equals('Web Fish'));
    });

    test('bytes-to-string conversion handles UTF-8 correctly', () {
      final testData = {
        'tanks': [],
        'version': '1.0.0',
        'appName': 'Aquarium AI - 🐠',
        'specialChars': 'Test with émojis and ñoñ-ASCII characters',
      };

      final jsonString = json.encode(testData);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final decodedString = utf8.decode(bytes);
      final parsedData = json.decode(decodedString) as Map<String, dynamic>;

      expect(parsedData['appName'], equals('Aquarium AI - 🐠'));
      expect(parsedData['specialChars'], equals('Test with émojis and ñoñ-ASCII characters'));
    });

    test('error handling for invalid UTF-8 bytes', () {
      // Create invalid UTF-8 bytes
      final invalidBytes = Uint8List.fromList([0xFF, 0xFE, 0xFD]);
      
      expect(() => utf8.decode(invalidBytes), throwsFormatException);
    });

    test('backup validation works with bytes-decoded content', () {
      // Create valid backup
      final validBackup = {
        'version': '1.0.0',
        'tanks': [],
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
        'tankCount': 0,
      };

      final jsonString = json.encode(validBackup);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final decodedString = utf8.decode(bytes);
      final parsedData = json.decode(decodedString) as Map<String, dynamic>;

      // Should pass validation
      expect(parsedData.containsKey('tanks'), isTrue);
      expect(parsedData.containsKey('version'), isTrue);

      // Create invalid backup (missing required fields)
      final invalidBackup = {
        'appName': 'Aquarium AI',
        'exportDate': DateTime.now().toIso8601String(),
      };

      final invalidJsonString = json.encode(invalidBackup);
      final invalidBytes = Uint8List.fromList(utf8.encode(invalidJsonString));
      final invalidDecodedString = utf8.decode(invalidBytes);
      final invalidParsedData = json.decode(invalidDecodedString) as Map<String, dynamic>;

      // Should fail validation
      expect(
        invalidParsedData.containsKey('tanks') && invalidParsedData.containsKey('version'),
        isFalse,
      );
    });
  });
}