import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fish_ai/providers/prompt_provider.dart';

void main() {
  group('PromptProvider Tests', () {
    late ProviderContainer container;

    setUp(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should return default prompt when no custom prompt is set', () async {
      final promptNotifier = container.read(promptProvider.notifier);
      
      // Wait for loading to complete
      await Future.delayed(Duration.zero);
      
      final systemPrompt = promptNotifier.getPrompt(PromptType.system);
      final defaultPrompt = promptNotifier.getDefaultPrompt(PromptType.system);
      
      expect(systemPrompt, equals(defaultPrompt));
      expect(promptNotifier.hasCustomPrompt(PromptType.system), isFalse);
    });

    test('should store and retrieve custom prompt', () async {
      final promptNotifier = container.read(promptProvider.notifier);
      
      // Wait for loading to complete
      await Future.delayed(Duration.zero);
      
      const customPrompt = 'This is a custom system prompt for testing.';
      
      // Set custom prompt
      await promptNotifier.setCustomPrompt(PromptType.system, customPrompt);
      
      // Verify custom prompt is returned
      expect(promptNotifier.getPrompt(PromptType.system), equals(customPrompt));
      expect(promptNotifier.hasCustomPrompt(PromptType.system), isTrue);
    });

    test('should reset prompt to default', () async {
      final promptNotifier = container.read(promptProvider.notifier);
      
      // Wait for loading to complete
      await Future.delayed(Duration.zero);
      
      const customPrompt = 'This is a custom system prompt for testing.';
      final defaultPrompt = promptNotifier.getDefaultPrompt(PromptType.system);
      
      // Set custom prompt
      await promptNotifier.setCustomPrompt(PromptType.system, customPrompt);
      expect(promptNotifier.hasCustomPrompt(PromptType.system), isTrue);
      
      // Reset to default
      await promptNotifier.resetPromptToDefault(PromptType.system);
      
      // Verify default prompt is returned
      expect(promptNotifier.getPrompt(PromptType.system), equals(defaultPrompt));
      expect(promptNotifier.hasCustomPrompt(PromptType.system), isFalse);
    });

    test('should reset all prompts to defaults', () async {
      final promptNotifier = container.read(promptProvider.notifier);
      
      // Wait for loading to complete
      await Future.delayed(Duration.zero);
      
      // Set custom prompts for multiple types
      await promptNotifier.setCustomPrompt(PromptType.system, 'Custom system');
      await promptNotifier.setCustomPrompt(PromptType.photoAnalysis, 'Custom photo');
      
      expect(promptNotifier.hasCustomPrompt(PromptType.system), isTrue);
      expect(promptNotifier.hasCustomPrompt(PromptType.photoAnalysis), isTrue);
      
      // Reset all
      await promptNotifier.resetAllPromptsToDefaults();
      
      // Verify all are reset
      expect(promptNotifier.hasCustomPrompt(PromptType.system), isFalse);
      expect(promptNotifier.hasCustomPrompt(PromptType.photoAnalysis), isFalse);
    });

    test('should provide correct prompt titles', () {
      final promptNotifier = container.read(promptProvider.notifier);
      final titles = promptNotifier.getPromptTitles();
      
      expect(titles[PromptType.system], equals('System Prompt'));
      expect(titles[PromptType.photoAnalysis], equals('Photo Analysis Prompt'));
      expect(titles[PromptType.automationScript], equals('Automation Script Prompt'));
      expect(titles[PromptType.waterAnalysis], equals('Water Analysis Prompt'));
      expect(titles[PromptType.fishCompatibility], equals('Fish Compatibility Prompt'));
      expect(titles[PromptType.stockingRecommendation], equals('Stocking Recommendation Prompt'));
      expect(titles[PromptType.tankStockingRecommendation], equals('Tank Stocking Recommendation Prompt'));
    });
  });
}