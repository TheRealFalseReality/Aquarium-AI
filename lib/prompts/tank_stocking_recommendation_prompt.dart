import 'dart:convert';
import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/tank.dart';

String buildTankStockingRecommendationPrompt(
    Tank tank,
    List<Fish> allFish,
    List<Fish> existingFish,
    double currentHarmonyScore, {
    bool includeCustomNames = false,
    String additionalNotes = '',
  }) {
  final fishListWithCompat = allFish.map((f) => {
    'name': f.name,
    'compatible': f.compatible,
  }).toList();

  final existingFishNames = existingFish.map((f) => f.name).toList();
  final tankSizeText = _formatTankSize(tank);
  final currentHarmonyPercentage = (currentHarmonyScore * 100).toStringAsFixed(1);

  // Build custom names info if included
  String customNamesInfo = '';
  if (includeCustomNames) {
    final customNamesMap = <String, String>{};
    for (final inhabitant in tank.inhabitants) {
      if (inhabitant.customName != inhabitant.fishUnit) {
        customNamesMap[inhabitant.fishUnit] = inhabitant.customName;
      }
    }
    if (customNamesMap.isNotEmpty) {
      customNamesInfo = '''

    Custom Names (User-provided species information):
    ${json.encode(customNamesMap)}
    Note: These custom names may provide more specific species information. Consider them for more precise recommendations.''';
    }
  }

  // Build additional notes section if provided
  String additionalNotesSection = '';
  if (additionalNotes.isNotEmpty) {
    additionalNotesSection = '''

    User's Additional Requests/Preferences:
    "$additionalNotes"
    Please consider these preferences when making recommendations.''';
  }

  return '''
    You are an expert aquarium stocking advisor. Your goal is to recommend additional fish to ADD to an existing tank while maintaining the highest possible harmony.

    CRITICAL REQUIREMENTS:
    1. MAINTAIN CURRENT HARMONY: The tank currently has $currentHarmonyPercentage% harmony - this MUST be maintained or improved
      If you cannot find a group of fish that meet the HIGH HARMONY rule, you may include fish that are listed as "With Caution" with **ALL** other fish in the group, but this should be avoided if possible.
      Fish listed as "Not Compatible" with any other fish in the group are NOT allowed.
    2. All recommended fish must be compatible with EVERY existing fish in the tank
    3. All recommended fish must be compatible with each other
    4. Priority is maintaining current harmony score ($currentHarmonyPercentage%) above all else
    5. Consider tank size limitations when making recommendations
    6. Only recommend fish that will enhance the ecosystem without causing stress

    Tank Information:
    - Tank Name: "${tank.name}"
    - Tank Size: "$tankSizeText"
    - Tank Type: "${tank.type}"
    - Tank Notes: "${tank.notes ?? 'No specific notes provided'}"
    - Current Harmony Score: $currentHarmonyPercentage% (THIS MUST BE MAINTAINED OR IMPROVED)
    - Current Inhabitants: ${json.encode(existingFishNames)}$customNamesInfo$additionalNotesSection

    Current Fish Compatibility Data:
    ${json.encode(existingFish.map((f) => {
      'name': f.name,
      'compatible': f.compatible,
    }).toList())}

    Available Fish Database (use this for recommendations):
    ${json.encode(fishListWithCompat)}

    Based on the current tank setup, provide 3 distinct recommendations for ADDITIONAL fish to add. Each recommendation should:
    - MAINTAIN OR IMPROVE the current $currentHarmonyPercentage% harmony score
    - Be compatible with ALL existing fish or Current Inhabitants
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
