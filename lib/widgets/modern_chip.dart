import 'package:flutter/material.dart';

/// ModernSelectableChip
/// Large, rounded, animated chip used for primary selections (e.g., categories, calculators).
/// Updated: Removed visual selection indicators (no checkmark). Selection is conveyed by:
/// - Gradient background
/// - Slight elevation & shadow
/// - Bolder font
class ModernSelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final IconData? icon;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final bool dense;

  const ModernSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.icon,
    this.elevation = 0,
    this.padding,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseRadius = dense ? 20.0 : 28.0;

    final Color fallbackBg = selected
        ? cs.primary.withValues(alpha: 0.18)
        : cs.surfaceContainerHighest.withValues(alpha: 0.55);

    final Gradient? gradient = selected
        ? LinearGradient(
            colors: [
              cs.primary,
              cs.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final Color borderColor = selected
        ? cs.primary.withValues(alpha: 0.75)
        : cs.outlineVariant.withValues(alpha: 0.28);

    final Color labelColor = selected ? cs.onPrimary : cs.onSurface;

    Widget? leading;
    if (emoji != null) {
      leading = Text(
        emoji!,
        style: TextStyle(
          fontSize: dense ? 16 : 20,
          height: 1.0,
        ),
      );
    } else if (icon != null) {
      leading = Icon(
        icon,
        size: dense ? 18 : 22,
        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
      );
    }

    return Semantics(
      selected: selected,
      button: true,
      label: '$label option',
      child: InkWell(
        borderRadius: BorderRadius.circular(baseRadius),
        onTap: onTap,
        splashColor: (selected ? cs.onPrimary : cs.primary).withValues(alpha: 0.18),
        highlightColor:
            (selected ? cs.onPrimary : cs.primary).withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: dense ? 14 : 22,
                vertical: dense ? 10 : 14,
              ),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? fallbackBg : null,
            borderRadius: BorderRadius.circular(baseRadius),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.25,
                        color: labelColor,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // (Removed checkmark / indicators)
            ],
          ),
        ),
      ),
    );
  }
}