import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prompt_provider.dart';
import 'prompt_defaults.dart';

// Use the default from the defaults file
const String systemPrompt = defaultSystemPrompt;

// Helper function to get the system prompt (custom or default)
String getSystemPrompt(WidgetRef ref) {
  return ref.read(promptProvider.notifier).getPrompt(PromptType.system);
}