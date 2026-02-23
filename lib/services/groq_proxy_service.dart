import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for the Firebase `groqProxy` Cloud Function.
///
/// When the app is using the developer Groq API key (free tier), all Groq
/// requests are routed through this service instead of calling the Groq API
/// directly. The actual API key lives in Firebase Secret Manager and is never
/// sent to the client device.
///
/// Calls are made directly to the Firebase callable function HTTPS endpoint
/// using the standard Firebase callable protocol (no additional SDK required).
class GroqProxyService {
  /// Firebase callable function endpoint for [groqProxy].
  static const _endpoint =
      'https://us-central1-fishai-31d40.cloudfunctions.net/groqProxy';

  /// Internal helper: POST [data] to the callable function endpoint.
  ///
  /// Wraps the Firebase callable protocol (body `{"data": ...}`,
  /// response `{"result": ...}`) and returns the `content` field from the
  /// function's result map.  Throws an [Exception] on HTTP errors or
  /// function-level errors returned in the `error` envelope.
  static Future<String?> _call(
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': data}),
    ).timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
          'Groq proxy error (${response.statusCode}): ${response.body}');
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
          'Groq proxy returned non-JSON response (${response.statusCode})');
    }
    if (decoded.containsKey('error')) {
      final error = decoded['error'] as Map<String, dynamic>;
      throw Exception('Groq proxy error: ${error['message']}');
    }

    final result = decoded['result'] as Map<String, dynamic>?;
    return result?['content'] as String?;
  }

  /// Sends a chat/text completion request via the server-side proxy.
  ///
  /// Parameters match [GroqHelper.sendChatMessages] so the two can be used
  /// interchangeably at call sites.
  ///
  /// Returns the assistant reply text, or `null` if the model returned no content.
  static Future<String?> sendChatMessages({
    required String model,
    required String systemPrompt,
    required List<Map<String, String>> messages,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _call(
        {
          'type': 'chat',
          'model': model,
          'systemPrompt': systemPrompt,
          'messages': messages,
        },
        timeout: timeout,
      );

  /// Sends a vision (image + text) completion request via the server-side proxy.
  ///
  /// Parameters match [GroqHelper.generateWithImage] so the two can be used
  /// interchangeably at call sites.
  ///
  /// Returns the model response text, or `null` if no content was returned.
  static Future<String?> generateWithImage({
    required String model,
    required String prompt,
    required String base64Image,
    required String mimeType,
    Duration timeout = const Duration(seconds: 70),
  }) =>
      _call(
        {
          'type': 'vision',
          'model': model,
          'prompt': prompt,
          'base64Image': base64Image,
          'mimeType': mimeType,
        },
        timeout: timeout,
      );

  /// Sends a single prompt to the model via the server-side proxy.
  ///
  /// Used by providers that build a full prompt string and send it as a single
  /// user message (e.g. aquarium stocking and fish compatibility providers).
  ///
  /// Returns the assistant reply text, or `null` if no content was returned.
  static Future<String?> sendMessage({
    required String model,
    required String prompt,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _call(
        {
          'type': 'chat',
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        },
        timeout: timeout,
      );
}
