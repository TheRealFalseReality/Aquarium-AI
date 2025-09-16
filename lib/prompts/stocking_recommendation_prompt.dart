import 'dart:convert';
import 'package:fish_ai/models/fish.dart';

String buildStockingRecommendationPrompt(
    String tankSize, String tankType, String userNotes, List<Fish> allFish) {
  final fishListWithCompat = allFish.map((f) => {
    'name': f.name,
    'compatible': f.compatible,
  }).toList();

  return '''
    You are an expert aquarium stocking advisor. Your primary goal is to create stocking plans with the highest possible harmony.

    A group of fish has HIGH HARMONY **ONLY IF** every fish in the group is present in the 'compatible' list of **EVERY OTHER** fish in that same group. 

    User's Input:
    - Tank Size: "$tankSize"
    - Tank Type: "$tankType"
    - Notes: "$userNotes"

    Available Fish and their compatibility data (use this for "coreFish" and "otherDataBasedFish"):
    ${json.encode(fishListWithCompat)}

    Based on the user's input, provide 3 distinct stocking recommendations. Prioritize groups that meet the HIGH HARMONY rule.

    For each recommendation, provide a JSON object with:
    - "title": A creative and descriptive title for the aquarium setup.
    - "summary": An elaborate, detailed summary (2-3 sentences) describing the tank's atmosphere, activity level, the temperament of the fish, and where in the water column the fish will live (top, middle, bottom dwellers).
    - "coreFish": A list of 2-4 fish names that form the main, high-harmony group for this recommendation.
    - "otherDataBasedFish": A list of other fish from the provided data that are compatible with **all** of the "coreFish".
    - "aiTankMatesSummary": A detailed summary explaining why the "aiRecommendedTankMates" are a good fit for the core group of fish.
    - "aiRecommendedTankMates": A list of 5-10 common fish names (not from the provided data) that you, as an AI, would recommend as additional tank mates.

    Return a single JSON object with a key "recommendations" that contains a list of these recommendation objects.
    ''';
}