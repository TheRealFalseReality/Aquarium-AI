import 'package:flutter/material.dart';

/// A reusable loading overlay component that can be used across different screens
/// to maintain consistent loading states.

class LoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final Widget child;
  final String? loadingText;
  final Color? overlayColor;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    required this.child,
    this.loadingText,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return child;
    }

    return Stack(
      children: [
        child,
        Container(
          color: overlayColor ?? Colors.black.withOpacity(0.3),
          child: Center(
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (loadingText != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingText!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A simple loading indicator widget for inline use
class LoadingIndicator extends StatelessWidget {
  final String? text;
  final double? size;
  final EdgeInsetsGeometry? padding;

  const LoadingIndicator({
    super.key,
    this.text,
    this.size,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 24,
            height: size ?? 24,
            child: const CircularProgressIndicator(),
          ),
          if (text != null) ...[
            const SizedBox(height: 8),
            Text(
              text!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
