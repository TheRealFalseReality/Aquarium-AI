import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fish.dart';
import '../models/compatibility_report.dart';

final fishCompatibilityProvider = NotifierProvider<FishCompatibilityNotifier, FishCompatibilityState>(FishCompatibilityNotifier.new);

class FishCompatibilityState {
  final Map<String, List<Fish>> fishData;
  final List<Fish> selectedFish;
  final CompatibilityReport? report;
  final bool isLoading;
  final String? error;

  FishCompatibilityState({
    this.fishData = const {},
    this.selectedFish = const [],
    this.report,
    this.isLoading = false,
    this.error,
  });

  FishCompatibilityState copyWith({
    Map<String, List<Fish>>? fishData,
    List<Fish>? selectedFish,
    CompatibilityReport? report,
    bool? isLoading,
    String? error,
  }) {
    return FishCompatibilityState(
      fishData: fishData ?? this.fishData,
      selectedFish: selectedFish ?? this.selectedFish,
      report: report ?? this.report,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FishCompatibilityNotifier extends Notifier<FishCompatibilityState> {
  @override
  FishCompatibilityState build() {
    _loadFishData();
    return FishCompatibilityState();
  }

  Future<void> _loadFishData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/fishcompat.json');
      final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;
      final freshwater = (jsonResponse['freshwater'] as List)
          .map((f) => Fish.fromJson(f))
          .toList();
      final marine =
          (jsonResponse['marine'] as List).map((f) => Fish.fromJson(f)).toList();
      state = state.copyWith(fishData: {'freshwater': freshwater, 'marine': marine});
    } catch (e) {
      state = state.copyWith(error: "Failed to load fish data: ${e.toString()}");
    }
  }

  void selectFish(Fish fish) {
    final newSelectedFish = List<Fish>.from(state.selectedFish);
    if (newSelectedFish.contains(fish)) {
      newSelectedFish.remove(fish);
    } else {
      newSelectedFish.add(fish);
    }
    state = state.copyWith(selectedFish: newSelectedFish, report: null);
  }

  void clearSelection() {
    state = state.copyWith(selectedFish: [], report: null);
  }

  Future<void> getCompatibilityReport(String category) async {
    if (state.selectedFish.isEmpty) return;

    state = state.copyWith(isLoading: true, report: null, error: null);

    final harmonyScore = _calculateHarmonyScore(state.selectedFish);
    final prompt = _buildPrompt(category, state.selectedFish, harmonyScore);
    final model =
        FirebaseAI.googleAI().generativeModel(model: 'gemini-1.5-flash');

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final reportJson = json.decode(response.text!);
      final report = CompatibilityReport(
        harmonyLabel: reportJson['harmonyLabel'],
        harmonySummary: reportJson['harmonySummary'],
        detailedSummary: reportJson['detailedSummary'],
        tankSize: reportJson['tankSize'],
        decorations: reportJson['decorations'],
        careGuide: reportJson['careGuide'],
        compatibleFish: List<String>.from(
            reportJson['compatibleFish'].map((f) => f['name'])),
        groupHarmonyScore: harmonyScore,
      );
      state = state.copyWith(report: report, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: "Failed to generate report: ${e.toString()}", isLoading: false);
    }
  }

  double _getWeightedScore(double score) {
    final randomFactor = Random().nextDouble() * 0.1 - 0.05;
    return (score + randomFactor).clamp(0.0, 1.0);
  }

  double _getPairwiseProbability(Fish fishA, Fish fishB) {
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

  double _calculateHarmonyScore(List<Fish> fishList) {
    if (fishList.isEmpty) return 1.0;
    if (fishList.length == 1)
      return _getPairwiseProbability(fishList[0], fishList[0]);

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

  String _buildPrompt(
      String category, List<Fish> fishList, double harmonyScore) {
    final fishNames = fishList.map((f) => f.name).join(', ');
    final harmonyPercentage = (harmonyScore * 100).toStringAsFixed(0);

    return '''
      You are an aquarium expert. A user has selected a group of fish. Your task is to generate a tailored care guide and compatibility summary.
      Selected Fish: $fishNames
      Fish Type: $category
      Group Harmony Score: $harmonyPercentage%
      Please provide a JSON object with the following:
      1. "harmonyLabel": "Based on the Group Harmony Score of $harmonyPercentage%, provide a one-word label (e.g., Excellent, Good, Fair, Poor).",
      2. "harmonySummary": "Based on the Group Harmony Score of $harmonyPercentage%, write a brief summary of the overall compatibility of this group.",
      3. "detailedSummary": "A detailed summary of the potential interactions in this specific group of fish.",
      4. "tankSize": "A recommended minimum tank size.",
      5. "decorations": "Recommended decorations and setup.",
      6. "careGuide": "A general care guide for this group.",
      7. "compatibleFish": [{"name": "List of other fish that are compatible with ALL selected fish."}]
      ''';
  }
}