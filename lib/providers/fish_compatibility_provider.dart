// lib/providers/fish_compatibility_provider.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/fish.dart';
import '../models/compatibility_report.dart';

class FishCompatibilityProvider extends ChangeNotifier {
  FishCompatibilityProvider() {
    _loadFishData();
  }

  Map<String, List<Fish>> _fishData = {};
  Map<String, List<Fish>> get fishData => _fishData;

  List<Fish> _selectedFish = [];
  List<Fish> get selectedFish => _selectedFish;

  CompatibilityReport? _report;
  CompatibilityReport? get report => _report;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> _loadFishData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/fishcompat.json');
      final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;
      final freshwater = (jsonResponse['freshwater'] as List)
          .map((f) => Fish.fromJson(f))
          .toList();
      final marine =
          (jsonResponse['marine'] as List).map((f) => Fish.fromJson(f)).toList();
      _fishData = {'freshwater': freshwater, 'marine': marine};
    } catch (e) {
      _error = "Failed to load fish data: ${e.toString()}";
    }
    notifyListeners();
  }

  void selectFish(Fish fish) {
    if (_selectedFish.contains(fish)) {
      _selectedFish.remove(fish);
    } else {
      _selectedFish.add(fish);
    }
    _report = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedFish = [];
    _report = null;
    notifyListeners();
  }

  Future<void> getCompatibilityReport(String category) async {
    if (_selectedFish.isEmpty) return;

    _isLoading = true;
    _report = null;
    _error = null;
    notifyListeners();

    final harmonyScore = _calculateHarmonyScore(_selectedFish);
    final prompt = _buildPrompt(category, _selectedFish, harmonyScore);
    final model =
        FirebaseAI.googleAI().generativeModel(model: 'gemini-1.5-flash');

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final reportJson = json.decode(response.text!);
      _report = CompatibilityReport(
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
    } catch (e) {
      _error = "Failed to generate report: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
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