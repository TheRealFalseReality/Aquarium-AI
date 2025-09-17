import 'dart:math';
import '../models/fish.dart';
import '../models/tank.dart';

class TankHarmonyCalculator {
  // Reuse the same calculation logic from fish compatibility provider
  static double _getWeightedScore(double score) {
    final randomFactor = Random().nextDouble() * 0.1 - 0.05;
    return (score + randomFactor).clamp(0.0, 1.0);
  }

  static double _getPairwiseProbability(Fish fishA, Fish fishB) {
    if (fishA.compatible.contains(fishB.name) &&
        fishB.compatible.contains(fishA.name)) {
      return _getWeightedScore(1.0);
    }
    if (fishA.notCompatible.contains(fishB.name) ||
        fishB.notCompatible.contains(fishA.name)) {
      return _getWeightedScore(0.0);
    }
    if (fishA.notRecommended.contains(fishB.name) ||
        fishB.notRecommended.contains(fishA.name)) {
      return _getWeightedScore(0.25);
    }
    if (fishA.withCaution.contains(fishB.name) ||
        fishB.withCaution.contains(fishA.name)) {
      return _getWeightedScore(0.75);
    }
    return _getWeightedScore(0.5);
  }

  static double calculateHarmonyScore(List<Fish> fishList) {
    if (fishList.length < 2) return 1.0;

    double minProb = 1.0;
    for (int i = 0; i < fishList.length; i++) {
      for (int j = i + 1; j < fishList.length; j++) {
        final prob = _getPairwiseProbability(fishList[i], fishList[j]);
        if (prob < minProb) {
          minProb = prob;
        }
      }
    }
    return minProb;
  }

  /// Calculate harmony score for a tank based on its inhabitants
  /// Returns null if fish data is not available
  static double? calculateTankHarmonyScore(Tank tank, Map<String, List<Fish>>? fishData) {
    if (fishData == null || tank.inhabitants.isEmpty) return null;
    
    // Get all fish types from the tank's category
    final categoryFish = fishData[tank.type] ?? [];
    if (categoryFish.isEmpty) return null;

    // Map tank inhabitants to Fish objects
    final tankFish = <Fish>[];
    for (final inhabitant in tank.inhabitants) {
      final fish = categoryFish.firstWhere(
        (f) => f.name == inhabitant.fishUnit,
        orElse: () => Fish(
          name: inhabitant.fishUnit,
          commonNames: [],
          imageURL: '',
          compatible: [],
          notRecommended: [],
          notCompatible: [],
          withCaution: [],
        ),
      );
      // Add each fish based on quantity (but for harmony calculation, treat as unique types)
      if (!tankFish.any((f) => f.name == fish.name)) {
        tankFish.add(fish);
      }
    }

    return calculateHarmonyScore(tankFish);
  }

  /// Get a human-readable harmony label based on the score
  static String getHarmonyLabel(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.8) return 'Good';
    if (score >= 0.6) return 'Fair';
    if (score >= 0.4) return 'Caution';
    return 'Poor';
  }

  /// Get a color for the harmony score display
  static String getHarmonyColorHex(double score) {
    if (score >= 0.8) return '#4CAF50'; // Green
    if (score >= 0.6) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }
}