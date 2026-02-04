import 'dart:async';
import 'dart:convert';
import 'package:fish_ai/models/compatibility_report.dart';
import 'package:fish_ai/models/fish.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'model_provider.dart';
import '../prompts/fish_compatibility_prompt.dart';
import '../utils/tank_harmony_calculator.dart';
import '../utils/json_utils.dart';
import '../services/fish_data_service.dart';
import '../utils/cancellable_completer.dart';
import '../utils/openai_retry_helper.dart';
import '../utils/api_error_handler.dart';

// Helper function to safely parse compatible fish array from AI response
List<String> parseCompatibleFish(dynamic compatibleFishData) {
  if (compatibleFishData == null) return [];
  
  if (compatibleFishData is List) {
    return compatibleFishData.map((item) {
      if (item is String) {
        // Direct string in array
        return item;
      } else if (item is Map<String, dynamic> && item['name'] is String) {
        // Object with name property
        return item['name'] as String;
      } else {
        // Fallback: convert to string
        return item.toString();
      }
    }).toList();
  } else if (compatibleFishData is String) {
    // If it's a single string, split by comma or return as single item
    if (compatibleFishData.contains(',')) {
      return compatibleFishData.split(',').map((s) => s.trim()).toList();
    }
    return [compatibleFishData];
  }
  
  return [];
}

final fishCompatibilityProvider = NotifierProvider<FishCompatibilityNotifier,
    FishCompatibilityState>(FishCompatibilityNotifier.new);

class FishCompatibilityState {
  final AsyncValue<Map<String, List<Fish>>> fishData;
  final List<Fish> selectedFish;
  final CompatibilityReport? report;
  final CompatibilityReport? lastReport;
  final bool isLoading;
  final String? error;
  final bool isRetryable;
  final String? lastCategory;

  FishCompatibilityState({
    this.fishData = const AsyncValue.loading(),
    this.selectedFish = const [],
    this.report,
    this.lastReport,
    this.isLoading = false,
    this.error,
    this.isRetryable = false,
    this.lastCategory,
  });

  FishCompatibilityState copyWith({
    AsyncValue<Map<String, List<Fish>>>? fishData,
    List<Fish>? selectedFish,
    CompatibilityReport? report,
    CompatibilityReport? lastReport,
    bool? isLoading,
    String? error,
    bool? isRetryable,
    String? lastCategory,
    bool clearReport = false,
    bool clearLastReport = false,
    bool clearError = false,
  }) {
    return FishCompatibilityState(
      fishData: fishData ?? this.fishData,
      selectedFish: selectedFish ?? this.selectedFish,
      report: clearReport ? null : report ?? this.report,
      lastReport: clearLastReport ? null : lastReport ?? this.lastReport,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isRetryable: isRetryable ?? this.isRetryable,
      lastCategory: lastCategory ?? this.lastCategory,
    );
  }
}

class FishCompatibilityNotifier extends Notifier<FishCompatibilityState> {
  CancellableCompleter<dynamic>? _cancellableCompleter;

  @override
  FishCompatibilityState build() {
    // Use the centralized fish data provider instead of loading data directly
    final fishDataAsync = ref.watch(fishDataProvider);
    
    return FishCompatibilityState(
      fishData: fishDataAsync,
    );
  }

  void selectFish(Fish fish) {
    final newSelectedFish = List<Fish>.from(state.selectedFish);
    if (newSelectedFish.contains(fish)) {
      newSelectedFish.remove(fish);
    } else {
      newSelectedFish.add(fish);
    }
    state = state.copyWith(selectedFish: newSelectedFish, clearReport: true);
  }

  void clearSelection() {
    state = state.copyWith(selectedFish: [], clearReport: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true, isRetryable: false);
  }

  void clearLastReport() {
    state = state.copyWith(clearLastReport: true);
  }

  void cancel() {
    _cancellableCompleter?.cancel();
    state = state.copyWith(isLoading: false);
  }

  Future<void> retryCompatibilityReport() async {
    if (state.lastCategory != null && state.selectedFish.isNotEmpty) {
      await getCompatibilityReport(state.lastCategory!);
    }
  }
      


  Future<void> getCompatibilityReport(String category, {String? additionalNotes}) async {
    if (state.selectedFish.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      clearReport: true,
      clearError: true,
      lastCategory: category,
    );

    final models = ref.read(modelProvider);
    final harmonyScore = TankHarmonyCalculator.calculateHarmonyScore(state.selectedFish);
    final fishNames = state.selectedFish.map((f) => f.name).toList();
    // EDITED: The prompt no longer needs to generate the breakdown.
    final prompt = buildFishCompatibilityPrompt(category, fishNames, harmonyScore, additionalNotes: additionalNotes);

    _cancellableCompleter = CancellableCompleter();

    try {
      String? responseText;
      if (models.activeProvider == AIProvider.gemini) {
        if (models.geminiApiKey.isEmpty) {
          throw Exception('Gemini API Key not set. Please go to settings to add your API key.');
        }
        final model = GenerativeModel(model: models.geminiModel, apiKey: models.geminiApiKey);
        final response = await model.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 30));
        _cancellableCompleter?.complete(response);
        responseText = response.text;
      } else {
        if (models.openAIApiKey.isEmpty) {
          throw Exception('OpenAI API Key not set. Please go to settings to add your API key.');
        }
        final response = await OpenAIRetryHelper.generateWithRetry(
          modelName: models.chatGPTModel,
          prompt: prompt,
          expectJson: true,
        );
        _cancellableCompleter?.complete(response);
        responseText = response;
      }

      if (responseText == null) {
        throw Exception('Received no response from the AI service after multiple retries.');
      }

      final cleanedResponse = extractJson(responseText);
      final reportJson = json.decode(cleanedResponse);
      
      // EDITED: Generate the calculation breakdown string here.
      final calculationBreakdown = TankHarmonyCalculator.generateCalculationBreakdown(state.selectedFish);

      final report = CompatibilityReport(
        harmonyLabel: reportJson['harmonyLabel']?.toString() ?? 'Unknown',
        harmonySummary: reportJson['harmonySummary']?.toString() ?? '',
        detailedSummary: reportJson['detailedSummary']?.toString() ?? '',
        tankSize: reportJson['tankSize']?.toString() ?? 'Not specified',
        decorations: reportJson['decorations']?.toString() ?? '',
        careGuide: reportJson['careGuide']?.toString() ?? '',
        compatibleFish: parseCompatibleFish(reportJson['compatibleFish']),
        groupHarmonyScore: harmonyScore,
        selectedFish: state.selectedFish,
        tankMatesSummary: reportJson['tankMatesSummary']?.toString() ?? '',
        calculationBreakdown: calculationBreakdown, // Use the generated string.
      );
      state = state.copyWith(
          report: report, lastReport: report, isLoading: false);
    } catch (e) {
      if (!(_cancellableCompleter?.isCancelled ?? false)) {
        final userFriendlyError = _getFriendlyErrorMessage(e.toString());
        state = state.copyWith(
          error: userFriendlyError,
          isLoading: false,
          isRetryable: true,
        );
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    return ApiErrorHandler.getFriendlyErrorMessage(error);
  }
}
