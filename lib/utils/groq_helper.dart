import 'package:groq/groq.dart';

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
}

