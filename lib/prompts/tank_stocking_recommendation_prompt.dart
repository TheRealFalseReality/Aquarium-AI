import 'dart:convert';
import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/tank.dart';

String buildTankStockingRecommendationPrompt(
    Tank tank,
    List<Fish> allFish,
    List<Fish> existingFish,
    double currentHarmonyScore, {
    String additionalNotes = '',
  }) {
  final availableFishNames = allFish.map((f) => f.name).toList();

  final existingFishNames = existingFish.map((f) => f.name).toList();
  final tankSizeText = _formatTankSize(tank);
  final currentHarmonyPercentage = (currentHarmonyScore * 100).toStringAsFixed(1);

  // Build species tags info from inhabitants' selected species tags
  String speciesTagsInfo = '';
  final speciesTagsMap = <String, List<String>>{};
  for (final inhabitant in tank.inhabitants) {
    if (inhabitant.speciesTags.isNotEmpty) {
      speciesTagsMap[inhabitant.fishUnit] = inhabitant.speciesTags;
    }
  }
  if (speciesTagsMap.isNotEmpty) {
    speciesTagsInfo = '''

    Species Tags (user-specified species for each fish type):
    ${json.encode(speciesTagsMap)}
    Note: These tags indicate the specific species or variants the user has. Consider them for more precise recommendations.''';
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

    Focus on fish that are naturally compatible with the existing inhabitants. Avoid pairing aggressive species with peaceful ones.
    Note: The app validates final compatibility scores independently, so provide diverse, well-reasoned options.

    REQUIREMENTS:
    1. All recommended fish must be naturally compatible with the existing inhabitants.
    2. Recommended fish must be compatible with each other.
    3. Maintain or improve the current harmony score ($currentHarmonyPercentage%).
    4. Consider tank size limitations.

    Tank Information:
    - Tank Name: "${tank.name}"
    - Tank Size: "$tankSizeText"
    - Tank Type: "${tank.type}"
    - Tank Notes: "${tank.notes ?? 'No specific notes provided'}"
    - Current Harmony Score: $currentHarmonyPercentage%
    - Current Inhabitants: ${json.encode(existingFishNames)}$speciesTagsInfo$additionalNotesSection

    Available Fish Database (choose recommendations only from this list):
    ${json.encode(availableFishNames)}

    Provide 3 distinct recommendations for ADDITIONAL fish to add. Each should:
    - Be compatible with ALL existing fish
    - Maintain or improve the $currentHarmonyPercentage% harmony score
    - Fit the tank size and bioload
    - Complement the existing ecosystem (consider water column usage)

    For each recommendation, provide a JSON object with:
    - "title": A creative title describing the addition (e.g., "Bottom Dweller Cleanup Crew")
    - "summary": 2-3 sentences on how these additions enhance the tank, their behavior, and water column position
    - "coreFish": 2-7 fish names from the database compatible with all existing fish
    - "otherDataBasedFish": Other compatible fish from the database that could also be added safely
    - "aiTankMatesSummary": Why these additions work well with the existing community
    - "aiRecommendedTankMates": 3-10 common fish names (not from the database) as additional suggestions
    - "compatibilityNotes": Notes on how these additions interact with existing fish

    Return a single JSON object with a key "recommendations" containing a list of these recommendation objects.
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
