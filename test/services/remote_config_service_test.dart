import 'package:fish_ai/constants.dart';
import 'package:fish_ai/services/remote_config_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteConfigService', () {
    group('defaults (no Firebase instance)', () {
      // Before any initialize() call the _instance is null, so all getters
      // must return the in-app fallback defaults.

      test('freeAiEnabled defaults to true', () {
        expect(RemoteConfigService.freeAiEnabled, isTrue);
      });

      test('maxRequestsPerMinute defaults to 4', () {
        expect(RemoteConfigService.maxRequestsPerMinute, equals(4));
      });

      test('maxRequestsPerDay defaults to 50', () {
        expect(RemoteConfigService.maxRequestsPerDay, equals(50));
      });

      test('maxPhotoAnalysesPerDay defaults to 3', () {
        expect(RemoteConfigService.maxPhotoAnalysesPerDay, equals(3));
      });

      test('freeTierChatHistoryLimit defaults to 3', () {
        expect(RemoteConfigService.freeTierChatHistoryLimit, equals(3));
      });

      test('defaultGeminiModel defaults to gemini-flash-latest', () {
        expect(RemoteConfigService.defaultGeminiModel, equals('gemini-flash-latest'));
      });

      test('defaultGeminiImageModel defaults to gemini-flash-latest', () {
        expect(RemoteConfigService.defaultGeminiImageModel, equals('gemini-flash-latest'));
      });

      test('defaultOpenAIModel defaults to gpt-4o', () {
        expect(RemoteConfigService.defaultOpenAIModel, equals('gpt-4o'));
      });

      test('defaultOpenAIImageModel defaults to gpt-4-vision-preview', () {
        expect(RemoteConfigService.defaultOpenAIImageModel, equals('gpt-4-vision-preview'));
      });

      test('defaultGroqModel defaults to llama-3.3-70b-versatile', () {
        expect(RemoteConfigService.defaultGroqModel, equals('llama-3.3-70b-versatile'));
      });

      test('defaultGroqImageModel defaults to llama-4-scout model', () {
        expect(
          RemoteConfigService.defaultGroqImageModel,
          equals('meta-llama/llama-4-scout-17b-16e-instruct'),
        );
      });

      test('founderDefaultGroqModel defaults to llama-3.3-70b-versatile', () {
        expect(
          RemoteConfigService.founderDefaultGroqModel,
          equals('llama-3.3-70b-versatile'),
        );
      });

      test('freeDefaultGroqModel defaults to llama-3.1-8b-instant', () {
        expect(
          RemoteConfigService.freeDefaultGroqModel,
          equals('llama-3.1-8b-instant'),
        );
      });

      test('aquapiOriginalImageUrl defaults to empty string (use local asset)', () {
        expect(RemoteConfigService.aquapiOriginalImageUrl, equals(''));
      });

      test('aquapiEssentialImageUrl defaults to empty string (use local asset)', () {
        expect(RemoteConfigService.aquapiEssentialImageUrl, equals(''));
      });

      test('fishcompatJson defaults to empty string (use local asset)', () {
        expect(RemoteConfigService.fishcompatJson, equals(''));
      });

      test('buyMeACoffeeUrl defaults to expected URL', () {
        expect(
          RemoteConfigService.buyMeACoffeeUrl,
          equals('https://buymeacoffee.com/capitalcityaquatics'),
        );
      });

      test('changelogEn defaults to empty string (use local asset)', () {
        expect(RemoteConfigService.changelogEn, equals(''));
      });
    });

    group('RemoteConfigKeys', () {
      test('key names match expected Remote Config parameter names', () {
        expect(RemoteConfigKeys.freeAiEnabled, equals('free_ai_enabled'));
        expect(RemoteConfigKeys.devMaxRequestsPerMinute,
            equals('dev_max_requests_per_minute'));
        expect(RemoteConfigKeys.devMaxRequestsPerDay,
            equals('dev_max_requests_per_day'));
        expect(RemoteConfigKeys.devMaxPhotoAnalysesPerDay,
            equals('dev_max_photo_analyses_per_day'));
        expect(RemoteConfigKeys.devDefaultChatHistoryLimit,
            equals('dev_default_chat_history_limit'));
        expect(RemoteConfigKeys.defaultGeminiModel,
            equals('default_gemini_model'));
        expect(RemoteConfigKeys.defaultGeminiImageModel,
            equals('default_gemini_image_model'));
        expect(RemoteConfigKeys.defaultOpenAIModel,
            equals('default_openai_model'));
        expect(RemoteConfigKeys.defaultOpenAIImageModel,
            equals('default_openai_image_model'));
        expect(RemoteConfigKeys.defaultGroqModel,
            equals('default_groq_model'));
        expect(RemoteConfigKeys.defaultGroqImageModel,
            equals('default_groq_image_model'));
        expect(RemoteConfigKeys.founderDefaultGroqModel,
            equals('founder_default_groq_model'));
        expect(RemoteConfigKeys.freeDefaultGroqModel,
            equals('free_default_groq_model'));
        expect(RemoteConfigKeys.aquapiOriginalImageUrl,
            equals('aquapi_original_image_url'));
        expect(RemoteConfigKeys.aquapiEssentialImageUrl,
            equals('aquapi_essential_image_url'));
        expect(RemoteConfigKeys.fishcompatJson,
            equals('fishcompat_json'));
        expect(RemoteConfigKeys.buyMeACoffeeUrl,
            equals('buy_me_a_coffee_url'));
        expect(RemoteConfigKeys.changelogEn,
            equals('changelogEn'));
      });
    });
  });
}
