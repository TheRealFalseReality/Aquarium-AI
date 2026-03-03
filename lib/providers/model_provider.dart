import 'package:fish_ai/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/remote_config_service.dart';

export 'package:fish_ai/constants.dart' show developerGroqApiKey;

// Provider default values — compile-time model names are now served by
// RemoteConfigService so the developer can update them without an app release.
const AIProvider defaultAIProvider = AIProvider.groq;

const int defaultChatHistoryLimit = 3;
const int minChatHistoryLimit = 1;
const int maxChatHistoryLimit = 20;

enum AIProvider { gemini, openAI, groq }

// 1. Define the state class
class ModelState {
  final String geminiModel;
  final String geminiImageModel;
  final String geminiApiKey;
  final String chatGPTModel;
  final String chatGPTImageModel;
  final String openAIApiKey;
  final String groqModel;
  final String groqImageModel;
  final String groqApiKey;

  /// Number of past messages sent to the AI on each chat request.
  /// Users who supply their own API key can configure this (1–20); the free
  /// service tier always uses [defaultChatHistoryLimit].
  final int chatHistoryLimit;

  /// Provider used for text/chat operations
  final AIProvider activeTextProvider;

  /// Provider used for image/multimedia analysis operations
  final AIProvider activeImageProvider;
  final bool isLoading;

  /// When true, the app's built-in developer Groq key is used for **text/chat**
  /// operations even if the user has stored their own Groq key.
  /// The user's key is preserved so they can re-enable it at any time.
  final bool useDevGroqKeyForText;

  /// When true, the app's built-in developer Groq key is used for **image/photo**
  /// operations even if the user has stored their own Groq key.
  /// The user's key is preserved so they can re-enable it at any time.
  final bool useDevGroqKeyForImage;

  ModelState({
    required this.geminiModel,
    required this.geminiImageModel,
    required this.geminiApiKey,
    required this.chatGPTModel,
    required this.chatGPTImageModel,
    required this.openAIApiKey,
    required this.groqModel,
    required this.groqImageModel,
    required this.groqApiKey,
    this.chatHistoryLimit = defaultChatHistoryLimit,
    required this.activeTextProvider,
    required this.activeImageProvider,
    this.isLoading = true,
    this.useDevGroqKeyForText = false,
    this.useDevGroqKeyForImage = false,
  });

  /// Convenience getter: returns the text provider (kept for backward compat)
  AIProvider get activeProvider => activeTextProvider;

  /// The Groq API key to use for **text/chat** operations.
  /// Routes through the developer Cloud Function proxy when [useDevGroqKeyForText]
  /// is explicitly ON; otherwise returns the user's own key (may be empty).
  String get effectiveGroqApiKeyForText {
    final freeAiEnabled = RemoteConfigService.freeAiEnabled;
    if (freeAiEnabled && useDevGroqKeyForText) {
      return developerGroqApiKey;
    }
    return groqApiKey;
  }

  /// The Groq API key to use for **image/photo** operations.
  /// Routes through the developer Cloud Function proxy when [useDevGroqKeyForImage]
  /// is explicitly ON; otherwise returns the user's own key (may be empty).
  String get effectiveGroqApiKeyForImage {
    final freeAiEnabled = RemoteConfigService.freeAiEnabled;
    if (freeAiEnabled && useDevGroqKeyForImage) {
      return developerGroqApiKey;
    }
    return groqApiKey;
  }

  /// Backwards-compat alias — returns [effectiveGroqApiKeyForText].
  String get effectiveGroqApiKey => effectiveGroqApiKeyForText;

  /// Whether the app has any Groq key available (user-provided or via the
  /// server-side developer proxy).
  bool get hasGroqKey =>
      effectiveGroqApiKeyForText.isNotEmpty || usingDeveloperGroqKeyForText;

  /// Whether text/chat operations are currently routing through the server-side
  /// developer Groq proxy (Firebase Cloud Function + Secret Manager).
  ///
  /// True ONLY when the Free AI toggle is explicitly ON and the free AI tier is
  /// enabled via Remote Config. Does NOT fall back to the proxy when the user
  /// key is empty — an empty key with Free AI off will produce an API error.
  /// Note: [developerGroqApiKey] is intentionally empty in production builds;
  /// the key lives in Firebase Secret Manager and is read by the Cloud Function.
  bool get usingDeveloperGroqKeyForText =>
      RemoteConfigService.freeAiEnabled && useDevGroqKeyForText;

  /// Whether image/photo operations are currently routing through the
  /// server-side developer Groq proxy.
  bool get usingDeveloperGroqKeyForImage =>
      RemoteConfigService.freeAiEnabled && useDevGroqKeyForImage;

  /// Whether either text OR image operations are using the developer Groq proxy.
  /// Used for UI indicators on the main settings page.
  bool get usingDeveloperGroqKeyForAny =>
      usingDeveloperGroqKeyForText || usingDeveloperGroqKeyForImage;

  /// Backwards-compat alias — true when any Groq operation uses the dev key.
  bool get usingDeveloperGroqKey => usingDeveloperGroqKeyForAny;
}

// 2. Create the Notifier
class ModelNotifier extends StateNotifier<ModelState> {
  ModelNotifier()
    : super(
        ModelState(
          geminiModel: RemoteConfigService.defaultGeminiModel,
          geminiImageModel: RemoteConfigService.defaultGeminiImageModel,
          geminiApiKey: '',
          chatGPTModel: RemoteConfigService.defaultOpenAIModel,
          chatGPTImageModel: RemoteConfigService.defaultOpenAIImageModel,
          openAIApiKey: '',
          groqModel: RemoteConfigService.defaultGroqModel,
          groqImageModel: RemoteConfigService.defaultGroqImageModel,
          groqApiKey: '',
          activeTextProvider: defaultAIProvider,
          activeImageProvider: defaultAIProvider,
          useDevGroqKeyForText: true,
          useDevGroqKeyForImage: true,
        ),
      ) {
    _loadModels();
  }

  /// Returns the best provider to switch to when the Free AI toggle is turned
  /// OFF, given the available API keys.  Prefers the first provider that has a
  /// key saved (Gemini → OpenAI → Groq) so the user is never left with an
  /// active provider that has no key.  Falls back to [defaultAIProvider] when
  /// no keys are present at all.
  static AIProvider _bestProviderWithKey({
    required String geminiApiKey,
    required String openAIApiKey,
    required String groqApiKey,
  }) {
    if (geminiApiKey.isNotEmpty) return AIProvider.gemini;
    if (openAIApiKey.isNotEmpty) return AIProvider.openAI;
    if (groqApiKey.isNotEmpty) return AIProvider.groq;
    return defaultAIProvider;
  }

  /// Returns true when [provider]'s API key is empty (i.e. the user has not
  /// configured a key for that provider yet).
  static bool _providerKeyIsEmpty(
    AIProvider provider,
    String geminiApiKey,
    String openAIApiKey,
    String groqApiKey,
  ) {
    switch (provider) {
      case AIProvider.gemini:
        return geminiApiKey.isEmpty;
      case AIProvider.openAI:
        return openAIApiKey.isEmpty;
      case AIProvider.groq:
        return groqApiKey.isEmpty;
    }
  }

  Future<void> _loadModels() async {
    final prefs = await SharedPreferences.getInstance();
    final geminiModel =
        prefs.getString('geminiModel') ??
        RemoteConfigService.defaultGeminiModel;
    final geminiImageModel =
        prefs.getString('geminiImageModel') ??
        RemoteConfigService.defaultGeminiImageModel;
    final geminiApiKey = prefs.getString('geminiApiKey') ?? '';
    final chatGPTModel =
        prefs.getString('chatGPTModel') ??
        RemoteConfigService.defaultOpenAIModel;
    final chatGPTImageModel =
        prefs.getString('chatGPTImageModel') ??
        RemoteConfigService.defaultOpenAIImageModel;
    final openAIApiKey = prefs.getString('openAIApiKey') ?? '';
    final groqModel =
        prefs.getString('groqModel') ?? RemoteConfigService.defaultGroqModel;
    final groqImageModel =
        prefs.getString('groqImageModel') ??
        RemoteConfigService.defaultGroqImageModel;
    final groqApiKey = prefs.getString('groqApiKey') ?? '';
    // Migrate legacy single useDevGroqKey → per-operation flags.
    // New users (no stored keys) default to ON (true = free AI).
    // Existing users who already have an API key stored default to OFF so their
    // key continues to work after an app upgrade without interruption.
    final legacyDevKey = prefs.getBool('useDevGroqKey');
    final hasAnyStoredKey =
        geminiApiKey.isNotEmpty ||
        openAIApiKey.isNotEmpty ||
        groqApiKey.isNotEmpty;
    final freeAiDefault = !hasAnyStoredKey;
    final useDevGroqKeyForText =
        prefs.getBool('useDevGroqKeyForText') ?? legacyDevKey ?? freeAiDefault;
    final useDevGroqKeyForImage =
        prefs.getBool('useDevGroqKeyForImage') ?? legacyDevKey ?? freeAiDefault;
    final chatHistoryLimit =
        (prefs.getInt('chatHistoryLimit') ?? defaultChatHistoryLimit).clamp(
          minChatHistoryLimit,
          maxChatHistoryLimit,
        );
    // Migrate legacy 'activeProvider' to both text and image providers if new keys are absent
    final legacyProviderIndex = prefs.getInt('activeProvider');
    var activeTextProvider =
        AIProvider.values[prefs.getInt('activeTextProvider') ??
            legacyProviderIndex ??
            defaultAIProvider.index];
    var activeImageProvider =
        AIProvider.values[prefs.getInt('activeImageProvider') ??
            legacyProviderIndex ??
            defaultAIProvider.index];

    // When Free AI is ON, ensure the active provider is Groq so the free
    // tier is actually used rather than the previously selected provider.
    if (useDevGroqKeyForText) activeTextProvider = AIProvider.groq;
    if (useDevGroqKeyForImage) activeImageProvider = AIProvider.groq;

    // When Free AI is OFF but the stored provider has no key (e.g. due to the
    // previous bug where toggling Free AI off left the provider as Groq even
    // when the user had a Gemini/OpenAI key), automatically pick the provider
    // that has a saved key so the user isn't stuck on a keyless provider.
    final bestProvider = _bestProviderWithKey(
      geminiApiKey: geminiApiKey,
      openAIApiKey: openAIApiKey,
      groqApiKey: groqApiKey,
    );
    if (!useDevGroqKeyForText &&
        _providerKeyIsEmpty(
          activeTextProvider,
          geminiApiKey,
          openAIApiKey,
          groqApiKey,
        )) {
      activeTextProvider = bestProvider;
    }
    if (!useDevGroqKeyForImage &&
        _providerKeyIsEmpty(
          activeImageProvider,
          geminiApiKey,
          openAIApiKey,
          groqApiKey,
        )) {
      activeImageProvider = bestProvider;
    }

    state = ModelState(
      geminiModel: geminiModel,
      geminiImageModel: geminiImageModel,
      geminiApiKey: geminiApiKey,
      chatGPTModel: chatGPTModel,
      chatGPTImageModel: chatGPTImageModel,
      openAIApiKey: openAIApiKey,
      groqModel: groqModel,
      groqImageModel: groqImageModel,
      groqApiKey: groqApiKey,
      chatHistoryLimit: chatHistoryLimit,
      activeTextProvider: activeTextProvider,
      activeImageProvider: activeImageProvider,
      useDevGroqKeyForText: useDevGroqKeyForText,
      useDevGroqKeyForImage: useDevGroqKeyForImage,
      isLoading: false,
    );
  }

  Future<void> setModels({
    required String newGeminiModel,
    required String newGeminiImageModel,
    required String newGeminiApiKey,
    required String newChatGPTModel,
    required String newChatGPTImageModel,
    required String newOpenAIApiKey,
    required String newGroqModel,
    required String newGroqImageModel,
    required String newGroqApiKey,
    required AIProvider newActiveTextProvider,
    required AIProvider newActiveImageProvider,
    int newChatHistoryLimit = defaultChatHistoryLimit,
    bool newUseDevGroqKeyForText = false,
    bool newUseDevGroqKeyForImage = false,
  }) async {
    if (newGeminiModel.isEmpty ||
        newGeminiImageModel.isEmpty ||
        newChatGPTModel.isEmpty ||
        newChatGPTImageModel.isEmpty ||
        newGroqModel.isEmpty ||
        newGroqImageModel.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // When Free AI is ON, ensure the active provider is Groq.
    final effectiveTextProvider = newUseDevGroqKeyForText
        ? AIProvider.groq
        : newActiveTextProvider;
    final effectiveImageProvider = newUseDevGroqKeyForImage
        ? AIProvider.groq
        : newActiveImageProvider;
    await prefs.setString('geminiModel', newGeminiModel);
    await prefs.setString('geminiImageModel', newGeminiImageModel);
    await prefs.setString('geminiApiKey', newGeminiApiKey);
    await prefs.setString('chatGPTModel', newChatGPTModel);
    await prefs.setString('chatGPTImageModel', newChatGPTImageModel);
    await prefs.setString('openAIApiKey', newOpenAIApiKey);
    await prefs.setString('groqModel', newGroqModel);
    await prefs.setString('groqImageModel', newGroqImageModel);
    await prefs.setString('groqApiKey', newGroqApiKey);
    await prefs.setInt(
      'chatHistoryLimit',
      newChatHistoryLimit.clamp(minChatHistoryLimit, maxChatHistoryLimit),
    );
    await prefs.setInt('activeTextProvider', effectiveTextProvider.index);
    await prefs.setInt('activeImageProvider', effectiveImageProvider.index);
    await prefs.setBool('useDevGroqKeyForText', newUseDevGroqKeyForText);
    await prefs.setBool('useDevGroqKeyForImage', newUseDevGroqKeyForImage);

    state = ModelState(
      geminiModel: newGeminiModel,
      geminiImageModel: newGeminiImageModel,
      geminiApiKey: newGeminiApiKey,
      chatGPTModel: newChatGPTModel,
      chatGPTImageModel: newChatGPTImageModel,
      openAIApiKey: newOpenAIApiKey,
      groqModel: newGroqModel,
      groqImageModel: newGroqImageModel,
      groqApiKey: newGroqApiKey,
      chatHistoryLimit: newChatHistoryLimit.clamp(
        minChatHistoryLimit,
        maxChatHistoryLimit,
      ),
      activeTextProvider: effectiveTextProvider,
      activeImageProvider: effectiveImageProvider,
      useDevGroqKeyForText: newUseDevGroqKeyForText,
      useDevGroqKeyForImage: newUseDevGroqKeyForImage,
      isLoading: false,
    );
  }

  /// Clear a single API key by name (geminiApiKey, openAIApiKey, or groqApiKey)
  /// without any validation. Persists the empty value immediately.
  Future<void> clearApiKey(String keyName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyName, '');
    state = ModelState(
      geminiModel: state.geminiModel,
      geminiImageModel: state.geminiImageModel,
      geminiApiKey: keyName == 'geminiApiKey' ? '' : state.geminiApiKey,
      chatGPTModel: state.chatGPTModel,
      chatGPTImageModel: state.chatGPTImageModel,
      openAIApiKey: keyName == 'openAIApiKey' ? '' : state.openAIApiKey,
      groqModel: state.groqModel,
      groqImageModel: state.groqImageModel,
      groqApiKey: keyName == 'groqApiKey' ? '' : state.groqApiKey,
      chatHistoryLimit: state.chatHistoryLimit,
      activeTextProvider: state.activeTextProvider,
      activeImageProvider: state.activeImageProvider,
      useDevGroqKeyForText: state.useDevGroqKeyForText,
      useDevGroqKeyForImage: state.useDevGroqKeyForImage,
      isLoading: false,
    );
  }

  /// Directly update the dev Groq key toggles without changing any other settings.
  /// Useful for quick on/off from the API Key dialog.
  ///
  /// When a Free AI toggle is turned ON, the corresponding active provider is
  /// automatically switched to Groq so the free tier is actually used.
  /// When a Free AI toggle is turned OFF, the active provider is switched to
  /// whichever provider has a saved API key (Gemini → OpenAI → Groq) so the
  /// user is not left on a provider with no key configured.
  Future<void> setDevGroqKeyToggles({
    required bool forText,
    required bool forImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDevGroqKeyForText', forText);
    await prefs.setBool('useDevGroqKeyForImage', forImage);
    // When Free AI is toggled ON, force active provider to Groq so the free
    // tier is actually used instead of the previously selected provider.
    // When Free AI is toggled OFF, fall back to whichever provider has a key
    // saved so the user is not left with a keyless Groq selection.
    final bestProvider = _bestProviderWithKey(
      geminiApiKey: state.geminiApiKey,
      openAIApiKey: state.openAIApiKey,
      groqApiKey: state.groqApiKey,
    );
    final newTextProvider = forText ? AIProvider.groq : bestProvider;
    final newImageProvider = forImage ? AIProvider.groq : bestProvider;
    await prefs.setInt('activeTextProvider', newTextProvider.index);
    await prefs.setInt('activeImageProvider', newImageProvider.index);
    state = ModelState(
      geminiModel: state.geminiModel,
      geminiImageModel: state.geminiImageModel,
      geminiApiKey: state.geminiApiKey,
      chatGPTModel: state.chatGPTModel,
      chatGPTImageModel: state.chatGPTImageModel,
      openAIApiKey: state.openAIApiKey,
      groqModel: state.groqModel,
      groqImageModel: state.groqImageModel,
      groqApiKey: state.groqApiKey,
      chatHistoryLimit: state.chatHistoryLimit,
      activeTextProvider: newTextProvider,
      activeImageProvider: newImageProvider,
      useDevGroqKeyForText: forText,
      useDevGroqKeyForImage: forImage,
      isLoading: false,
    );
  }

  Future<void> resetModelsToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    // Remove only the model names from storage
    await prefs.remove('geminiModel');
    await prefs.remove('geminiImageModel');
    await prefs.remove('chatGPTModel');
    await prefs.remove('chatGPTImageModel');
    await prefs.remove('groqModel');
    await prefs.remove('groqImageModel');

    // Set the state back to the default models, but keep the existing API keys and providers
    state = ModelState(
      geminiModel: RemoteConfigService.defaultGeminiModel,
      geminiImageModel: RemoteConfigService.defaultGeminiImageModel,
      geminiApiKey: state.geminiApiKey,
      chatGPTModel: RemoteConfigService.defaultOpenAIModel,
      chatGPTImageModel: RemoteConfigService.defaultOpenAIImageModel,
      openAIApiKey: state.openAIApiKey,
      groqModel: RemoteConfigService.defaultGroqModel,
      groqImageModel: RemoteConfigService.defaultGroqImageModel,
      groqApiKey: state.groqApiKey,
      chatHistoryLimit: state.chatHistoryLimit,
      activeTextProvider: state.activeTextProvider,
      activeImageProvider: state.activeImageProvider,
      useDevGroqKeyForText: state.useDevGroqKeyForText,
      useDevGroqKeyForImage: state.useDevGroqKeyForImage,
      isLoading: false,
    );
  }
}

// 3. Create the Provider
final modelProvider = StateNotifierProvider<ModelNotifier, ModelState>(
  (ref) => ModelNotifier(),
);

// New provider to easily check the loading state
final modelProviderLoading = Provider<bool>((ref) {
  return ref.watch(modelProvider).isLoading;
});
