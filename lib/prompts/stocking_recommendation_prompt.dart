import 'dart:convert';
import 'package:fish_ai/models/fish.dart';

String buildStockingRecommendationPrompt(
    String tankSize, String tankType, String userNotes, List<Fish> allFish, {List<Fish>? selectedFish}) {
  final fishNames = allFish.map((f) => f.name).toList();

  // Build selected fish context if any fish are selected
  String selectedFishContext = '';
  if (selectedFish != null && selectedFish.isNotEmpty) {
    final selectedFishNames = selectedFish.map((f) => f.name).join(', ');
    selectedFishContext = '''

    IMPORTANT: The user has specifically selected these fish that they want to include in the stocking plan:
    $selectedFishNames
    
    You MUST include these selected fish in the "coreFish" list of your recommendations. Build the stocking plans around these specific fish.
    ''';
  }

  return '''
    You are an expert aquarium stocking advisor. Your primary goal is to create stocking plans with the highest possible harmony.

    Focus on naturally compatible fish groups. Avoid pairing aggressive species with peaceful ones.
    Note: The app validates final compatibility scores independently, so provide diverse, well-reasoned options.

    User's Input:
    - Tank Size: "$tankSize"
    - Tank Type: "$tankType"
    - Notes: "$userNotes"$selectedFishContext

    Available Fish (choose "coreFish" and "otherDataBasedFish" only from this list):
    ${json.encode(fishNames)}

    Based on the user's input, provide 3 distinct stocking recommendations. Prioritize naturally compatible groups.

    For each recommendation, provide a JSON object with:
    - "title": A creative and descriptive title for the aquarium setup.
    - "summary": A 2-3 sentence summary describing the tank's atmosphere, activity level, temperament, and water column usage (top, middle, bottom dwellers).
    - "coreFish": A list of 2-7 fish names from the list above that form the main compatible group.
    - "otherDataBasedFish": Other fish from the list above that are compatible with all "coreFish".
    - "aiTankMatesSummary": Why the "aiRecommendedTankMates" are a good fit for the core group.
    - "aiRecommendedTankMates": 5-10 common fish names (not from the provided list) as additional tank mate suggestions.

    Return a single JSON object with a key "recommendations" containing a list of these recommendation objects.
    ''';
}
