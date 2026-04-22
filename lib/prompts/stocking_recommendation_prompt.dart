import 'dart:convert';

import 'package:fish_ai/models/fish.dart';

String buildStockingRecommendationPrompt(
  String tankSize,
  String tankType,
  String userNotes,
  List<Fish> allFish, {
  List<Fish>? selectedFish,
  Map<String, List<String>>? speciesSelections,
}) {
  // Standalone stocking builds a complete plan for a new setup, so quantity
  // guidance should be interpreted as absolute target counts.
  final fishNames = allFish.map((f) => f.name).toList();

  // Build selected fish context if any fish are selected
  String selectedFishContext = '';
  if (selectedFish != null && selectedFish.isNotEmpty) {
    // Build a human-readable description including any specific species chosen
    final selectedFishDetails = selectedFish
        .map((f) {
          final species = speciesSelections?[f.name];
          if (species != null && species.isNotEmpty) {
            return '${f.name} (${species.join(', ')})';
          }
          return f.name;
        })
        .join(', ');
    selectedFishContext =
        '''

    IMPORTANT: The user has specifically selected these fish that they want to include in the stocking plan:
    $selectedFishDetails
    
    You MUST include these selected fish in the "coreFish" list of your recommendations. Build the stocking plans around these specific fish. When specific species/varieties are noted in parentheses, tailor the recommendations for those varieties. If no specific variety is indicated in parentheses for a fish, provide recommendations for that fish type in general without assuming a specific variety.
    Also include realistic quantity guidance for each selected fish (schooling/shoaling sizes, pair/group needs, and total stocking load for the tank size).
    ''';
  }

  return '''
    You are an expert aquarium stocking advisor. Your primary goal is to create stocking plans with the highest possible harmony.

    Focus on naturally compatible fish groups. Avoid pairing aggressive species with peaceful ones.
    Note: The app validates final compatibility scores independently, so provide diverse, well-reasoned options.

    User's Input:
    - Tank Size: "${tankSize.isEmpty ? 'Not specified' : tankSize}"
    - Tank Type: "$tankType"
    - Notes: "$userNotes"$selectedFishContext

    Available Fish (choose "coreFish" and "otherDataBasedFish" only from this list):
    ${json.encode(fishNames)}

    Based on the user's input, provide 3 distinct stocking recommendations. Prioritize naturally compatible groups.

    For each recommendation, provide a JSON object with:
    - "title": A creative and descriptive title for the aquarium setup.
    - "summary": A 2-3 sentence summary describing the tank's atmosphere, activity level, temperament, water column usage (top, middle, bottom dwellers), and quantity guidance.
    - "coreFish": A list of 2-7 fish names from the list above that form the main compatible group.
    - "otherDataBasedFish": Other fish from the list above that are compatible with all "coreFish".
    - "aiTankMatesSummary": Why the "aiRecommendedTankMates" are a good fit for the core group.
    - "aiRecommendedTankMates": 5-10 common fish names (not from the provided list) as additional tank mate suggestions.
    - "quantityGuidance": A JSON object where each key is a fish name from "coreFish" and each value is a short count recommendation (example: "8-10", "pair", "1").

    Quantity and stocking-load requirements:
    - Explicitly consider fish counts, schooling needs, and total stocking load relative to tank size.
    - Avoid overstocking recommendations.
    - Keep quantity guidance realistic for the provided tank size and tank type.
    - In this standalone planner, quantity guidance represents absolute target counts for the full new setup (not incremental additions).

    Return a single JSON object with a key "recommendations" containing a list of these recommendation objects.
    ''';
}
