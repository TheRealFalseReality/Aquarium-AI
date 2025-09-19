import 'dart:async';
import 'dart:convert';
import 'package:fish_ai/models/compatibility_report.dart';
import 'package:fish_ai/models/fish.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dart_openai/dart_openai.dart';
import 'model_provider.dart';
import '../prompts/fish_compatibility_prompt.dart';
import '../utils/tank_harmony_calculator.dart';

// Helper class for cancellable operations
class CancellableCompleter<T> {
  final Completer<T> _completer = Completer<T>();
  bool _isCancelled = false;

  Future<T> get future => _completer.future;
  bool get isCompleted => _completer.isCompleted;
  bool get isCancelled => _isCancelled;

  void complete([FutureOr<T>? value]) {
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }

  void cancel() {
    if (!_completer.isCompleted) {
      _isCancelled = true;
      _completer.completeError(CancelledException());
    }
  }
}

class CancelledException implements Exception {
  @override
  String toString() => 'Future was cancelled';
}

// Helper function to extract JSON from a markdown code block
String _extractJson(String text) {
  final regExp = RegExp(r'```json\s*([\s\S]*?)\s*```');
  final match = regExp.firstMatch(text);
  if (match != null) {
    return match.group(1) ?? text;
  }
  return text;
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
  Completer<void>? _dataLoadingCompleter;

  @override
  FishCompatibilityState build() {
    // Start loading fish data immediately
    _loadFishData();
    return FishCompatibilityState();
  }

  Future<void> _loadFishData() async {
    // Ensure state shows loading during the actual loading process
    state = state.copyWith(fishData: const AsyncValue.loading());
    _dataLoadingCompleter = Completer<void>();
    
    try {
      final jsonString =
          await rootBundle.loadString('assets/fishcompat.json');
      final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;
      final freshwater =
          (jsonResponse['freshwater'] as List).map((f) => Fish.fromJson(f)).toList();
      final marine =
          (jsonResponse['marine'] as List).map((f) => Fish.fromJson(f)).toList();
      state = state.copyWith(
          fishData: AsyncValue.data(
              {'freshwater': freshwater, 'marine': marine}));
      _dataLoadingCompleter?.complete();
    } catch (e, stackTrace) {
      state = state.copyWith(fishData: AsyncValue.error(e, stackTrace));
      _dataLoadingCompleter?.completeError(e, stackTrace);
    }
  }

  /// Wait for fish data to be loaded, with a timeout
  Future<void> waitForFishData({Duration timeout = const Duration(seconds: 10)}) async {
    if (!state.fishData.isLoading && state.fishData.hasValue) {
      return; // Already loaded
    }
    
    if (_dataLoadingCompleter != null && !_dataLoadingCompleter!.isCompleted) {
      try {
        await _dataLoadingCompleter!.future.timeout(timeout);
      } catch (e) {
        // Timeout or other error - let caller handle the still-loading state
      }
    }
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
        ).timeout(const Duration(seconds: 30));
        _cancellableCompleter?.complete(response);
        return response.choices.first.message.content?.first.text;
      } catch (e) {
        // Check the error message for rate limit indicators
        if (e.toString().contains('429') || e.toString().toLowerCase().contains('rate limit')) {
          retries++;
          if (retries >= maxRetries) {
            rethrow; // rethrow the exception if we've exhausted all retries
          }
          // Exponential backoff
          await Future.delayed(Duration(milliseconds: delay));
          delay *= 2; 
        } else {
          rethrow; // rethrow other exceptions immediately
        }
      }
    }
    return null;
  }

  Future<void> getCompatibilityReport(String category) async {
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
    final prompt = buildFishCompatibilityPrompt(category, fishNames, harmonyScore);

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
        responseText = await _generateOpenAIContentWithRetry(models.chatGPTModel, prompt);
      }

      if (responseText == null) {
        throw Exception('Received no response from the AI service after multiple retries.');
      }

      final cleanedResponse = _extractJson(responseText);
      final reportJson = json.decode(cleanedResponse);
      
      // EDITED: Generate the calculation breakdown string here.
      final calculationBreakdown = TankHarmonyCalculator.generateCalculationBreakdown(state.selectedFish);

      final report = CompatibilityReport(
        harmonyLabel: reportJson['harmonyLabel'],
        harmonySummary: reportJson['harmonySummary'],
        detailedSummary: reportJson['detailedSummary'],
        tankSize: reportJson['tankSize'],
        decorations: reportJson['decorations'],
        careGuide: reportJson['careGuide'],
        compatibleFish: List<String>.from(
          reportJson['compatibleFish'].map((f) => f['name']),
        ),
        groupHarmonyScore: harmonyScore,
        selectedFish: state.selectedFish,
        tankMatesSummary: reportJson['tankMatesSummary'],
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
    if (error.contains('429') || error.toLowerCase().contains('rate limit')) {
        return '️ **Rate Limit Reached**\n\nThe AI service is busy. Please try again in a moment.';
    }
    if (error.toLowerCase().contains('quota')) {
        return '️ **Quota Exceeded**\n\nYou have exceeded your OpenAI API quota. Please check your plan and billing details on the OpenAI website.';
    }
    return '⚠️ **An Unexpected Error Occurred**\n\n$error';
  }
}