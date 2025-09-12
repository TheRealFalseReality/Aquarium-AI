import 'package:flutter/material.dart';

/// MiniAIChip
/// Compact chip used for chatbot suggestion menus & follow-ups.
/// Updated: Can now accept a custom gradient for styling.
class MiniAIChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;
  final bool dense;
  final bool iconOnly;
  final String? tooltip;
  final Gradient? customGradient;

  const MiniAIChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.dense = false,
    this.iconOnly = false,
    this.tooltip,
    this.customGradient,
  });

  @override
  State<MiniAIChip> createState() => _MiniAIChipState();
}

class _MiniAIChipState extends State<MiniAIChip> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(widget.iconOnly ? 18 : 22);

    final bool hasCustomLook = widget.customGradient != null && !widget.selected;

    final Gradient? gradient = widget.selected
        ? LinearGradient(
            colors: [
              cs.primary,
              cs.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : widget.customGradient;

    final backgroundColor = widget.selected
        ? cs.primary.withOpacity(0.18)
        : cs.surface.withOpacity(widget.iconOnly ? 0.5 : 0.65);

    final iconColor = widget.selected || hasCustomLook
        ? cs.onPrimary
        : cs.onSurface.withOpacity(0.85);

    final labelColor = widget.selected || hasCustomLook
        ? cs.onPrimary
        : cs.onSurface.withOpacity(0.90);

    final scale = _pressed
        ? 0.92
        : (_hover ? 1.05 : 1.0);

    final padding = widget.iconOnly
        ? const EdgeInsets.all(6)
        : EdgeInsets.symmetric(
            horizontal: widget.dense ? 10 : 14,
            vertical: widget.dense ? 6 : 8,
          );

    Widget chipContent = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _hover || widget.selected ? 1.0 : 0.92,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? backgroundColor : null,
            borderRadius: borderRadius,
            border: Border.all(
              color: widget.selected
                  ? cs.primary.withOpacity(0.6)
                  : cs.outlineVariant.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: widget.selected || hasCustomLook
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: widget.iconOnly
                      ? 18
                      : (widget.dense ? 16 : 18),
                  color: iconColor,
                ),
              if (!widget.iconOnly) ...[
                if (widget.icon != null) const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: widget.selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          letterSpacing: 0.25,
                          color: labelColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      chipContent = Tooltip(message: widget.tooltip!, child: chipContent);
    }

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
            setState(() => _pressed = true);
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
          },
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: chipContent,
        ),
      ),
    );
  }
}