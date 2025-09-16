import 'package:fish_ai/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define default values as constants for reusability
const String defaultGeminiModel = geminiModelDefault;
const String defaultGeminiImageModel = geminiImageModelDefault;
const String defaultChatGPTModel = openAIModelDefault;
const String defaultChatGPTImageModel = openAIImageModelDefault;
const AIProvider defaultAIProvider = AIProvider.gemini;

enum AIProvider { gemini, openAI }

// 1. Define the state class
class ModelState {
  final String geminiModel;
  final String geminiImageModel;
  final String geminiApiKey;
  final String chatGPTModel;
  final String chatGPTImageModel;
  final String openAIApiKey;
  final AIProvider activeProvider;
  final bool isLoading;

  ModelState({
    required this.geminiModel,
    required this.geminiImageModel,
    required this.geminiApiKey,
    required this.chatGPTModel,
    required this.chatGPTImageModel,
    required this.openAIApiKey,
    required this.activeProvider,
    this.isLoading = true,
  });
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
          activeProvider: defaultAIProvider,
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
    final chatGPTImageModel = prefs.getString('chatGPTImageModel') ?? defaultChatGPTImageModel;
    final openAIApiKey = prefs.getString('openAIApiKey') ?? '';
    final activeProvider = AIProvider.values[prefs.getInt('activeProvider') ?? defaultAIProvider.index];

    state = ModelState(
      geminiModel: geminiModel,
      geminiImageModel: geminiImageModel,
      geminiApiKey: geminiApiKey,
      chatGPTModel: chatGPTModel,
      chatGPTImageModel: chatGPTImageModel,
      openAIApiKey: openAIApiKey,
      activeProvider: activeProvider,
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
    required AIProvider newActiveProvider,
  }) async {
    if (newGeminiModel.isEmpty || newGeminiImageModel.isEmpty || newChatGPTModel.isEmpty || newChatGPTImageModel.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiModel', newGeminiModel);
    await prefs.setString('geminiImageModel', newGeminiImageModel);
    await prefs.setString('geminiApiKey', newGeminiApiKey);
    await prefs.setString('chatGPTModel', newChatGPTModel);
    await prefs.setString('chatGPTImageModel', newChatGPTImageModel);
    await prefs.setString('openAIApiKey', newOpenAIApiKey);
    await prefs.setInt('activeProvider', newActiveProvider.index);

    state = ModelState(
      geminiModel: newGeminiModel,
      geminiImageModel: newGeminiImageModel,
      geminiApiKey: newGeminiApiKey,
      chatGPTModel: newChatGPTModel,
      chatGPTImageModel: newChatGPTImageModel,
      openAIApiKey: newOpenAIApiKey,
      activeProvider: newActiveProvider,
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

    // Set the state back to the default models, but keep the existing API keys and provider
    state = ModelState(
      geminiModel: defaultGeminiModel,
      geminiImageModel: defaultGeminiImageModel,
      geminiApiKey: state.geminiApiKey,
      chatGPTModel: defaultChatGPTModel,
      chatGPTImageModel: defaultChatGPTImageModel,
      openAIApiKey: state.openAIApiKey,
      activeProvider: state.activeProvider,
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