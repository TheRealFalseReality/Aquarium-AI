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
  final code = localeCode ??
      PlatformDispatcher.instance.locale.languageCode;
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
