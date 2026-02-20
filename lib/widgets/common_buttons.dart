import 'package:flutter/material.dart';

/// A collection of common button patterns used throughout the app
/// to maintain consistency and reduce code duplication.

/// Standard Close button with consistent styling
class CommonCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final bool isIconButton;

  const CommonCloseButton({
    super.key,
    this.onPressed,
    this.label,
    this.isIconButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isIconButton) {
      return IconButton(
        icon: const Icon(Icons.close),
        onPressed: onPressed ?? () => Navigator.pop(context),
        tooltip: 'Close',
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed ?? () => Navigator.pop(context),
      icon: const Icon(Icons.close),
      label: Text(label ?? 'Close'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    );
  }
}

/// Standard Regenerate button with loading state
class RegenerateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? label;
  final String? loadingLabel;

  const RegenerateButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
      label: Text(isLoading 
          ? (loadingLabel ?? 'Regenerating...') 
          : (label ?? 'Regenerate')),
    );
  }
}

/// Standard action button row with Regenerate and Close buttons
class ActionButtonRow extends StatelessWidget {
  final VoidCallback? onRegenerate;
  final VoidCallback? onClose;
  final VoidCallback? onShare;
  final bool isRegenerating;
  final String? regenerateLabel;
  final String? closeLabel;

  const ActionButtonRow({
    super.key,
    this.onRegenerate,
    this.onClose,
    this.onShare,
    this.isRegenerating = false,
    this.regenerateLabel,
    this.closeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onRegenerate != null) ...[
          Expanded(
            child: RegenerateButton(
              onPressed: onRegenerate,
              isLoading: isRegenerating,
              label: regenerateLabel,
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (onShare != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: CommonCloseButton(
            onPressed: onClose,
            label: closeLabel,
          ),
        ),
      ],
    );
  }
}
