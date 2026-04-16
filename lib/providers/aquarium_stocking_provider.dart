import 'dart:async';
import 'dart:convert';

import 'package:fish_ai/models/fish.dart';
import 'package:fish_ai/models/stocking_recommendation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/analysis_history_entry.dart';
import '../models/tank.dart';
import '../prompts/stocking_recommendation_prompt.dart';
import '../prompts/tank_stocking_recommendation_prompt.dart';
import '../services/app_check_service.dart';
import '../services/groq_proxy_service.dart';
import '../services/remote_config_service.dart';
import '../utils/ai_language_utils.dart';
import '../utils/api_error_handler.dart';
import '../utils/dev_rate_limiter.dart';
import '../utils/groq_helper.dart';
import '../utils/json_utils.dart';
import '../utils/openai_retry_helper.dart';
import '../utils/tank_harmony_calculator.dart';
import 'analysis_history_provider.dart';
import 'app_settings_provider.dart';
import 'fish_compatibility_provider.dart';
import 'model_provider.dart';
import 'purchase_provider.dart' show isFounderProvider;

class AquariumStockingState {
  final bool isLoading;
  final List<StockingRecommendation>? recommendations;
  final List<StockingRecommendation>? lastRecommendations;
  final String? error;
  final bool isApiKeyError;
  final bool isRetryable;
  final bool isRateLimitError;
  final bool isQuotaError;
  final bool isNetworkError;
  final List<Fish> selectedFish;

  AquariumStockingState({
    this.isLoading = false,
    this.recommendations,
    this.lastRecommendations,
    this.error,
    this.isApiKeyError = false,
    this.isRetryable = false,
    this.isRateLimitError = false,
    this.isQuotaError = false,
    this.isNetworkError = false,
    this.selectedFish = const [],
  });

  AquariumStockingState copyWith({
    bool? isLoading,
    List<StockingRecommendation>? recommendations,
    List<StockingRecommendation>? lastRecommendations,
    String? error,
    bool? isApiKeyError,
    bool? isRetryable,
    bool? isRateLimitError,
    bool? isQuotaError,
    bool? isNetworkError,
    List<Fish>? selectedFish,
    bool clearError = false,
    bool clearRecommendation = false,
  }) {
    return AquariumStockingState(
      isLoading: isLoading ?? this.isLoading,
      recommendations: clearRecommendation
          ? null
          : recommendations ?? this.recommendations,
      lastRecommendations: lastRecommendations ?? this.lastRecommendations,
      error: clearError ? null : error ?? this.error,
      isApiKeyError: clearError ? false : isApiKeyError ?? this.isApiKeyError,
      isRetryable: clearError ? false : isRetryable ?? this.isRetryable,
      isRateLimitError:
          clearError ? false : isRateLimitError ?? this.isRateLimitError,
      isQuotaError: clearError ? false : isQuotaError ?? this.isQuotaError,
      isNetworkError: clearError ? false : isNetworkError ?? this.isNetworkError,
      selectedFish: selectedFish ?? this.selectedFish,
    );
  }
}

class AquariumStockingNotifier extends StateNotifier<AquariumStockingState> {
  final Ref ref;

  AquariumStockingNotifier(this.ref) : super(AquariumStockingState());

  void cancel() {
    state = state.copyWith(isLoading: false, clearError: true);
  }

  void selectFish(Fish fish) {
    final newSelectedFish = List<Fish>.from(state.selectedFish);
    if (newSelectedFish.contains(fish)) {
      newSelectedFish.remove(fish);
    } else {
      newSelectedFish.add(fish);
    }
    state = state.copyWith(selectedFish: newSelectedFish);
  }

  void clearSelectedFish() {
    state = state.copyWith(selectedFish: []);
  }

  void clearRecommendations() {
    state = state.copyWith(clearRecommendation: true);
  }

  Future<void> getStockingRecommendations({
    required String tankSize,
    required String tankType,
    required String userNotes,
    Map<String, List<String>>? speciesSelections,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearRecommendation: true,
    );

    final fishDataAsync = ref.read(fishCompatibilityProvider).fishData;
    if (fishDataAsync.isLoading) {
      state = state.copyWith(
        error:
            'Fish data is still loading, please wait a moment and try again.',
        isLoading: false,
      );
      return;
    }
    final fishData = fishDataAsync.asData?.value;
    if (fishData == null) {
      state = state.copyWith(
        error: 'Fish data is unavailable. Cannot generate recommendations.',
        isLoading: false,
      );
      return;
    }
    final models = ref.read(modelProvider);
    final settings = ref.read(appSettingsProvider);
    final allFish = fishData[tankType] ?? [];

    if (allFish.isEmpty) {
      state = state.copyWith(
        error: 'No fish data available for the selected tank type.',
        isLoading: false,
      );
      return;
    }

    // Check dev rate limit before consuming the API
    if (models.usingDeveloperGroqKeyForText) {
      final isFounder = ref.read(isFounderProvider);
      final maxPerMin = isFounder
          ? RemoteConfigService.founderMaxRequestsPerMinute
          : RemoteConfigService.maxRequestsPerMinute;
      final maxPerDay = isFounder
          ? RemoteConfigService.founderMaxRequestsPerDay
          : RemoteConfigService.maxRequestsPerDay;
      final result = await DevRateLimiter.checkAndRecordRequest(
        isFounder: isFounder,
      );
      if (result == DevRateLimitResult.minuteLimitReached) {
        final secs = await DevRateLimiter.secondsUntilNextSlot(
          isFounder: isFounder,
        );
        state = state.copyWith(
          error:
              '⏱️ Free-tier limit reached ($maxPerMin requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          isLoading: false,
          isRateLimitError: true,
        );
        return;
      } else if (result == DevRateLimitResult.dailyLimitReached) {
        state = state.copyWith(
          error:
              '📅 Daily free-tier limit reached ($maxPerDay requests/day). Come back tomorrow or add your own Groq API key in Settings.',
          isLoading: false,
          isRateLimitError: true,
        );
        return;
      }
    }
    final processedTankSize = _processTankSize(tankSize);
    final prompt = appendAiContextInstructions(
      buildStockingRecommendationPrompt(
        processedTankSize,
        tankType,
        userNotes,
        allFish,
        selectedFish: state.selectedFish,
        speciesSelections: speciesSelections,
      ),
      aiResponseLanguage: settings.aiResponseLanguage,
      localeCode: settings.localeCode,
      experienceLevel: settings.userExperienceLevel,
    );

    // Trigger reCAPTCHA v3 App Check verification on web before the AI call.
    await AppCheckService.requestToken();

    try {
      String? responseText;
      if (models.activeProvider == AIProvider.gemini) {
        if (models.geminiApiKey.isEmpty) {
          throw Exception(
            'Gemini API Key not set. Please go to settings to add your API key.',
          );
        }
        final model = GenerativeModel(
          model: models.geminiModel,
          apiKey: models.geminiApiKey,
        );
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 45));
        responseText = response.text;
      } else if (models.activeProvider == AIProvider.openAI) {
        if (models.openAIApiKey.isEmpty) {
          throw Exception(
            'OpenAI API Key not set. Please go to settings to add your API key.',
          );
        }
        responseText = await OpenAIRetryHelper.generateWithRetry(
          modelName: models.chatGPTModel,
          prompt: prompt,
          expectJson: true,
          timeout: const Duration(seconds: 45),
        );
      } else if (models.activeProvider == AIProvider.groq) {
        if (!models.hasGroqKey) {
          throw Exception(
            'Groq API Key not set. Please go to settings to add your API key.',
          );
        }
        if (models.usingDeveloperGroqKeyForText) {
          responseText = await GroqProxyService.sendMessage(
            model: models.freeGroqTextModel(ref.read(isFounderProvider)),
            prompt: prompt,
          ).timeout(const Duration(seconds: 45));
        } else {
          final groq = GroqHelper.createClient(
            apiKey: models.effectiveGroqApiKey,
            model: models.groqModel,
          );
          final response = await groq
              .sendMessage(prompt)
              .timeout(const Duration(seconds: 45));
          responseText = response.choices.first.message.content;
        }
      }

      if (responseText == null) {
        throw Exception(
          'Received no response from the AI service after multiple retries.',
        );
      }

      final cleanedResponse = extractJson(responseText);
      final recommendationsJson =
          json.decode(cleanedResponse) as Map<String, dynamic>;

      final List<StockingRecommendation> allGeneratedRecs = [];
      final recommendationList = recommendationsJson['recommendations'] as List;

      for (var rec in recommendationList) {
        final coreFishNames = List<String>.from(rec['coreFish']);
        final otherFishNames = List<String>.from(rec['otherDataBasedFish']);

        final coreFish = allFish
            .where((fish) => coreFishNames.contains(fish.name))
            .toList();
        final otherFish = allFish
            .where((fish) => otherFishNames.contains(fish.name))
            .toList();

        if (coreFish.isNotEmpty) {
          final harmonyScore = TankHarmonyCalculator.calculateHarmonyScore(
            coreFish,
          );
          allGeneratedRecs.add(
            StockingRecommendation(
              title: rec['title'],
              summary: rec['summary'],
              coreFish: coreFish,
              otherDataBasedFish: otherFish,
              aiTankMatesSummary: rec['aiTankMatesSummary'],
              aiRecommendedTankMates: List<String>.from(
                rec['aiRecommendedTankMates'],
              ),
              harmonyScore: harmonyScore,
            ),
          );
        }
      }

      allGeneratedRecs.sort((a, b) => b.harmonyScore.compareTo(a.harmonyScore));

      List<StockingRecommendation> finalRecs = [];
      finalRecs.addAll(allGeneratedRecs.where((r) => r.harmonyScore >= 0.8));

      if (finalRecs.length < 3 && allGeneratedRecs.length > finalRecs.length) {
        var remainingRecs = allGeneratedRecs
            .where((r) => !finalRecs.contains(r))
            .toList();
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
        // Save to analysis history
        final typeLabel = tankType.isNotEmpty ? tankType : 'Tank';
        ref
            .read(analysisHistoryProvider.notifier)
            .addEntry(
              AnalysisHistoryEntry.create(
                type: AnalysisType.stockingRecommendation,
                title:
                    'Stocking: $typeLabel ${processedTankSize.isNotEmpty ? '($processedTankSize)' : ''}'
                        .trim(),
                resultData: {
                  'recommendations': finalRecs.map((r) => r.toJson()).toList(),
                  'tankSize': tankSize,
                  'tankType': tankType,
                  'userNotes': userNotes,
                },
              ),
            );
      } else {
        state = state.copyWith(
          error:
              'Could not generate a valid recommendation for your criteria. Try adjusting the notes or tank size.',
          isLoading: false,
        );
      }
    } catch (e) {
      final errorStr = e.toString();
      final isApiKeyErr = ApiErrorHandler.isApiKeyError(errorStr);
      final isQuotaErr = ApiErrorHandler.isQuotaError(errorStr);
      final isNetworkErr = ApiErrorHandler.isNetworkError(errorStr);
      if (!isApiKeyErr && models.usingDeveloperGroqKeyForText) {
        await DevRateLimiter.undoLastRequest();
      }
      final errorMessage = ApiErrorHandler.getFriendlyErrorMessage(errorStr);
      state = state.copyWith(
        error: errorMessage,
        isApiKeyError: isApiKeyErr,
        isRetryable: !isApiKeyErr && !isQuotaErr,
        isQuotaError: isQuotaErr,
        isNetworkError: isNetworkErr,
        isLoading: false,
      );
    }
  }

  Future<void> getTankStockingRecommendations({
    required Tank tank,
    String additionalNotes = '',
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearRecommendation: true,
    );

    if (tank.inhabitants.isEmpty) {
      state = state.copyWith(
        error:
            'Tank has no existing inhabitants. Use the regular stocking tool for empty tanks.',
        isLoading: false,
      );
      return;
    }

    final fishDataAsync = ref.read(fishCompatibilityProvider).fishData;
    if (fishDataAsync.isLoading) {
      state = state.copyWith(
        error:
            'Fish data is still loading, please wait a moment and try again.',
        isLoading: false,
      );
      return;
    }
    final fishData = fishDataAsync.asData?.value;
    if (fishData == null) {
      state = state.copyWith(
        error: 'Fish data is unavailable. Cannot generate recommendations.',
        isLoading: false,
      );
      return;
    }
    final models = ref.read(modelProvider);
    final settings = ref.read(appSettingsProvider);
    final allFish = fishData[tank.type] ?? [];
    if (allFish.isEmpty) {
      state = state.copyWith(
        error: 'No fish data available for the selected tank type.',
        isLoading: false,
      );
      return;
    }

    // Check dev rate limit before consuming the API
    if (models.usingDeveloperGroqKeyForText) {
      final isFounder = ref.read(isFounderProvider);
      final maxPerMin = isFounder
          ? RemoteConfigService.founderMaxRequestsPerMinute
          : RemoteConfigService.maxRequestsPerMinute;
      final maxPerDay = isFounder
          ? RemoteConfigService.founderMaxRequestsPerDay
          : RemoteConfigService.maxRequestsPerDay;
      final result = await DevRateLimiter.checkAndRecordRequest(
        isFounder: isFounder,
      );
      if (result == DevRateLimitResult.minuteLimitReached) {
        final secs = await DevRateLimiter.secondsUntilNextSlot(
          isFounder: isFounder,
        );
        state = state.copyWith(
          error:
              '⏱️ Free-tier limit reached ($maxPerMin requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          isLoading: false,
          isRateLimitError: true,
        );
        return;
      } else if (result == DevRateLimitResult.dailyLimitReached) {
        state = state.copyWith(
          error:
              '📅 Daily free-tier limit reached ($maxPerDay requests/day). Come back tomorrow or add your own Groq API key in Settings.',
          isLoading: false,
          isRateLimitError: true,
        );
        return;
      }
    }

    // Get existing fish from tank inhabitants
    final existingFish = <Fish>[];
    for (final inhabitant in tank.inhabitants) {
      // Prefer UUID-based lookup for renamed-fish resilience; fall back to name.
      final fish = (inhabitant.fishUuid != null
              ? allFish.where((f) => f.uuid == inhabitant.fishUuid).firstOrNull
              : null) ??
          allFish.firstWhere(
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
      // Add individual fish based on quantity for proper compatibility calculations
      for (int i = 0; i < inhabitant.quantity; i++) {
        existingFish.add(fish);
      }
    }

    if (existingFish.isEmpty) {
      state = state.copyWith(
        error:
            'Could not find fish data for tank inhabitants. Please check if fish names match the database.',
        isLoading: false,
      );
      return;
    }

    // Calculate current tank harmony score
    final currentHarmonyScore = TankHarmonyCalculator.calculateHarmonyScore(
      existingFish,
    );

    final prompt = appendAiContextInstructions(
      buildTankStockingRecommendationPrompt(
        tank,
        allFish,
        existingFish,
        currentHarmonyScore,
        additionalNotes: additionalNotes,
      ),
      aiResponseLanguage: settings.aiResponseLanguage,
      localeCode: settings.localeCode,
      experienceLevel: settings.userExperienceLevel,
    );

    // Trigger reCAPTCHA v3 App Check verification on web before the AI call.
    await AppCheckService.requestToken();

    try {
      String? responseText;
      if (models.activeProvider == AIProvider.gemini) {
        if (models.geminiApiKey.isEmpty) {
          throw Exception(
            'Gemini API Key not set. Please go to settings to add your API key.',
          );
        }
        final model = GenerativeModel(
          model: models.geminiModel,
          apiKey: models.geminiApiKey,
        );
        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 45));
        responseText = response.text;
      } else if (models.activeProvider == AIProvider.openAI) {
        if (models.openAIApiKey.isEmpty) {
          throw Exception(
            'OpenAI API Key not set. Please go to settings to add your API key.',
          );
        }
        responseText = await OpenAIRetryHelper.generateWithRetry(
          modelName: models.chatGPTModel,
          prompt: prompt,
          expectJson: true,
          timeout: const Duration(seconds: 45),
        );
      } else if (models.activeProvider == AIProvider.groq) {
        if (!models.hasGroqKey) {
          throw Exception(
            'Groq API Key not set. Please go to settings to add your API key.',
          );
        }
        if (models.usingDeveloperGroqKeyForText) {
          responseText = await GroqProxyService.sendMessage(
            model: models.freeGroqTextModel(ref.read(isFounderProvider)),
            prompt: prompt,
          ).timeout(const Duration(seconds: 45));
        } else {
          final groq = GroqHelper.createClient(
            apiKey: models.effectiveGroqApiKey,
            model: models.groqModel,
          );
          final response = await groq
              .sendMessage(prompt)
              .timeout(const Duration(seconds: 45));
          responseText = response.choices.first.message.content;
        }
      }

      if (responseText == null) {
        throw Exception(
          'Received no response from the AI service after multiple retries.',
        );
      }

      final cleanedResponse = extractJson(responseText);
      final recommendationsJson =
          json.decode(cleanedResponse) as Map<String, dynamic>;

      final List<StockingRecommendation> allGeneratedRecs = [];
      final recommendationList = recommendationsJson['recommendations'] as List;

      for (var rec in recommendationList) {
        final coreFishNames = List<String>.from(rec['coreFish']);
        final otherFishNames = List<String>.from(rec['otherDataBasedFish']);

        final coreFish = allFish
            .where((fish) => coreFishNames.contains(fish.name))
            .toList();
        final otherFish = allFish
            .where((fish) => otherFishNames.contains(fish.name))
            .toList();

        if (coreFish.isNotEmpty) {
          // Calculate harmony score including existing fish
          final allTankFish = [...existingFish, ...coreFish];
          final harmonyScore = TankHarmonyCalculator.calculateHarmonyScore(
            allTankFish,
          );

          allGeneratedRecs.add(
            StockingRecommendation(
              title: rec['title'],
              summary: rec['summary'],
              coreFish: coreFish,
              otherDataBasedFish: otherFish,
              aiTankMatesSummary: rec['aiTankMatesSummary'],
              aiRecommendedTankMates: List<String>.from(
                rec['aiRecommendedTankMates'],
              ),
              harmonyScore: harmonyScore,
              compatibilityNotes: rec['compatibilityNotes'],
              isAdditionRecommendation: true,
            ),
          );
        }
      }

      // Sort by harmony score (highest first)
      allGeneratedRecs.sort((a, b) => b.harmonyScore.compareTo(a.harmonyScore));

      List<StockingRecommendation> finalRecs = [];
      finalRecs.addAll(allGeneratedRecs.where((r) => r.harmonyScore >= 0.8));

      if (finalRecs.length < 3 && allGeneratedRecs.length > finalRecs.length) {
        var remainingRecs = allGeneratedRecs
            .where((r) => !finalRecs.contains(r))
            .toList();
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
        // Save to analysis history
        ref
            .read(analysisHistoryProvider.notifier)
            .addEntry(
              AnalysisHistoryEntry.create(
                type: AnalysisType.stockingRecommendation,
                title: 'Tank Stocking: ${tank.name}',
                resultData: {
                  'recommendations': finalRecs.map((r) => r.toJson()).toList(),
                  'tankName': tank.name,
                  'tankType': tank.type,
                },
              ),
            );
      } else {
        state = state.copyWith(
          error:
              'Could not generate suitable additions for your tank. The existing inhabitants may be too restrictive.',
          isLoading: false,
        );
      }
    } catch (e) {
      final errorStr = e.toString();
      final isApiKeyErr = ApiErrorHandler.isApiKeyError(errorStr);
      final isQuotaErr = ApiErrorHandler.isQuotaError(errorStr);
      final isNetworkErr = ApiErrorHandler.isNetworkError(errorStr);
      if (!isApiKeyErr && models.usingDeveloperGroqKeyForText) {
        await DevRateLimiter.undoLastRequest();
      }
      final errorMessage = ApiErrorHandler.getFriendlyErrorMessage(errorStr);
      state = state.copyWith(
        error: errorMessage,
        isApiKeyError: isApiKeyErr,
        isRetryable: !isApiKeyErr && !isQuotaErr,
        isQuotaError: isQuotaErr,
        isNetworkError: isNetworkErr,
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

  // Note: extractJson is now imported from json_utils.dart
}

final aquariumStockingProvider =
    StateNotifierProvider<AquariumStockingNotifier, AquariumStockingState>(
      (ref) => AquariumStockingNotifier(ref),
    );
