import 'dart:convert';

/// Extracts JSON content from a markdown code block or returns the raw text
/// 
/// This utility function handles AI responses that may wrap JSON in markdown
/// code blocks (```json ... ```) or return raw JSON.
/// 
/// Example:
/// ```dart
/// final response = '```json\n{"key": "value"}\n```';
/// final json = extractJson(response); // Returns: '{"key": "value"}'
/// ```
String extractJson(String text) {
  final regExp = RegExp(r'```json\s*([\s\S]*?)\s*```');
  final match = regExp.firstMatch(text);
  if (match != null) {
    return match.group(1) ?? text.trim();
  }
  
  // Check if the text is already valid JSON
  try {
    json.decode(text);
    return text;
  } catch (e) {
    return text;
  }
}

