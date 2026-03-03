import 'package:fish_ai/utils/ai_language_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAiLanguage', () {
    test('returns null for empty-string aiResponseLanguage (no instruction)', () {
      expect(
        resolveAiLanguage(aiResponseLanguage: '', localeCode: 'de'),
        isNull,
      );
    });

    test('returns explicit language when set', () {
      expect(
        resolveAiLanguage(aiResponseLanguage: 'Portuguese', localeCode: 'en'),
        equals('Portuguese'),
      );
    });

    test('follows app locale when aiResponseLanguage is null and locale is de', () {
      expect(
        resolveAiLanguage(aiResponseLanguage: null, localeCode: 'de'),
        equals('German'),
      );
    });

    test('follows app locale when aiResponseLanguage is null and locale is es', () {
      expect(
        resolveAiLanguage(aiResponseLanguage: null, localeCode: 'es'),
        equals('Spanish'),
      );
    });

    test('follows app locale when aiResponseLanguage is null and locale is fr', () {
      expect(
        resolveAiLanguage(aiResponseLanguage: null, localeCode: 'fr'),
        equals('French'),
      );
    });

    test('returns null when aiResponseLanguage is null and locale is en', () {
      expect(
        resolveAiLanguage(aiResponseLanguage: null, localeCode: 'en'),
        isNull,
      );
    });

    test('returns null for unknown locale when aiResponseLanguage is null', () {
      expect(
        resolveAiLanguage(aiResponseLanguage: null, localeCode: 'ja'),
        isNull,
      );
    });
  });

  group('appendLanguageInstruction', () {
    test('appends instruction for non-English locale', () {
      final result = appendLanguageInstruction(
        'System prompt.',
        aiResponseLanguage: null,
        localeCode: 'de',
      );
      expect(result, contains('IMPORTANT: Always respond in German.'));
    });

    test('does not append instruction when aiResponseLanguage is empty string', () {
      final result = appendLanguageInstruction(
        'System prompt.',
        aiResponseLanguage: '',
        localeCode: 'de',
      );
      expect(result, equals('System prompt.'));
    });

    test('does not append instruction for English locale', () {
      final result = appendLanguageInstruction(
        'System prompt.',
        aiResponseLanguage: null,
        localeCode: 'en',
      );
      expect(result, equals('System prompt.'));
    });

    test('appends custom language when explicitly set', () {
      final result = appendLanguageInstruction(
        'System prompt.',
        aiResponseLanguage: 'Japanese',
        localeCode: 'en',
      );
      expect(result, contains('IMPORTANT: Always respond in Japanese.'));
    });
  });
}
