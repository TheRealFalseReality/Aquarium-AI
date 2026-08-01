import 'package:flutter/material.dart';

/// Extension to provide accessible feedback methods on BuildContext
extension AccessibleFeedbackContext on BuildContext {
  /// Shows an accessible message instead of using SnackBar
  void showAccessibleMessage(
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    AccessibleFeedback.showMessage(
      this,
      message: message,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }
}

/// Provides accessible feedback to users via the Scaffold messaging system.
///
/// Uses [ScaffoldMessenger.showSnackBar] with live-region semantics so screen
/// readers announce the message automatically.  Using [ScaffoldMessenger]
/// instead of a raw [OverlayEntry] ensures the overlay lifecycle is managed
/// correctly across navigation transitions, preventing duplicate-GlobalKey
/// widget-tree errors that can arise from static [OverlayEntry] state.
class AccessibleFeedback {
  static void showMessage(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBg = backgroundColor ?? colorScheme.inverseSurface;
    final effectiveFg = textColor ?? colorScheme.onInverseSurface;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          label: message,
          child: Text(message, style: TextStyle(color: effectiveFg)),
        ),
        backgroundColor: effectiveBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        duration: duration,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
                textColor: effectiveFg,
              )
            : null,
      ),
    );
  }
}
