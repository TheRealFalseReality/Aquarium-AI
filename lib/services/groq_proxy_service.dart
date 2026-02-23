import 'package:cloud_functions/cloud_functions.dart';

/// Client for the Firebase `groqProxy` Cloud Function.
///
/// When the app is using the developer Groq API key (free tier), all Groq
/// requests are routed through this service instead of calling the Groq API
/// directly. The actual API key lives in Firebase Secret Manager and is never
/// sent to the client device.
class GroqProxyService {
  /// Default callable instance for chat and sendMessage calls (30 s timeout).
  static final _callable =
      FirebaseFunctions.instance.httpsCallable('groqProxy');

  /// Callable instance with an extended timeout for vision requests.
  static final _visionCallable = FirebaseFunctions.instance.httpsCallable(
    'groqProxy',
    options: HttpsCallableOptions(timeout: const Duration(seconds: 70)),
  );

  /// Sends a chat/text completion request via the server-side proxy.
  ///
  /// Parameters match [GroqHelper.sendChatMessages] so the two can be used
  /// interchangeably at call sites.
  ///
  /// Returns the assistant reply text, or `null` if the model returned no content.
  /// Throws a [FirebaseFunctionsException] on error.
  static Future<String?> sendChatMessages({
    required String model,
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    final result = await _callable.call<Map<dynamic, dynamic>>({
      'type': 'chat',
      'model': model,
      'systemPrompt': systemPrompt,
      'messages': messages,
    });
    return result.data['content'] as String?;
  }

  /// Sends a vision (image + text) completion request via the server-side proxy.
  ///
  /// Parameters match [GroqHelper.generateWithImage] so the two can be used
  /// interchangeably at call sites.
  ///
  /// Returns the model response text, or `null` if no content was returned.
  /// Throws a [FirebaseFunctionsException] on error.
  static Future<String?> generateWithImage({
    required String model,
    required String prompt,
    required String base64Image,
    required String mimeType,
  }) async {
    final result = await _visionCallable.call<Map<dynamic, dynamic>>({
      'type': 'vision',
      'model': model,
      'prompt': prompt,
      'base64Image': base64Image,
      'mimeType': mimeType,
    });
    return result.data['content'] as String?;
  }

  /// Sends a single prompt to the model via the server-side proxy.
  ///
  /// Used by providers that build a full prompt string and send it as a single
  /// user message (e.g. aquarium stocking and fish compatibility providers).
  ///
  /// Returns the assistant reply text, or `null` if no content was returned.
  /// Throws a [FirebaseFunctionsException] on error.
  static Future<String?> sendMessage({
    required String model,
    required String prompt,
  }) async {
    final result = await _callable.call<Map<dynamic, dynamic>>({
      'type': 'chat',
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    });
    return result.data['content'] as String?;
  }
}
