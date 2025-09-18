import 'dart:convert';

import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/stocking_recommendation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dart_openai/dart_openai.dart';
import 'model_provider.dart';
import 'fish_compatibility_provider.dart';
import 'dart:async';
import '../prompts/stocking_recommendation_prompt.dart';
import '../prompts/tank_stocking_recommendation_prompt.dart';
import '../utils/tank_harmony_calculator.dart';
import '../models/tank.dart';

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

  // Helper function for OpenAI calls with retry logic
  Future<String?> _generateOpenAIContentWithRetry(String modelName, String prompt) async {
    int retries = 0;
    const maxRetries = 3;
    int delay = 1000; // start with 1 second

    while (retries < maxRetries) {
      try {
        final response = await OpenAI.instance.chat.create(
          model: modelName,
          responseFormat: {"type": "json_object"},
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)],
              role: OpenAIChatMessageRole.user,
            ),
          ],
        ).timeout(const Duration(seconds: 45)); // Increased timeout
        return response.choices.first.message.content?.first.text;
      } catch (e) {
        // Check the error message for rate limit indicators
        if (e.toString().contains('429') || e.toString().toLowerCase().contains('rate limit')) {
          retries++;
          if (retries >= maxRetries) {
            rethrow; 
          }
          await Future.delayed(Duration(milliseconds: delay));
          delay *= 2; 
        } else {
          rethrow; 
        }
      }
    }
    return null;
  }

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
    final allFish = fishData[tankType] ?? [];
    if (allFish.isEmpty) {
      state = state.copyWith(
        error: 'No fish data available for the selected tank type.',
        isLoading: false,
      );
      return;
    }
    
    final processedTankSize = _processTankSize(tankSize);
    final prompt = buildStockingRecommendationPrompt(processedTankSize, tankType, userNotes, allFish);

    try {
      String? responseText;
      if (models.activeProvider == AIProvider.gemini) {
        if (models.geminiApiKey.isEmpty) {
          throw Exception('Gemini API Key not set. Please go to settings to add your API key.');
        }
        final model = GenerativeModel(model: models.geminiModel, apiKey: models.geminiApiKey);
        final response = await model.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 45));
        responseText = response.text;
      } else {
        if (models.openAIApiKey.isEmpty) {
          throw Exception('OpenAI API Key not set. Please go to settings to add your API key.');
        }
        responseText = await _generateOpenAIContentWithRetry(models.chatGPTModel, prompt);
      }

      if (responseText == null) {
        throw Exception('Received no response from the AI service after multiple retries.');
      }

      final cleanedResponse = _extractJson(responseText);
      final recommendationsJson = json.decode(cleanedResponse) as Map<String, dynamic>;

      final List<StockingRecommendation> allGeneratedRecs = [];
      final recommendationList = recommendationsJson['recommendations'] as List;

      for (var rec in recommendationList) {
        final coreFishNames = List<String>.from(rec['coreFish']);
        final otherFishNames = List<String>.from(rec['otherDataBasedFish']);

        final coreFish = allFish.where((fish) => coreFishNames.contains(fish.name)).toList();
        final otherFish = allFish.where((fish) => otherFishNames.contains(fish.name)).toList();
        
        if (coreFish.isNotEmpty) {
          final harmonyScore = TankHarmonyCalculator.calculateHarmonyScore(coreFish);
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
      String errorMessage = 'Failed to generate recommendations: ${e.toString()}';
      if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota')) {
          errorMessage = '️ **Quota Exceeded**\n\nYou have exceeded your OpenAI API quota. Please check your plan and billing details on the OpenAI website.';
      } else if (e.toString().toLowerCase().contains('rate limit')) {
          errorMessage = '️ **Rate Limit Reached**\n\nThe AI service is busy. Please try again in a moment.';
      }
      state = state.copyWith(
        error: errorMessage,
        isLoading: false,
      );
    }
  }

  Future<void> getTankStockingRecommendations({
    required Tank tank,
  }) async {
    state = state.copyWith(
        isLoading: true, clearError: true, clearRecommendation: true);

    if (tank.inhabitants.isEmpty) {
      state = state.copyWith(
        error: 'Tank has no existing inhabitants. Use the regular stocking tool for empty tanks.',
        isLoading: false,
      );
      return;
    }

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
    final allFish = fishData[tank.type] ?? [];
    if (allFish.isEmpty) {
      state = state.copyWith(
        error: 'No fish data available for the selected tank type.',
        isLoading: false,
      );
      return;
    }

    // Get existing fish from tank inhabitants
    final existingFish = <Fish>[];
    for (final inhabitant in tank.inhabitants) {
      final fish = allFish.firstWhere(
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
      if (!existingFish.any((f) => f.name == fish.name)) {
        existingFish.add(fish);
      }
    }

    if (existingFish.isEmpty) {
      state = state.copyWith(
        error: 'Could not find fish data for tank inhabitants. Please check if fish names match the database.',
        isLoading: false,
      );
      return;
    }

    final prompt = buildTankStockingRecommendationPrompt(tank, allFish, existingFish);

    try {
      String? responseText;
      if (models.activeProvider == AIProvider.gemini) {
        if (models.geminiApiKey.isEmpty) {
          throw Exception('Gemini API Key not set. Please go to settings to add your API key.');
        }
        final model = GenerativeModel(model: models.geminiModel, apiKey: models.geminiApiKey);
        final response = await model.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 45));
        responseText = response.text;
      } else {
        if (models.openAIApiKey.isEmpty) {
          throw Exception('OpenAI API Key not set. Please go to settings to add your API key.');
        }
        responseText = await _generateOpenAIContentWithRetry(models.chatGPTModel, prompt);
      }

      if (responseText == null) {
        throw Exception('Received no response from the AI service after multiple retries.');
      }

      final cleanedResponse = _extractJson(responseText);
      final recommendationsJson = json.decode(cleanedResponse) as Map<String, dynamic>;

      final List<StockingRecommendation> allGeneratedRecs = [];
      final recommendationList = recommendationsJson['recommendations'] as List;

      for (var rec in recommendationList) {
        final coreFishNames = List<String>.from(rec['coreFish']);
        final otherFishNames = List<String>.from(rec['otherDataBasedFish']);

        final coreFish = allFish.where((fish) => coreFishNames.contains(fish.name)).toList();
        final otherFish = allFish.where((fish) => otherFishNames.contains(fish.name)).toList();
        
        if (coreFish.isNotEmpty) {
          // Calculate harmony score including existing fish
          final allTankFish = [...existingFish, ...coreFish];
          final harmonyScore = TankHarmonyCalculator.calculateHarmonyScore(allTankFish);
          
          allGeneratedRecs.add(StockingRecommendation(
            title: rec['title'],
            summary: rec['summary'],
            coreFish: coreFish,
            otherDataBasedFish: otherFish,
            aiTankMatesSummary: rec['aiTankMatesSummary'],
            aiRecommendedTankMates: List<String>.from(rec['aiRecommendedTankMates']), 
            harmonyScore: harmonyScore,
            compatibilityNotes: rec['compatibilityNotes'],
            isAdditionRecommendation: true,
          ));
        }
      }

      // Sort by harmony score (highest first)
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
          error: 'Could not generate suitable additions for your tank. The existing inhabitants may be too restrictive.',
          isLoading: false,
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to generate recommendations: ${e.toString()}';
      if (e.toString().contains('429') || e.toString().toLowerCase().contains('quota')) {
          errorMessage = '️ **Quota Exceeded**\n\nYou have exceeded your OpenAI API quota. Please check your plan and billing details on the OpenAI website.';
      } else if (e.toString().toLowerCase().contains('rate limit')) {
          errorMessage = '️ **Rate Limit Reached**\n\nThe AI service is busy. Please try again in a moment.';
      }
      state = state.copyWith(
        error: errorMessage,
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

  String _extractJson(String text) {
    final regExp = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = regExp.firstMatch(text);
    return match?.group(1) ?? text;
  }
}

final aquariumStockingProvider =
    StateNotifierProvider<AquariumStockingNotifier, AquariumStockingState>(
  (ref) => AquariumStockingNotifier(ref),
);