import 'dart:math';
import '../models/fish.dart';
import '../models/tank.dart';

class TankHarmonyCalculator {
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

  static double _geometricMean(List<double> values) {
    if (values.isEmpty) return 1.0;
    // If any value is 0, the geometric mean is 0.
    if (values.any((v) => v <= 0.0)) return 0.0;
    final logSum = values.fold<double>(0.0, (sum, v) => sum + log(v));
    return exp(logSum / values.length);
  }

  /// Geometric mean for harmony (robust but fair: a few bad pairs lower score).
  /// Special-cases:
  /// - 0 fish: return 1.0 (no conflicts possible)
  /// - 1 fish: return its pairwise probability with itself
  /// - 2 fish: return their pairwise probability
  static double calculateHarmonyScore(List<Fish> fishList) {
    if (fishList.isEmpty) return 1.0;

    if (fishList.length == 1) {
      final fish = fishList.first;
      return _getPairwiseProbability(fish, fish);
    }

    if (fishList.length == 2) {
      return _getPairwiseProbability(fishList[0], fishList[1]);
    }

    final probabilities = <double>[];
    for (int i = 0; i < fishList.length; i++) {
      for (int j = i + 1; j < fishList.length; j++) {
        probabilities.add(_getPairwiseProbability(fishList[i], fishList[j]));
      }
    }

    return _geometricMean(probabilities);
  }

  /// Calculate harmony score for a tank based on its inhabitants
  /// Returns null if fish data is not available
  static double? calculateTankHarmonyScore(Tank tank, Map<String, List<Fish>>? fishData) {
    if (fishData == null || tank.inhabitants.isEmpty) return null;

    // Get all fish types from the tank's category
    final categoryFish = fishData[tank.type] ?? [];
    if (categoryFish.isEmpty) return null;

    // Map tank inhabitants to Fish objects, accounting for individual fish quantities
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
      // Add individual fish based on quantity for proper pairwise calculations
      for (int i = 0; i < inhabitant.quantity; i++) {
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

  /// Generate a detailed breakdown of the harmony calculation
  static String generateCalculationBreakdown(List<Fish> fishList) {
    final buffer = StringBuffer();

    if (fishList.isEmpty) {
      return "Select at least one fish to see compatibility.";
    }

    if (fishList.length == 1) {
      final fish = fishList.first;
      final selfProb = _getPairwiseProbability(fish, fish);

      buffer.writeln("Single Fish Selected:");
      buffer.writeln(fish.name);

      buffer.writeln("\nGroup Harmony Score:");
      buffer.writeln(
        "pair(${fish.name}, ${fish.name}) = ${(selfProb * 100).toStringAsFixed(1)}%",
      );
      return buffer.toString();
    }

    if (fishList.length == 2) {
      final fishA = fishList[0];
      final fishB = fishList[1];
      final prob = _getPairwiseProbability(fishA, fishB);

      buffer.writeln("Pairwise Compatibility:");
      buffer.writeln("${fishA.name} & ${fishB.name}: ${(prob * 100).toStringAsFixed(1)}%");

      buffer.writeln("\nGroup Harmony Score:");
      buffer.writeln("pair(${fishA.name}, ${fishB.name}) = ${(prob * 100).toStringAsFixed(1)}%");
      return buffer.toString();
    }

    // 3+ fish: list all pairs and compute geometric mean
    buffer.writeln("Pairwise Compatibility:");

    final probabilities = <double>[];
    for (int i = 0; i < fishList.length; i++) {
      for (int j = i + 1; j < fishList.length; j++) {
        final fishA = fishList[i];
        final fishB = fishList[j];
        final prob = _getPairwiseProbability(fishA, fishB);
        probabilities.add(prob);

        buffer.writeln("${fishA.name} & ${fishB.name}: ${(prob * 100).toStringAsFixed(1)}%");
      }
    }

    buffer.writeln("\nGroup Harmony Score:");
    final geometricMean = _geometricMean(probabilities);
    final probStrings = probabilities.map((p) => "${(p * 100).toStringAsFixed(1)}%").join(', ');
    buffer.writeln("geometricMean([$probStrings]) = ${(geometricMean * 100).toStringAsFixed(1)}%");

    return buffer.toString();
  }
}