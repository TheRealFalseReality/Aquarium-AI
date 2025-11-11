import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/utils/groq_helper.dart';
import 'package:groq/groq.dart';

void main() {
  group('GroqHelper', () {
    test('should create Groq client with required parameters', () {
      // Note: This will fail in actual use without valid credentials
      // but tests the instantiation logic
      expect(
        () => GroqHelper.createClient(
          apiKey: 'test-key',
          model: 'llama3-8b-8192',
        ),
        returnsNormally,
      );
    });

    test('should create Groq client with system prompt', () {
      expect(
        () => GroqHelper.createClient(
          apiKey: 'test-key',
          model: 'llama3-8b-8192',
          systemPrompt: 'You are a helpful assistant',
        ),
        returnsNormally,
      );
    });

    test('should return Groq instance', () {
      final groq = GroqHelper.createClient(
        apiKey: 'test-key',
        model: 'llama3-8b-8192',
      );
      
      expect(groq, isA<Groq>());
    });
  });
}
