import 'package:fish_ai/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define default values as constants for reusability
const String defaultGeminiModel = geminiModelDefault;
const String defaultGeminiImageModel = geminiImageModelDefault;

// 1. Define the state class
class ModelState {
  final String geminiModel;
  final String geminiImageModel;

  ModelState({required this.geminiModel, required this.geminiImageModel});
}

// 2. Create the Notifier
class ModelNotifier extends StateNotifier<ModelState> {
  ModelNotifier()
      : super(ModelState(
          // Use the constants for the initial state
          geminiModel: defaultGeminiModel,
          geminiImageModel: defaultGeminiImageModel,
        )) {
    _loadModels();
  }

  // Method to load models from shared preferences
  Future<void> _loadModels() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the constants as the fallback
    final geminiModel = prefs.getString('geminiModel') ?? defaultGeminiModel;
    final geminiImageModel =
        prefs.getString('geminiImageModel') ?? defaultGeminiImageModel;
    state = ModelState(
        geminiModel: geminiModel, geminiImageModel: geminiImageModel);
  }

  // Method to update and save models
  Future<void> setModels(String newGeminiModel, String newGeminiImageModel) async {
    if (newGeminiModel.isEmpty || newGeminiImageModel.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiModel', newGeminiModel);
    await prefs.setString('geminiImageModel', newGeminiImageModel);
    state = ModelState(
        geminiModel: newGeminiModel, geminiImageModel: newGeminiImageModel);
  }

  // *** NEW METHOD ***
  // Method to reset models to their default values
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    // Remove the custom values from storage
    await prefs.remove('geminiModel');
    await prefs.remove('geminiImageModel');
    
    // Set the state back to the default constants
    state = ModelState(
      geminiModel: defaultGeminiModel,
      geminiImageModel: defaultGeminiImageModel,
    );
  }
}

// 3. Create the Provider
final modelProvider = StateNotifierProvider<ModelNotifier, ModelState>(
  (ref) => ModelNotifier(),
);