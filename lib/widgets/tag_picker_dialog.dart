import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../l10n/app_localizations.dart';
import '../models/tank.dart';

/// Preset colour options shown as swatches in the tag colour picker.
enum _TagColorPreset { primary, secondary, tertiary, custom }

/// A dialog that lets the user:
///   • pick existing tags (from [allExistingTags]) to add to [currentTags]
///   • remove tags that are already in [currentTags]
///   • create a brand-new tag with a chosen colour
///
/// Returns the updated `List<TankTag>` via `Navigator.pop`, or null if the
/// user cancels.
class TagPickerDialog extends StatefulWidget {
  /// Every tag that exists across all tanks — shown as suggestions.
  final List<TankTag> allExistingTags;

  /// The tags that the current tank already has (pre-selected).
  final List<TankTag> currentTags;

  const TagPickerDialog({
    super.key,
    required this.allExistingTags,
    required this.currentTags,
  });

  @override
  State<TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends State<TagPickerDialog> {
  late List<TankTag> _selected;
  final _newTagController = TextEditingController();
  _TagColorPreset _colorPreset = _TagColorPreset.secondary;
  Color? _customColor;
  bool _showNewTagRow = false;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentTags);
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Returns the ARGB int to store for the currently selected preset,
  /// or null when the preset is secondary (theme default).
  int? _resolvedColor(BuildContext context) {
    switch (_colorPreset) {
      case _TagColorPreset.primary:
        return Theme.of(context).colorScheme.primary.value;
      case _TagColorPreset.secondary:
        return null; // null → use theme secondary at render time
      case _TagColorPreset.tertiary:
        return Theme.of(context).colorScheme.tertiary.value;
      case _TagColorPreset.custom:
        return _customColor?.value;
    }
  }

  Color _previewColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (_colorPreset) {
      case _TagColorPreset.primary:
        return cs.primary;
      case _TagColorPreset.secondary:
        return cs.secondary;
      case _TagColorPreset.tertiary:
        return cs.tertiary;
      case _TagColorPreset.custom:
        return _customColor ?? cs.secondary;
    }
  }

  void _toggleExisting(TankTag tag) {
    setState(() {
      final idx = _selected.indexWhere((t) => t.name == tag.name);
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        _selected.add(tag);
      }
    });
  }

  void _addNewTag(BuildContext context) {
    final name = _newTagController.text.trim();
    if (name.isEmpty) return;
    // Avoid duplicates
    if (_selected.any((t) => t.name == name)) {
      _newTagController.clear();
      return;
    }
    final tag = TankTag(name: name, color: _resolvedColor(context));
    setState(() {
      _selected.add(tag);
      _newTagController.clear();
      _showNewTagRow = false;
    });
  }

  Future<void> _openCustomColorPicker(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    Color working = _customColor ?? cs.secondary;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.customColor),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (ctx2, setInner) => ColorPicker(
              pickerColor: working,
              onColorChanged: (c) {
                working = c;
                setInner(() {});
              },
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.7,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _customColor = working;
                _colorPreset = _TagColorPreset.custom;
              });
              Navigator.of(ctx).pop();
            },
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // Suggestions = all existing tags not yet in _selected, de-duplicated by name.
    final selectedNames = _selected.map((t) => t.name).toSet();
    final suggestions = widget.allExistingTags
        .where((t) => !selectedNames.contains(t.name))
        .fold<List<TankTag>>([], (acc, t) {
          if (acc.every((a) => a.name != t.name)) acc.add(t);
          return acc;
        });

    return AlertDialog(
      title: Text(l10n.manageTags),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Current tags ──────────────────────────────────────────────
              if (_selected.isNotEmpty) ...[
                Text(
                  l10n.currentTags,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _selected.map((tag) {
                    final tagColor = tag.color != null
                        ? Color(tag.color!)
                        : cs.secondary;
                    final onTagColor = tagColor.computeLuminance() > 0.4
                        ? Colors.black87
                        : Colors.white;
                    return Chip(
                      label: Text(
                        tag.name,
                        style: TextStyle(fontSize: 12, color: onTagColor),
                      ),
                      backgroundColor: tagColor.withOpacity(0.85),
                      side: BorderSide(color: tagColor, width: 1),
                      deleteIconColor: onTagColor.withOpacity(0.7),
                      onDeleted: () => _toggleExisting(tag),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
              ],

              // ── Suggestions ───────────────────────────────────────────────
              if (suggestions.isNotEmpty) ...[
                Text(
                  l10n.existingTags,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: suggestions.map((tag) {
                    final tagColor = tag.color != null
                        ? Color(tag.color!)
                        : cs.secondary;
                    final onTagColor = tagColor.computeLuminance() > 0.4
                        ? Colors.black87
                        : Colors.white;
                    return ActionChip(
                      avatar: Icon(Icons.add, size: 14, color: onTagColor),
                      label: Text(
                        tag.name,
                        style: TextStyle(fontSize: 12, color: onTagColor),
                      ),
                      backgroundColor: tagColor.withOpacity(0.7),
                      side: BorderSide(color: tagColor, width: 1),
                      onPressed: () => _toggleExisting(tag),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
              ],

              // ── New tag ───────────────────────────────────────────────────
              Text(
                l10n.addTag,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // Colour preset row
              Row(
                children: [
                  _ColorSwatch(
                    color: cs.primary,
                    label: l10n.colorPrimary,
                    selected: _colorPreset == _TagColorPreset.primary,
                    onTap: () =>
                        setState(() => _colorPreset = _TagColorPreset.primary),
                  ),
                  const SizedBox(width: 6),
                  _ColorSwatch(
                    color: cs.secondary,
                    label: l10n.colorSecondary,
                    selected: _colorPreset == _TagColorPreset.secondary,
                    onTap: () => setState(
                      () => _colorPreset = _TagColorPreset.secondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ColorSwatch(
                    color: cs.tertiary,
                    label: l10n.colorTertiary,
                    selected: _colorPreset == _TagColorPreset.tertiary,
                    onTap: () =>
                        setState(() => _colorPreset = _TagColorPreset.tertiary),
                  ),
                  const SizedBox(width: 6),
                  _CustomColorSwatch(
                    color: _customColor,
                    label: l10n.colorCustom,
                    selected: _colorPreset == _TagColorPreset.custom,
                    onTap: () => _openCustomColorPicker(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Name input + add button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTagController,
                      autofocus: _showNewTagRow,
                      decoration: InputDecoration(
                        hintText: l10n.addTagHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor: _previewColor(context),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addNewTag(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: () => _addNewTag(context),
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: l10n.addTag,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: selected
                ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                : null,
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 14,
                  color: color.computeLuminance() > 0.4
                      ? Colors.black87
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class _CustomColorSwatch extends StatelessWidget {
  final Color? color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CustomColorSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayColor = color ?? cs.surfaceContainerHighest;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: displayColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? cs.onSurface : cs.outline.withOpacity(0.5),
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: displayColor.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            Icons.colorize,
            size: 13,
            color: color != null
                ? (displayColor.computeLuminance() > 0.4
                      ? Colors.black87
                      : Colors.white)
                : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
