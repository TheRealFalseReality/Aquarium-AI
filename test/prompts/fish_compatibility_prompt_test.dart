import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/prompts/fish_compatibility_prompt.dart';
import 'package:fish_ai/models/fish.dart';

void main() {
  group('Fish Compatibility Prompt Tests', () {
    test('should include database fish information in prompt', () {
      // Arrange
      final testFish = [
        Fish(
          name: "Neon Tetra", 
          commonNames: ["Neon"], 
          imageURL: "test", 
          compatible: ["Guppy"], 
          notRecommended: [], 
          notCompatible: [], 
          withCaution: []
        ),
        Fish(
          name: "Guppy", 
          commonNames: ["Guppy Fish"], 
          imageURL: "test", 
          compatible: ["Neon Tetra"], 
          notRecommended: [], 
          notCompatible: [], 
          withCaution: []
        ),
      ];
      
      // Act
      final prompt = buildFishCompatibilityPrompt(
        "freshwater", 
        ["Neon Tetra"], 
        0.85, 
        testFish
      );
      
      // Assert
      expect(prompt, contains("Available Fish Database"));
      expect(prompt, contains("do NOT include these in compatibleFish"));
      expect(prompt, contains("Neon Tetra"));
      expect(prompt, contains("Guppy"));
      expect(prompt, contains("not from the provided database"));
    });

    test('should include harmony score in prompt', () {
      // Arrange
      final testFish = <Fish>[];
      
      // Act
      final prompt = buildFishCompatibilityPrompt(
        "marine", 
        ["Test Fish"], 
        0.75, 
        testFish
      );
      
      // Assert
      expect(prompt, contains("Group Harmony Score: 75%"));
      expect(prompt, contains("Test Fish"));
      expect(prompt, contains("marine"));
    });

    test('should handle empty fish database', () {
      // Arrange
      final emptyFishList = <Fish>[];
      
      // Act
      final prompt = buildFishCompatibilityPrompt(
        "freshwater", 
        ["Single Fish"], 
        1.0, 
        emptyFishList
      );
      
      // Assert
      expect(prompt, contains("Available Fish Database"));
      expect(prompt, contains("[]")); // Empty JSON array
      expect(prompt, contains("Group Harmony Score: 100%"));
    });
  });
}