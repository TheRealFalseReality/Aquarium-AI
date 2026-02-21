import 'dart:async';
import 'dart:convert';
import 'package:fish_ai/models/compatibility_report.dart';
import 'package:fish_ai/models/fish.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'model_provider.dart';
import '../models/analysis_history_entry.dart';
import 'analysis_history_provider.dart';
import '../prompts/fish_compatibility_prompt.dart';
import '../utils/tank_harmony_calculator.dart';
import '../utils/json_utils.dart';
import '../services/fish_data_service.dart';
import '../utils/cancellable_completer.dart';
import '../utils/openai_retry_helper.dart';
import '../utils/api_error_handler.dart';
import '../utils/groq_helper.dart';
import '../utils/dev_rate_limiter.dart';
import '../utils/dev_limits.dart';

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
  final bool isApiKeyError;
  final String? lastCategory;

  FishCompatibilityState({
    this.fishData = const AsyncValue.loading(),
    this.selectedFish = const [],
    this.report,
    this.lastReport,
    this.isLoading = false,
    this.error,
    this.isRetryable = false,
    this.isApiKeyError = false,
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
    bool? isApiKeyError,
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
      isRetryable: clearError ? false : isRetryable ?? this.isRetryable,
      isApiKeyError: clearError ? false : isApiKeyError ?? this.isApiKeyError,
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
    state = state.copyWith(clearError: true, isRetryable: false, isApiKeyError: false);
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

    // Check dev rate limit before consuming the API
    if (models.usingDeveloperGroqKey) {
      final allowed = await DevRateLimiter.checkAndRecordRequest();
      if (!allowed) {
        final secs = await DevRateLimiter.secondsUntilNextSlot();
        state = state.copyWith(
          error: '⏱️ Free-tier limit reached ($devMaxRequestsPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          isLoading: false,
        );
        return;
      }
    }

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
      } else if (models.activeProvider == AIProvider.groq) {
        if (!models.hasGroqKey) {
          throw Exception('Groq API Key not set. Please go to settings to add your API key.');
        }
        final groq = GroqHelper.createClient(
          apiKey: models.effectiveGroqApiKey,
          model: models.groqModel,
        );
        final response = await groq.sendMessage(prompt).timeout(const Duration(seconds: 30));
        _cancellableCompleter?.complete(response);
        responseText = response.choices.first.message.content;
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
      // Save to analysis history
      final fishNames = state.selectedFish.isNotEmpty
          ? state.selectedFish.map((f) => f.name).join(', ')
          : 'Selected Fish';
      ref.read(analysisHistoryProvider.notifier).addEntry(
        AnalysisHistoryEntry.create(
          type: AnalysisType.compatibilityReport,
          title: 'Compatibility – $fishNames',
          resultData: {
            'report': report.toJson(),
            'fishType': category,
          },
        ),
      );
    } catch (e) {
      if (!(_cancellableCompleter?.isCancelled ?? false)) {
        final isApiKeyErr = ApiErrorHandler.isApiKeyError(e.toString());
        // Rollback the rate-limit slot for real AI errors.
        if (!isApiKeyErr && models.usingDeveloperGroqKey) {
          await DevRateLimiter.undoLastRequest();
        }
        final userFriendlyError = _getFriendlyErrorMessage(e.toString());
        state = state.copyWith(
          error: userFriendlyError,
          isLoading: false,
          isRetryable: !isApiKeyErr,
          isApiKeyError: isApiKeyErr,
        );
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    return ApiErrorHandler.getFriendlyErrorMessage(error);
  }
}
