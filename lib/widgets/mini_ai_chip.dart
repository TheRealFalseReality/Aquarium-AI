import 'package:flutter/material.dart';

class MiniAIChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Widget? customIcon;
  final bool iconOnly;
  final bool selected;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool dense;
  final LinearGradient? customGradient;

  const MiniAIChip({
    super.key,
    required this.label,
    this.icon,
    this.customIcon,
    this.iconOnly = false,
    this.selected = false,
    this.onTap,
    this.tooltip,
    this.dense = false,
    this.customGradient,
  }) : assert(icon == null || customIcon == null,
            'Cannot provide both an icon and a customIcon');

  @override
  State<MiniAIChip> createState() => _MiniAIChipState();
}

class _MiniAIChipState extends State<MiniAIChip> {
  bool _isHovering = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isSelected = widget.selected;

    final Color textColor = isSelected ? cs.onPrimary : cs.onSurfaceVariant;
    final double scale = _isTapped ? 0.95 : (_isHovering ? 1.05 : 1.0);
    final double elevation =
        isSelected ? 8 : (_isHovering || _isTapped ? 6 : 2);

    final gradient = widget.customGradient ??
        LinearGradient(
          colors: isSelected
              ? [cs.primary, cs.secondary]
              : [cs.surfaceVariant, cs.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    final double horizontalPadding =
        widget.iconOnly ? (widget.dense ? 8 : 12) : (widget.dense ? 12 : 16);
    final double verticalPadding = widget.dense ? 6 : 10;
    final double iconSize = widget.dense ? 16 : 20;

    Widget? iconWidget;
    if (widget.customIcon != null) {
      iconWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
        child: widget.customIcon,
      );
    } else if (widget.icon != null) {
      iconWidget = Icon(widget.icon, size: iconSize, color: textColor);
    }

    Widget content = widget.iconOnly
        ? (iconWidget ?? const SizedBox.shrink())
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconWidget != null) ...[
                iconWidget,
                SizedBox(width: widget.dense ? 6 : 8),
              ],
              // Wrapped the Text widget with Flexible to prevent overflow
              Flexible(
                child: Text(
                  widget.label,
                  style: (widget.dense
                          ? Theme.of(context).textTheme.bodySmall
                          : Theme.of(context).textTheme.labelLarge)
                      ?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          );

    Widget chip = Material(
      color: Colors.transparent,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.2 : 0.1),
                blurRadius: elevation,
                offset: Offset(0, elevation / 4),
              )
            ],
            border: Border.all(
              color: isSelected
                  ? cs.primaryContainer.withOpacity(0.5)
                  : cs.outline.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: content,
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isTapped = true),
        onTapUp: (_) => setState(() => _isTapped = false),
        onTapCancel: () => setState(() => _isTapped = false),
        onTap: widget.onTap,
        child: widget.tooltip != null
            ? Tooltip(
                message: widget.tooltip!,
                child: chip,
              )
            : chip,
      ),
    );
  }
}