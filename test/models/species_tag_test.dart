import 'package:fish_ai/models/species_tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpeciesTag Model Tests', () {
    test('SpeciesTag creation with tags', () {
      final tag = SpeciesTag(
        fishType: 'Barbs',
        tags: ['Tiger Barb', 'Cherry Barb', 'Rosy Barb'],
      );

      expect(tag.fishType, equals('Barbs'));
      expect(tag.tags, hasLength(3));
      expect(tag.tags, contains('Tiger Barb'));
      expect(tag.tags, contains('Cherry Barb'));
      expect(tag.tags, contains('Rosy Barb'));
    });

    test('SpeciesTag creation with empty tags', () {
      final tag = SpeciesTag(
        fishType: 'Cichlids',
        tags: [],
      );

      expect(tag.fishType, equals('Cichlids'));
      expect(tag.tags, isEmpty);
    });

    test('SpeciesTag toJson conversion', () {
      final tag = SpeciesTag(
        fishType: 'Tetras',
        tags: ['Neon Tetra', 'Cardinal Tetra'],
      );

      final json = tag.toJson();

      expect(json['fishType'], equals('Tetras'));
      expect(json['tags'], isA<List<String>>());
      expect(json['tags'], hasLength(2));
      expect(json['tags'], contains('Neon Tetra'));
    });

    test('SpeciesTag fromJson conversion', () {
      final json = {
        'fishType': 'Guppies',
        'tags': ['Fancy Guppy', 'Endler Guppy'],
      };

      final tag = SpeciesTag.fromJson(json);

      expect(tag.fishType, equals('Guppies'));
      expect(tag.tags, hasLength(2));
      expect(tag.tags, contains('Fancy Guppy'));
      expect(tag.tags, contains('Endler Guppy'));
    });

    test('SpeciesTag fromJson with missing tags', () {
      final json = {
        'fishType': 'Angelfish',
      };

      final tag = SpeciesTag.fromJson(json);

      expect(tag.fishType, equals('Angelfish'));
      expect(tag.tags, isEmpty);
    });

    test('SpeciesTag copyWith method', () {
      final tag = SpeciesTag(
        fishType: 'Danios',
        tags: ['Zebra Danio'],
      );

      final updatedTag = tag.copyWith(
        tags: ['Zebra Danio', 'Pearl Danio'],
      );

      expect(updatedTag.fishType, equals('Danios'));
      expect(updatedTag.tags, hasLength(2));
      expect(updatedTag.tags, contains('Pearl Danio'));
    });

    test('SpeciesTag copyWith only fishType', () {
      final tag = SpeciesTag(
        fishType: 'Goldfish',
        tags: ['Common Goldfish'],
      );

      final updatedTag = tag.copyWith(
        fishType: 'Koi',
      );

      expect(updatedTag.fishType, equals('Koi'));
      expect(updatedTag.tags, contains('Common Goldfish'));
    });

    test('SpeciesTag roundtrip JSON conversion', () {
      final original = SpeciesTag(
        fishType: 'Bettas',
        tags: ['Betta splendens', 'Siamese Fighting Fish'],
      );

      final json = original.toJson();
      final restored = SpeciesTag.fromJson(json);

      expect(restored.fishType, equals(original.fishType));
      expect(restored.tags, equals(original.tags));
    });
  });
}
