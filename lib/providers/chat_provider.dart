import 'dart:async';
import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/analysis_history_entry.dart';
import '../models/analysis_result.dart';
import '../models/automation_script.dart';
import '../models/fish_info_result.dart';
import '../models/photo_analysis_result.dart';
import '../prompts/aquapi_prompt.dart';
import '../prompts/automation_script_prompt.dart';
import '../prompts/fish_info_prompt.dart';
import '../prompts/photo_analysis_prompt.dart';
import '../prompts/water_analysis_prompt.dart';
import '../services/app_check_service.dart';
import '../services/groq_proxy_service.dart';
import '../services/remote_config_service.dart';
import '../utils/ai_language_utils.dart';
import '../utils/api_error_handler.dart';
import '../utils/cancellable_completer.dart';
import '../utils/dev_rate_limiter.dart';
import '../utils/groq_helper.dart';
import '../utils/json_utils.dart';
import 'analysis_history_provider.dart';
import 'app_settings_provider.dart';
import 'model_provider.dart';
import 'purchase_provider.dart' show isFounderProvider;

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
  final bool isApiKeyError;
  final bool isRateLimitError;
  final bool isQuotaError;
  final bool isNetworkError;
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
    this.isApiKeyError = false,
    this.isRateLimitError = false,
    this.isQuotaError = false,
    this.isNetworkError = false,
    this.originalMessage,
    this.isAd = false,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});
}

class PersistedChatMessage {
  final String text;
  final bool isUser;

  PersistedChatMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {'text': text, 'isUser': isUser};

  factory PersistedChatMessage.fromJson(Map<String, dynamic> json) {
    return PersistedChatMessage(
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
    );
  }
}

class SavedChatConversation {
  final String id;
  final String name;
  final String? tankId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PersistedChatMessage> messages;

  SavedChatConversation({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.tankId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (tankId != null) 'tankId': tankId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory SavedChatConversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = (json['messages'] as List?) ?? <dynamic>[];
    return SavedChatConversation(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Conversation',
      tankId: json['tankId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      messages: rawMessages
          .whereType<Map>()
          .map(
            (raw) => PersistedChatMessage.fromJson(
              (raw as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }

  SavedChatConversation copyWith({
    String? name,
    String? tankId,
    bool clearTankId = false,
    DateTime? updatedAt,
    List<PersistedChatMessage>? messages,
  }) {
    return SavedChatConversation(
      id: id,
      name: name ?? this.name,
      tankId: clearTankId ? null : (tankId ?? this.tankId),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

class ChatConversationSummary {
  final String id;
  final String name;
  final String? tankId;
  final DateTime updatedAt;
  final int messageCount;

  ChatConversationSummary({
    required this.id,
    required this.name,
    required this.tankId,
    required this.updatedAt,
    required this.messageCount,
  });
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final modelState = ref.watch(modelProvider);
  return ChatNotifier(modelState: modelState, ref: ref);
});

// ====================== Utility (now imported from json_utils.dart) ======================

// ====================== Chat Notifier ======================
class ChatNotifier extends StateNotifier<ChatState> {
  static const String _conversationsKey = 'chat_conversations_v1';
  static const String _activeConversationKey = 'active_chat_conversation_v1';
  static const String _defaultWelcomeText =
      "# Welcome to Aquarium AI!\n\nAsk aquarium questions, run water analyses, generate automation scripts, or try the **Photo Analyzer** to identify fish and assess tank health.";

  ChatNotifier({required ModelState modelState, required Ref ref})
    : _modelState = modelState,
      _ref = ref,
      super(ChatState(messages: [])) {
    state = ChatState(messages: _defaultMessages);
    final now = DateTime.now();
    final starter = SavedChatConversation(
      id: const Uuid().v4(),
      name: 'Current Chat',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
    _conversations = [starter];
    _activeConversationId = starter.id;
    _conversationStoreReady = true;
    _initializeProvider();
    unawaited(_loadConversationStore());
  }

  final ModelState _modelState;
  final Ref _ref;

  CancellableCompleter<dynamic>? _cancellable;
  Uint8List? _lastPhotoBytes;
  String? _lastPhotoNote;
  List<SavedChatConversation> _conversations = [];
  String? _activeConversationId;
  bool _conversationStoreReady = false;
  Timer? _saveConversationDebounce;

  List<ChatMessage> get _defaultMessages => [
    ChatMessage(
      text: _defaultWelcomeText,
      isUser: false,
    ),
    ChatMessage(text: 'ad', isUser: false, isAd: true),
  ];

  List<PersistedChatMessage> _persistableMessagesFromState() {
    return state.messages
        .where(
          (m) =>
              !m.isAd &&
              !m.isError &&
              m.text.trim().isNotEmpty &&
              m.text != _defaultWelcomeText,
        )
        .map((m) => PersistedChatMessage(text: m.text, isUser: m.isUser))
        .toList();
  }

  List<ChatMessage> _uiMessagesFromPersisted(List<PersistedChatMessage> messages) {
    if (messages.isEmpty) {
      return _defaultMessages;
    }
    return [
      ...messages.map((m) => ChatMessage(text: m.text, isUser: m.isUser)),
      ChatMessage(text: 'ad', isUser: false, isAd: true),
    ];
  }

  Future<void> _loadConversationStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_conversationsKey);
      final activeId = prefs.getString(_activeConversationKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as List;
        _conversations = decoded
            .whereType<Map>()
            .map(
              (item) => SavedChatConversation.fromJson(
                (item as Map).cast<String, dynamic>(),
              ),
            )
            .toList();
      }

      if (_conversations.isEmpty) {
        final now = DateTime.now();
        final starter = SavedChatConversation(
          id: const Uuid().v4(),
          name: 'Current Chat',
          createdAt: now,
          updatedAt: now,
          messages: [],
        );
        _conversations = [starter];
      }

      _activeConversationId =
          _conversations.any((c) => c.id == activeId) ? activeId : _conversations.first.id;
      final activeConversation = _conversations.firstWhere(
        (c) => c.id == _activeConversationId,
      );
      state = ChatState(messages: _uiMessagesFromPersisted(activeConversation.messages));
      _conversationStoreReady = true;
      await _saveConversationStore();
    } catch (e, st) {
      debugPrint('Failed to load chat conversations: $e');
      debugPrint('$st');
    }
  }

  Future<void> _saveConversationStore() async {
    if (!_conversationStoreReady) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = json.encode(_conversations.map((c) => c.toJson()).toList());
    await prefs.setString(_conversationsKey, payload);
    if (_activeConversationId != null) {
      await prefs.setString(_activeConversationKey, _activeConversationId!);
    }
  }

  List<ChatConversationSummary> get conversations {
    final sorted = [..._conversations]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted
        .map(
          (c) => ChatConversationSummary(
            id: c.id,
            name: c.name,
            tankId: c.tankId,
            updatedAt: c.updatedAt,
            messageCount: c.messages.length,
          ),
        )
        .toList();
  }

  String? get activeConversationId => _activeConversationId;

  SavedChatConversation? _findConversationById(String id) {
    for (final item in _conversations) {
      if (item.id == id) return item;
    }
    return null;
  }

  ChatConversationSummary? get activeConversation {
    if (_activeConversationId == null) return null;
    final conversation = _findConversationById(_activeConversationId!);
    if (conversation == null) return null;
    return ChatConversationSummary(
      id: conversation.id,
      name: conversation.name,
      tankId: conversation.tankId,
      updatedAt: conversation.updatedAt,
      messageCount: conversation.messages.length,
    );
  }

  void schedulePersistActiveConversation() {
    if (!_conversationStoreReady || _activeConversationId == null) return;
    _saveConversationDebounce?.cancel();
    _saveConversationDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(persistActiveConversationNow());
    });
  }

  Future<void> persistActiveConversationNow() async {
    if (!_conversationStoreReady || _activeConversationId == null) return;
    final index = _conversations.indexWhere((c) => c.id == _activeConversationId);
    if (index < 0) return;

    final updated = _conversations[index].copyWith(
      updatedAt: DateTime.now(),
      messages: _persistableMessagesFromState(),
    );
    _conversations[index] = updated;
    await _saveConversationStore();
  }

  Future<void> createConversation({
    required String name,
    String? tankId,
    bool copyCurrentMessages = false,
  }) async {
    if (!_conversationStoreReady) return;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final now = DateTime.now();
    final conversation = SavedChatConversation(
      id: const Uuid().v4(),
      name: trimmedName,
      tankId: tankId,
      createdAt: now,
      updatedAt: now,
      messages: copyCurrentMessages ? _persistableMessagesFromState() : [],
    );
    _conversations = [conversation, ..._conversations];
    _activeConversationId = conversation.id;
    state = ChatState(messages: _uiMessagesFromPersisted(conversation.messages));
    await _saveConversationStore();
  }

  Future<void> updateActiveConversationMetadata({
    required String name,
    String? tankId,
  }) async {
    if (!_conversationStoreReady || _activeConversationId == null) return;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    final index = _conversations.indexWhere((c) => c.id == _activeConversationId);
    if (index < 0) return;
    _conversations[index] = _conversations[index].copyWith(
      name: trimmedName,
      tankId: tankId,
      clearTankId: tankId == null,
      updatedAt: DateTime.now(),
    );
    await _saveConversationStore();
  }

  Future<void> switchConversation(String conversationId) async {
    if (!_conversationStoreReady || conversationId == _activeConversationId) return;
    await persistActiveConversationNow();
    final conversation = _findConversationById(conversationId);
    if (conversation == null) return;
    _activeConversationId = conversation.id;
    state = ChatState(messages: _uiMessagesFromPersisted(conversation.messages));
    await _saveConversationStore();
  }

  Future<void> deleteConversation(String conversationId) async {
    if (!_conversationStoreReady) return;
    _conversations.removeWhere((c) => c.id == conversationId);

    if (_conversations.isEmpty) {
      final now = DateTime.now();
      _conversations = [
        SavedChatConversation(
          id: const Uuid().v4(),
          name: 'Current Chat',
          createdAt: now,
          updatedAt: now,
          messages: [],
        ),
      ];
    }

    if (!_conversations.any((c) => c.id == _activeConversationId)) {
      _activeConversationId = _conversations.first.id;
    }

    final activeConversation = _conversations.firstWhere(
      (c) => c.id == _activeConversationId,
    );
    state = ChatState(messages: _uiMessagesFromPersisted(activeConversation.messages));
    await _saveConversationStore();
  }

  @override
  void dispose() {
    _saveConversationDebounce?.cancel();
    super.dispose();
  }

  /// Returns the effective chat history limit.
  /// Users who supply their own API key for the active text provider use their
  /// configured [ModelState.chatHistoryLimit]. Free-tier users are capped;
  /// Founder Aquarists get an increased cap over the standard free tier.
  int get _historyLimit {
    final usingDevKey = switch (_modelState.activeTextProvider) {
      AIProvider.gemini => false, // no dev key for Gemini
      AIProvider.openAI => false, // no dev key for OpenAI
      AIProvider.groq => _modelState.usingDeveloperGroqKeyForText,
    };
    if (!usingDevKey) return _modelState.chatHistoryLimit;
    final isFounder = _ref.read(isFounderProvider);
    return isFounder
        ? RemoteConfigService.founderChatHistoryLimit
        : RemoteConfigService.freeTierChatHistoryLimit;
  }

  void _initializeProvider() {
    // Collect all distinct providers needed (text and image may be the same or different).
    // Each provider is initialized at most once even if selected for both roles.
    final selectedProviders = {
      _modelState.activeTextProvider,
      _modelState.activeImageProvider,
    };
    if (selectedProviders.contains(AIProvider.openAI) &&
        _modelState.openAIApiKey.isNotEmpty) {
      OpenAI.apiKey = _modelState.openAIApiKey;
    }
  }

  /// Returns `true` when the current user has Founder Aquarist status
  /// (real purchase or debug override).
  bool get _isFounder => _ref.read(isFounderProvider);

  /// Effective per-minute request cap for the current user tier.
  int get _effectiveMaxPerMinute => _isFounder
      ? RemoteConfigService.founderMaxRequestsPerMinute
      : RemoteConfigService.maxRequestsPerMinute;

  /// Effective per-day request cap for the current user tier.
  int get _effectiveMaxPerDay => _isFounder
      ? RemoteConfigService.founderMaxRequestsPerDay
      : RemoteConfigService.maxRequestsPerDay;

  /// Effective per-day photo analysis cap for the current user tier.
  int get _effectiveMaxPhotosPerDay => _isFounder
      ? RemoteConfigService.founderMaxPhotoAnalysesPerDay
      : RemoteConfigService.maxPhotoAnalysesPerDay;

  void cancel() {
    _cancellable?.cancel();
    state = ChatState(messages: state.messages, isLoading: false);
  }

  // Returns the missing-key error message for the active text provider, or null if a key is set.
  String? _missingApiKeyError() {
    switch (_modelState.activeTextProvider) {
      case AIProvider.gemini:
        if (_modelState.geminiApiKey.isEmpty) {
          return 'Gemini API Key is not set. Please add your key in Settings.';
        }
        break;
      case AIProvider.openAI:
        if (_modelState.openAIApiKey.isEmpty) {
          return 'OpenAI API Key is not set. Please add your key in Settings.';
        }
        break;
      case AIProvider.groq:
        if (!_modelState.hasGroqKey) {
          return 'Groq API Key is not set. Please add your key in Settings.';
        }
        break;
    }
    return null;
  }

  /// Returns the effective system prompt for [message].
  /// Appends the AquaPi supplement when the message is AquaPi-related,
  /// adds a language instruction, and adds an experience level instruction.
  String _effectiveSystemPrompt(String message) {
    final base = effectiveSystemPrompt(message);
    final settings = _ref.read(appSettingsProvider);
    return appendAiContextInstructions(
      base,
      aiResponseLanguage: settings.aiResponseLanguage,
      localeCode: settings.localeCode,
      experienceLevel: settings.userExperienceLevel,
    );
  }

  // ================== Generic Chat ==================
  Future<void> sendMessage(String message) async {
    if (_modelState.usingDeveloperGroqKeyForText) {
      final result = await DevRateLimiter.checkAndRecordRequest(
        isFounder: _isFounder,
      );
      if (result == DevRateLimitResult.minuteLimitReached) {
        final secs = await DevRateLimiter.secondsUntilNextSlot(
          isFounder: _isFounder,
        );
        return _handleError(
          '⏱️ Free-tier limit reached ($_effectiveMaxPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          message,
          isRateLimitError: true,
        );
      } else if (result == DevRateLimitResult.dailyLimitReached) {
        return _handleError(
          '📅 Daily free-tier limit reached ($_effectiveMaxPerDay requests/day). Come back tomorrow or add your own Groq API key in Settings.',
          message,
          isRateLimitError: true,
        );
      }
    }
    // Trigger reCAPTCHA v3 App Check verification on web before the AI call.
    await AppCheckService.requestToken();
    switch (_modelState.activeTextProvider) {
      case AIProvider.gemini:
        if (_modelState.geminiApiKey.isEmpty) {
          return _handleError(
            'Gemini API Key is not set. Please add your key in Settings.',
            message,
          );
        }
        return _sendGeminiMessage(message);
      case AIProvider.openAI:
        if (_modelState.openAIApiKey.isEmpty) {
          return _handleError(
            'OpenAI API Key is not set. Please add your key in Settings.',
            message,
          );
        }
        return _sendOpenAIMessage(message);
      case AIProvider.groq:
        if (!_modelState.hasGroqKey) {
          return _handleError(
            'Groq API Key is not set. Please add your key in Settings.',
            message,
          );
        }
        return _sendGroqMessage(message);
    }
  }

  Future<void> retryMessage(String original) async {
    // Trigger reCAPTCHA v3 App Check verification on web before the AI call.
    await AppCheckService.requestToken();
    switch (_modelState.activeTextProvider) {
      case AIProvider.gemini:
        return _sendGeminiMessage(original, isRetry: true);
      case AIProvider.openAI:
        return _sendOpenAIMessage(original, isRetry: true);
      case AIProvider.groq:
        return _sendGroqMessage(original, isRetry: true);
    }
  }

  Future<void> _sendGeminiMessage(
    String message, {
    bool isRetry = false,
  }) async {
    if (_modelState.geminiApiKey.isEmpty) {
      return _handleError('Gemini API Key is not set.', message);
    }
    _prepareForSending(message, isRetry: isRetry);
    _cancellable = CancellableCompleter();
    try {
      // Build a fresh session each request with the last N non-ad, non-error
      // messages (excluding the current one just added by _prepareForSending)
      // as seed history, so the session never accumulates unbounded tokens.
      final allMessages = state.messages
          .where((m) => !m.isAd && !m.isError)
          .toList();
      // Drop the current user message (last entry added by _prepareForSending).
      final priorMessages = allMessages.length > 1
          ? allMessages.sublist(0, allMessages.length - 1)
          : <ChatMessage>[];
      final limit = _historyLimit;
      final recentHistory = priorMessages.length > limit
          ? priorMessages.sublist(priorMessages.length - limit)
          : priorMessages;
      final seedHistory = [
        Content.model([TextPart(_effectiveSystemPrompt(message))]),
        ...recentHistory.map(
          (m) => m.isUser
              ? Content.text(m.text)
              : Content.model([TextPart(m.text)]),
        ),
      ];
      final model = GenerativeModel(
        model: _modelState.geminiModel,
        apiKey: _modelState.geminiApiKey,
      );
      final session = model.startChat(history: seedHistory);
      final response = await session
          .sendMessage(Content.text(message))
          .timeout(const Duration(seconds: 30));
      _cancellable?.complete(response);
      if (response.text == null) {
        throw Exception('No response received from Gemini');
      }
      _processTextResponse(response.text!);
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        _handleError(e.toString(), message);
      }
    }
  }

  Future<void> _sendOpenAIMessage(
    String message, {
    bool isRetry = false,
  }) async {
    _prepareForSending(message, isRetry: isRetry);
    _cancellable = CancellableCompleter();
    try {
      // Limit history to the last N non-ad, non-error messages to reduce token usage.
      final allHistory = state.messages
          .where((m) => !m.isAd && !m.isError)
          .toList();
      final limit = _historyLimit;
      final recentHistory = allHistory.length > limit
          ? allHistory.sublist(allHistory.length - limit)
          : allHistory;
      final history = recentHistory
          .map(
            (m) => OpenAIChatCompletionChoiceMessageModel(
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(m.text),
              ],
              role: m.isUser
                  ? OpenAIChatMessageRole.user
                  : OpenAIChatMessageRole.assistant,
            ),
          )
          .toList();

      final response = await OpenAI.instance.chat
          .create(
            model: _modelState.chatGPTModel,
            messages: [
              OpenAIChatCompletionChoiceMessageModel(
                content: [
                  OpenAIChatCompletionChoiceMessageContentItemModel.text(
                    _effectiveSystemPrompt(message),
                  ),
                ],
                role: OpenAIChatMessageRole.system,
              ),
              ...history,
            ],
          )
          .timeout(const Duration(seconds: 30));
      _cancellable?.complete(response);
      final responseText = response.choices.first.message.content?.first.text;
      if (responseText == null) {
        throw Exception('No response received from OpenAI');
      }
      _processTextResponse(responseText);
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        _handleError(e.toString(), message);
      }
    }
  }

  Future<void> _sendGroqMessage(String message, {bool isRetry = false}) async {
    if (!_modelState.hasGroqKey) {
      return _handleError('Groq API Key is not set.', message);
    }
    _prepareForSending(message, isRetry: isRetry);
    _cancellable = CancellableCompleter();
    try {
      // Limit history to the last N non-ad, non-error messages to reduce token
      // usage. The current user message was already added to state.messages by
      // _prepareForSending, so it is included within this window.
      final allHistory = state.messages
          .where((m) => !m.isAd && !m.isError)
          .toList();
      final limit = _historyLimit;
      final recentHistory = allHistory.length > limit
          ? allHistory.sublist(allHistory.length - limit)
          : allHistory;
      final messages = recentHistory
          .map(
            (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
          )
          .toList();

      final responseText = _modelState.usingDeveloperGroqKeyForText
          ? await GroqProxyService.sendChatMessages(
              model: _modelState.freeGroqTextModel(_isFounder),
              systemPrompt: _effectiveSystemPrompt(message),
              messages: messages,
            ).timeout(const Duration(seconds: 30))
          : await GroqHelper.sendChatMessages(
              apiKey: _modelState.effectiveGroqApiKeyForText,
              model: _modelState.groqModel,
              systemPrompt: _effectiveSystemPrompt(message),
              messages: messages,
            );
      _cancellable?.complete(responseText);
      if (responseText == null) {
        throw Exception('No response received from Groq');
      }
      _processTextResponse(responseText);
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        _handleError(e.toString(), message);
      }
    }
  }

  // ================== Water Parameter Analysis ==================
  Future<WaterAnalysisResult?> analyzeWaterParameters(
    Map<String, String> params,
  ) async {
    final keyError = _missingApiKeyError();
    if (keyError != null) {
      final userMsg = 'Please analyze my water parameters.';
      await _handleError(keyError, userMsg);
      return null;
    }
    if (_modelState.usingDeveloperGroqKeyForText) {
      final result = await DevRateLimiter.checkAndRecordRequest(
        isFounder: _isFounder,
      );
      if (result == DevRateLimitResult.minuteLimitReached) {
        final secs = await DevRateLimiter.secondsUntilNextSlot(
          isFounder: _isFounder,
        );
        final userMsg = 'Please analyze my water parameters.';
        await _handleError(
          '⏱️ Free-tier limit reached ($_effectiveMaxPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          userMsg,
          isRateLimitError: true,
        );
        return null;
      } else if (result == DevRateLimitResult.dailyLimitReached) {
        final userMsg = 'Please analyze my water parameters.';
        await _handleError(
          '📅 Daily free-tier limit reached ($_effectiveMaxPerDay requests/day). Come back tomorrow or add your own Groq API key in Settings.',
          userMsg,
          isRateLimitError: true,
        );
        return null;
      }
    }
    // Trigger reCAPTCHA v3 App Check verification on web before the AI call.
    await AppCheckService.requestToken();
    final userMsg =
        'Please analyze my water parameters for my ${params['tankType']} tank.\n'
        'Temp: ${params['temp']}°${params['tempUnit']}'
        '${params['ph']!.isNotEmpty ? ', pH: ${params['ph']}' : ''}'
        '${params['salinity']!.isNotEmpty ? ', Salinity: ${params['salinity']} ${params['salinityUnit']}' : ''}'
        '${params['additionalInfo']!.isNotEmpty ? ', Additional Info: ${params['additionalInfo']}' : ''}';
    _prepareForSending(userMsg);
    final settings = _ref.read(appSettingsProvider);
    final prompt = appendAiContextInstructions(
      buildWaterAnalysisPrompt(
        tankType: params['tankType']!,
        ph: params['ph']!,
        temp: params['temp']!,
        salinity: params['salinity']!,
        additionalInfo: params['additionalInfo']!,
        tempUnit: params['tempUnit']!,
        salinityUnit: params['salinityUnit']!,
      ),
      aiResponseLanguage: settings.aiResponseLanguage,
      localeCode: settings.localeCode,
      experienceLevel: settings.userExperienceLevel,
    );
    try {
      final responseText = await _generateContent(prompt, expectJson: true);
      final decoded = json.decode(extractJson(responseText));
      final result = WaterAnalysisResult.fromJson(decoded);
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: 'Here is your water analysis:',
            isUser: false,
            analysisResult: result,
          ),
        ],
        isLoading: false,
      );
      // Save to analysis history
      final tankType = params['tankType']!.isNotEmpty
          ? params['tankType']!
          : 'Tank';
      _ref
          .read(analysisHistoryProvider.notifier)
          .addEntry(
            AnalysisHistoryEntry.create(
              type: AnalysisType.waterParameters,
              title: 'Water Analysis – $tankType',
              resultData: result.toJson(),
            ),
          );
      return result;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        _handleError(e.toString(), userMsg);
      }
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
    if (_modelState.usingDeveloperGroqKeyForText) {
      final result = await DevRateLimiter.checkAndRecordRequest(
        isFounder: _isFounder,
      );
      if (result == DevRateLimitResult.minuteLimitReached) {
        final secs = await DevRateLimiter.secondsUntilNextSlot(
          isFounder: _isFounder,
        );
        await _handleError(
          '⏱️ Free-tier limit reached ($_effectiveMaxPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          'Generate an automation script.',
          isRateLimitError: true,
        );
        return null;
      } else if (result == DevRateLimitResult.dailyLimitReached) {
        await _handleError(
          '📅 Daily free-tier limit reached ($_effectiveMaxPerDay requests/day). Come back tomorrow or add your own Groq API key in Settings.',
          'Generate an automation script.',
          isRateLimitError: true,
        );
        return null;
      }
    }
    // Trigger reCAPTCHA v3 App Check verification on web before the AI call.
    await AppCheckService.requestToken();
    final userMsg = 'Generate an automation script for: "$description"';
    _prepareForSending(userMsg);
    final settings = _ref.read(appSettingsProvider);
    final prompt = appendAiContextInstructions(
      buildAutomationScriptPrompt(description),
      aiResponseLanguage: settings.aiResponseLanguage,
      localeCode: settings.localeCode,
      experienceLevel: settings.userExperienceLevel,
    );
    try {
      final responseText = await _generateContent(prompt, expectJson: true);
      final decoded = json.decode(extractJson(responseText));
      final script = AutomationScript.fromJson(decoded);
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: 'Here is your automation script:',
            isUser: false,
            automationScript: script,
          ),
        ],
        isLoading: false,
      );
      // Save to analysis history
      _ref
          .read(analysisHistoryProvider.notifier)
          .addEntry(
            AnalysisHistoryEntry.create(
              type: AnalysisType.automationScript,
              title: script.title.isNotEmpty
                  ? script.title
                  : 'Automation Script',
              resultData: script.toJson(),
            ),
          );
      return script;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        _handleError(e.toString(), userMsg);
      }
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
    if (_modelState.usingDeveloperGroqKeyForText) {
      final result = await DevRateLimiter.checkAndRecordRequest(
        isFounder: _isFounder,
      );
      if (result == DevRateLimitResult.minuteLimitReached) {
        final secs = await DevRateLimiter.secondsUntilNextSlot(
          isFounder: _isFounder,
        );
        await _handleError(
          '⏱️ Free-tier limit reached ($_effectiveMaxPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
          'Look up fish info: $fishNames.',
          isRateLimitError: true,
        );
        return null;
      } else if (result == DevRateLimitResult.dailyLimitReached) {
        await _handleError(
          '📅 Daily free-tier limit reached ($_effectiveMaxPerDay requests/day). Come back tomorrow or add your own Groq API key in Settings.',
          'Look up fish info: $fishNames.',
          isRateLimitError: true,
        );
        return null;
      }
    }
    // Trigger reCAPTCHA v3 App Check verification on web before the AI call.
    await AppCheckService.requestToken();
    final userMsg =
        'Give me comprehensive information about: $fishNames'
        '${tankSize != null && tankSize.isNotEmpty ? ' (tank size: $tankSize)' : ''}'
        '${additionalNotes != null && additionalNotes.isNotEmpty ? '. Notes: $additionalNotes' : ''}.';
    _prepareForSending(userMsg);
    final settings = _ref.read(appSettingsProvider);
    final prompt = appendAiContextInstructions(
      buildFishInfoPrompt(
        fishNames: fishNames,
        tankSize: tankSize,
        additionalNotes: additionalNotes,
      ),
      aiResponseLanguage: settings.aiResponseLanguage,
      localeCode: settings.localeCode,
      experienceLevel: settings.userExperienceLevel,
    );
    try {
      final responseText = await _generateContent(prompt, expectJson: true);
      final parsed = FishInfoResult.tryParseJson(extractJson(responseText));
      if (parsed == null) {
        throw const FormatException('Malformed JSON from AI fish info.');
      }
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
      // Save to analysis history
      _ref
          .read(analysisHistoryProvider.notifier)
          .addEntry(
            AnalysisHistoryEntry.create(
              type: AnalysisType.fishInfo,
              title: 'Fish Info – $fishNames',
              resultData: parsed.toJson(),
            ),
          );
      return parsed;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        _handleError(e.toString(), userMsg);
      }
      return null;
    }
  }

  // ================== Photo Analysis ==================
  Future<PhotoAnalysisResult?> analyzePhoto({
    required Uint8List imageBytes,
    String? userNote,
    String mimeType = 'image/jpeg',
    bool isRegeneration = false,
  }) async {
    // Check rate limits before showing the loading state, so the user sees the
    // error as a chat message rather than a silent failure.
    if (_modelState.usingDeveloperGroqKeyForImage) {
      // Per-minute + per-day request limit checked first — no quota consumed if this fails.
      final reqResult = await DevRateLimiter.checkAndRecordRequest(
        isFounder: _isFounder,
      );
      if (reqResult == DevRateLimitResult.minuteLimitReached) {
        final secs = await DevRateLimiter.secondsUntilNextSlot(
          isFounder: _isFounder,
        );
        state = ChatState(
          messages: [
            ...state.messages,
            ChatMessage(
              text:
                  '⏱️ **Free-tier limit reached** ($_effectiveMaxPerMinute requests/min). Please wait $secs second${secs == 1 ? '' : 's'} or add your own Groq API key in Settings.',
              isUser: false,
              isError: true,
              isRetryable: false,
              isRateLimitError: true,
              photoBytes: imageBytes,
            ),
          ],
          isLoading: false,
        );
        return null;
      } else if (reqResult == DevRateLimitResult.dailyLimitReached) {
        state = ChatState(
          messages: [
            ...state.messages,
            ChatMessage(
              text:
                  '📅 **Daily free-tier limit reached** ($_effectiveMaxPerDay requests/day). Come back tomorrow or add your own Groq API key in Settings.',
              isUser: false,
              isError: true,
              isRetryable: false,
              isRateLimitError: true,
            ),
          ],
          isLoading: false,
        );
        return null;
      }
      // Daily photo limit (only for new analyses, not regenerations)
      if (!isRegeneration) {
        final photoAllowed = await DevRateLimiter.checkAndRecordPhotoAnalysis(
          isFounder: _isFounder,
        );
        if (!photoAllowed) {
          // Rollback the per-minute slot we just recorded since the photo won't proceed.
          await DevRateLimiter.undoLastRequest();
          state = ChatState(
            messages: [
              ...state.messages,
              ChatMessage(
                text:
                    '📸 **Daily Photo Limit Reached**\n\nFree tier allows $_effectiveMaxPhotosPerDay photo ${_effectiveMaxPhotosPerDay == 1 ? 'analysis' : 'analyses'} per day. Add your own Groq API key in Settings for unlimited access.',
                isUser: false,
                isError: true,
                isRetryable: false,
                isRateLimitError: true,
              ),
            ],
            isLoading: false,
          );
          return null;
        }
      }
    }
    // Store photo bytes/note before the request so that retry via
    // regeneratePhotoAnalysis() works even if the AI call fails.
    _lastPhotoBytes = imageBytes;
    _lastPhotoNote = userNote;
    final note = (userNote?.trim().isNotEmpty ?? false)
        ? 'User note: ${userNote!.trim()}'
        : 'No additional user note.';
    if (!isRegeneration) {
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: '📷 Submitted an aquarium photo for AI analysis.\n\n$note',
            isUser: true,
            photoBytes: imageBytes,
          ),
        ],
        isLoading: true,
      );
    } else {
      state = ChatState(messages: state.messages, isLoading: true);
    }
    final settings = _ref.read(appSettingsProvider);
    final prompt = appendAiContextInstructions(
      buildPhotoAnalysisPrompt(note),
      aiResponseLanguage: settings.aiResponseLanguage,
      localeCode: settings.localeCode,
      experienceLevel: settings.userExperienceLevel,
    );
    final originalMessage =
        'Retry photo analysis${userNote?.isNotEmpty == true ? ': $userNote' : ''}';
    // Trigger reCAPTCHA v3 App Check verification on web before the AI call.
    await AppCheckService.requestToken();
    try {
      final responseText = await _generateContentWithImage(
        prompt,
        imageBytes,
        mimeType,
      );
      final parsed = PhotoAnalysisResult.tryParseJson(
        extractJson(responseText),
      );
      if (parsed == null) {
        throw const FormatException('Malformed JSON from AI photo analysis.');
      }
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text: isRegeneration
                ? '🖼️ Photo analysis regenerated.'
                : '🖼️ Photo analysis complete. Tap to view detailed results.',
            isUser: false,
            photoAnalysisResult: parsed,
            photoBytes: imageBytes,
          ),
        ],
        isLoading: false,
      );
      // Save to analysis history
      String? photoBase64;
      try {
        photoBase64 = base64Encode(imageBytes);
      } catch (_) {}
      _ref
          .read(analysisHistoryProvider.notifier)
          .addEntry(
            AnalysisHistoryEntry.create(
              type: AnalysisType.photoAnalysis,
              title: userNote != null && userNote.trim().isNotEmpty
                  ? 'Photo Analysis – ${userNote.trim()}'
                  : 'Photo Analysis',
              resultData: parsed.raw,
              photoBase64: photoBase64,
              modelName: switch (_modelState.activeImageProvider) {
                AIProvider.gemini => _modelState.geminiImageModel,
                AIProvider.openAI => _modelState.chatGPTImageModel,
                AIProvider.groq => _modelState.usingDeveloperGroqKeyForImage
                    ? _modelState.freeGroqImageModel(_isFounder)
                    : _modelState.groqImageModel,
              },
            ),
          );
      return parsed;
    } catch (e) {
      if (!(_cancellable?.isCancelled ?? false)) {
        // Rollback rate limit slots since the AI call failed.
        // The daily photo counter is only incremented for new analyses (not
        // regenerations), so it is only rolled back in that case.
        if (_modelState.usingDeveloperGroqKeyForImage) {
          await DevRateLimiter.undoLastRequest();
          if (!isRegeneration) await DevRateLimiter.undoPhotoAnalysis();
        }
        final errorStr = e.toString();
        final apiKeyError = ApiErrorHandler.isApiKeyError(errorStr);
        final quotaError =
            !apiKeyError && ApiErrorHandler.isQuotaError(errorStr);
        final networkError = ApiErrorHandler.isNetworkError(errorStr);
        final msg = apiKeyError || quotaError
            ? ApiErrorHandler.getFriendlyErrorMessage(errorStr)
            : _getPhotoError(errorStr);
        state = ChatState(
          messages: [
            ...state.messages,
            ChatMessage(
              text: msg,
              isUser: false,
              isError: true,
              isRetryable: !apiKeyError && !quotaError,
              isApiKeyError: apiKeyError,
              isQuotaError: quotaError,
              isNetworkError: networkError,
              originalMessage:
                  apiKeyError || quotaError ? null : originalMessage,
              photoBytes: imageBytes,
            ),
          ],
          isLoading: false,
        );
      }
      return null;
    }
  }

  Future<PhotoAnalysisResult?> regeneratePhotoAnalysis() {
    if (_lastPhotoBytes == null) {
      state = ChatState(
        messages: [
          ...state.messages,
          ChatMessage(
            text:
                '⚠️ No previous photo available to regenerate. Please upload a photo first.',
            isUser: false,
          ),
        ],
      );
      return Future.value(null);
    }
    return analyzePhoto(
      imageBytes: _lastPhotoBytes!,
      userNote: _lastPhotoNote,
      isRegeneration: true,
    );
  }

  // ================== Unified Content Generation ==================
  Future<String> _generateContent(
    String prompt, {
    bool expectJson = false,
  }) async {
    _cancellable = CancellableCompleter();
    try {
      String? responseText;
      switch (_modelState.activeTextProvider) {
        case AIProvider.gemini:
          final model = GenerativeModel(
            model: _modelState.geminiModel,
            apiKey: _modelState.geminiApiKey,
          );
          final response = await model
              .generateContent([Content.text(prompt)])
              .timeout(const Duration(seconds: 30));
          _cancellable?.complete(response);
          responseText = response.text;
          break;
        case AIProvider.openAI:
          final response = await OpenAI.instance.chat
              .create(
                model: _modelState.chatGPTModel,
                responseFormat: expectJson ? {"type": "json_object"} : null,
                messages: [
                  OpenAIChatCompletionChoiceMessageModel(
                    content: [
                      OpenAIChatCompletionChoiceMessageContentItemModel.text(
                        prompt,
                      ),
                    ],
                    role: OpenAIChatMessageRole.user,
                  ),
                ],
              )
              .timeout(const Duration(seconds: 30));
          _cancellable?.complete(response);
          responseText = response.choices.first.message.content?.first.text;
          break;
        case AIProvider.groq:
          if (_modelState.usingDeveloperGroqKeyForText) {
            responseText = await GroqProxyService.sendMessage(
              model: _modelState.freeGroqTextModel(_isFounder),
              prompt: prompt,
            ).timeout(const Duration(seconds: 30));
            _cancellable?.complete();
          } else {
            final groq = GroqHelper.createClient(
              apiKey: _modelState.effectiveGroqApiKeyForText,
              model: _modelState.groqModel,
            );
            final response = await groq
                .sendMessage(prompt)
                .timeout(const Duration(seconds: 30));
            _cancellable?.complete(response);
            responseText = response.choices.first.message.content;
          }
          break;
      }
      if (responseText == null) {
        throw Exception('Received no response from the AI service.');
      }
      return responseText;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _generateContentWithImage(
    String prompt,
    Uint8List imageBytes,
    String mimeType,
  ) async {
    _cancellable = CancellableCompleter();
    try {
      String? responseText;
      switch (_modelState.activeImageProvider) {
        case AIProvider.gemini:
          final model = GenerativeModel(
            model: _modelState.geminiImageModel,
            apiKey: _modelState.geminiApiKey,
          );
          final content = [
            Content.multi([DataPart(mimeType, imageBytes), TextPart(prompt)]),
          ];
          final response = await model
              .generateContent(content)
              .timeout(const Duration(seconds: 55));
          _cancellable?.complete(response);
          responseText = response.text;
          break;
        case AIProvider.openAI:
          final base64Image = base64Encode(imageBytes);
          final response = await OpenAI.instance.chat
              .create(
                model: _modelState.chatGPTImageModel,
                responseFormat: {"type": "json_object"},
                messages: [
                  OpenAIChatCompletionChoiceMessageModel(
                    role: OpenAIChatMessageRole.user,
                    content: [
                      OpenAIChatCompletionChoiceMessageContentItemModel.text(
                        prompt,
                      ),
                      OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
                        "data:$mimeType;base64,$base64Image",
                      ),
                    ],
                  ),
                ],
              )
              .timeout(const Duration(seconds: 55));
          _cancellable?.complete(response);
          responseText = response.choices.first.message.content?.first.text;
          break;
        case AIProvider.groq:
          final base64Image = base64Encode(imageBytes);
          final responseGroq = _modelState.usingDeveloperGroqKeyForImage
              ? await GroqProxyService.generateWithImage(
                  model: _modelState.freeGroqImageModel(_isFounder),
                  prompt: prompt,
                  base64Image: base64Image,
                  mimeType: mimeType,
                )
              : await GroqHelper.generateWithImage(
                  apiKey: _modelState.effectiveGroqApiKeyForImage,
                  model: _modelState.groqImageModel,
                  prompt: prompt,
                  base64Image: base64Image,
                  mimeType: mimeType,
                );
          _cancellable?.complete();
          responseText = responseGroq;
          break;
      }
      if (responseText == null) {
        throw Exception('Received no response from the AI service.');
      }
      return responseText;
    } catch (e) {
      rethrow;
    }
  }

  // ================== Helpers & Error Handling ==================
  void _prepareForSending(String message, {bool isRetry = false}) {
    final currentMessages = state.messages.where((m) => !m.isAd).toList();
    if (!isRetry) {
      state = ChatState(
        messages: [
          ...currentMessages,
          ChatMessage(text: message, isUser: true),
        ],
        isLoading: true,
      );
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
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(
          text: mainResponse,
          isUser: false,
          followUpQuestions: followUps,
        ),
      ],
      isLoading: false,
    );
  }

  Future<void> _handleError(
    String error,
    String originalMessage, {
    bool isRateLimitError = false,
  }) async {
    final apiKeyError =
        !isRateLimitError && ApiErrorHandler.isApiKeyError(error);
    final quotaError =
        !isRateLimitError && !apiKeyError && ApiErrorHandler.isQuotaError(error);
    final networkError =
        !isRateLimitError && ApiErrorHandler.isNetworkError(error);
    // Rollback the rate-limit slot for real AI errors (not pre-flight limit checks).
    if (!isRateLimitError &&
        !apiKeyError &&
        _modelState.usingDeveloperGroqKeyForText) {
      await DevRateLimiter.undoLastRequest();
    }
    // Use the error as-is for already-formatted rate limit messages; otherwise run it
    // through the friendly-message formatter.
    final friendlyError = isRateLimitError
        ? error
        : ApiErrorHandler.getFriendlyErrorMessage(error);
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(
          text: friendlyError,
          isUser: false,
          isError: true,
          isRetryable: !apiKeyError && !isRateLimitError && !quotaError,
          isApiKeyError: apiKeyError,
          isRateLimitError: isRateLimitError,
          isQuotaError: quotaError,
          isNetworkError: networkError,
          originalMessage: apiKeyError || isRateLimitError || quotaError
              ? null
              : originalMessage,
        ),
      ],
      isLoading: false,
    );
  }

  String _getPhotoError(String err) {
    if (err.contains('FormatException') || err.contains('json')) {
      return '🖼️ **Photo Analysis JSON Error**\n\nI got something back but could not parse it. Please retry.';
    }
    if (err.contains('network') || err.contains('connection')) {
      return '🔌 **Connection Issue**\n\nCould not reach the photo analysis service.';
    }
    return '⚠️ **Photo Analysis Error**\n\n${err.split('\n').first}';
  }
}
