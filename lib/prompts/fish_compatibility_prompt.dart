String buildFishCompatibilityPrompt(String category, List<String> fishNames, double harmonyScore) {
  final fishList = fishNames.join(', ');
  final harmonyPercentage = (harmonyScore * 100).toStringAsFixed(0);

  return '''
      You are an aquarium expert. A user has selected a group of fish. Your task is to generate a tailored care guide and compatibility summary.
      Selected Fish: $fishList
      Fish Type: $category
      Group Harmony Score: $harmonyPercentage%
      Please provide a JSON object with the following:
      1. "harmonyLabel": "Based on the Group Harmony Score of $harmonyPercentage%, provide a one-word label (e.g., Excellent, Good, Fair, Poor).",
      2. "harmonySummary": "Based on the Group Harmony Score of $harmonyPercentage%, write a brief summary of the overall compatibility of this group.",
      3. "detailedSummary": "A detailed summary of the potential interactions in this specific group of fish.",
      4. "tankSize": "A recommended minimum tank size.",
      5. "decorations": "Recommended decorations and setup.",
      6. "careGuide": "A general care guide for this group.",
      7. "tankMatesSummary": "A short summary of the best tank mates for the selected fish.",
      8. "compatibleFish": [{"name": "List of other fish that are compatible with ALL selected fish. If the selected fish are community fish, include at least 10 compatible fish."}]
      ''';
}