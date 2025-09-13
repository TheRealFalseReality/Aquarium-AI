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
      // --- SELECTED STATE ---
      if (selectedColor != null) {
        // Use custom solid color
        finalBackgroundColor = selectedColor;
        finalGradient = null;
        finalBorderColor = selectedColor!.withOpacity(0.75);
        // Determine contrasting text color if not provided
        finalLabelColor = selectedTextColor ??
            (ThemeData.estimateBrightnessForColor(selectedColor!) ==
                    Brightness.dark
                ? Colors.white
                : Colors.black);
        finalIconColor = finalLabelColor;
      } else {
        // Use default theme gradient
        finalBackgroundColor = null; // Must be null for gradient to be visible
        finalGradient = LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        finalBorderColor = cs.primary.withOpacity(0.75);
        finalLabelColor = selectedTextColor ?? cs.onPrimary;
        finalIconColor = finalLabelColor;
      }
    } else {
      // --- UNSELECTED STATE ---
      finalBackgroundColor = cs.surfaceContainerHighest.withOpacity(0.55);
      finalGradient = null;
      finalBorderColor = cs.outlineVariant.withOpacity(0.28);
      finalLabelColor = cs.onSurface;
      finalIconColor = cs.onSurfaceVariant;
    }

    Widget? leading;
    if (emoji != null) {
      leading = Text(
        emoji!,
        style: TextStyle(fontSize: dense ? 16 : 20, height: 1.0),
      );
    } else if (icon != null) {
      leading = Icon(
        icon,
        size: dense ? 18 : 22,
        color: finalIconColor,
      );
    }

    return Semantics(
      selected: selected,
      button: true,
      label: '$label option',
      child: InkWell(
        borderRadius: BorderRadius.circular(baseRadius),
        onTap: onTap,
        splashColor: (selected ? finalLabelColor : cs.primary).withOpacity(0.18),
        highlightColor:
            (selected ? finalLabelColor : cs.primary).withOpacity(0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: dense ? 14 : 22,
                vertical: dense ? 10 : 14,
              ),
          decoration: BoxDecoration(
            gradient: finalGradient,
            color: finalBackgroundColor,
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
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.25,
                        color: finalLabelColor,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}