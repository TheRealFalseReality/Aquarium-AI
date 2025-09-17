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
import 'model_provider.dart';
import '../prompts/system_prompt.dart';
import '../prompts/water_analysis_prompt.dart';
import '../prompts/automation_script_prompt.dart';
import '../prompts/photo_analysis_prompt.dart';

// ====================== Cancellable Helper ======================
class CancellableCompleter<T> {
  final Completer<T> _completer = Completer<T>();
  bool _isCancelled = false;

  Future<T> get future => _completer.future;
  bool get isCancelled => _isCancelled;

  void complete(FutureOr<T> value) {
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  void completeError(Object error, [StackTrace? stack]) {
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.completeError(error, stack);
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

// ====================== Chat Message / State ======================
class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? followUpQuestions;
  final WaterAnalysisResult? analysisResult;
  final AutomationScript? automationScript;
  final PhotoAnalysisResult? photoAnalysisResult;
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

// ====================== Utility ======================
String _extractJson(String text) {
  final regExp = RegExp(r'```json\s*([\s\S]*?)\s*```');
  final match = regExp.firstMatch(text);
  if (match != null) {
    return match.group(1) ?? text.trim();
  }
  try {
     json.decode(text);
     return text;
  } catch(e) {
    return text;
  }
}

// ====================== Chat Notifier ======================
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({required ModelState modelState})
      : _modelState = modelState,
        super(ChatState(messages: [])) {
    state = ChatState(messages: [
      ChatMessage(
        text:
            "# Welcome to Fish.AI!\n\nAsk aquarium questions, run water analyses, generate automation scripts, or try the **Photo Analyzer** to identify fish and assess tank health.",
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
    switch (_modelState.activeProvider) {
      case AIProvider.gemini:
        if (_modelState.geminiApiKey.isNotEmpty) _initGeminiSession();
        break;
      case AIProvider.openAI:
        if (_modelState.openAIApiKey.isNotEmpty) OpenAI.apiKey = _modelState.openAIApiKey;
        break;
      case AIProvider.groq:
        if (_modelState.groqApiKey.isNotEmpty) _initGroqSession();
        break;
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
    if (_modelState.groqApiKey.isEmpty) return;
    final groq = Groq(apiKey: _modelState.groqApiKey, model: _modelState.groqModel);
    groq.startChat();
    groq.setCustomInstructionsWith(systemPrompt);
    _groqChatSession = groq;
  }


  void cancel() {
    _cancellable?.cancel();
    state = ChatState(messages: state.messages, isLoading: false);
  }

  // ================== Generic Chat ==================
  Future<void> sendMessage(String message) {
    switch (_modelState.activeProvider) {
      case AIProvider.gemini:
        if (_modelState.geminiApiKey.isEmpty) return _handleError('Gemini API Key is not set.', message);
        return _sendGeminiMessage(message);
      case AIProvider.openAI:
        if (_modelState.openAIApiKey.isEmpty) return _handleError('OpenAI API Key is not set.', message);
        return _sendOpenAIMessage(message);
      case AIProvider.groq:
        if (_modelState.groqApiKey.isEmpty) return _handleError('Groq API Key is not set.', message);
        return _sendGroqMessage(message);
    }
  }

  Future<void> retryMessage(String original) {
    switch (_modelState.activeProvider) {
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
      final history = state.messages.where((m) => !m.isAd && !m.isError).map((m) => OpenAIChatCompletionChoiceMessageModel(
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
      if (responseText == null) throw Exception('No response received from Groq');
      _processTextResponse(responseText);
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) _handleError(e.toString(), message);
    }
  }
  
  // ================== Water Parameter Analysis ==================
  Future<WaterAnalysisResult?> analyzeWaterParameters(Map<String, String> params) async {
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
      final decoded = json.decode(_extractJson(responseText));
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
    final userMsg = 'Generate an automation script for: "$description"';
    _prepareForSending(userMsg);
    final prompt = buildAutomationScriptPrompt(description);
    try {
      final responseText = await _generateContent(prompt, expectJson: true);
      final decoded = json.decode(_extractJson(responseText));
      final script = AutomationScript.fromJson(decoded);
      state = ChatState(messages: [...state.messages, ChatMessage(text: 'Here is your automation script:', isUser: false, automationScript: script)], isLoading: false);
      return script;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) _handleError(e.toString(), userMsg);
      return null;
    }
  }

  // ================== Photo Analysis ==================
  Future<PhotoAnalysisResult?> analyzePhoto({required Uint8List imageBytes, String? userNote, String mimeType = 'image/jpeg', bool isRegeneration = false}) async {
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
      final parsed = PhotoAnalysisResult.tryParseJson(_extractJson(responseText));
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
      switch (_modelState.activeProvider) {
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
           final groq = Groq(apiKey: _modelState.groqApiKey, model: _modelState.groqModel);
           groq.startChat(); 
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
      switch (_modelState.activeProvider) {
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
          // Construct a message with multiple parts, similar to OpenAI
          final groqMessage = '''
            $prompt
            Image data: data:$mimeType;base64,$base64Image
          ''';
          final groq = Groq(apiKey: _modelState.groqApiKey, model: _modelState.groqImageModel);
          groq.startChat();
          final response = await groq.sendMessage(groqMessage).timeout(const Duration(seconds: 55));
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