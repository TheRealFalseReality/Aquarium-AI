import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ModelState {
  final String geminiModel;
  final String geminiImageModel;

  ModelState({required this.geminiModel, required this.geminiImageModel});
}
// 2. Create the Notifier
class ModelNotifier extends StateNotifier<ModelState> {
  ModelNotifier()
      : super(ModelState(
          geminiModel: geminiModel,
          geminiImageModel: geminiImageModel,
        )) {
    _loadModels();
  }

  // Method to load models from shared preferences
  Future<void> _loadModels() async {
    final prefs = await SharedPreferences.getInstance();
    final geminiModel = prefs.getString('geminiModel') ?? state.geminiModel;
    final geminiImageModel =
        prefs.getString('geminiImageModel') ?? state.geminiImageModel;
    state = ModelState(
        geminiModel: geminiModel, geminiImageModel: geminiImageModel);
  }

  // Method to update and save models
  Future<void> setModels(String newGeminiModel, String newGeminiImageModel) async {
    if (newGeminiModel.isEmpty || newGeminiImageModel.isEmpty) {
      // Basic validation: do not save if empty
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiModel', newGeminiModel);
    await prefs.setString('geminiImageModel', newGeminiImageModel);
    state = ModelState(
        geminiModel: newGeminiModel, geminiImageModel: newGeminiImageModel);
  }
}

final modelProvider = StateNotifierProvider<ModelNotifier, ModelState>(
  (ref) => ModelNotifier(),
);