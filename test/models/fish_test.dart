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
  });
}