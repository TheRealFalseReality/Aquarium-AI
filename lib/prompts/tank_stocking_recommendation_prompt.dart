import 'dart:convert';
import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/tank.dart';

String buildTankStockingRecommendationPrompt(
    Tank tank, List<Fish> allFish, List<Fish> existingFish, double currentHarmonyScore) {
  final fishListWithCompat = allFish.map((f) => {
    'name': f.name,
    'compatible': f.compatible,
  }).toList();

  final existingFishNames = existingFish.map((f) => f.name).toList();
  final tankSizeText = _formatTankSize(tank);
  final currentHarmonyPercentage = (currentHarmonyScore * 100).toStringAsFixed(1);

  return '''
    You are an expert aquarium stocking advisor. Your goal is to recommend additional fish to ADD to an existing tank while maintaining the highest possible harmony.

    CRITICAL REQUIREMENTS:
    1. MAINTAIN CURRENT HARMONY: The tank currently has $currentHarmonyPercentage% harmony - this MUST be maintained or improved
    2. All recommended fish must be compatible with EVERY existing fish in the tank
    3. All recommended fish must be compatible with each other
    4. Priority is maintaining current harmony score ($currentHarmonyPercentage%) above all else
    5. Consider tank size limitations when making recommendations
    6. Only recommend fish that will enhance the ecosystem without causing stress

    Tank Information:
    - Tank Name: "${tank.name}"
    - Tank Size: "$tankSizeText"
    - Tank Type: "${tank.type}"
    - Current Harmony Score: $currentHarmonyPercentage% (THIS MUST BE MAINTAINED OR IMPROVED)
    - Current Inhabitants: ${json.encode(existingFishNames)}

    Current Fish Compatibility Data:
    ${json.encode(existingFish.map((f) => {
      'name': f.name,
      'compatible': f.compatible,
    }).toList())}

    Available Fish Database (use this for recommendations):
    ${json.encode(fishListWithCompat)}

    Based on the current tank setup, provide 3 distinct recommendations for ADDITIONAL fish to add. Each recommendation should:
    - MAINTAIN OR IMPROVE the current $currentHarmonyPercentage% harmony score
    - Be compatible with ALL existing fish
    - Consider appropriate stocking levels for the tank size
    - Suggest fish that complement the existing ecosystem
    - Account for water column usage (top, middle, bottom dwellers)
    - Consider bioload and tank capacity
    - Prioritize harmony preservation above variety

    For each recommendation, provide a JSON object with:
    - "title": A creative title describing what this addition would bring to the tank (e.g., "Bottom Dweller Cleanup Crew", "Colorful Mid-Water Community")
    - "summary": A detailed 2-3 sentence summary explaining how these additions will enhance the tank ecosystem, their behavior, and where they'll position in the water column
    - "coreFish": A list of 1-3 fish names from the database that are the main additions and compatible with ALL existing fish
    - "otherDataBasedFish": A list of other compatible fish from the database that could also be added safely
    - "aiTankMatesSummary": Explanation of why these additions work well with the existing community
    - "aiRecommendedTankMates": A list of 3-7 common fish names (not from the database) that would also be good additions
    - "compatibilityNotes": Specific notes about how these additions interact with the existing fish and any special considerations

    Return a single JSON object with a key "recommendations" that contains a list of these recommendation objects.
    ''';
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