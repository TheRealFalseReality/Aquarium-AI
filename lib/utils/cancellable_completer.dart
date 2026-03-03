import 'dart:async';

/// A completer that can be cancelled, preventing completion after cancellation.
///
/// This utility class is used across the application to manage async operations
/// that may need to be cancelled, such as AI API calls.
///
/// Example usage:
/// ```dart
/// final cancellable = CancellableCompleter<String>();
///
/// // Start async operation
/// someAsyncOperation().then((result) {
///   cancellable.complete(result);
/// }).catchError((error) {
///   cancellable.completeError(error);
/// });
///
/// // Cancel if needed
/// if (shouldCancel) {
///   cancellable.cancel();
/// }
/// ```
class CancellableCompleter<T> {
  final Completer<T> _completer = Completer<T>();
  bool _isCancelled = false;

  Future<T> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  bool get isCancelled => _isCancelled;

  void complete([FutureOr<T>? value]) {
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }

  void cancel() {
    if (!_completer.isCompleted) {
      _isCancelled = true;
      _completer.completeError(CancelledException());
    }
  }
}

/// Exception thrown when a cancellable operation is cancelled.
class CancelledException implements Exception {
  @override
  String toString() => 'Future was cancelled';
}
