import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../l10n/app_localizations.dart';
import '../theme_colors.dart';
import 'remove_ads_dialog.dart';

/// Shows a modern, sleek dialog for AI errors.
///
/// Provides a [Retry] button when [onRetry] is supplied and an optional
/// [Go to AI Provider Settings] button when [isApiKeyError] is `true`.
///
/// When [isRateLimitError] is `true`, the dialog shows a Founder Aquarist
/// upsell (ad removal + higher limits) instead of the generic error header.
///
/// Falls back to a regular toast/snack if the context is no longer valid.
void showAiErrorDialog(
  BuildContext context, {
  required String errorMessage,
  VoidCallback? onRetry,
  bool isApiKeyError = false,
  bool isRetryable = true,
  bool isRateLimitError = false,
}) {
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _AiErrorDialog(
      errorMessage: errorMessage,
      onRetry: isRetryable ? onRetry : null,
      isApiKeyError: isApiKeyError,
      isRateLimitError: isRateLimitError,
      parentContext: context,
    ),
  );
}

class _AiErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final bool isApiKeyError;
  final bool isRateLimitError;

  /// The parent screen's [BuildContext], used to open the Founder dialog after
  /// this dialog is dismissed (the dialog's own context becomes invalid after
  /// pop).
  final BuildContext parentContext;

  const _AiErrorDialog({
    required this.errorMessage,
    required this.parentContext,
    this.onRetry,
    this.isApiKeyError = false,
    this.isRateLimitError = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final founderColor = AquaThemeColors.founderColor(context);

    String headerTitle;
    if (isRateLimitError) {
      headerTitle = l10n.rateLimitReachedTitle;
    } else if (isApiKeyError) {
      headerTitle = l10n.apiKeyRequiredTitle;
    } else {
      headerTitle = l10n.aiErrorTitle;
    }

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
            decoration: BoxDecoration(
              color: isRateLimitError
                  ? founderColor.withOpacity(0.15)
                  : cs.errorContainer,
            ),
            child: Row(
              children: [
                Icon(
                  isRateLimitError
                      ? Icons.timer_off_rounded
                      : Icons.error_rounded,
                  color:
                      isRateLimitError ? founderColor : cs.onErrorContainer,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    headerTitle,
                    style: tt.titleLarge?.copyWith(
                      color: isRateLimitError
                          ? founderColor
                          : cs.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isRateLimitError
                        ? founderColor
                        : cs.onErrorContainer,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: l10n.dismiss,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: errorMessage,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(p: tt.bodyMedium),
                  ),
                  if (isRateLimitError) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: founderColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: founderColor.withOpacity(0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.diamond,
                                size: 16,
                                color: founderColor,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.founderAquaristPerksTitle,
                                  style: tt.labelLarge?.copyWith(
                                    color: founderColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _PerkRow(
                            icon: Icons.block,
                            label: l10n.founderPerkAdsRemoved,
                            color: founderColor,
                          ),
                          const SizedBox(height: 4),
                          _PerkRow(
                            icon: Icons.auto_awesome,
                            label: l10n.founderPerkIncreasedAILimits,
                            color: founderColor,
                          ),
                          const SizedBox(height: 8),
                          MarkdownBody(
                            data: l10n.rateLimitFounderUpsellBody,
                            styleSheet: MarkdownStyleSheet.fromTheme(
                              Theme.of(context),
                            ).copyWith(
                              p: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
                  child: Text(l10n.dismiss),
                ),
                if (isRateLimitError)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (parentContext.mounted) {
                        showRemoveAdsDialog(parentContext);
                      }
                    },
                    icon: const Icon(Icons.diamond, size: 18),
                    label: Text(l10n.becomeFounderAquarist),
                    style: FilledButton.styleFrom(
                      backgroundColor: founderColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (isApiKeyError && !isRateLimitError)
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
                if (!isApiKeyError && !isRateLimitError && onRetry != null)
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry!();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.retry),
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

/// A single perk row inside the rate-limit error dialog's founder upsell box.
class _PerkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PerkRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
