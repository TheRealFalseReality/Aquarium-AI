import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/model_provider.dart';
import '../widgets/api_key_dialog.dart';

/// Checks whether the currently active AI provider has an API key configured.
/// If not, shows the [ApiKeyDialog] and returns `false`.
/// Returns `true` when a key is present and the caller may proceed.
bool checkApiKey(BuildContext context, WidgetRef ref) {
  final modelState = ref.read(modelProvider);
  final bool hasKey;
  switch (modelState.activeProvider) {
    case AIProvider.gemini:
      hasKey = modelState.geminiApiKey.isNotEmpty;
      break;
    case AIProvider.openAI:
      hasKey = modelState.openAIApiKey.isNotEmpty;
      break;
    case AIProvider.groq:
      hasKey = modelState.groqApiKey.isNotEmpty;
      break;
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
