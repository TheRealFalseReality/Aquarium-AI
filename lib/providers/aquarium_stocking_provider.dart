import 'dart:convert';
import 'dart:math';

import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/stocking_recommendation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'model_provider.dart';
import 'fish_compatibility_provider.dart';

// The state for our new provider
class AquariumStockingState {
  final bool isLoading;
  final StockingRecommendation? recommendation;
  final StockingRecommendation? lastRecommendation;
  final String? error;

  AquariumStockingState({
    this.isLoading = false,
    this.recommendation,
    this.lastRecommendation,
    this.error,
  });

  AquariumStockingState copyWith({
    bool? isLoading,
    StockingRecommendation? recommendation,
    StockingRecommendation? lastRecommendation,
    String? error,
    bool clearError = false,
    bool clearRecommendation = false,
  }) {
    return AquariumStockingState(
      isLoading: isLoading ?? this.isLoading,
      recommendation:
          clearRecommendation ? null : recommendation ?? this.recommendation,
      lastRecommendation: lastRecommendation ?? this.lastRecommendation,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AquariumStockingNotifier extends StateNotifier<AquariumStockingState> {
  final Ref ref;

  AquariumStockingNotifier(this.ref) : super(AquariumStockingState());

  Future<void> getStockingRecommendations({
    required String tankSize,
    required String tankType,
    required String userNotes,
  }) async {
    state = state.copyWith(
        isLoading: true, clearError: true, clearRecommendation: true);

    final fishDataAsync = ref.read(fishCompatibilityProvider).fishData;

    if (fishDataAsync.isLoading) {
      state = state.copyWith(
        error: 'Fish data is still loading, please wait a moment and try again.',
        isLoading: false,
      );
      return;
    }

    final fishData = fishDataAsync.valueOrNull;
    if (fishData == null) {
      state = state.copyWith(
        error: 'Fish data is unavailable. Cannot generate recommendations.',
        isLoading: false,
      );
      return;
    }

    final models = ref.read(modelProvider);

    if (models.apiKey.isEmpty) {
      state = state.copyWith(
        error: 'API Key not set. Please go to settings to add your API key.',
        isLoading: false,
      );
      return;
    }

    final allFish = fishData[tankType] ?? [];
    if (allFish.isEmpty) {
      state = state.copyWith(
        error: 'No fish data available for the selected tank type.',
        isLoading: false,
      );
      return;
    }

    final model = GenerativeModel(
      model: models.geminiModel,
      apiKey: models.apiKey,
    );

    final processedTankSize = _processTankSize(tankSize);
    final prompt = _buildPrompt(processedTankSize, tankType, userNotes, allFish);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final cleanedResponse = _extractJson(response.text!);
      final recommendationsJson =
          json.decode(cleanedResponse) as Map<String, dynamic>;

      final List<StockingRecommendation> recommendations = [];
      final recommendationList = recommendationsJson['recommendations'] as List;

      for (var rec in recommendationList) {
        final fishNames = List<String>.from(rec['fish']);
        final recommendedFish =
            allFish.where((fish) => fishNames.contains(fish.name)).toList();

        if (recommendedFish.isNotEmpty) {
          final harmonyScore = _calculateHarmonyScore(recommendedFish);

          // Only consider recommendations with a high score
          if (harmonyScore >= 0.8) {
            recommendations.add(StockingRecommendation(
              title: rec['title'],
              summary: rec['summary'],
              fish: recommendedFish,
              harmonyScore: harmonyScore,
              tankMatesSummary: rec['tankMatesSummary'],
              tankMates: List<String>.from(rec['compatibleFish']),
            ));
          }
        }
      }

      // Sort by score to ensure the absolute best is selected
      recommendations.sort((a, b) => b.harmonyScore.compareTo(a.harmonyScore));

      if (recommendations.isNotEmpty) {
        final bestRecommendation = recommendations.first;
        state = state.copyWith(
          recommendation: bestRecommendation,
          lastRecommendation: bestRecommendation,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error:
              'Could not generate a high-harmony recommendation for your criteria. Try adjusting the notes or tank size.',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to generate recommendations: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  String _processTankSize(String tankSize) {
    if (double.tryParse(tankSize) != null) {
      return '$tankSize gallons';
    }
    return tankSize;
  }

  // --- MODIFIED PROMPT ---
  String _buildPrompt(
      String tankSize, String tankType, String userNotes, List<Fish> allFish) {
    // Create a more detailed list that includes compatibility info
    final fishListWithCompat = allFish.map((f) => {
      'name': f.name,
      'compatible': f.compatible,
    }).toList();

    return '''
    You are an expert aquarium stocking advisor. Your most important goal is to create a stocking plan with the highest possible harmony.

    A group of fish has HIGH HARMONY **ONLY IF** every fish in the group is present in the 'compatible' list of **EVERY OTHER** fish in that same group. Do not suggest a group if this rule is not met.

    User's Input:
    - Tank Size: "$tankSize"
    - Tank Type: "$tankType"
    - Notes: "$userNotes"

    Available Fish and their compatibility data:
    ${json.encode(fishListWithCompat)}

    Based on the user's input and the strict harmony rule, provide 3 distinct stocking recommendations that have a very high harmony score (over 80%).

    Each recommendation must be a JSON object with "title", "summary", a "fish" list (containing only fish names), "tankMatesSummary", and a "compatibleFish" list (containing other fish names compatible with the entire group).

    Return a single JSON object with a key "recommendations" that contains a list of these recommendation objects.
    ''';
  }

  String _extractJson(String text) {
    final regExp = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = regExp.firstMatch(text);
    return match?.group(1) ?? text;
  }

  double _getPairwiseProbability(Fish fishA, Fish fishB) {
    if (fishA.compatible.contains(fishB.name) &&
        fishB.compatible.contains(fishA.name)) return 1.0;
    if (fishA.notCompatible.contains(fishB.name) ||
        fishB.notCompatible.contains(fishA.name)) return 0.0;
    if (fishA.notRecommended.contains(fishB.name) ||
        fishB.notRecommended.contains(fishA.name)) return 0.25;
    if (fishA.withCaution.contains(fishB.name) ||
        fishB.withCaution.contains(fishA.name)) return 0.75;
    return 0.5;
  }

  double _calculateHarmonyScore(List<Fish> fishList) {
    if (fishList.length <= 1) return 1.0;

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
}

final aquariumStockingProvider =
    StateNotifierProvider<AquariumStockingNotifier, AquariumStockingState>(
  (ref) => AquariumStockingNotifier(ref),
);