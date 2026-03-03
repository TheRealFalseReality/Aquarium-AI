/// Centralized error message handling for AI API calls
///
/// This utility provides consistent error messages across the application
/// when dealing with AI API errors like rate limits, quota issues, etc.
class ApiErrorHandler {
  /// Converts a raw error message into a user-friendly error message
  ///
  /// Handles common API errors like:
  /// - TLS/SSL handshake errors
  /// - Rate limits (429 errors)
  /// - Quota exceeded errors
  /// - Network connection issues
  /// - Generic errors
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await callAIAPI();
  /// } catch (e) {
  ///   final friendlyError = ApiErrorHandler.getFriendlyErrorMessage(e.toString());
  ///   showError(friendlyError);
  /// }
  /// ```
  static String getFriendlyErrorMessage(String error) {
    // Check for TLS/SSL handshake errors
    if (isHandshakeError(error)) {
      return '🔒 **Secure Connection Failed**\n\n'
          'Unable to establish a secure connection. This could be due to:\n'
          '• Network security settings or firewall\n'
          '• VPN or proxy interference\n'
          '• Outdated device certificates\n'
          '• Server connectivity issues\n\n'
          'Try disabling VPN/proxy or check your network settings.';
    }

    final errorLower = error.toLowerCase();

    // Check for rate limit errors
    if (error.contains('429') || errorLower.contains('rate limit')) {
      return '⚠️ **Rate Limit Reached**\n\nThe AI service is busy. Please try again in a moment.';
    }

    // Check for quota exceeded errors
    if (errorLower.contains('quota')) {
      return '⚠️ **Quota Exceeded**\n\nYou have exceeded your API quota. Please check your plan and billing details.';
    }

    // Check for API key errors
    if (errorLower.contains('api key') || errorLower.contains('unauthorized')) {
      return '⚠️ **Authentication Error**\n\nYour API key may be invalid or missing. Please check your settings.';
    }

    // Check for network errors
    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return '🔌 **Connection Issue**\n\nCould not reach the AI service. Please check your internet connection.';
    }

    // Generic error message
    return '⚠️ **An Unexpected Error Occurred**\n\n$error';
  }

  /// Checks if an error is API key related (missing or invalid key)
  static bool isApiKeyError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('api key') ||
        lower.contains('unauthorized') ||
        lower.contains('authentication') ||
        lower.contains('invalid_api_key') ||
        lower.contains('not set. please');
  }

  /// Checks if an error is rate limit related
  static bool isRateLimitError(String error) {
    return error.contains('429') || error.toLowerCase().contains('rate limit');
  }

  /// Checks if an error is quota related
  static bool isQuotaError(String error) {
    return error.toLowerCase().contains('quota');
  }

  /// Checks if an error is TLS/SSL handshake related
  static bool isHandshakeError(String error) {
    return error.toLowerCase().contains('handshake') ||
        error.toLowerCase().contains('certificate') ||
        error.toLowerCase().contains('ssl') ||
        error.toLowerCase().contains('tls');
  }

  /// Checks if an error is network/connection related
  static bool isNetworkError(String error) {
    return error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection') ||
        error.toLowerCase().contains('socket') ||
        isHandshakeError(error);
  }
}
