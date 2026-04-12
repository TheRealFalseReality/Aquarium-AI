import 'dart:ui' show PlatformDispatcher;

/// Resolves the language name to append to an AI system prompt.
///
/// - [aiResponseLanguage] is the user's explicit AI language preference:
///   - `null`   → follow the app locale (uses [localeCode])
///   - `""`     → no instruction (AI decides, typically English)
///   - other    → explicit language name, e.g. `"Portuguese"`
/// - [localeCode] is the app's locale (e.g. `"de"`, `"es"`), or `null`
///   for system default.
///
/// Returns the language name to use in the instruction, or `null` if no
/// language instruction should be added.
String? resolveAiLanguage({
  required String? aiResponseLanguage,
  required String? localeCode,
}) {
  // Explicit "" means "no instruction"
  if (aiResponseLanguage != null && aiResponseLanguage.isEmpty) return null;

  // Explicit non-empty language name
  if (aiResponseLanguage != null && aiResponseLanguage.isNotEmpty) {
    return aiResponseLanguage;
  }

  // null → follow app locale
  final code = localeCode ?? PlatformDispatcher.instance.locale.languageCode;
  return _languageName(code);
}

/// Maps a supported BCP-47 language code to a display name for the AI prompt.
/// Returns `null` for English or any unrecognized code (no instruction needed).
String? _languageName(String code) {
  switch (code) {
    case 'de':
      return 'German';
    case 'es':
      return 'Spanish';
    case 'fr':
      return 'French';
    default:
      return null;
  }
}

/// Appends a language instruction to [prompt] if needed.
/// Returns the original prompt unchanged when no instruction is required.
String appendLanguageInstruction(
  String prompt, {
  required String? aiResponseLanguage,
  required String? localeCode,
}) {
  final lang = resolveAiLanguage(
    aiResponseLanguage: aiResponseLanguage,
    localeCode: localeCode,
  );
  if (lang == null) return prompt;
  return '$prompt\nIMPORTANT: Always respond in $lang.';
}

/// Returns the human-readable label for an experience level string.
String _experienceLevelLabel(String level) {
  switch (level) {
    case 'intermediate':
      return 'Intermediate';
    case 'advanced':
      return 'Advanced';
    case 'expert':
      return 'Expert';
    default:
      return 'Beginner';
  }
}

/// Appends an experience level instruction to [prompt].
/// [experienceLevel] should be one of: 'beginner', 'intermediate', 'advanced', 'expert'.
/// Returns the original prompt unchanged when [experienceLevel] is null or empty.
String appendExperienceInstruction(
  String prompt, {
  required String? experienceLevel,
}) {
  if (experienceLevel == null || experienceLevel.isEmpty) return prompt;
  final label = _experienceLevelLabel(experienceLevel);
  return '$prompt\nUser experience level: $label. Tailor your response accordingly — use simple explanations for beginners, and more technical depth for advanced/expert users.';
}

/// Appends both a language instruction and an experience level instruction.
/// Combines [appendLanguageInstruction] and [appendExperienceInstruction].
String appendAiContextInstructions(
  String prompt, {
  required String? aiResponseLanguage,
  required String? localeCode,
  required String? experienceLevel,
}) {
  final withLang = appendLanguageInstruction(
    prompt,
    aiResponseLanguage: aiResponseLanguage,
    localeCode: localeCode,
  );
  return appendExperienceInstruction(withLang, experienceLevel: experienceLevel);
}
