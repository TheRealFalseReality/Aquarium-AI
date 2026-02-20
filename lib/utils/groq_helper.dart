import 'dart:convert';

import 'package:groq/groq.dart';
import 'package:http/http.dart' as http;

/// The Groq OpenAI-compatible chat completions endpoint.
const String _groqChatEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

/// Helper class for Groq API initialization and common operations
/// 
/// This utility provides consistent Groq client initialization
/// across the application, reducing code duplication.
class GroqHelper {
  /// Creates and initializes a Groq client with the specified configuration
  /// 
  /// Parameters:
  /// - [apiKey]: The Groq API key
  /// - [model]: The model to use (e.g., 'llama3-8b-8192')
  /// - [systemPrompt]: Optional system prompt to set as custom instructions
  /// 
  /// Returns a configured Groq instance ready for chat
  /// 
  /// Example:
  /// ```dart
  /// final groq = GroqHelper.createClient(
  ///   apiKey: 'your-api-key',
  ///   model: 'llama3-8b-8192',
  ///   systemPrompt: 'You are a helpful assistant',
  /// );
  /// final response = await groq.sendMessage('Hello!');
  /// ```
  static Groq createClient({
    required String apiKey,
    required String model,
    String? systemPrompt,
  }) {
    final configuration = Configuration(model: model);
    final groq = Groq(apiKey: apiKey, configuration: configuration);
    groq.startChat();
    
    if (systemPrompt != null) {
      groq.setCustomInstructionsWith(systemPrompt);
    }
    
    return groq;
  }

  /// Sends a vision (image + text) request directly to Groq's chat completions
  /// endpoint using the `http` package.
  ///
  /// Groq's standard Dart package does not support multimodal messages, and
  /// routing through `dart_openai` can produce serialization mismatches. This
  /// method constructs the JSON body manually to match exactly what Groq expects.
  ///
  /// The response is requested in JSON format (`json_object`) so callers
  /// should parse the returned string as JSON.
  ///
  /// Parameters:
  /// - [apiKey]: The Groq API key
  /// - [model]: A Groq vision-capable model
  ///   (e.g., 'meta-llama/llama-4-scout-17b-16e-instruct')
  /// - [prompt]: The text portion of the request
  /// - [base64Image]: The image encoded as a base64 string
  /// - [mimeType]: The MIME type of the image (e.g., 'image/jpeg')
  /// - [timeout]: Timeout duration for the request (default: 55 seconds)
  ///
  /// Returns the response text, or null if no content was returned.
  /// Throws an [Exception] if the API returns a non-200 status.
  static Future<String?> generateWithImage({
    required String apiKey,
    required String model,
    required String prompt,
    required String base64Image,
    required String mimeType,
    Duration timeout = const Duration(seconds: 55),
  }) async {
    final requestBody = jsonEncode({
      'model': model,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
            },
          ],
        }
      ],
    });

    final response = await http.post(
      Uri.parse(_groqChatEndpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    ).timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception('Groq vision API error (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List?;
    if (choices == null || choices.isEmpty) return null;
    final firstChoice = choices.first;
    if (firstChoice is! Map) return null;
    final message = firstChoice['message'];
    if (message is! Map) return null;
    return message['content'] as String?;
  }
}

