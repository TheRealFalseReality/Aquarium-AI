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
  });
}

