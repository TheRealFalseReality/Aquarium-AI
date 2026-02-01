import 'package:flutter_test/flutter_test.dart';
import 'package:fish_ai/utils/cancellable_completer.dart';

void main() {
  group('CancellableCompleter', () {
    test('should complete successfully', () async {
      final completer = CancellableCompleter<String>();
      
      completer.complete('success');
      
      final result = await completer.future;
      expect(result, 'success');
      expect(completer.isCompleted, true);
      expect(completer.isCancelled, false);
    });

    test('should complete with error', () async {
      final completer = CancellableCompleter<String>();
      
      completer.completeError(Exception('test error'));
      
      expect(
        () async => await completer.future,
        throwsException,
      );
      expect(completer.isCompleted, true);
      expect(completer.isCancelled, false);
    });

    test('should cancel successfully', () async {
      final completer = CancellableCompleter<String>();
      
      completer.cancel();
      
      expect(
        () async => await completer.future,
        throwsA(isA<CancelledException>()),
      );
      expect(completer.isCancelled, true);
    });

    test('should not complete after cancellation', () async {
      final completer = CancellableCompleter<String>();
      
      completer.cancel();
      completer.complete('should not complete');
      
      expect(
        () async => await completer.future,
        throwsA(isA<CancelledException>()),
      );
    });

    test('should not complete error after cancellation', () async {
      final completer = CancellableCompleter<String>();
      
      completer.cancel();
      completer.completeError(Exception('should not throw'));
      
      expect(
        () async => await completer.future,
        throwsA(isA<CancelledException>()),
      );
    });

    test('CancelledException should have proper toString', () {
      final exception = CancelledException();
      expect(exception.toString(), 'Future was cancelled');
    });
  });
}

