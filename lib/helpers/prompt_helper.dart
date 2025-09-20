import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prompt_provider.dart';
import '../prompts/system_prompt.dart';
import '../prompts/photo_analysis_prompt.dart';
import '../prompts/automation_script_prompt.dart';
import '../prompts/water_analysis_prompt.dart';
import '../prompts/fish_compatibility_prompt.dart';
import '../prompts/stocking_recommendation_prompt.dart';
import '../prompts/tank_stocking_recommendation_prompt.dart';

class PromptHelper {
  // Helper to get the system prompt
  static String getSystemPromptText(WidgetRef ref) {
    return ref.read(promptProvider.notifier).getPrompt(PromptType.system);
  }

  // Helper to build photo analysis prompt with custom template
  static String buildPhotoAnalysisPromptText(String userNote, WidgetRef ref) {
    return buildPhotoAnalysisPrompt(userNote, ref);
  }

  // Helper to build automation script prompt with custom template
  static String buildAutomationScriptPromptText(String description, WidgetRef ref) {
    return buildAutomationScriptPrompt(description, ref);
  }

  // Helper to build water analysis prompt with custom template
  static String buildWaterAnalysisPromptText({
    required String tankType,
    required String ph,
    required String temp,
    required String salinity,
    required String additionalInfo,
    required String tempUnit,
    required String salinityUnit,
    required WidgetRef ref,
  }) {
    return buildWaterAnalysisPrompt(
      tankType: tankType,
      ph: ph,
      temp: temp,
      salinity: salinity,
      additionalInfo: additionalInfo,
      tempUnit: tempUnit,
      salinityUnit: salinityUnit,
      ref: ref,
    );
  }
}