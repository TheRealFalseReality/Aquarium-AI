import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:groq/groq.dart';

import '../models/analysis_result.dart';
import '../models/automation_script.dart';
import '../models/photo_analysis_result.dart';
import '../models/fish_info_result.dart';
import 'model_provider.dart';
import '../prompts/system_prompt.dart';
import '../prompts/water_analysis_prompt.dart';
import '../prompts/automation_script_prompt.dart';
import '../prompts/photo_analysis_prompt.dart';
import '../prompts/fish_info_prompt.dart';
import '../utils/json_utils.dart';
import '../utils/cancellable_completer.dart';
import '../utils/groq_helper.dart';
import '../utils/dev_rate_limiter.dart';
import '../utils/dev_limits.dart';

// ====================== Chat Message / State ======================
class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? followUpQuestions;
  final WaterAnalysisResult? analysisResult;
  final AutomationScript? automationScript;
  final PhotoAnalysisResult? photoAnalysisResult;
  final FishInfoResult? fishInfoResult;
  final Uint8List? photoBytes;
  final bool isError;
  final bool isRetryable;
  final String? originalMessage;
  final bool isAd;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.followUpQuestions,
    this.analysisResult,
    this.automationScript,
    this.photoAnalysisResult,
    this.fishInfoResult,
    this.photoBytes,
    this.isError = false,
    this.isRetryable = false,
    this.originalMessage,
    this.isAd = false,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final modelState = ref.watch(modelProvider);
  return ChatNotifier(modelState: modelState);
});

// ====================== Utility (now imported from json_utils.dart) ======================

// ====================== Chat Notifier ======================
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({required ModelState modelState})
      : _modelState = modelState,
        super(ChatState(messages: [])) {
    state = ChatState(messages: [
      ChatMessage(
        text:
            "# Welcome to Aquarium AI!\n\nAsk aquarium questions, run water analyses, generate automation scripts, or try the **Photo Analyzer** to identify fish and assess tank health.",
        isUser: false,
      ),
      ChatMessage(text: 'ad', isUser: false, isAd: true),
    ]);
    _initializeProvider();
  }

  final ModelState _modelState;
  ChatSession? _geminiChatSession;
  Groq? _groqChatSession;
  CancellableCompleter<dynamic>? _cancellable;
  Uint8List? _lastPhotoBytes;
  String? _lastPhotoNote;

  void _initializeProvider() {
    // Collect all distinct providers needed (text and image may be the same or different).
    // Each provider is initialized at most once even if selected for both roles.
    final selectedProviders = {_modelState.activeTextProvider, _modelState.activeImageProvider};
    if (selectedProviders.contains(AIProvider.gemini) && _modelState.geminiApiKey.isNotEmpty) {
      _initGeminiSession();
    }
    if (selectedProviders.contains(AIProvider.openAI) && _modelState.openAIApiKey.isNotEmpty) {
      OpenAI.apiKey = _modelState.openAIApiKey;
    }
    if (selectedProviders.contains(AIProvider.groq) && _modelState.hasGroqKey) {
      _initGroqSession();
    }
  }

  void _initGeminiSession() {
    if (_modelState.geminiApiKey.isEmpty) return;
    final model = GenerativeModel(
      model: _modelState.geminiModel,
      apiKey: _modelState.geminiApiKey,
    );
    _geminiChatSession = model.startChat(
      history: [Content.model([TextPart(systemPrompt)])],
    );
  }
  
  void _initGroqSession() {
    if (!_modelState.hasGroqKey) return;
    _groqChatSession = GroqHelper.createClient(
      apiKey: _modelState.effectiveGroqApiKey,
      model: _modelState.groqModel,
      systemPrompt: systemPrompt,
    );
  }


  void cancel() {
    _cancellable?.cancel();
    state = ChatState(messages: state.messages, isLoading: false);
  }

  // Returns the missing-key error message for the active text provider, or null if a key is set.
  String? _missingApiKeyError() {
    switch (_modelState.activeTextProvider) {
      case AIProvider.gemini:
        if (_modelState.geminiApiKey.isEmpty) return 'Gemini API Key is not set. Please add your key in Settings.';
        break;
      case AIProvider.openAI:
        if (_modelState.openAIApiKey.isEmpty) return 'OpenAI API Key is not set. Please add your key in Settings.';
        break;
      case AIProvider.groq:
        if (!_modelState.hasGroqKey) return 'Groq API Key is not set. Please add your key in Settings.';
        break;
    }
    return null;
  }

  // ================== Generic Chat ==================
  Future<void> sendMessage(String message) async {
    if (_modelState.usingDeveloperGroqKey) {
      final allowed = await DevRateLimiter.checkAndRecordRequest();
      if (!allowed) {
        final secs = await DevRateLimiter.secondsUntilNextSlot();
        return _handleError(
          '⏱️ Free-tier limit reached ($devMaxRequestsPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          message,
        );
      }
    }
    switch (_modelState.activeTextProvider) {
      case AIProvider.gemini:
        if (_modelState.geminiApiKey.isEmpty) return _handleError('Gemini API Key is not set.', message);
        return _sendGeminiMessage(message);
      case AIProvider.openAI:
        if (_modelState.openAIApiKey.isEmpty) return _handleError('OpenAI API Key is not set.', message);
        return _sendOpenAIMessage(message);
      case AIProvider.groq:
        if (!_modelState.hasGroqKey) return _handleError('Groq API Key is not set.', message);
        return _sendGroqMessage(message);
    }
  }

  Future<void> retryMessage(String original) {
    switch (_modelState.activeTextProvider) {
      case AIProvider.gemini:
        return _sendGeminiMessage(original, isRetry: true);
      case AIProvider.openAI:
        return _sendOpenAIMessage(original, isRetry: true);
      case AIProvider.groq:
        return _sendGroqMessage(original, isRetry: true);
    }
  }

  Future<void> _sendGeminiMessage(String message, {bool isRetry = false}) async {
    if (_geminiChatSession == null) return _handleError('Gemini session not initialized. API key might be missing or invalid.', message);
    _prepareForSending(message, isRetry: isRetry);
    _cancellable = CancellableCompleter();
    try {
      final response = await _geminiChatSession!.sendMessage(Content.text(message)).timeout(const Duration(seconds: 30));
      _cancellable?.complete(response);
      if (response.text == null) throw Exception('No response received from Gemini');
      _processTextResponse(response.text!);
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) _handleError(e.toString(), message);
    }
  }

  Future<void> _sendOpenAIMessage(String message, {bool isRetry = false}) async {
    _prepareForSending(message, isRetry: isRetry);
    _cancellable = CancellableCompleter();
    try {
      // Limit history to the last 10 non-ad, non-error messages to reduce token usage.
      final allHistory = state.messages.where((m) => !m.isAd && !m.isError).toList();
      final recentHistory = allHistory.length > 10 ? allHistory.sublist(allHistory.length - 10) : allHistory;
      final history = recentHistory.map((m) => OpenAIChatCompletionChoiceMessageModel(
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(m.text)],
          role: m.isUser ? OpenAIChatMessageRole.user : OpenAIChatMessageRole.assistant,
        )).toList();

      final response = await OpenAI.instance.chat.create(
        model: _modelState.chatGPTModel,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)], role: OpenAIChatMessageRole.system),
          ...history,
        ],
      ).timeout(const Duration(seconds: 30));
      _cancellable?.complete(response);
      final responseText = response.choices.first.message.content?.first.text;
      if (responseText == null) throw Exception('No response received from OpenAI');
      _processTextResponse(responseText);
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) _handleError(e.toString(), message);
    }
  }

  Future<void> _sendGroqMessage(String message, {bool isRetry = false}) async {
    if (_groqChatSession == null) return _handleError('Groq session not initialized. API key might be missing or invalid.', message);
    _prepareForSending(message, isRetry: isRetry);
    _cancellable = CancellableCompleter();
    try {
      final response = await _groqChatSession!.sendMessage(message).timeout(const Duration(seconds: 30));
      _cancellable?.complete(response);
      final responseText = response.choices.first.message.content;
      _processTextResponse(responseText);
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) _handleError(e.toString(), message);
    }
  }
  
  // ================== Water Parameter Analysis ==================
  Future<WaterAnalysisResult?> analyzeWaterParameters(Map<String, String> params) async {
    final keyError = _missingApiKeyError();
    if (keyError != null) {
      final userMsg = 'Please analyze my water parameters.';
      await _handleError(keyError, userMsg);
      return null;
    }
    if (_modelState.usingDeveloperGroqKey) {
      final allowed = await DevRateLimiter.checkAndRecordRequest();
      if (!allowed) {
        final secs = await DevRateLimiter.secondsUntilNextSlot();
        final userMsg = 'Please analyze my water parameters.';
        await _handleError(
          '⏱️ Free-tier limit reached ($devMaxRequestsPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          userMsg,
        );
        return null;
      }
    }
    final userMsg = 'Please analyze my water parameters for my ${params['tankType']} tank.\n'
        'Temp: ${params['temp']}°${params['tempUnit']}'
        '${params['ph']!.isNotEmpty ? ', pH: ${params['ph']}' : ''}'
        '${params['salinity']!.isNotEmpty ? ', Salinity: ${params['salinity']} ${params['salinityUnit']}' : ''}'
        '${params['additionalInfo']!.isNotEmpty ? ', Additional Info: ${params['additionalInfo']}' : ''}';
    _prepareForSending(userMsg);
    final prompt = buildWaterAnalysisPrompt(
      tankType: params['tankType']!,
      ph: params['ph']!,
      temp: params['temp']!,
      salinity: params['salinity']!,
      additionalInfo: params['additionalInfo']!,
      tempUnit: params['tempUnit']!,
      salinityUnit: params['salinityUnit']!,
    );
    try {
      final responseText = await _generateContent(prompt, expectJson: true);
      final decoded = json.decode(extractJson(responseText));
      final result = WaterAnalysisResult.fromJson(decoded);
      state = ChatState(messages: [...state.messages, ChatMessage(text: 'Here is your water analysis:', isUser: false, analysisResult: result)], isLoading: false);
      return result;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) _handleError(e.toString(), userMsg);
      return null;
    }
  }

  // ================== Automation Script ==================
  Future<AutomationScript?> generateAutomationScript(String description) async {
    final keyError = _missingApiKeyError();
    if (keyError != null) {
      await _handleError(keyError, 'Generate an automation script.');
      return null;
    }
    if (_modelState.usingDeveloperGroqKey) {
      final allowed = await DevRateLimiter.checkAndRecordRequest();
      if (!allowed) {
        final secs = await DevRateLimiter.secondsUntilNextSlot();
        await _handleError(
          '⏱️ Free-tier limit reached ($devMaxRequestsPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          'Generate an automation script.',
        );
        return null;
      }
    }
    final userMsg = 'Generate an automation script for: "$description"';
    _prepareForSending(userMsg);
    final prompt = buildAutomationScriptPrompt(description);
    try {
      final responseText = await _generateContent(prompt, expectJson: true);
      final decoded = json.decode(extractJson(responseText));
      final script = AutomationScript.fromJson(decoded);
      state = ChatState(messages: [...state.messages, ChatMessage(text: 'Here is your automation script:', isUser: false, automationScript: script)], isLoading: false);
      return script;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) _handleError(e.toString(), userMsg);
      return null;
    }
  }

  // ================== Fish Info ==================
  Future<FishInfoResult?> getFishInfo({
    required String fishNames,
    String? tankSize,
    String? additionalNotes,
  }) async {
    final keyError = _missingApiKeyError();
    if (keyError != null) {
      await _handleError(keyError, 'Look up fish info: $fishNames.');
      return null;
    }
    if (_modelState.usingDeveloperGroqKey) {
      final allowed = await DevRateLimiter.checkAndRecordRequest();
      if (!allowed) {
        final secs = await DevRateLimiter.secondsUntilNextSlot();
        await _handleError(
          '⏱️ Free-tier limit reached ($devMaxRequestsPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          'Look up fish info: $fishNames.',
        );
        return null;
      }
    }
    final userMsg = 'Give me comprehensive information about: $fishNames'
        '${tankSize != null && tankSize.isNotEmpty ? ' (tank size: $tankSize)' : ''}'
        '${additionalNotes != null && additionalNotes.isNotEmpty ? '. Notes: $additionalNotes' : ''}.';
    _prepareForSending(userMsg);
    final prompt = buildFishInfoPrompt(
      fishNames: fishNames,
      tankSize: tankSize,
      additionalNotes: additionalNotes,
    );
    try {
      final responseText = await _generateContent(prompt, expectJson: true);
      final parsed = FishInfoResult.tryParseJson(extractJson(responseText));
      if (parsed == null) throw const FormatException('Malformed JSON from AI fish info.');
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: '🐟 Fish info lookup complete. Tap to view detailed results.',
            isUser: false,
            fishInfoResult: parsed,
          ),
        ],
        isLoading: false,
      );
      return parsed;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) _handleError(e.toString(), userMsg);
      return null;
    }
  }

  // ================== Photo Analysis ==================
  Future<PhotoAnalysisResult?> analyzePhoto({required Uint8List imageBytes, String? userNote, String mimeType = 'image/jpeg', bool isRegeneration = false}) async {
    // Check rate limits before showing the loading state, so the user sees the
    // error as a chat message rather than a silent failure.
    if (_modelState.usingDeveloperGroqKey) {
      // Per-minute request limit checked first — no quota consumed if this fails.
      final reqAllowed = await DevRateLimiter.checkAndRecordRequest();
      if (!reqAllowed) {
        final secs = await DevRateLimiter.secondsUntilNextSlot();
        state = ChatState(
          messages: [
            ...state.messages,
            ChatMessage(
              text: '⏱️ **Free-tier limit reached** ($devMaxRequestsPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
              isUser: false,
              isError: true,
              isRetryable: true,
              originalMessage: 'Retry photo analysis${userNote?.isNotEmpty == true ? ': $userNote' : ''}',
              photoBytes: imageBytes,
            ),
          ],
          isLoading: false,
        );
        return null;
      }
      // Daily photo limit (only for new analyses, not regenerations)
      if (!isRegeneration) {
        final photoAllowed = await DevRateLimiter.checkAndRecordPhotoAnalysis();
        if (!photoAllowed) {
          state = ChatState(
            messages: [
              ...state.messages,
              ChatMessage(
                text: '📸 **Daily Photo Limit Reached**\n\nFree tier allows $devMaxPhotoAnalysesPerDay photo ${devMaxPhotoAnalysesPerDay == 1 ? 'analysis' : 'analyses'} per day. Add your own Groq API key in Settings for unlimited access.',
                isUser: false,
                isError: true,
                isRetryable: false,
              ),
            ],
            isLoading: false,
          );
          return null;
        }
      }
    }
    final note = (userNote?.trim().isNotEmpty ?? false) ? 'User note: ${userNote!.trim()}' : 'No additional user note.';
    if (!isRegeneration) {
      state = ChatState(messages: [...state.messages, ChatMessage(text: '📷 Submitted an aquarium photo for AI analysis.\n\n$note', isUser: true, photoBytes: imageBytes)], isLoading: true);
    } else {
      state = ChatState(messages: state.messages, isLoading: true);
    }
    final prompt = buildPhotoAnalysisPrompt(note);
    final originalMessage = 'Retry photo analysis${userNote?.isNotEmpty == true ? ': $userNote' : ''}';
    try {
      final responseText = await _generateContentWithImage(prompt, imageBytes, mimeType);
      final parsed = PhotoAnalysisResult.tryParseJson(extractJson(responseText));
      if (parsed == null) throw const FormatException('Malformed JSON from AI photo analysis.');
      _lastPhotoBytes = imageBytes;
      _lastPhotoNote = userNote;
      state = ChatState(
        messages: [...state.messages, ChatMessage(text: isRegeneration ? '🖼️ Photo analysis regenerated.' : '🖼️ Photo analysis complete. Tap to view detailed results.', isUser: false, photoAnalysisResult: parsed, photoBytes: imageBytes)],
        isLoading: false,
      );
      return parsed;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        final msg = _getPhotoError(e.toString());
        state = ChatState(messages: [...state.messages, ChatMessage(text: msg, isUser: false, isError: true, isRetryable: true, originalMessage: originalMessage, photoBytes: imageBytes)], isLoading: false);
      }
      return null;
    }
  }

  Future<PhotoAnalysisResult?> regeneratePhotoAnalysis() {
    if (_lastPhotoBytes == null) {
      state = ChatState(messages: [...state.messages, ChatMessage(text: '⚠️ No previous photo available to regenerate. Please upload a photo first.', isUser: false)]);
      return Future.value(null);
    }
    return analyzePhoto(imageBytes: _lastPhotoBytes!, userNote: _lastPhotoNote, isRegeneration: true);
  }

  // ================== Unified Content Generation ==================
  Future<String> _generateContent(String prompt, {bool expectJson = false}) async {
    _cancellable = CancellableCompleter();
    try {
      String? responseText;
      switch (_modelState.activeTextProvider) {
        case AIProvider.gemini:
          final model = GenerativeModel(model: _modelState.geminiModel, apiKey: _modelState.geminiApiKey);
          final response = await model.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 30));
          _cancellable?.complete(response);
          responseText = response.text;
          break;
        case AIProvider.openAI:
          final response = await OpenAI.instance.chat.create(
            model: _modelState.chatGPTModel,
            responseFormat: expectJson ? {"type": "json_object"} : null,
            messages: [OpenAIChatCompletionChoiceMessageModel(content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)], role: OpenAIChatMessageRole.user)],
          ).timeout(const Duration(seconds: 30));
          _cancellable?.complete(response);
          responseText = response.choices.first.message.content?.first.text;
          break;
        case AIProvider.groq:
           final groq = GroqHelper.createClient(
             apiKey: _modelState.effectiveGroqApiKey,
             model: _modelState.groqModel,
           );
           final response = await groq.sendMessage(prompt).timeout(const Duration(seconds: 30));
           _cancellable?.complete(response);
           responseText = response.choices.first.message.content;
           break;
      }
      if (responseText == null) throw Exception('Received no response from the AI service.');
      return responseText;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _generateContentWithImage(String prompt, Uint8List imageBytes, String mimeType) async {
    _cancellable = CancellableCompleter();
    try {
      String? responseText;
      switch (_modelState.activeImageProvider) {
        case AIProvider.gemini:
          final model = GenerativeModel(model: _modelState.geminiImageModel, apiKey: _modelState.geminiApiKey);
          final content = [Content.multi([DataPart(mimeType, imageBytes), TextPart(prompt)])];
          final response = await model.generateContent(content).timeout(const Duration(seconds: 55));
          _cancellable?.complete(response);
          responseText = response.text;
          break;
        case AIProvider.openAI:
          final base64Image = base64Encode(imageBytes);
          final response = await OpenAI.instance.chat.create(
            model: _modelState.chatGPTImageModel,
            responseFormat: {"type": "json_object"},
            messages: [OpenAIChatCompletionChoiceMessageModel(role: OpenAIChatMessageRole.user, content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
                OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl("data:$mimeType;base64,$base64Image"),
              ])],
          ).timeout(const Duration(seconds: 55));
          _cancellable?.complete(response);
          responseText = response.choices.first.message.content?.first.text;
          break;
        case AIProvider.groq:
          final base64Image = base64Encode(imageBytes);
          final responseGroq = await GroqHelper.generateWithImage(
            apiKey: _modelState.effectiveGroqApiKey,
            model: _modelState.groqImageModel,
            prompt: prompt,
            base64Image: base64Image,
            mimeType: mimeType,
          );
          _cancellable?.complete();
          responseText = responseGroq;
          break;
      }
      if (responseText == null) throw Exception('Received no response from the AI service.');
      return responseText;
    } catch (e) {
      rethrow;
    }
  }

  // ================== Helpers & Error Handling ==================
  void _prepareForSending(String message, {bool isRetry = false}) {
    final currentMessages = state.messages.where((m) => !m.isAd).toList();
    if (!isRetry) {
      state = ChatState(messages: [...currentMessages, ChatMessage(text: message, isUser: true)], isLoading: true);
    } else {
      state = ChatState(messages: currentMessages, isLoading: true);
    }
  }

  void _processTextResponse(String responseText) {
    String mainResponse = responseText;
    List<String> followUps = [];
    try {
      final reg = RegExp(r'{\s*"follow_ups"\s*:\s*\[.*?\]\s*}', dotAll: true);
      final m = reg.firstMatch(responseText);
      if (m != null) {
        var jsonString = m.group(0);
        if (jsonString != null) {
          mainResponse = responseText.replaceFirst(jsonString, '').trim();
          jsonString = jsonString.replaceAll(RegExp(r',\s*\]'), ']');
          final decoded = json.decode(jsonString);
          if (decoded['follow_ups'] is List) {
            followUps = List<String>.from(decoded['follow_ups']);
          }
        }
      }
    } catch (_) {}
    state = ChatState(messages: [...state.messages, ChatMessage(text: mainResponse, isUser: false, followUpQuestions: followUps)], isLoading: false);
  }

  Future<void> _handleError(String error, String originalMessage) async {
    final msg = '⚠️ **An Unexpected Error Occurred**\n\n$error';
    state = ChatState(messages: [...state.messages, ChatMessage(text: msg, isUser: false, isError: true, isRetryable: true, originalMessage: originalMessage)], isLoading: false);
  }

  String _getPhotoError(String err) {
    if (err.contains('FormatException') || err.contains('json')) return '🖼️ **Photo Analysis JSON Error**\n\nI got something back but could not parse it. Please retry.';
    if (err.contains('network') || err.contains('connection')) return '🔌 **Connection Issue**\n\nCould not reach the photo analysis service.';
    return '⚠️ **Photo Analysis Error**\n\n${err.split('\n').first}';
  }
}
