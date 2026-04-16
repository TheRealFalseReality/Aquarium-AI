/// The type of API error, used to determine the appropriate user-facing message
/// and call-to-action buttons.
enum ApiErrorType {
  /// The API key is missing, invalid, or unauthorized.
  apiKey,

  /// The user has hit a rate limit (HTTP 429 or similar).
  rateLimit,

  /// The user's API quota or billing limit is exceeded.
  quota,

  /// A TLS/SSL handshake or certificate error.
  handshake,

  /// A network or connectivity error (no internet, DNS failure, etc.).
  network,

  /// The request timed out before the server could respond.
  timeout,

  /// The server returned a 5xx error (internal server error, bad gateway, etc.).
  serverError,

  /// The AI declined to respond due to a content safety filter.
  contentFilter,

  /// The AI response could not be parsed (malformed JSON, unexpected format).
  malformedResponse,

  /// The API returned a 403 Forbidden, often related to billing or plan limits.
  forbidden,

  /// An unrecognised error that doesn't fit any of the above categories.
  unknown,
}

/// Centralized error message handling for AI API calls.
///
/// This utility provides consistent error messages across the application
/// when dealing with AI API errors like rate limits, quota issues, etc.
class ApiErrorHandler {
  /// Classifies a raw error string into an [ApiErrorType].
  static ApiErrorType classifyError(String error) {
    if (isHandshakeError(error)) return ApiErrorType.handshake;
    if (isTimeoutError(error)) return ApiErrorType.timeout;
    if (isContentFilterError(error)) return ApiErrorType.contentFilter;
    if (isMalformedResponseError(error)) return ApiErrorType.malformedResponse;
    if (isRateLimitError(error)) return ApiErrorType.rateLimit;
    if (isQuotaError(error)) return ApiErrorType.quota;
    if (isForbiddenError(error)) return ApiErrorType.forbidden;
    if (isApiKeyError(error)) return ApiErrorType.apiKey;
    if (isServerError(error)) return ApiErrorType.serverError;
    if (isNetworkError(error)) return ApiErrorType.network;
    return ApiErrorType.unknown;
  }

  /// Converts a raw error message into a user-friendly error message.
  ///
  /// Handles common API errors like:
  /// - TLS/SSL handshake errors
  /// - Rate limits (429 errors)
  /// - Quota exceeded errors
  /// - API key / authentication errors
  /// - Network connection issues
  /// - Timeout errors
  /// - Server errors (5xx)
  /// - Content safety filter blocks
  /// - Malformed AI responses
  /// - Forbidden / billing errors
  /// - Generic errors (falls back to the raw message)
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
    switch (classifyError(error)) {
      case ApiErrorType.handshake:
        return '🔒 **Secure Connection Failed**\n\n'
            'Unable to establish a secure connection. This could be due to:\n'
            '• Network security settings or firewall\n'
            '• VPN or proxy interference\n'
            '• Outdated device certificates\n\n'
            'Try disabling your VPN/proxy or switching to a different network.';

      case ApiErrorType.timeout:
        return '⏳ **Request Timed Out**\n\n'
            'The AI service took too long to respond. This can happen when the '
            'service is under heavy load.\n\n'
            'Please try again in a moment.';

      case ApiErrorType.contentFilter:
        return '🛡️ **Content Filtered**\n\n'
            'The AI could not process this request because it was flagged by '
            'the safety filter.\n\n'
            'Try rephrasing your question or using different terms.';

      case ApiErrorType.malformedResponse:
        return '📄 **Unexpected Response**\n\n'
            'The AI returned a response that could not be read properly.\n\n'
            'Please try again — this is usually a one-time issue.';

      case ApiErrorType.rateLimit:
        return '⏱️ **Rate Limit Reached**\n\n'
            'You\'ve sent too many requests in a short time. '
            'Please wait a moment and try again.\n\n'
            'To avoid this, consider upgrading your API plan or adding your '
            'own API key in **Settings**.';

      case ApiErrorType.quota:
        return '📊 **API Quota Exceeded**\n\n'
            'Your API usage limit has been reached for the current billing '
            'period.\n\n'
            'Check your API provider\'s dashboard to review your plan, or '
            'add a different API key in **Settings**.';

      case ApiErrorType.forbidden:
        return '🚫 **Access Denied**\n\n'
            'Your API key does not have permission to use this service. '
            'This usually means your plan doesn\'t include this feature, '
            'or billing needs to be set up.\n\n'
            'Check your API provider\'s dashboard or update your key in '
            '**Settings**.';

      case ApiErrorType.apiKey:
        return '🔑 **API Key Issue**\n\n'
            'Your API key appears to be missing or invalid.\n\n'
            'Go to **Settings** to add or update your API key.';

      case ApiErrorType.serverError:
        return '🔧 **Service Temporarily Unavailable**\n\n'
            'The AI service is experiencing issues on their end.\n\n'
            'This is usually resolved quickly — please try again in a few '
            'minutes.';

      case ApiErrorType.network:
        return '🔌 **Connection Issue**\n\n'
            'Could not reach the AI service. Please check that:\n'
            '• You have an active internet connection\n'
            '• Your Wi-Fi or mobile data is turned on\n\n'
            'Then try again.';

      case ApiErrorType.unknown:
        // Fall back to the raw error message, but clean it up.
        final cleaned = _cleanRawError(error);
        return '⚠️ **Something Went Wrong**\n\n$cleaned\n\n'
            'If this keeps happening, try restarting the app or checking '
            'your settings.';
    }
  }

  /// Strips common exception wrapper text to make the raw error more readable.
  static String _cleanRawError(String error) {
    var cleaned = error;
    // Remove "Exception: " prefixes (including nested ones).
    cleaned = cleaned.replaceAll(RegExp(r'^(Exception:\s*)+', multiLine: true), '');
    // Remove "FormatException: " prefixes.
    cleaned = cleaned.replaceAll(
      RegExp(r'^FormatException:\s*', multiLine: true),
      '',
    );
    // Remove generic Dart error prefixes.
    cleaned = cleaned.replaceAll(
      RegExp(r'^(Error|TypeError|StateError|RangeError):\s*', multiLine: true),
      '',
    );
    return cleaned.trim();
  }

  /// Checks if an error is API key related (missing or invalid key).
  static bool isApiKeyError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('api key') ||
        lower.contains('api_key') ||
        lower.contains('unauthorized') ||
        lower.contains('authentication') ||
        lower.contains('invalid_api_key') ||
        lower.contains('not set. please') ||
        lower.contains('unauthenticated');
  }

  /// Checks if an error is rate limit related.
  static bool isRateLimitError(String error) {
    final lower = error.toLowerCase();
    return error.contains('429') ||
        lower.contains('rate limit') ||
        lower.contains('rate_limit') ||
        lower.contains('too many requests');
  }

  /// Checks if an error is quota related.
  static bool isQuotaError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('quota') ||
        lower.contains('billing') ||
        lower.contains('insufficient_quota') ||
        lower.contains('exceeded your current') ||
        lower.contains('usage limit');
  }

  /// Checks if an error is TLS/SSL handshake related.
  static bool isHandshakeError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('handshake') ||
        lower.contains('certificate') ||
        lower.contains('ssl') ||
        lower.contains('tls');
  }

  /// Checks if an error is network/connection related.
  static bool isNetworkError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('socket') ||
        lower.contains('dns') ||
        lower.contains('host lookup') ||
        lower.contains('no address associated') ||
        isHandshakeError(error);
  }

  /// Checks if an error is a timeout.
  static bool isTimeoutError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('time out') ||
        lower.contains('deadline exceeded');
  }

  /// Checks if an error is a server-side error (5xx).
  static bool isServerError(String error) {
    final lower = error.toLowerCase();
    return error.contains('500') ||
        error.contains('502') ||
        error.contains('503') ||
        error.contains('504') ||
        lower.contains('internal server error') ||
        lower.contains('bad gateway') ||
        lower.contains('service unavailable') ||
        lower.contains('server error');
  }

  /// Checks if an error is from a content safety filter.
  static bool isContentFilterError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('safety') ||
        lower.contains('content filter') ||
        lower.contains('content_filter') ||
        lower.contains('blocked') ||
        lower.contains('harm category') ||
        lower.contains('finish_reason: safety') ||
        lower.contains('responsible ai');
  }

  /// Checks if an error is from a malformed or unparseable AI response.
  static bool isMalformedResponseError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('formatexception') ||
        lower.contains('malformed json') ||
        lower.contains('unexpected end of input') ||
        lower.contains('not a valid json') ||
        (lower.contains('json') && lower.contains('parse'));
  }

  /// Checks if an error is a 403 Forbidden error.
  static bool isForbiddenError(String error) {
    final lower = error.toLowerCase();
    return error.contains('403') ||
        lower.contains('forbidden') ||
        lower.contains('permission denied') ||
        lower.contains('access denied');
  }

  /// Returns `true` when the error type should offer a "Retry" action.
  static bool isRetryableError(String error) {
    final type = classifyError(error);
    return type == ApiErrorType.timeout ||
        type == ApiErrorType.network ||
        type == ApiErrorType.serverError ||
        type == ApiErrorType.handshake ||
        type == ApiErrorType.malformedResponse ||
        type == ApiErrorType.unknown;
  }

  /// Returns `true` when the error type should offer a "Go to Settings" action
  /// (i.e. the user should check or update their API key / plan).
  static bool isSettingsActionable(String error) {
    final type = classifyError(error);
    return type == ApiErrorType.apiKey ||
        type == ApiErrorType.quota ||
        type == ApiErrorType.forbidden;
  }
}
