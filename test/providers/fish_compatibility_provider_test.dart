import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/providers/fish_compatibility_provider.dart';

void main() {
  group('Fish Compatibility Provider Helper Functions', () {
    test('parseCompatibleFish handles array of objects with name properties', () {
      // Test the expected format from the AI
      final input = [
        {'name': 'Guppy'},
        {'name': 'Neon Tetra'},
        {'name': 'Corydoras'}
      ];
      
      final result = parseCompatibleFish(input);
      
      expect(result, equals(['Guppy', 'Neon Tetra', 'Corydoras']));
    });

    test('parseCompatibleFish handles array of strings', () {
      // Test when AI returns direct string array
      final input = ['Guppy', 'Neon Tetra', 'Corydoras'];
      
      final result = parseCompatibleFish(input);
      
      expect(result, equals(['Guppy', 'Neon Tetra', 'Corydoras']));
    });

    test('parseCompatibleFish handles single string with comma separation', () {
      // Test when AI returns a single string with comma-separated values
      final input = 'Guppy, Neon Tetra, Corydoras';
      
      final result = parseCompatibleFish(input);
      
      expect(result, equals(['Guppy', 'Neon Tetra', 'Corydoras']));
    });

    test('parseCompatibleFish handles single string without commas', () {
      // Test when AI returns a single fish name
      final input = 'Guppy';
      
      final result = parseCompatibleFish(input);
      
      expect(result, equals(['Guppy']));
    });

    test('parseCompatibleFish handles null input', () {
      // Test null safety
      final result = parseCompatibleFish(null);
      
      expect(result, equals([]));
    });

    test('parseCompatibleFish handles mixed array with fallback', () {
      // Test when AI returns mixed types (should convert to string)
      final input = [
        {'name': 'Guppy'},
        'Neon Tetra',
        123, // Should convert to string
      ];
      
      final result = parseCompatibleFish(input);
      
      expect(result, equals(['Guppy', 'Neon Tetra', '123']));
    });

    test('parseCompatibleFish handles empty array', () {
      // Test empty array
      final result = parseCompatibleFish([]);
      
      expect(result, equals([]));
    });
  });
}