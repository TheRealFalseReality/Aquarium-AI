import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Shows a modern, sleek dialog for AI errors.
///
/// Provides a [Retry] button when [onRetry] is supplied and an optional
/// [Go to AI Provider Settings] button when [isApiKeyError] is `true`.
///
/// Falls back to a regular toast/snack if the context is no longer valid.
void showAiErrorDialog(
  BuildContext context, {
  required String errorMessage,
  VoidCallback? onRetry,
  bool isApiKeyError = false,
  bool isRetryable = true,
}) {
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _AiErrorDialog(
      errorMessage: errorMessage,
      onRetry: isRetryable ? onRetry : null,
      isApiKeyError: isApiKeyError,
    ),
  );
}

class _AiErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final bool isApiKeyError;

  const _AiErrorDialog({
    required this.errorMessage,
    this.onRetry,
    this.isApiKeyError = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(color: cs.errorContainer),
            child: Row(
              children: [
                Icon(Icons.error_rounded, color: cs.onErrorContainer, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isApiKeyError ? 'API Key Required' : 'AI Error',
                    style: tt.titleLarge?.copyWith(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: cs.onErrorContainer),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Dismiss',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: MarkdownBody(
                data: errorMessage,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(p: tt.bodyMedium),
              ),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Dismiss'),
                ),
                if (isApiKeyError)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/settings');
                    },
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('AI Provider Settings'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                  ),
                if (!isApiKeyError && onRetry != null)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry!();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
