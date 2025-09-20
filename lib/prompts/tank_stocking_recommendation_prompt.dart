import 'dart:convert';
import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/tank.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prompt_provider.dart';

String buildTankStockingRecommendationPrompt(
    Tank tank, List<Fish> allFish, List<Fish> existingFish, double currentHarmonyScore, [Ref? ref]) {
  final fishListWithCompat = allFish.map((f) => {
    'name': f.name,
    'compatible': f.compatible,
  }).toList();

  final existingFishNames = existingFish.map((f) => f.name).toList();
  final tankSizeText = _formatTankSize(tank);
  final currentHarmonyPercentage = (currentHarmonyScore * 100).toStringAsFixed(1);

  String basePrompt;
  
  if (ref != null) {
    basePrompt = ref.read(promptProvider.notifier).getPrompt(PromptType.tankStockingRecommendation);
  } else {
    // Fallback to default for backward compatibility
    basePrompt = '''
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
    ''';
  }

  final existingFishData = existingFish.map((f) => {
    'name': f.name,
    'compatible': f.compatible,
  }).toList();

  return basePrompt
      .replaceAll('{currentHarmonyPercentage}', currentHarmonyPercentage)
      .replaceAll('{tankName}', tank.name)
      .replaceAll('{tankSizeText}', tankSizeText)
      .replaceAll('{tankType}', tank.type)
      .replaceAll('{existingFishNames}', json.encode(existingFishNames))
      .replaceAll('{existingFishData}', json.encode(existingFishData))
      .replaceAll('{fishListWithCompat}', json.encode(fishListWithCompat));
}

String _formatTankSize(Tank tank) {
  if (tank.sizeGallons != null && tank.sizeLiters != null) {
    return '${tank.sizeGallons!.toStringAsFixed(0)} gallons (${tank.sizeLiters!.toStringAsFixed(0)} liters)';
  } else if (tank.sizeGallons != null) {
    return '${tank.sizeGallons!.toStringAsFixed(0)} gallons';
  } else if (tank.sizeLiters != null) {
    return '${tank.sizeLiters!.toStringAsFixed(0)} liters';
  }
  return 'Size not specified';
}