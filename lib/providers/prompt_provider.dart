import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../prompts/system_prompt.dart';
import '../prompts/photo_analysis_prompt.dart';
import '../prompts/automation_script_prompt.dart';
import '../prompts/water_analysis_prompt.dart';
import '../prompts/fish_compatibility_prompt.dart';
import '../prompts/stocking_recommendation_prompt.dart';
import '../prompts/tank_stocking_recommendation_prompt.dart';

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
    PromptType.system: systemPrompt,
    PromptType.photoAnalysis: '''
    You are Aquarium AI — aquarium & fish identification assistant.

    TASKS:
    1. Identify fish species (best guess if uncertain) with confidence 0–1.
    2. Provide a concise summary (Markdown allowed; use **bold** sparingly).
    3. Tank health observations (algae, plants, substrate, clarity, stocking, stress).
    4. Potential issues & recommended actions.
    5. Visual-only water heuristics (clarity, algaeLevel, stockingAssessment). DO NOT invent numeric parameters.
    6. "howAquaPiHelps" explaining AquaPi benefits; end with [Shop AquaPi](https://www.capitalcityaquatics.com/store).

    Return ONLY JSON:
    {
      "summary": "...",
      "identifiedFish": [
        { "commonName": "...", "scientificName": "...", "confidence": 0.0, "notes": "..." }
      ],
      "tankHealth": {
        "observations": ["..."],
        "potentialIssues": ["..."],
        "recommendedActions": ["..."]
      },
      "waterQualityGuesses": {
        "clarity": "Clear | Slightly Cloudy | Cloudy | Green Tint | Murky",
        "algaeLevel": "Low | Moderate | High | Heavy",
        "stockingAssessment": "Light | Moderate | Heavy (crowded)"
      },
      "howAquaPiHelps": "Markdown..."
    }

    If no fish identified confidently: identifiedFish = [] and explain uncertainty in summary.
    User context: {userNote}
    ''',
    PromptType.automationScript: '''
    You are an expert on Home Assistant and ESPHome. A user wants to create a simple automation for their aquarium. Based on the user's description, provide a valid and well-commented YAML code snippet for either a Home Assistant automation or an ESPHome configuration. Also, provide a brief, friendly explanation of what the code does and where it should be placed.
    User's request: "{description}"
    Respond with a JSON object with this exact structure:
    {
      "title": "Automation for [User's Request]",
      "explanation": "A Markdown-formatted explanation of the script that concludes with subtle links to our store: [Shop AquaPi](https://www.capitalcityaquatics.com/store) and the Home Assistant website: [Learn more about Home Assistant](https://www.home-assistant.io/).",
      "code": "The YAML code block as a string, including newline characters (\\n) for proper formatting."
    }
    Ensure the YAML code is valid and can be directly used in Home Assistant or ESPHome.
    ''',
    PromptType.waterAnalysis: '''
    Act as an aquarium expert. Analyze the following water parameters for a {tankType} aquarium:
    {ph_line}
    - Temperature: "{temp}°{tempUnit}"
    {salinity_line}
    {additionalInfo_line}
    Provide a detailed but easy-to-understand analysis. Respond with a JSON object.
    IMPORTANT: For the 'value' field of the temperature parameter, you MUST use the original user-provided value which is '{temp}°{tempUnit}'. For all other parameters, if their value is numeric, please return it as a string in the JSON.
    The status for each parameter and the overall summary MUST be one of "Good", "Needs Attention", or "Bad".
    The 'howAquaPiHelps' section should conclude with a subtle link to our store: [Shop AquaPi](https://www.capitalcityaquatics.com/store).

    The JSON structure must be:
    {
      "summary": { "status": "Good" | "Needs Attention" | "Bad", "title": "...", "message": "..." },
      "parameters": [
        { "name": "Temperature", "value": "{temp}°{tempUnit}", "idealRange": "...", "status": "Good" | "Needs Attention" | "Bad", "advice": "..." }
        // ... other parameters if provided
      ],
      "howAquaPiHelps": "..."
    }
    ''',
    PromptType.fishCompatibility: '''
      You are an aquarium expert. A user has selected a group of fish. Your task is to generate a tailored care guide and compatibility summary.
      Selected Fish: {fishList}
      Fish Type: {category}
      Group Harmony Score: {harmonyPercentage}%
      Please provide a JSON object with the following:
      1. "harmonyLabel": "Based on the Group Harmony Score of {harmonyPercentage}%, provide a one-word label (e.g., Excellent, Good, Fair, Poor).",
      2. "harmonySummary": "Based on the Group Harmony Score of {harmonyPercentage}%, write a brief summary of the overall compatibility of this group.",
      3. "detailedSummary": "A detailed summary of the potential interactions in this specific group of fish.",
      4. "tankSize": "A recommended minimum tank size.",
      5. "decorations": "Recommended decorations and setup.",
      6. "careGuide": "A general care guide for this group.",
      7. "tankMatesSummary": "A short summary of the best tank mates for the selected fish.",
      8. "compatibleFish": [{"name": "List of other fish that are compatible with ALL selected fish. If the selected fish are community fish, include at least 10 compatible fish."}]
      ''',
    PromptType.stockingRecommendation: '''
    You are an expert aquarium stocking advisor. Your primary goal is to create stocking plans with the highest possible harmony.

    A group of fish has HIGH HARMONY **ONLY IF** every fish in the group is present in the 'compatible' list of **EVERY OTHER** fish in that same group. 

    User's Input:
    - Tank Size: "{tankSize}"
    - Tank Type: "{tankType}"
    - Notes: "{userNotes}"

    Available Fish and their compatibility data (use this for "coreFish" and "otherDataBasedFish"):
    {fishListWithCompat}

    Based on the user's input, provide 3 distinct stocking recommendations. Prioritize groups that meet the HIGH HARMONY rule.

    For each recommendation, provide a JSON object with:
    - "title": A creative and descriptive title for the aquarium setup.
    - "summary": An elaborate, detailed summary (2-3 sentences) describing the tank's atmosphere, activity level, the temperament of the fish, and where in the water column the fish will live (top, middle, bottom dwellers).
    - "coreFish": A list of 2-7 fish names that form the main, high-harmony group for this recommendation.
    - "otherDataBasedFish": A list of other fish from the provided data that are compatible or listed "With Caution" with **all** of the "coreFish".
    - "aiTankMatesSummary": A detailed summary explaining why the "aiRecommendedTankMates" are a good fit for the core group of fish.
    - "aiRecommendedTankMates": A list of 5-10 common fish names ONLY (not from the provided data) that you, as an AI, would recommend as additional tank mates.

    Return a single JSON object with a key "recommendations" that contains a list of these recommendation objects.
    ''',
    PromptType.tankStockingRecommendation: '''
    You are an expert aquarium stocking advisor. Your goal is to recommend additional fish to ADD to an existing tank while maintaining the highest possible harmony.

    CRITICAL REQUIREMENTS:
    1. MAINTAIN CURRENT HARMONY: The tank currently has {currentHarmonyPercentage}% harmony - this MUST be maintained or improved
    2. All recommended fish must be compatible with EVERY existing fish in the tank
    3. All recommended fish must be compatible with each other
    4. Priority is maintaining current harmony score ({currentHarmonyPercentage}%) above all else
    5. Consider tank size limitations when making recommendations
    6. Only recommend fish that will enhance the ecosystem without causing stress

    Tank Information:
    - Tank Name: "{tankName}"
    - Tank Size: "{tankSizeText}"
    - Tank Type: "{tankType}"
    - Current Harmony Score: {currentHarmonyPercentage}% (THIS MUST BE MAINTAINED OR IMPROVED)
    - Current Inhabitants: {existingFishNames}

    Current Fish Compatibility Data:
    {existingFishData}

    Available Fish Database (use this for recommendations):
    {fishListWithCompat}

    Based on the current tank setup, provide 3 distinct recommendations for ADDITIONAL fish to add. Each recommendation should:
    - MAINTAIN OR IMPROVE the current {currentHarmonyPercentage}% harmony score
    - Be compatible with ALL existing fish
    - Consider appropriate stocking levels for the tank size
    - Suggest fish that complement the existing ecosystem
    - Account for water column usage (top, middle, bottom dwellers)
    - Consider bioload and tank capacity
    - Prioritize harmony preservation above variety

    For each recommendation, provide a JSON object with:
    - "title": A creative title describing what this addition would bring to the tank (e.g., "Bottom Dweller Cleanup Crew", "Colorful Mid-Water Community")
    - "summary": A detailed 2-3 sentence summary explaining how these additions will enhance the tank ecosystem, their behavior, and where they'll position in the water column
    - "coreFish": A list of 2-7 (at least 3 preferred) fish names from the database that are the main additions and compatible (preferred) or listed "With Caution" with all of the existing fish. These should form the core of the new additions.
    - "otherDataBasedFish": A list of other compatible fish from the database that could also be added safely and compatible or listed "With Caution" with most of the existing fish
    - "aiTankMatesSummary": Explanation of why these additions work well with the existing community
    - "aiRecommendedTankMates": A list of 3-10 common fish names ONLY (not from the database) that would also be good additions.
    - "compatibilityNotes": Specific notes about how these additions interact with the existing fish and any special considerations

    Return a single JSON object with a key "recommendations" that contains a list of these recommendation objects.
    ''',
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