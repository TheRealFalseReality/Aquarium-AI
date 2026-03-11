import 'package:fish_ai/models/fish.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fish Model Tests', () {
    test('Fish creation with all properties', () {
      final fish = Fish(
        name: 'Angelfish',
        commonNames: ['Angel', 'Pterophyllum'],
        imageURL: 'https://example.com/angelfish.jpg',
        compatible: ['Cory Catfish', 'Tetras'],
        notRecommended: ['Aggressive Cichlids'],
        notCompatible: ['Bettas'],
        withCaution: ['Dwarf Gouramis'],
      );

      expect(fish.name, equals('Angelfish'));
      expect(fish.commonNames, contains('Angel'));
      expect(fish.commonNames, contains('Pterophyllum'));
      expect(fish.imageURL, equals('https://example.com/angelfish.jpg'));
      expect(fish.compatible, contains('Cory Catfish'));
      expect(fish.compatible, contains('Tetras'));
      expect(fish.notRecommended, contains('Aggressive Cichlids'));
      expect(fish.notCompatible, contains('Bettas'));
      expect(fish.withCaution, contains('Dwarf Gouramis'));
    });

    test('Fish creation with minimal properties', () {
      final fish = Fish(
        name: 'Basic Fish',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );

      expect(fish.name, equals('Basic Fish'));
      expect(fish.commonNames, isEmpty);
      expect(fish.imageURL, isEmpty);
      expect(fish.compatible, isEmpty);
      expect(fish.notRecommended, isEmpty);
      expect(fish.notCompatible, isEmpty);
      expect(fish.withCaution, isEmpty);
    });

    test('Info fields default to null / empty list', () {
      final fish = Fish(
        name: 'Neon Tetra',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      expect(fish.originHabitat, isNull);
      expect(fish.careFacts, isEmpty);
      expect(fish.generalInfo, isNull);
      expect(fish.compatibilityHighlights, isEmpty);
      expect(fish.funFact, isNull);
    });

    test('Fish creation with all info fields', () {
      final fish = Fish(
        name: 'Neon Tetra',
        commonNames: ['Neon'],
        imageURL: '',
        originHabitat: 'Originates from the Amazon basin.',
        careFacts: ['Soft, acidic water preferred', 'Keep in groups of 6+'],
        generalInfo: 'A popular beginner fish.',
        compatibilityHighlights: [
          'Peaceful community fish',
          'Avoid large predators',
        ],
        funFact: 'Their bright stripe is used to communicate.',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      expect(fish.originHabitat, equals('Originates from the Amazon basin.'));
      expect(
        fish.careFacts,
        containsAll(['Soft, acidic water preferred', 'Keep in groups of 6+']),
      );
      expect(fish.generalInfo, equals('A popular beginner fish.'));
      expect(
        fish.compatibilityHighlights,
        containsAll(['Peaceful community fish', 'Avoid large predators']),
      );
      expect(
        fish.funFact,
        equals('Their bright stripe is used to communicate.'),
      );
    });

    test('reefSafe is null by default (freshwater fish)', () {
      final fish = Fish(
        name: 'Neon Tetra',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      expect(fish.reefSafe, isNull);
    });

    test('uuid is null by default', () {
      final fish = Fish(
        name: 'Neon Tetra',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      expect(fish.uuid, isNull);
    });

    test('uuid can be set', () {
      const testUuid = '12345678-1234-1234-1234-123456789abc';
      final fish = Fish(
        uuid: testUuid,
        name: 'Clownfish',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      expect(fish.uuid, equals(testUuid));
    });

    test('reefSafe can be set to Yes for safe marine fish', () {
      final fish = Fish(
        name: 'Clownfish',
        commonNames: [],
        imageURL: '',
        reefSafe: 'Yes',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      expect(fish.reefSafe, equals('Yes'));
    });

    test('reefSafe can be set to No for unsafe marine fish', () {
      final fish = Fish(
        name: 'Lionfish',
        commonNames: [],
        imageURL: '',
        reefSafe: 'No',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      expect(fish.reefSafe, equals('No'));
    });

    test('reefSafe can be set to Caution for conditionally safe fish', () {
      final fish = Fish(
        name: 'Hawkfish',
        commonNames: [],
        imageURL: '',
        reefSafe: 'Caution',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      expect(fish.reefSafe, equals('Caution'));
    });

    test('Fish.fromJson parses reefSafe field correctly', () {
      final json = {
        'name': 'Triggerfish',
        'commonNames': [],
        'imageURL': '',
        'reefSafe': 'No',
        'compatible': [],
        'notRecommended': [],
        'notCompatible': [],
        'withCaution': [],
      };
      final fish = Fish.fromJson(json);
      expect(fish.reefSafe, equals('No'));
    });

    test('Fish.fromJson parses uuid field correctly', () {
      const testUuid = '12345678-1234-1234-1234-123456789abc';
      final json = {
        'uuid': testUuid,
        'name': 'Clownfish',
        'commonNames': [],
        'imageURL': '',
        'compatible': [],
        'notRecommended': [],
        'notCompatible': [],
        'withCaution': [],
      };
      final fish = Fish.fromJson(json);
      expect(fish.uuid, equals(testUuid));
    });

    test('Fish.fromJson handles missing uuid as null (backward compat)', () {
      final json = {
        'name': 'Betta',
        'commonNames': [],
        'imageURL': '',
        'compatible': [],
        'notRecommended': [],
        'notCompatible': [],
        'withCaution': [],
      };
      final fish = Fish.fromJson(json);
      expect(fish.uuid, isNull);
    });

    test('Fish.fromJson handles missing reefSafe as null', () {
      final json = {
        'name': 'Betta',
        'commonNames': [],
        'imageURL': '',
        'compatible': [],
        'notRecommended': [],
        'notCompatible': [],
        'withCaution': [],
      };
      final fish = Fish.fromJson(json);
      expect(fish.reefSafe, isNull);
    });

    test('Fish.fromJson parses info fields', () {
      final json = {
        'name': 'Neon Tetra',
        'commonNames': ['Neon'],
        'imageURL': '',
        'originHabitat': 'Amazon basin',
        'careFacts': ['Soft water', 'Groups of 6+'],
        'generalInfo': 'A popular beginner fish.',
        'compatibilityHighlights': ['Peaceful', 'Avoid predators'],
        'funFact': 'Communicates via colour.',
        'compatible': [],
        'notRecommended': [],
        'notCompatible': [],
        'withCaution': [],
      };
      final fish = Fish.fromJson(json);
      expect(fish.originHabitat, equals('Amazon basin'));
      expect(fish.careFacts, containsAll(['Soft water', 'Groups of 6+']));
      expect(fish.generalInfo, equals('A popular beginner fish.'));
      expect(
        fish.compatibilityHighlights,
        containsAll(['Peaceful', 'Avoid predators']),
      );
      expect(fish.funFact, equals('Communicates via colour.'));
    });

    test('Fish.fromJson ignores legacy description field (backward compat)', () {
      final json = {
        'name': 'Betta',
        'commonNames': [],
        'imageURL': '',
        'description': 'Old description field that is no longer used',
        'compatible': [],
        'notRecommended': [],
        'notCompatible': [],
        'withCaution': [],
      };
      // Should parse without errors — description is simply ignored
      final fish = Fish.fromJson(json);
      expect(fish.name, equals('Betta'));
    });

    test('Fish.fromJson defaults info fields to null / empty when absent', () {
      final json = {
        'name': 'Betta',
        'commonNames': [],
        'imageURL': '',
        'compatible': [],
        'notRecommended': [],
        'notCompatible': [],
        'withCaution': [],
      };
      final fish = Fish.fromJson(json);
      expect(fish.originHabitat, isNull);
      expect(fish.careFacts, isEmpty);
      expect(fish.generalInfo, isNull);
      expect(fish.compatibilityHighlights, isEmpty);
      expect(fish.funFact, isNull);
    });

    test('Fish.toJson omits reefSafe when null', () {
      final fish = Fish(
        name: 'Betta',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      final json = fish.toJson();
      expect(json.containsKey('reefSafe'), isFalse);
    });

    test('Fish.toJson omits uuid when null', () {
      final fish = Fish(
        name: 'Betta',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      final json = fish.toJson();
      expect(json.containsKey('uuid'), isFalse);
    });

    test('Fish.toJson includes uuid when set', () {
      const testUuid = '12345678-1234-1234-1234-123456789abc';
      final fish = Fish(
        uuid: testUuid,
        name: 'Clownfish',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      final json = fish.toJson();
      expect(json.containsKey('uuid'), isTrue);
      expect(json['uuid'], equals(testUuid));
    });

    test('Fish.toJson includes reefSafe when set', () {
      final fish = Fish(
        name: 'Clownfish',
        commonNames: [],
        imageURL: '',
        reefSafe: 'Yes',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      final json = fish.toJson();
      expect(json.containsKey('reefSafe'), isTrue);
      expect(json['reefSafe'], equals('Yes'));
    });

    test('Fish.toJson omits info fields when null/empty', () {
      final fish = Fish(
        name: 'Betta',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      final json = fish.toJson();
      expect(json.containsKey('originHabitat'), isFalse);
      expect(json.containsKey('careFacts'), isFalse);
      expect(json.containsKey('generalInfo'), isFalse);
      expect(json.containsKey('compatibilityHighlights'), isFalse);
      expect(json.containsKey('funFact'), isFalse);
      expect(json.containsKey('description'), isFalse);
    });

    test('Fish.toJson includes info fields when set', () {
      final fish = Fish(
        name: 'Neon Tetra',
        commonNames: ['Neon'],
        imageURL: '',
        originHabitat: 'Amazon basin',
        careFacts: ['Soft water'],
        generalInfo: 'Popular beginner fish.',
        compatibilityHighlights: ['Peaceful'],
        funFact: 'Communicates via colour.',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      );
      final json = fish.toJson();
      expect(json['originHabitat'], equals('Amazon basin'));
      expect(json['careFacts'], equals(['Soft water']));
      expect(json['generalInfo'], equals('Popular beginner fish.'));
      expect(json['compatibilityHighlights'], equals(['Peaceful']));
      expect(json['funFact'], equals('Communicates via colour.'));
    });

    group('isStorageUrl', () {
      test('returns true for Firebase Storage download URLs', () {
        final fish = Fish(
          name: 'Clownfish',
          commonNames: [],
          imageURL:
              'https://firebasestorage.googleapis.com/v0/b/my-app.appspot.com'
              '/o/fish_images%2F1234_clownfish.jpg?alt=media&token=abc',
          compatible: [],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        );
        expect(fish.isStorageUrl, isTrue);
      });

      test('returns false for non-Storage URLs', () {
        final fish = Fish(
          name: 'Clownfish',
          commonNames: [],
          imageURL:
              'https://raw.githubusercontent.com/user/repo/main/assets/images/fish/clownfish.webp',
          compatible: [],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        );
        expect(fish.isStorageUrl, isFalse);
      });

      test('returns false for empty URL', () {
        final fish = Fish(
          name: 'Clownfish',
          commonNames: [],
          imageURL: '',
          compatible: [],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        );
        expect(fish.isStorageUrl, isFalse);
      });
    });

    group('localImagePath', () {
      test('returns empty string for Firebase Storage URLs', () {
        final fish = Fish(
          name: 'Clownfish',
          commonNames: [],
          imageURL:
              'https://firebasestorage.googleapis.com/v0/b/my-app.appspot.com'
              '/o/fish_images%2F1234_clownfish.jpg?alt=media&token=abc',
          compatible: [],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        );
        expect(fish.localImagePath, equals(''));
      });

      test('extracts local asset path from GitHub raw URL', () {
        final fish = Fish(
          name: 'Clownfish',
          commonNames: [],
          imageURL:
              'https://raw.githubusercontent.com/user/repo/main/'
              'assets/images/fish/clownfish.webp',
          compatible: [],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        );
        expect(fish.localImagePath, equals('assets/images/fish/clownfish.webp'));
      });

      test('constructs asset path from bare filename', () {
        final fish = Fish(
          name: 'Clownfish',
          commonNames: [],
          imageURL: 'clownfish.jpg',
          compatible: [],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        );
        expect(fish.localImagePath, equals('assets/images/fish/clownfish.webp'));
      });
    });
  });
}
