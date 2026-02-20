import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/model_provider.dart';
import '../widgets/api_key_dialog.dart';

/// Checks whether the currently active AI providers (text and image) have API keys configured.
/// If not, shows the [ApiKeyDialog] and returns `false`.
/// Returns `true` when keys are present and the caller may proceed.
bool checkApiKey(BuildContext context, WidgetRef ref) {
  final modelState = ref.read(modelProvider);
  bool hasKey = true;

  // Check text provider key
  switch (modelState.activeTextProvider) {
    case AIProvider.gemini:
      if (modelState.geminiApiKey.isEmpty) hasKey = false;
      break;
    case AIProvider.openAI:
      if (modelState.openAIApiKey.isEmpty) hasKey = false;
      break;
    case AIProvider.groq:
      if (modelState.groqApiKey.isEmpty) hasKey = false;
      break;
  }

  // Check image provider key (only if different from text provider)
  if (hasKey && modelState.activeImageProvider != modelState.activeTextProvider) {
    switch (modelState.activeImageProvider) {
      case AIProvider.gemini:
        if (modelState.geminiApiKey.isEmpty) hasKey = false;
        break;
      case AIProvider.openAI:
        if (modelState.openAIApiKey.isEmpty) hasKey = false;
        break;
      case AIProvider.groq:
        if (modelState.groqApiKey.isEmpty) hasKey = false;
        break;
    }
  }

  if (!hasKey) {
    showDialog(
      context: context,
      builder: (_) => const ApiKeyDialog(),
    );
    return false;
  }
  return true;
}
