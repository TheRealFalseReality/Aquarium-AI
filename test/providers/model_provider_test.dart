import 'package:fish_ai/providers/model_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ModelNotifier — Free AI toggle provider fallback', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    /// Helper that reads the current [ModelState] from a fresh [ProviderContainer]
    /// after waiting for [_loadModels] to complete.
    Future<ModelState> loadState(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Poll until loading is done.
      for (var i = 0; i < 50; i++) {
        if (!container.read(modelProvider).isLoading) break;
        await Future.delayed(const Duration(milliseconds: 20));
      }
      return container.read(modelProvider);
    }

    // ── setDevGroqKeyToggles ─────────────────────────────────────────────────

    test('turning Free AI OFF with Gemini key saved → provider switches to Gemini', () async {
      // Start: Free AI ON, Gemini key saved (user was on Free AI after setting up Gemini)
      SharedPreferences.setMockInitialValues({
        'geminiApiKey': 'my-gemini-key',
        'useDevGroqKeyForText': true,
        'useDevGroqKeyForImage': true,
        'activeTextProvider': AIProvider.groq.index,
        'activeImageProvider': AIProvider.groq.index,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for initial load.
      for (var i = 0; i < 50; i++) {
        if (!container.read(modelProvider).isLoading) break;
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Toggle Free AI OFF.
      await container.read(modelProvider.notifier).setDevGroqKeyToggles(
        forText: false,
        forImage: false,
      );

      final state = container.read(modelProvider);
      expect(state.activeTextProvider, AIProvider.gemini,
          reason: 'Should switch to Gemini because a Gemini key is saved');
      expect(state.activeImageProvider, AIProvider.gemini,
          reason: 'Should switch to Gemini because a Gemini key is saved');
      expect(state.useDevGroqKeyForText, isFalse);
      expect(state.useDevGroqKeyForImage, isFalse);
    });

    test('turning Free AI OFF with only OpenAI key saved → provider switches to OpenAI', () async {
      SharedPreferences.setMockInitialValues({
        'openAIApiKey': 'my-openai-key',
        'useDevGroqKeyForText': true,
        'useDevGroqKeyForImage': true,
        'activeTextProvider': AIProvider.groq.index,
        'activeImageProvider': AIProvider.groq.index,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (var i = 0; i < 50; i++) {
        if (!container.read(modelProvider).isLoading) break;
        await Future.delayed(const Duration(milliseconds: 20));
      }

      await container.read(modelProvider.notifier).setDevGroqKeyToggles(
        forText: false,
        forImage: false,
      );

      final state = container.read(modelProvider);
      expect(state.activeTextProvider, AIProvider.openAI,
          reason: 'Should switch to OpenAI because an OpenAI key is saved');
      expect(state.activeImageProvider, AIProvider.openAI,
          reason: 'Should switch to OpenAI because an OpenAI key is saved');
    });

    test('turning Free AI OFF with only Groq key saved → provider stays on Groq', () async {
      SharedPreferences.setMockInitialValues({
        'groqApiKey': 'my-groq-key',
        'useDevGroqKeyForText': true,
        'useDevGroqKeyForImage': true,
        'activeTextProvider': AIProvider.groq.index,
        'activeImageProvider': AIProvider.groq.index,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (var i = 0; i < 50; i++) {
        if (!container.read(modelProvider).isLoading) break;
        await Future.delayed(const Duration(milliseconds: 20));
      }

      await container.read(modelProvider.notifier).setDevGroqKeyToggles(
        forText: false,
        forImage: false,
      );

      final state = container.read(modelProvider);
      expect(state.activeTextProvider, AIProvider.groq,
          reason: 'Should stay on Groq because only a Groq key is saved');
    });

    test('turning Free AI OFF with no keys saved → provider falls back to default', () async {
      SharedPreferences.setMockInitialValues({
        'useDevGroqKeyForText': true,
        'useDevGroqKeyForImage': true,
        'activeTextProvider': AIProvider.groq.index,
        'activeImageProvider': AIProvider.groq.index,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (var i = 0; i < 50; i++) {
        if (!container.read(modelProvider).isLoading) break;
        await Future.delayed(const Duration(milliseconds: 20));
      }

      await container.read(modelProvider.notifier).setDevGroqKeyToggles(
        forText: false,
        forImage: false,
      );

      final state = container.read(modelProvider);
      expect(state.activeTextProvider, defaultAIProvider,
          reason: 'Should fall back to defaultAIProvider when no keys are saved');
    });

    test('turning Free AI ON always sets provider to Groq', () async {
      SharedPreferences.setMockInitialValues({
        'geminiApiKey': 'my-gemini-key',
        'useDevGroqKeyForText': false,
        'useDevGroqKeyForImage': false,
        'activeTextProvider': AIProvider.gemini.index,
        'activeImageProvider': AIProvider.gemini.index,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (var i = 0; i < 50; i++) {
        if (!container.read(modelProvider).isLoading) break;
        await Future.delayed(const Duration(milliseconds: 20));
      }

      await container.read(modelProvider.notifier).setDevGroqKeyToggles(
        forText: true,
        forImage: true,
      );

      final state = container.read(modelProvider);
      expect(state.activeTextProvider, AIProvider.groq,
          reason: 'Free AI ON should always force Groq as active provider');
      expect(state.activeImageProvider, AIProvider.groq);
      expect(state.useDevGroqKeyForText, isTrue);
      expect(state.useDevGroqKeyForImage, isTrue);
    });

    // ── _loadModels backward-compat fix ──────────────────────────────────────

    test('on load: Free AI OFF, stored provider is Groq with no key, Gemini key exists → corrects to Gemini', () async {
      // This simulates the state a user would have after hitting the old bug:
      // they had Gemini selected, turned on Free AI (which saved Groq as provider),
      // then turned off Free AI (old code left provider as Groq).
      final state = await loadState({
        'geminiApiKey': 'my-gemini-key',
        'useDevGroqKeyForText': false,
        'useDevGroqKeyForImage': false,
        'activeTextProvider': AIProvider.groq.index,   // buggy stored value
        'activeImageProvider': AIProvider.groq.index,  // buggy stored value
      });

      expect(state.activeTextProvider, AIProvider.gemini,
          reason: 'On load, should auto-correct to Gemini (has key) instead of keyless Groq');
      expect(state.activeImageProvider, AIProvider.gemini);
    });

    test('on load: Free AI OFF, stored provider is Groq WITH a Groq key → keeps Groq', () async {
      final state = await loadState({
        'groqApiKey': 'my-groq-key',
        'useDevGroqKeyForText': false,
        'useDevGroqKeyForImage': false,
        'activeTextProvider': AIProvider.groq.index,
        'activeImageProvider': AIProvider.groq.index,
      });

      expect(state.activeTextProvider, AIProvider.groq,
          reason: 'Should stay on Groq when Groq key is present');
    });
  });
}
