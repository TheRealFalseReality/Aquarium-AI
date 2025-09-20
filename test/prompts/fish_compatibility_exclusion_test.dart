import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/prompts/fish_compatibility_prompt.dart';
import 'package:fish_ai/models/fish.dart';

void main() {
  group('Fish Compatibility Database Exclusion Tests', () {
    late List<Fish> sampleDatabaseFish;

    setUp(() {
      // Create sample fish database similar to actual data
      sampleDatabaseFish = [
        Fish(
          name: "Angelfish (Female) ♀",
          commonNames: ["Freshwater Angelfish", "Pterophyllum scalare"],
          imageURL: "test",
          compatible: ["Cory Cats", "Plecos / Catfish"],
          notRecommended: ["Barbs", "Bettas (Male) ♂"],
          notCompatible: ["Cichlids - Lake Malawian/Victoria"],
          withCaution: ["Discus"]
        ),
        Fish(
          name: "Cory Cats",
          commonNames: ["Corydoras", "Cory Catfish"],
          imageURL: "test",
          compatible: ["Angelfish (Female) ♀", "Plecos / Catfish"],
          notRecommended: [],
          notCompatible: [],
          withCaution: []
        ),
        Fish(
          name: "Plecos / Catfish",
          commonNames: ["Pleco", "Suckerfish"],
          imageURL: "test",
          compatible: ["Angelfish (Female) ♀", "Cory Cats"],
          notRecommended: [],
          notCompatible: [],
          withCaution: []
        ),
      ];
    });

    test('prompt should explicitly exclude database fish names', () {
      // Act
      final prompt = buildFishCompatibilityPrompt(
        "freshwater",
        ["Angelfish (Female) ♀"],
        0.8,
        sampleDatabaseFish
      );

      // Assert - Check that database exclusion is mentioned
      expect(prompt, contains("do NOT include these in compatibleFish"));
      expect(prompt, contains("not from the provided database"));
      
      // Check that database fish information is included for AI reference
      expect(prompt, contains("Angelfish (Female) ♀"));
      expect(prompt, contains("Cory Cats"));
      expect(prompt, contains("Plecos / Catfish"));
      
      // Verify the prompt structure is correct
      expect(prompt, contains("Available Fish Database"));
      expect(prompt, contains("compatibleFish"));
    });

    test('prompt should include fish compatibility data for context', () {
      // Act
      final prompt = buildFishCompatibilityPrompt(
        "freshwater",
        ["Angelfish (Female) ♀", "Cory Cats"],
        0.9,
        sampleDatabaseFish
      );

      // Assert - Check that compatibility data is included
      expect(prompt, contains('"compatible"'));
      expect(prompt, contains("Plecos / Catfish")); // Should be in compatible list
      
      // Check that the instruction is clear about excluding database fish
      expect(prompt, contains("List of other common fish names ONLY (not from the provided database)"));
    });

    test('prompt should work with empty database', () {
      // Act
      final prompt = buildFishCompatibilityPrompt(
        "marine",
        ["Test Fish"],
        0.5,
        []
      );

      // Assert - Should still include exclusion instruction even with empty database
      expect(prompt, contains("do NOT include these in compatibleFish"));
      expect(prompt, contains("Available Fish Database"));
      expect(prompt, contains("[]")); // Empty JSON array
    });

    test('prompt should include all required fields', () {
      // Act
      final prompt = buildFishCompatibilityPrompt(
        "freshwater",
        ["Angelfish (Female) ♀"],
        0.75,
        sampleDatabaseFish
      );

      // Assert - Check all required response fields are mentioned
      final requiredFields = [
        'harmonyLabel',
        'harmonySummary', 
        'detailedSummary',
        'tankSize',
        'decorations',
        'careGuide',
        'tankMatesSummary',
        'compatibleFish'
      ];

      for (final field in requiredFields) {
        expect(prompt, contains('"$field"'), reason: 'Field $field should be in prompt');
      }
    });
  });
}