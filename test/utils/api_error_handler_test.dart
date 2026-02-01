import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/utils/api_error_handler.dart';

void main() {
  group('ApiErrorHandler', () {
    group('getFriendlyErrorMessage', () {
      test('should detect rate limit error with 429', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('Error 429: Too many requests');
        expect(result, contains('Rate Limit Reached'));
        expect(result, contains('AI service is busy'));
      });

      test('should detect rate limit error with text', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('rate limit exceeded');
        expect(result, contains('Rate Limit Reached'));
      });

      test('should detect quota error', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('quota exceeded for this month');
        expect(result, contains('Quota Exceeded'));
        expect(result, contains('API quota'));
      });

      test('should detect API key error', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('invalid api key provided');
        expect(result, contains('Authentication Error'));
        expect(result, contains('API key'));
      });

      test('should detect unauthorized error', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('unauthorized access');
        expect(result, contains('Authentication Error'));
      });

      test('should detect network error', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('network connection failed');
        expect(result, contains('Connection Issue'));
        expect(result, contains('internet connection'));
      });

      test('should detect connection error', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('connection timeout');
        expect(result, contains('Connection Issue'));
      });

      test('should detect handshake error', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('HandshakeException: Connection terminated during handshake');
        expect(result, contains('Secure Connection Failed'));
        expect(result, contains('VPN or proxy'));
      });

      test('should detect certificate error', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('certificate verification failed');
        expect(result, contains('Secure Connection Failed'));
        expect(result, contains('device certificates'));
      });

      test('should detect SSL error', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('SSL connection error');
        expect(result, contains('Secure Connection Failed'));
      });

      test('should detect TLS error', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('TLS handshake failed');
        expect(result, contains('Secure Connection Failed'));
      });

      test('should return generic error for unknown errors', () {
        final result = ApiErrorHandler.getFriendlyErrorMessage('unknown error occurred');
        expect(result, contains('An Unexpected Error Occurred'));
        expect(result, contains('unknown error occurred'));
      });
    });

    group('isRateLimitError', () {
      test('should detect 429 error code', () {
        expect(ApiErrorHandler.isRateLimitError('Error 429'), true);
      });

      test('should detect rate limit text', () {
        expect(ApiErrorHandler.isRateLimitError('rate limit exceeded'), true);
        expect(ApiErrorHandler.isRateLimitError('Rate Limit reached'), true);
      });

      test('should return false for non-rate-limit errors', () {
        expect(ApiErrorHandler.isRateLimitError('quota exceeded'), false);
        expect(ApiErrorHandler.isRateLimitError('network error'), false);
      });
    });

    group('isQuotaError', () {
      test('should detect quota errors', () {
        expect(ApiErrorHandler.isQuotaError('quota exceeded'), true);
        expect(ApiErrorHandler.isQuotaError('Quota limit reached'), true);
      });

      test('should return false for non-quota errors', () {
        expect(ApiErrorHandler.isQuotaError('rate limit'), false);
        expect(ApiErrorHandler.isQuotaError('network error'), false);
      });
    });

    group('isHandshakeError', () {
      test('should detect handshake errors', () {
        expect(ApiErrorHandler.isHandshakeError('HandshakeException occurred'), true);
        expect(ApiErrorHandler.isHandshakeError('handshake failed'), true);
      });

      test('should detect certificate errors', () {
        expect(ApiErrorHandler.isHandshakeError('certificate verification failed'), true);
        expect(ApiErrorHandler.isHandshakeError('Certificate expired'), true);
      });

      test('should detect SSL/TLS errors', () {
        expect(ApiErrorHandler.isHandshakeError('SSL error'), true);
        expect(ApiErrorHandler.isHandshakeError('TLS handshake failed'), true);
      });

      test('should return false for non-handshake errors', () {
        expect(ApiErrorHandler.isHandshakeError('rate limit'), false);
        expect(ApiErrorHandler.isHandshakeError('quota error'), false);
      });
    });

    group('isNetworkError', () {
      test('should detect network errors', () {
        expect(ApiErrorHandler.isNetworkError('network error'), true);
        expect(ApiErrorHandler.isNetworkError('Network connection failed'), true);
      });

      test('should detect connection errors', () {
        expect(ApiErrorHandler.isNetworkError('connection timeout'), true);
        expect(ApiErrorHandler.isNetworkError('Connection refused'), true);
      });

      test('should detect socket errors', () {
        expect(ApiErrorHandler.isNetworkError('socket exception'), true);
        expect(ApiErrorHandler.isNetworkError('SocketException occurred'), true);
      });

      test('should detect handshake errors as network errors', () {
        expect(ApiErrorHandler.isNetworkError('HandshakeException'), true);
        expect(ApiErrorHandler.isNetworkError('certificate error'), true);
        expect(ApiErrorHandler.isNetworkError('SSL error'), true);
      });

      test('should return false for non-network errors', () {
        expect(ApiErrorHandler.isNetworkError('rate limit'), false);
        expect(ApiErrorHandler.isNetworkError('quota exceeded'), false);
      });
    });
  });
}
