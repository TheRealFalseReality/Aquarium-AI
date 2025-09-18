import 'package:fish_ai/models/tank.dart';
import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/providers/aquarium_stocking_provider.dart';
import 'package:fish_ai/prompts/tank_stocking_recommendation_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tank Stocking Recommendations Tests', () {
    test('Tank stocking prompt includes existing fish', () {
      final tank = Tank.create(
        name: 'Test Tank',
        type: 'freshwater',
        sizeGallons: 55.0,
        inhabitants: [
          TankInhabitant(
            id: 'id1',
            customName: 'My Angel',
            fishUnit: 'Angelfish',
            quantity: 2,
          ),
        ],
      );

      final allFish = [
        Fish(
          name: 'Angelfish',
          commonNames: [],
          imageURL: '',
          compatible: ['Cory Cats', 'Neon Tetra'],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        ),
        Fish(
          name: 'Cory Cats',
          commonNames: [],
          imageURL: '',
          compatible: ['Angelfish'],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        ),
      ];

      final existingFish = [
        Fish(
          name: 'Angelfish',
          commonNames: [],
          imageURL: '',
          compatible: ['Cory Cats', 'Neon Tetra'],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        ),
      ];

      final prompt = buildTankStockingRecommendationPrompt(tank, allFish, existingFish);

      expect(prompt.contains('Test Tank'), isTrue);
      expect(prompt.contains('Angelfish'), isTrue);
      expect(prompt.contains('55'), isTrue);
      expect(prompt.contains('freshwater'), isTrue);
      expect(prompt.contains('additional fish to ADD'), isTrue);
    });

    test('Tank formatting for different size units', () {
      final tankGallons = Tank.create(
        name: 'Gallon Tank',
        type: 'freshwater',
        sizeGallons: 75.0,
      );

      final tankLiters = Tank.create(
        name: 'Liter Tank',
        type: 'marine',
        sizeLiters: 200.0,
      );

      final tankBoth = Tank.create(
        name: 'Both Units Tank',
        type: 'freshwater',
        sizeGallons: 55.0,
        sizeLiters: 208.2,
      );

      final tankNone = Tank.create(
        name: 'No Size Tank',
        type: 'freshwater',
      );

      final allFish = <Fish>[];
      final existingFish = <Fish>[];

      final promptGallons = buildTankStockingRecommendationPrompt(tankGallons, allFish, existingFish);
      final promptLiters = buildTankStockingRecommendationPrompt(tankLiters, allFish, existingFish);
      final promptBoth = buildTankStockingRecommendationPrompt(tankBoth, allFish, existingFish);
      final promptNone = buildTankStockingRecommendationPrompt(tankNone, allFish, existingFish);

      expect(promptGallons.contains('75 gallons'), isTrue);
      expect(promptLiters.contains('200 liters'), isTrue);
      expect(promptBoth.contains('55 gallons (208 liters)'), isTrue);
      expect(promptNone.contains('Size not specified'), isTrue);
    });

    test('Empty tank inhabitants handling', () {
      final emptyTank = Tank.create(
        name: 'Empty Tank',
        type: 'freshwater',
      );

      expect(emptyTank.inhabitants.isEmpty, isTrue);
    });

    test('StockingRecommendation with tank-specific fields', () {
      final recommendation = StockingRecommendation(
        title: 'Test Recommendation',
        summary: 'Test summary',
        coreFish: [],
        otherDataBasedFish: [],
        aiTankMatesSummary: 'Test AI summary',
        aiRecommendedTankMates: ['Tetra', 'Catfish'],
        harmonyScore: 0.95,
        compatibilityNotes: 'These fish work well with existing inhabitants',
        isAdditionRecommendation: true,
      );

      expect(recommendation.isAdditionRecommendation, isTrue);
      expect(recommendation.compatibilityNotes, isNotNull);
      expect(recommendation.compatibilityNotes, contains('existing inhabitants'));
    });
  });
}