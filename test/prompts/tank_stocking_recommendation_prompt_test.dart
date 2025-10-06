import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/prompts/tank_stocking_recommendation_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildTankStockingRecommendationPrompt', () {
    late Tank testTank;
    late List<Fish> allFish;
    late List<Fish> existingFish;

    setUp(() {
      testTank = Tank(
        id: 'test-tank-1',
        name: 'My Test Tank',
        type: 'freshwater',
        sizeGallons: 55.0,
        sizeLiters: 208.0,
        notes: 'Community tank with peaceful fish',
        inhabitants: [
          TankInhabitant(
            id: 'inh-1',
            customName: 'Blue Beauty',
            fishUnit: 'Guppy',
            quantity: 5,
          ),
          TankInhabitant(
            id: 'inh-2',
            customName: 'Red Flame',
            fishUnit: 'Neon Tetra',
            quantity: 10,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      allFish = [
        Fish(
          name: 'Guppy',
          commonNames: ['Guppy', 'Million Fish'],
          imageURL: 'guppy.jpg',
          compatible: ['Neon Tetra', 'Platy'],
          notRecommended: [],
          notCompatible: ['Betta'],
          withCaution: [],
        ),
        Fish(
          name: 'Neon Tetra',
          commonNames: ['Neon Tetra'],
          imageURL: 'neon.jpg',
          compatible: ['Guppy', 'Platy'],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        ),
        Fish(
          name: 'Platy',
          commonNames: ['Platy'],
          imageURL: 'platy.jpg',
          compatible: ['Guppy', 'Neon Tetra'],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        ),
      ];

      existingFish = [
        allFish[0], // Guppy
        allFish[1], // Neon Tetra
      ];
    });

    test('generates prompt with basic tank information', () {
      final prompt = buildTankStockingRecommendationPrompt(
        testTank,
        allFish,
        existingFish,
        0.85,
      );

      // Verify tank information is included
      expect(prompt, contains('My Test Tank'));
      expect(prompt, contains('55 gallons'));
      expect(prompt, contains('208 liters'));
      expect(prompt, contains('freshwater'));
      expect(prompt, contains('Community tank with peaceful fish'));
      expect(prompt, contains('85.0%'));
    });

    test('generates prompt without custom names by default', () {
      final prompt = buildTankStockingRecommendationPrompt(
        testTank,
        allFish,
        existingFish,
        0.85,
      );

      // Should not include custom names section
      expect(prompt, isNot(contains('Custom Names for Current Inhabitants')));
      expect(prompt, isNot(contains('Blue Beauty')));
      expect(prompt, isNot(contains('Red Flame')));
    });

    test('generates prompt with custom names when requested', () {
      final prompt = buildTankStockingRecommendationPrompt(
        testTank,
        allFish,
        existingFish,
        0.85,
        useCustomNames: true,
      );

      // Should include custom names section
      expect(prompt, contains('Custom Names for Current Inhabitants'));
      expect(prompt, contains('Blue Beauty'));
      expect(prompt, contains('Red Flame'));
      expect(prompt, contains('Guppy: Blue Beauty'));
      expect(prompt, contains('Neon Tetra: Red Flame'));
    });

    test('generates prompt without additional notes by default', () {
      final prompt = buildTankStockingRecommendationPrompt(
        testTank,
        allFish,
        existingFish,
        0.85,
      );

      // Should not include additional notes section
      expect(prompt, isNot(contains('User Additional Notes/Preferences')));
    });

    test('generates prompt with additional notes when provided', () {
      final prompt = buildTankStockingRecommendationPrompt(
        testTank,
        allFish,
        existingFish,
        0.85,
        additionalNotes: 'Looking for colorful bottom dwellers',
      );

      // Should include additional notes section
      expect(prompt, contains('User Additional Notes/Preferences'));
      expect(prompt, contains('Looking for colorful bottom dwellers'));
    });

    test('generates prompt with both custom names and additional notes', () {
      final prompt = buildTankStockingRecommendationPrompt(
        testTank,
        allFish,
        existingFish,
        0.85,
        useCustomNames: true,
        additionalNotes: 'Need schooling fish for mid-level',
      );

      // Should include both custom names and additional notes
      expect(prompt, contains('Custom Names for Current Inhabitants'));
      expect(prompt, contains('Blue Beauty'));
      expect(prompt, contains('User Additional Notes/Preferences'));
      expect(prompt, contains('Need schooling fish for mid-level'));
    });

    test('includes critical requirements in prompt', () {
      final prompt = buildTankStockingRecommendationPrompt(
        testTank,
        allFish,
        existingFish,
        0.85,
      );

      // Verify critical requirements are present
      expect(prompt, contains('CRITICAL REQUIREMENTS'));
      expect(prompt, contains('MAINTAIN CURRENT HARMONY'));
      expect(prompt, contains('compatible with EVERY existing fish'));
      expect(prompt, contains('compatible with each other'));
    });

    test('includes fish compatibility data in prompt', () {
      final prompt = buildTankStockingRecommendationPrompt(
        testTank,
        allFish,
        existingFish,
        0.85,
      );

      // Verify fish compatibility data is included
      expect(prompt, contains('Current Fish Compatibility Data'));
      expect(prompt, contains('Available Fish Database'));
      expect(prompt, contains('"compatible"'));
    });

    test('formats tank size correctly with only gallons', () {
      final tankWithGallonsOnly = testTank.copyWith(
        sizeLiters: null,
      );

      final prompt = buildTankStockingRecommendationPrompt(
        tankWithGallonsOnly,
        allFish,
        existingFish,
        0.85,
      );

      expect(prompt, contains('55 gallons'));
      expect(prompt, isNot(contains('liters')));
    });

    test('formats tank size correctly with only liters', () {
      final tankWithLitersOnly = testTank.copyWith(
        sizeGallons: null,
      );

      final prompt = buildTankStockingRecommendationPrompt(
        tankWithLitersOnly,
        allFish,
        existingFish,
        0.85,
      );

      expect(prompt, contains('208 liters'));
      expect(prompt, isNot(contains('gallons')));
    });
  });
}
