import 'package:fish_ai/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define default values as constants for reusability
const String defaultGeminiModel = geminiModelDefault;
const String defaultGeminiImageModel = geminiImageModelDefault;
const String defaultChatGPTModel = openAIModelDefault;
const String defaultChatGPTImageModel = openAIImageModelDefault;
const String defaultGroqModel = groqModelDefault;
const String defaultGroqImageModel = groqImageModelDefault;
const AIProvider defaultAIProvider = AIProvider.gemini;

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
  /// Provider used for text/chat operations
  final AIProvider activeTextProvider;
  /// Provider used for image/multimedia analysis operations
  final AIProvider activeImageProvider;
  final bool isLoading;

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
    required this.activeTextProvider,
    required this.activeImageProvider,
    this.isLoading = true,
  });

  /// Convenience getter: returns the text provider (kept for backward compat)
  AIProvider get activeProvider => activeTextProvider;
}

// 2. Create the Notifier
class ModelNotifier extends StateNotifier<ModelState> {
  ModelNotifier()
      : super(ModelState(
          geminiModel: defaultGeminiModel,
          geminiImageModel: defaultGeminiImageModel,
          geminiApiKey: '',
          chatGPTModel: defaultChatGPTModel,
          chatGPTImageModel: defaultChatGPTImageModel,
          openAIApiKey: '',
          groqModel: defaultGroqModel,
          groqImageModel: defaultGroqImageModel,
          groqApiKey: '',
          activeTextProvider: defaultAIProvider,
          activeImageProvider: defaultAIProvider,
        )) {
    _loadModels();
  }

  Future<void> _loadModels() async {
    final prefs = await SharedPreferences.getInstance();
    final geminiModel = prefs.getString('geminiModel') ?? defaultGeminiModel;
    final geminiImageModel =
        prefs.getString('geminiImageModel') ?? defaultGeminiImageModel;
    final geminiApiKey = prefs.getString('geminiApiKey') ?? '';
    final chatGPTModel = prefs.getString('chatGPTModel') ?? defaultChatGPTModel;
    final chatGPTImageModel =
        prefs.getString('chatGPTImageModel') ?? defaultChatGPTImageModel;
    final openAIApiKey = prefs.getString('openAIApiKey') ?? '';
    final groqModel = prefs.getString('groqModel') ?? defaultGroqModel;
    final groqImageModel =
        prefs.getString('groqImageModel') ?? defaultGroqImageModel;
    final groqApiKey = prefs.getString('groqApiKey') ?? '';
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
      activeTextProvider: activeTextProvider,
      activeImageProvider: activeImageProvider,
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
    await prefs.setInt('activeTextProvider', newActiveTextProvider.index);
    await prefs.setInt('activeImageProvider', newActiveImageProvider.index);

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
      activeTextProvider: newActiveTextProvider,
      activeImageProvider: newActiveImageProvider,
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
      geminiModel: defaultGeminiModel,
      geminiImageModel: defaultGeminiImageModel,
      geminiApiKey: state.geminiApiKey,
      chatGPTModel: defaultChatGPTModel,
      chatGPTImageModel: defaultChatGPTImageModel,
      openAIApiKey: state.openAIApiKey,
      groqModel: defaultGroqModel,
      groqImageModel: defaultGroqImageModel,
      groqApiKey: state.groqApiKey,
      activeTextProvider: state.activeTextProvider,
      activeImageProvider: state.activeImageProvider,
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
