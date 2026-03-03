import 'package:dart_openai/dart_openai.dart';

/// Helper class for OpenAI API calls with automatic retry logic
///
/// This utility provides consistent retry behavior with exponential backoff
/// for rate-limited API calls across the application.
class OpenAIRetryHelper {
  /// Generates OpenAI chat completion with automatic retry on rate limits
  ///
  /// Parameters:
  /// - [modelName]: The OpenAI model to use (e.g., 'gpt-4', 'gpt-3.5-turbo')
  /// - [prompt]: The prompt text to send
  /// - [expectJson]: Whether to request JSON response format
  /// - [timeout]: Timeout duration for each attempt (default: 30 seconds)
  /// - [maxRetries]: Maximum number of retry attempts (default: 3)
  /// - [initialDelay]: Initial delay in milliseconds before first retry (default: 1000ms)
  ///
  /// Returns the response text or null if all retries failed
  ///
  /// Throws the last exception if all retries are exhausted
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final response = await OpenAIRetryHelper.generateWithRetry(
  ///     modelName: 'gpt-4',
  ///     prompt: 'Tell me about fish',
  ///     expectJson: false,
  ///   );
  ///   print(response);
  /// } catch (e) {
  ///   print('Failed after retries: $e');
  /// }
  /// ```
  static Future<String?> generateWithRetry({
    required String modelName,
    required String prompt,
    bool expectJson = false,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
    int initialDelay = 1000,
  }) async {
    int retries = 0;
    int delay = initialDelay;

    while (retries < maxRetries) {
      try {
        final response = await OpenAI.instance.chat
            .create(
              model: modelName,
              responseFormat: expectJson ? {"type": "json_object"} : null,
              messages: [
                OpenAIChatCompletionChoiceMessageModel(
                  content: [
                    OpenAIChatCompletionChoiceMessageContentItemModel.text(
                      prompt,
                    ),
                  ],
                  role: OpenAIChatMessageRole.user,
                ),
              ],
            )
            .timeout(timeout);

        return response.choices.first.message.content?.first.text;
      } catch (e) {
        // Check the error message for rate limit indicators
        if (e.toString().contains('429') ||
            e.toString().toLowerCase().contains('rate limit')) {
          retries++;
          if (retries >= maxRetries) {
            rethrow; // Rethrow the exception if we've exhausted all retries
          }
          // Exponential backoff
          await Future.delayed(Duration(milliseconds: delay));
          delay *= 2;
        } else {
          rethrow; // Rethrow other exceptions immediately
        }
      }
    }
    // This should never be reached because the loop will either return a response
    // or rethrow an exception, but we need to satisfy the return type
    throw Exception('Failed to generate response after $maxRetries retries');
  }
}
