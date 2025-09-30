import 'package:flutter/material.dart';

/// ModernSelectableChip
/// Large, rounded, animated chip used for primary selections (e.g., categories, calculators).
/// Updated: Now supports custom selectedColor and selectedTextColor for more versatile styling.
class ModernSelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  final IconData? icon;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final bool dense;
  final Color? selectedColor; // New: Custom background color for selected state
  final Color? selectedTextColor; // New: Custom text color for selected state

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
    this.selectedColor,
    this.selectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseRadius = dense ? 20.0 : 28.0;

    // Determine colors based on selection and custom properties
    Color? finalBackgroundColor;
    Gradient? finalGradient;
    Color finalBorderColor;
    Color finalLabelColor;
    Color finalIconColor;

    if (selected) {
      finalBackgroundColor = selectedColor ?? cs.primary;
      finalBorderColor =
          selectedColor?.withOpacity(0.5) ?? cs.primary.withOpacity(0.75);
      finalLabelColor = selectedTextColor ?? cs.onPrimary;
      finalIconColor = selectedTextColor ?? cs.onPrimary;
    } else {
      finalBackgroundColor = cs.surfaceContainerHighest;
      finalBorderColor = cs.outline.withOpacity(0.2);
      finalLabelColor = cs.onSurfaceVariant;
      finalIconColor = cs.onSurfaceVariant;
    }

    Widget? leading;
    if (icon != null) {
      leading = Icon(icon, size: dense ? 18 : 22, color: finalIconColor);
    } else if (emoji != null) {
      leading = Text(
        emoji!,
        style: TextStyle(fontSize: dense ? 20 : 26),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        // MODIFIED: Added constraints to allow the chip to have a max width, forcing text to wrap.
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.45),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: padding ??
            (dense
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        decoration: BoxDecoration(
          color: finalBackgroundColor,
          gradient: finalGradient,
          borderRadius: BorderRadius.circular(baseRadius),
          border: Border.all(
            color: finalBorderColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: (selectedColor ?? cs.primary).withOpacity(0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.25,
                      color: finalLabelColor,
                    ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}