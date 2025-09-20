import 'package:fish_ai/prompts/photo_analysis_prompt.dart';
import 'package:fish_ai/prompts/automation_script_prompt.dart';
import 'package:fish_ai/prompts/water_analysis_prompt.dart';
import 'package:fish_ai/providers/prompt_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Prompt Integration Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('photo analysis prompt should use custom template when available', () async {
      final promptNotifier = container.read(promptProvider.notifier);
      
      // Wait for loading to complete
      await Future.delayed(Duration.zero);
      
      const customTemplate = '''
      You are a CUSTOM aquarium expert. User context: {userNote}
      Analyze this photo with custom instructions.
      ''';
      
      // Set custom photo analysis prompt
      await promptNotifier.setCustomPrompt(PromptType.photoAnalysis, customTemplate);
      
      // Build prompt with user note
      const userNote = 'My fish looks sick';
      final builtPrompt = buildPhotoAnalysisPrompt(userNote, container);
      
      expect(builtPrompt, contains('CUSTOM aquarium expert'));
      expect(builtPrompt, contains(userNote));
      expect(builtPrompt, contains('My fish looks sick'));
    });

    test('automation script prompt should use custom template when available', () async {
      final promptNotifier = container.read(promptProvider.notifier);
      
      // Wait for loading to complete
      await Future.delayed(Duration.zero);
      
      const customTemplate = '''
      CUSTOM automation expert for {description}.
      Create a YAML configuration.
      ''';
      
      // Set custom automation script prompt
      await promptNotifier.setCustomPrompt(PromptType.automationScript, customTemplate);
      
      // Build prompt with description
      const description = 'Turn on lights at sunrise';
      final builtPrompt = buildAutomationScriptPrompt(description, container);
      
      expect(builtPrompt, contains('CUSTOM automation expert'));
      expect(builtPrompt, contains(description));
      expect(builtPrompt, contains('Turn on lights at sunrise'));
    });

    test('water analysis prompt should use custom template when available', () async {
      final promptNotifier = container.read(promptProvider.notifier);
      
      // Wait for loading to complete
      await Future.delayed(Duration.zero);
      
      const customTemplate = '''
      CUSTOM water analysis for {tankType} tank.
      Temperature: {temp}°{tempUnit}
      {ph_line}
      {salinity_line}
      {additionalInfo_line}
      ''';
      
      // Set custom water analysis prompt
      await promptNotifier.setCustomPrompt(PromptType.waterAnalysis, customTemplate);
      
      // Build prompt with parameters
      final builtPrompt = buildWaterAnalysisPrompt(
        tankType: 'Saltwater',
        ph: '8.2',
        temp: '78',
        salinity: '1.025',
        additionalInfo: 'Algae growth',
        tempUnit: 'F',
        salinityUnit: 'SG',
        ref: container,
      );
      
      expect(builtPrompt, contains('CUSTOM water analysis'));
      expect(builtPrompt, contains('Saltwater tank'));
      expect(builtPrompt, contains('78°F'));
      expect(builtPrompt, contains('pH: 8.2'));
      expect(builtPrompt, contains('1.025 Specific Gravity'));
      expect(builtPrompt, contains('Algae growth'));
    });

    test('should fall back to default prompt when custom is not set', () async {
      // Don't set any custom prompts
      await Future.delayed(Duration.zero);
      
      const userNote = 'Test note';
      final builtPrompt = buildPhotoAnalysisPrompt(userNote, container);
      
      // Should contain default content
      expect(builtPrompt, contains('Aquarium AI — aquarium & fish identification assistant'));
      expect(builtPrompt, contains(userNote));
    });
  });
}