import 'package:dart_openai/dart_openai.dart';
import 'package:groq/groq.dart';

/// The base URL for Groq's OpenAI-compatible API endpoint.
const String _groqOpenAIBaseUrl = 'https://api.groq.com/openai';

/// The default OpenAI API base URL, used to restore after a Groq vision call.
const String _openAIDefaultBaseUrl = 'https://api.openai.com';

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

  /// Sends a vision (image + text) request to Groq using its OpenAI-compatible API.
  ///
  /// Groq's standard Dart package does not support multimodal messages, so this
  /// method temporarily configures [OpenAI] (from dart_openai) to point at
  /// Groq's OpenAI-compatible endpoint for the duration of the request.
  ///
  /// The response is requested in JSON format (`json_object`) so callers
  /// should parse the returned string as JSON.
  ///
  /// Parameters:
  /// - [apiKey]: The Groq API key
  /// - [model]: A Groq vision-capable model (e.g., 'llama-3.2-11b-vision-preview')
  /// - [prompt]: The text portion of the request
  /// - [base64Image]: The image encoded as a base64 string
  /// - [mimeType]: The MIME type of the image (e.g., 'image/jpeg')
  /// - [timeout]: Timeout duration for the request (default: 55 seconds)
  ///
  /// Returns the response text, or null if no content was returned.
  static Future<String?> generateWithImage({
    required String apiKey,
    required String model,
    required String prompt,
    required String base64Image,
    required String mimeType,
    Duration timeout = const Duration(seconds: 55),
  }) async {
    // Save the current base URL so it can be restored after the Groq call.
    // Fall back to the OpenAI default if it is somehow empty.
    final previousBaseUrl = OpenAI.baseUrl.isNotEmpty ? OpenAI.baseUrl : _openAIDefaultBaseUrl;
    try {
      OpenAI.baseUrl = _groqOpenAIBaseUrl;
      OpenAI.apiKey = apiKey;

      final response = await OpenAI.instance.chat.create(
        model: model,
        responseFormat: {"type": "json_object"},
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
              OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
                  "data:$mimeType;base64,$base64Image"),
            ],
          ),
        ],
      ).timeout(timeout);

      if (response.choices.isEmpty) return null;
      return response.choices.first.message.content?.firstOrNull?.text;
    } finally {
      OpenAI.baseUrl = previousBaseUrl;
    }
  }
}

