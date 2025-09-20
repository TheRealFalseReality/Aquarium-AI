import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../prompts/prompt_defaults.dart';

// Define prompt identifiers
enum PromptType {
  system,
  photoAnalysis,
  automationScript,
  waterAnalysis,
  fishCompatibility,
  stockingRecommendation,
  tankStockingRecommendation,
}

// State class for prompt management
class PromptState {
  final Map<PromptType, String> customPrompts;
  final bool isLoading;

  PromptState({
    required this.customPrompts,
    this.isLoading = true,
  });

  PromptState copyWith({
    Map<PromptType, String>? customPrompts,
    bool? isLoading,
  }) {
    return PromptState(
      customPrompts: customPrompts ?? this.customPrompts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Notifier for managing prompts
class PromptNotifier extends StateNotifier<PromptState> {
  PromptNotifier()
      : super(PromptState(
          customPrompts: {},
        )) {
    _loadPrompts();
  }

  // Default prompts for reference and restoration
  static const Map<PromptType, String> _defaultPrompts = {
    PromptType.system: defaultSystemPrompt,
    PromptType.photoAnalysis: defaultPhotoAnalysisPrompt,
    PromptType.automationScript: defaultAutomationScriptPrompt,
    PromptType.waterAnalysis: defaultWaterAnalysisPrompt,
    PromptType.fishCompatibility: defaultFishCompatibilityPrompt,
    PromptType.stockingRecommendation: defaultStockingRecommendationPrompt,
    PromptType.tankStockingRecommendation: defaultTankStockingRecommendationPrompt,
  };

  Future<void> _loadPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<PromptType, String> customPrompts = {};

    for (PromptType type in PromptType.values) {
      final key = 'custom_prompt_${type.name}';
      final customPrompt = prefs.getString(key);
      if (customPrompt != null && customPrompt.isNotEmpty) {
        customPrompts[type] = customPrompt;
      }
    }

    state = PromptState(
      customPrompts: customPrompts,
      isLoading: false,
    );
  }

  Future<void> setCustomPrompt(PromptType type, String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'custom_prompt_${type.name}';
    
    if (prompt.trim().isEmpty || prompt.trim() == _defaultPrompts[type]?.trim()) {
      // Remove custom prompt if it's empty or same as default
      await prefs.remove(key);
      final newCustomPrompts = Map<PromptType, String>.from(state.customPrompts);
      newCustomPrompts.remove(type);
      state = state.copyWith(customPrompts: newCustomPrompts);
    } else {
      // Save custom prompt
      await prefs.setString(key, prompt);
      final newCustomPrompts = Map<PromptType, String>.from(state.customPrompts);
      newCustomPrompts[type] = prompt;
      state = state.copyWith(customPrompts: newCustomPrompts);
    }
  }

  Future<void> resetPromptToDefault(PromptType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'custom_prompt_${type.name}';
    await prefs.remove(key);
    
    final newCustomPrompts = Map<PromptType, String>.from(state.customPrompts);
    newCustomPrompts.remove(type);
    state = state.copyWith(customPrompts: newCustomPrompts);
  }

  Future<void> resetAllPromptsToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (PromptType type in PromptType.values) {
      final key = 'custom_prompt_${type.name}';
      await prefs.remove(key);
    }
    
    state = state.copyWith(customPrompts: {});
  }

  String getPrompt(PromptType type) {
    return state.customPrompts[type] ?? _defaultPrompts[type] ?? '';
  }

  String getDefaultPrompt(PromptType type) {
    return _defaultPrompts[type] ?? '';
  }

  bool hasCustomPrompt(PromptType type) {
    return state.customPrompts.containsKey(type);
  }

  Map<PromptType, String> getPromptTitles() {
    return {
      PromptType.system: 'System Prompt',
      PromptType.photoAnalysis: 'Photo Analysis Prompt',
      PromptType.automationScript: 'Automation Script Prompt',
      PromptType.waterAnalysis: 'Water Analysis Prompt',
      PromptType.fishCompatibility: 'Fish Compatibility Prompt',
      PromptType.stockingRecommendation: 'Stocking Recommendation Prompt',
      PromptType.tankStockingRecommendation: 'Tank Stocking Recommendation Prompt',
    };
  }
}

// Provider instance
final promptProvider = StateNotifierProvider<PromptNotifier, PromptState>(
  (ref) => PromptNotifier(),
);

// Convenience provider for checking loading state
final promptProviderLoading = Provider<bool>((ref) {
  return ref.watch(promptProvider).isLoading;
});