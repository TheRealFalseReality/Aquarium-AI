import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A centralized error handling widget that provides consistent error UI
class ErrorHandlerWidget extends ConsumerWidget {
  final String? error;
  final VoidCallback? onRetry;
  final bool showRetry;
  final Widget? child;
  final String? customRetryLabel;

  const ErrorHandlerWidget({
    super.key,
    this.error,
    this.onRetry,
    this.showRetry = true,
    this.child,
    this.customRetryLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error == null) {
      return child ?? const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    
    return Card(
      color: cs.errorContainer.withOpacity(0.1),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: cs.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(customRetryLabel ?? 'Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A loading indicator with customizable message
class LoadingIndicatorWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingIndicatorWidget({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: const CircularProgressIndicator(),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A widget that combines loading and error states
class AsyncStatusWidget extends ConsumerWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;
  final String? loadingMessage;
  final String? retryLabel;

  const AsyncStatusWidget({
    super.key,
    required this.isLoading,
    this.error,
    this.onRetry,
    required this.child,
    this.loadingMessage,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return LoadingIndicatorWidget(message: loadingMessage);
    }

    if (error != null) {
      return ErrorHandlerWidget(
        error: error,
        onRetry: onRetry,
        customRetryLabel: retryLabel,
      );
    }

    return child;
  }
}

/// Extension to help with AsyncValue from Riverpod
extension AsyncValueErrorHandling<T> on AsyncValue<T> {
  Widget when({
    required Widget Function(T data) data,
    Widget Function(Object error, StackTrace stack)? error,
    Widget Function()? loading,
    String? loadingMessage,
    VoidCallback? onRetry,
  }) {
    return when(
      data: data,
      error: error ?? (err, stack) => ErrorHandlerWidget(
        error: err.toString(),
        onRetry: onRetry,
      ),
      loading: loading ?? () => LoadingIndicatorWidget(message: loadingMessage),
    );
  }
}