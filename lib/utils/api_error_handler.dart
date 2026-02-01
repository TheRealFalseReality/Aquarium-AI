/// Centralized error message handling for AI API calls
/// 
/// This utility provides consistent error messages across the application
/// when dealing with AI API errors like rate limits, quota issues, etc.
class ApiErrorHandler {
  /// Converts a raw error message into a user-friendly error message
  /// 
  /// Handles common API errors like:
  /// - Rate limits (429 errors)
  /// - Quota exceeded errors
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
    // Check for rate limit errors
    if (error.contains('429') || error.toLowerCase().contains('rate limit')) {
      return '⚠️ **Rate Limit Reached**\n\nThe AI service is busy. Please try again in a moment.';
    }
    
    // Check for quota exceeded errors
    if (error.toLowerCase().contains('quota')) {
      return '⚠️ **Quota Exceeded**\n\nYou have exceeded your API quota. Please check your plan and billing details.';
    }
    
    // Check for API key errors
    if (error.toLowerCase().contains('api key') || error.toLowerCase().contains('unauthorized')) {
      return '⚠️ **Authentication Error**\n\nYour API key may be invalid or missing. Please check your settings.';
    }
    
    // Check for network errors
    if (error.toLowerCase().contains('network') || error.toLowerCase().contains('connection')) {
      return '🔌 **Connection Issue**\n\nCould not reach the AI service. Please check your internet connection.';
    }
    
    // Generic error message
    return '⚠️ **An Unexpected Error Occurred**\n\n$error';
  }
  
  /// Checks if an error is rate limit related
  static bool isRateLimitError(String error) {
    return error.contains('429') || error.toLowerCase().contains('rate limit');
  }
  
  /// Checks if an error is quota related
  static bool isQuotaError(String error) {
    return error.toLowerCase().contains('quota');
  }
}

