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

/// Provides accessible feedback to users without using deprecated AnnounceSemanticsEvent.
/// This replaces SnackBars with semantic announcements that are properly accessible.
class AccessibleFeedback {
  /// Shows an accessible message using semantic properties instead of deprecated announcements.
  /// This creates a temporary overlay with live region semantics for screen readers.
  static OverlayEntry? _currentEntry;

  static void showMessage(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
    Color? backgroundColor,
    Color? textColor,
  }) {
    // Remove any existing feedback
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Create overlay entry with semantic live region
    _currentEntry = OverlayEntry(
      builder: (context) => _AccessibleFeedbackWidget(
        message: message,
        onAction: onAction,
        actionLabel: actionLabel,
        backgroundColor: backgroundColor ?? colorScheme.inverseSurface,
        textColor: textColor ?? colorScheme.onInverseSurface,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }

  /// Dismisses any currently shown message
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _AccessibleFeedbackWidget extends StatefulWidget {
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onDismiss;

  const _AccessibleFeedbackWidget({
    required this.message,
    this.onAction,
    this.actionLabel,
    required this.backgroundColor,
    required this.textColor,
    required this.onDismiss,
  });

  @override
  State<_AccessibleFeedbackWidget> createState() => _AccessibleFeedbackWidgetState();
}

class _AccessibleFeedbackWidgetState extends State<_AccessibleFeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Semantics(
            // Use live region for accessibility announcements
            liveRegion: true,
            announcement: widget.message,
            child: Material(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(4),
              elevation: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (widget.onAction != null && widget.actionLabel != null) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          widget.onAction!();
                          widget.onDismiss();
                        },
                        child: Text(
                          widget.actionLabel!,
                          style: TextStyle(
                            color: widget.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: widget.textColor,
                        size: 20,
                      ),
                      onPressed: widget.onDismiss,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Dismiss',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}