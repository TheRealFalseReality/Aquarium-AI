import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prompt_provider.dart';

// Provider that gives access to the current system prompt
final systemPromptProvider = Provider<String>((ref) {
  final promptNotifier = ref.watch(promptProvider.notifier);
  return promptNotifier.getPrompt(PromptType.system);
});

// Provider that gives access to other prompts - can be extended as needed
final photoAnalysisPromptProvider = Provider.family<String, String>((ref, userNote) {
  final promptNotifier = ref.read(promptProvider.notifier);
  final template = promptNotifier.getPrompt(PromptType.photoAnalysis);
  return template.replaceAll('{userNote}', userNote);
});

final automationScriptPromptProvider = Provider.family<String, String>((ref, description) {
  final promptNotifier = ref.read(promptProvider.notifier);
  final template = promptNotifier.getPrompt(PromptType.automationScript);
  return template.replaceAll('{description}', description);
});