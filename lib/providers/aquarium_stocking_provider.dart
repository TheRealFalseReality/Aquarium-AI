import 'dart:convert';

import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/stocking_recommendation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'model_provider.dart';
import 'fish_compatibility_provider.dart';

class AquariumStockingState {
  final bool isLoading;
  final List<StockingRecommendation>? recommendations;
  final List<StockingRecommendation>? lastRecommendations;
  final String? error;

  AquariumStockingState({
    this.isLoading = false,
    this.recommendations,
    this.lastRecommendations,
    this.error,
  });

  AquariumStockingState copyWith({
    bool? isLoading,
    List<StockingRecommendation>? recommendations,
    List<StockingRecommendation>? lastRecommendations,
    String? error,
    bool clearError = false,
    bool clearRecommendation = false,
  }) {
    return AquariumStockingState(
      isLoading: isLoading ?? this.isLoading,
      recommendations:
          clearRecommendation ? null : recommendations ?? this.recommendations,
      lastRecommendations: lastRecommendations ?? this.lastRecommendations,
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
    
    final model = GenerativeModel(model: models.geminiModel, apiKey: models.apiKey);
    final processedTankSize = _processTankSize(tankSize);
    final prompt = _buildPrompt(processedTankSize, tankType, userNotes, allFish);

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final cleanedResponse = _extractJson(response.text!);
      final recommendationsJson = json.decode(cleanedResponse) as Map<String, dynamic>;

      final List<StockingRecommendation> allGeneratedRecs = [];
      final recommendationList = recommendationsJson['recommendations'] as List;

      for (var rec in recommendationList) {
        final coreFishNames = List<String>.from(rec['coreFish']);
        final otherFishNames = List<String>.from(rec['otherDataBasedFish']);

        final coreFish = allFish.where((fish) => coreFishNames.contains(fish.name)).toList();
        final otherFish = allFish.where((fish) => otherFishNames.contains(fish.name)).toList();
        
        if (coreFish.isNotEmpty) {
          final harmonyScore = _calculateHarmonyScore(coreFish);
          allGeneratedRecs.add(StockingRecommendation(
            title: rec['title'],
            summary: rec['summary'],
            coreFish: coreFish,
            otherDataBasedFish: otherFish,
            aiTankMatesSummary: rec['aiTankMatesSummary'],
            aiRecommendedTankMates: List<String>.from(rec['aiRecommendedTankMates']), 
            harmonyScore: harmonyScore,
          ));
        }
      }

      allGeneratedRecs.sort((a, b) => b.harmonyScore.compareTo(a.harmonyScore));

      List<StockingRecommendation> finalRecs = [];
      finalRecs.addAll(allGeneratedRecs.where((r) => r.harmonyScore >= 0.8));

      if (finalRecs.length < 3 && allGeneratedRecs.length > finalRecs.length) {
        var remainingRecs = allGeneratedRecs.where((r) => !finalRecs.contains(r)).toList();
        int needed = 3 - finalRecs.length;
        if (remainingRecs.isNotEmpty) {
            finalRecs.addAll(remainingRecs.take(needed));
        }
      }
      
      if (finalRecs.isEmpty && allGeneratedRecs.isNotEmpty) {
          finalRecs.add(allGeneratedRecs.first);
      }

      if (finalRecs.isNotEmpty) {
        state = state.copyWith(
          recommendations: finalRecs,
          lastRecommendations: finalRecs,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Could not generate a valid recommendation for your criteria. Try adjusting the notes or tank size.',
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

  String _buildPrompt(
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

  String _extractJson(String text) {
    final regExp = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = regExp.firstMatch(text);
    return match?.group(1) ?? text;
  }

  double _getPairwiseProbability(Fish fishA, Fish fishB) {
    if (fishA.compatible.contains(fishB.name) &&
        fishB.compatible.contains(fishA.name)) {
      return 1.0;
    }
    if (fishA.notCompatible.contains(fishB.name) ||
        fishB.notCompatible.contains(fishA.name)) {
      return 0.0;
    }
    if (fishA.notRecommended.contains(fishB.name) ||
        fishB.notRecommended.contains(fishA.name)) {
      return 0.25;
    }
    if (fishA.withCaution.contains(fishB.name) ||
        fishB.withCaution.contains(fishA.name)) {
      return 0.75;
    }
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