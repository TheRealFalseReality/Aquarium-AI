import 'package:fish_ai/utils/json_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JSON Utils Tests', () {
    test('extractJson removes markdown code block wrapper', () {
      const input = '''```json
{
  "test": "value",
  "number": 42
}
```''';
      
      final result = extractJson(input);
      
      expect(result, contains('"test"'));
      expect(result, contains('"value"'));
      expect(result, isNot(contains('```json')));
      expect(result, isNot(contains('```')));
    });

    test('extractJson handles JSON with extra whitespace', () {
      const input = '''```json

{
  "test": "value"
}

```''';
      
      final result = extractJson(input);
      
      expect(result, contains('"test"'));
      expect(result, isNot(contains('```')));
    });

    test('extractJson returns raw text when no code block present', () {
      const input = '{"test": "value"}';
      
      final result = extractJson(input);
      
      expect(result, equals(input));
    });

    test('extractJson handles invalid JSON gracefully', () {
      const input = 'This is not JSON at all';
      
      final result = extractJson(input);
      
      expect(result, equals(input));
    });

    test('extractJson handles multiple code blocks (takes first)', () {
      const input = '''```json
{"first": "block"}
```
Some text
```json
{"second": "block"}
```''';
      
      final result = extractJson(input);
      
      expect(result, contains('"first"'));
      expect(result, isNot(contains('"second"')));
    });

    test('extractJson validates JSON format', () {
      // Valid JSON should be returned as is
      const validJson = '{"valid": true, "number": 123}';
      final result1 = extractJson(validJson);
      expect(result1, equals(validJson));
      
      // Invalid JSON should still be returned
      const invalidJson = '{invalid json}';
      final result2 = extractJson(invalidJson);
      expect(result2, equals(invalidJson));
    });
  });
}

