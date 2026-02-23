import 'package:fish_ai/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  /// Returns the dev key when [useDevGroqKeyForText] is set AND the free AI
  /// tier is enabled via Remote Config; otherwise returns the user's key
  /// (with dev key as fallback when user key is empty and free AI is enabled).
  String get effectiveGroqApiKeyForText {
    final freeAiEnabled = RemoteConfigService.freeAiEnabled;
    if (freeAiEnabled && useDevGroqKeyForText && developerGroqApiKey.isNotEmpty) {
      return developerGroqApiKey;
    }
    return groqApiKey.isNotEmpty
        ? groqApiKey
        : (freeAiEnabled ? developerGroqApiKey : '');
  }

  /// The Groq API key to use for **image/photo** operations.
  /// Returns the dev key when [useDevGroqKeyForImage] is set AND the free AI
  /// tier is enabled via Remote Config; otherwise returns the user's key
  /// (with dev key as fallback when user key is empty and free AI is enabled).
  String get effectiveGroqApiKeyForImage {
    final freeAiEnabled = RemoteConfigService.freeAiEnabled;
    if (freeAiEnabled && useDevGroqKeyForImage && developerGroqApiKey.isNotEmpty) {
      return developerGroqApiKey;
    }
    return groqApiKey.isNotEmpty
        ? groqApiKey
        : (freeAiEnabled ? developerGroqApiKey : '');
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
  /// True when the free AI tier is enabled server-side AND the user has not
  /// provided their own Groq key (or has explicitly chosen the free tier).
  /// Note: [developerGroqApiKey] is intentionally empty in production builds;
  /// the key lives in Firebase Secret Manager and is read by the Cloud Function.
  bool get usingDeveloperGroqKeyForText =>
      RemoteConfigService.freeAiEnabled &&
      (useDevGroqKeyForText || groqApiKey.isEmpty);

  /// Whether image/photo operations are currently routing through the
  /// server-side developer Groq proxy.
  bool get usingDeveloperGroqKeyForImage =>
      RemoteConfigService.freeAiEnabled &&
      (useDevGroqKeyForImage || groqApiKey.isEmpty);

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
      : super(ModelState(
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
        )) {
    _loadModels();
  }

  Future<void> _loadModels() async {
    final prefs = await SharedPreferences.getInstance();
    final geminiModel = prefs.getString('geminiModel') ?? RemoteConfigService.defaultGeminiModel;
    final geminiImageModel =
        prefs.getString('geminiImageModel') ?? RemoteConfigService.defaultGeminiImageModel;
    final geminiApiKey = prefs.getString('geminiApiKey') ?? '';
    final chatGPTModel = prefs.getString('chatGPTModel') ?? RemoteConfigService.defaultOpenAIModel;
    final chatGPTImageModel =
        prefs.getString('chatGPTImageModel') ?? RemoteConfigService.defaultOpenAIImageModel;
    final openAIApiKey = prefs.getString('openAIApiKey') ?? '';
    final groqModel = prefs.getString('groqModel') ?? RemoteConfigService.defaultGroqModel;
    final groqImageModel =
        prefs.getString('groqImageModel') ?? RemoteConfigService.defaultGroqImageModel;
    final groqApiKey = prefs.getString('groqApiKey') ?? '';
    // Migrate legacy single useDevGroqKey → per-operation flags.
    // New users default to ON (true); existing users who had an explicit setting keep it.
    final legacyDevKey = prefs.getBool('useDevGroqKey');
    final useDevGroqKeyForText = prefs.getBool('useDevGroqKeyForText') ?? legacyDevKey ?? true;
    final useDevGroqKeyForImage = prefs.getBool('useDevGroqKeyForImage') ?? legacyDevKey ?? true;
    final chatHistoryLimit = (prefs.getInt('chatHistoryLimit') ?? defaultChatHistoryLimit)
        .clamp(minChatHistoryLimit, maxChatHistoryLimit);
    // Migrate legacy 'activeProvider' to both text and image providers if new keys are absent
    final legacyProviderIndex = prefs.getInt('activeProvider');
    final activeTextProvider = AIProvider.values[
        prefs.getInt('activeTextProvider') ?? legacyProviderIndex ?? defaultAIProvider.index];
    final activeImageProvider = AIProvider.values[
        prefs.getInt('activeImageProvider') ?? legacyProviderIndex ?? defaultAIProvider.index];

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
    await prefs.setString('geminiModel', newGeminiModel);
    await prefs.setString('geminiImageModel', newGeminiImageModel);
    await prefs.setString('geminiApiKey', newGeminiApiKey);
    await prefs.setString('chatGPTModel', newChatGPTModel);
    await prefs.setString('chatGPTImageModel', newChatGPTImageModel);
    await prefs.setString('openAIApiKey', newOpenAIApiKey);
    await prefs.setString('groqModel', newGroqModel);
    await prefs.setString('groqImageModel', newGroqImageModel);
    await prefs.setString('groqApiKey', newGroqApiKey);
    await prefs.setInt('chatHistoryLimit', newChatHistoryLimit.clamp(minChatHistoryLimit, maxChatHistoryLimit));
    await prefs.setInt('activeTextProvider', newActiveTextProvider.index);
    await prefs.setInt('activeImageProvider', newActiveImageProvider.index);
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
      chatHistoryLimit: newChatHistoryLimit.clamp(minChatHistoryLimit, maxChatHistoryLimit),
      activeTextProvider: newActiveTextProvider,
      activeImageProvider: newActiveImageProvider,
      useDevGroqKeyForText: newUseDevGroqKeyForText,
      useDevGroqKeyForImage: newUseDevGroqKeyForImage,
      isLoading: false,
    );
  }

  /// Directly update the dev Groq key toggles without changing any other settings.
  /// Useful for quick on/off from the API Key dialog.
  Future<void> setDevGroqKeyToggles({
    required bool forText,
    required bool forImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDevGroqKeyForText', forText);
    await prefs.setBool('useDevGroqKeyForImage', forImage);
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
      activeTextProvider: state.activeTextProvider,
      activeImageProvider: state.activeImageProvider,
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
