import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../theme_colors.dart';
import '../theme_provider.dart';
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeState = ref.watch(themeProviderNotifierProvider);
    final themeNotifier = ref.read(themeProviderNotifierProvider.notifier);
    final isMaterialYouAvailable =
        !kIsWeb && (defaultTargetPlatform == TargetPlatform.android);

    return MainLayout(
      title: 'Appearance',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Appearance',
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Customise the look of the app.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ── Light / Dark / System ──────────────────────────────────────
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(context, Icons.brightness_6_outlined,
                      'Brightness mode', cs.primary),
                  const SizedBox(height: 12),
                  Center(
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {themeState.themeMode},
                      onSelectionChanged: (modes) {
                        themeNotifier.setThemeMode(modes.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Font Selection ─────────────────────────────────────────────
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(context, Icons.font_download_outlined,
                      'Font', cs.primary),
                  const SizedBox(height: 4),
                  Text(
                    'Choose the font used throughout the app.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _FontSelector(
                    selected: themeState.font,
                    onSelected: (font) => themeNotifier.setFont(font),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Colour Themes ──────────────────────────────────────────────
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(context, Icons.palette_outlined,
                      'Colour theme', cs.primary),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a colour palette for the entire app.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _ThemeGrid(
                    selected: themeState.colorTheme,
                    isMaterialYouAvailable: isMaterialYouAvailable,
                    customSeedColor: themeState.customSeedColor,
                    customThemeName: themeState.customThemeName,
                    onSelected: (theme) => themeNotifier.setColorTheme(theme),
                    onCustomEdit: () => _showCustomThemePicker(
                      context,
                      themeState.customSeedColor,
                      themeState.customThemeName,
                      themeNotifier,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  /// Opens the custom colour picker dialog.
  void _showCustomThemePicker(
    BuildContext context,
    Color initialColor,
    String initialName,
    ThemeProviderNotifier notifier,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _CustomThemeDialog(
        initialColor: initialColor,
        initialName: initialName,
        onSave: (color, name) => notifier.setCustomTheme(color, name),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Font selector
// ---------------------------------------------------------------------------

class _FontSelector extends StatelessWidget {
  const _FontSelector({
    required this.selected,
    required this.onSelected,
  });

  final AppFont selected;
  final ValueChanged<AppFont> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: AppFont.values.map((font) {
        final isSelected = selected == font;
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(font),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? cs.primary : cs.outline.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? cs.primaryContainer.withOpacity(0.3)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          font.displayName,
                          style: TextStyle(
                            fontFamily: font.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? cs.primary
                                : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'The quick brown fox jumps over the lazy dog.',
                          style: TextStyle(
                            fontFamily: font.fontFamily,
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: cs.primary, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme grid
// ---------------------------------------------------------------------------

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({
    required this.selected,
    required this.isMaterialYouAvailable,
    required this.customSeedColor,
    required this.customThemeName,
    required this.onSelected,
    required this.onCustomEdit,
  });

  final AppColorTheme selected;
  final bool isMaterialYouAvailable;
  final Color customSeedColor;
  final String customThemeName;
  final ValueChanged<AppColorTheme> onSelected;
  final VoidCallback onCustomEdit;

  @override
  Widget build(BuildContext context) {
    final themes = AppColorTheme.values
        .where((t) => t != AppColorTheme.materialYou || isMaterialYouAvailable)
        .toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: themes
          .map((t) => _ThemeChip(
                theme: t,
                isSelected: selected == t,
                customSeedColor: customSeedColor,
                customThemeName: customThemeName,
                // Custom chip: open the picker; setCustomTheme handles selection.
                // Other chips: directly select the theme.
                onTap: t == AppColorTheme.custom
                    ? onCustomEdit
                    : () => onSelected(t),
                onCustomEdit:
                    t == AppColorTheme.custom ? onCustomEdit : null,
              ))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual theme chip
// ---------------------------------------------------------------------------

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.isSelected,
    required this.customSeedColor,
    required this.customThemeName,
    required this.onTap,
    this.onCustomEdit,
  });

  final AppColorTheme theme;
  final bool isSelected;
  final Color customSeedColor;
  final String customThemeName;
  final VoidCallback onTap;
  final VoidCallback? onCustomEdit;

  static const _swatchPrimary = {
    AppColorTheme.defaultTheme: AquaThemeColors.defaultSwatchPrimary,
    AppColorTheme.materialYou: Colors.deepPurple,
    AppColorTheme.oceanBlue: AquaThemeColors.oceanBlueSwatchPrimary,
    AppColorTheme.iceBlue: AquaThemeColors.iceBlueSwatchPrimary,
    AppColorTheme.gold: AquaThemeColors.goldSwatchPrimary,
    AppColorTheme.mulberry: AquaThemeColors.mulberrySwatchPrimary,
    AppColorTheme.midnight: AquaThemeColors.midnightSwatchPrimary,
    AppColorTheme.orange: AquaThemeColors.orangeSwatchPrimary,
    AppColorTheme.green: AquaThemeColors.greenSwatchPrimary,
    AppColorTheme.skyBlue: AquaThemeColors.skyBlueSwatchPrimary,
    AppColorTheme.royalBlue: AquaThemeColors.royalBlueSwatchPrimary,
    AppColorTheme.orchid: AquaThemeColors.orchidSwatchPrimary,
    AppColorTheme.hotPink: AquaThemeColors.hotPinkSwatchPrimary,
    AppColorTheme.crimson: AquaThemeColors.crimsonSwatchPrimary,
  };

  static const _swatchSecondary = {
    AppColorTheme.defaultTheme: AquaThemeColors.defaultSwatchSecondary,
    AppColorTheme.materialYou: Colors.purple,
    AppColorTheme.oceanBlue: AquaThemeColors.oceanBlueSwatchSecondary,
    AppColorTheme.iceBlue: AquaThemeColors.iceBlueSwatchSecondary,
    AppColorTheme.gold: AquaThemeColors.goldSwatchSecondary,
    AppColorTheme.mulberry: AquaThemeColors.mulberrySwatchSecondary,
    AppColorTheme.midnight: AquaThemeColors.midnightSwatchSecondary,
    AppColorTheme.orange: AquaThemeColors.orangeSwatchSecondary,
    AppColorTheme.green: AquaThemeColors.greenSwatchSecondary,
    AppColorTheme.skyBlue: AquaThemeColors.skyBlueSwatchSecondary,
    AppColorTheme.royalBlue: AquaThemeColors.royalBlueSwatchSecondary,
    AppColorTheme.orchid: AquaThemeColors.orchidSwatchSecondary,
    AppColorTheme.hotPink: AquaThemeColors.hotPinkSwatchSecondary,
    AppColorTheme.crimson: AquaThemeColors.crimsonSwatchSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final isCustom = theme == AppColorTheme.custom;

    // Swatch colours: custom theme uses the user-defined seed colour.
    final Color primary =
        isCustom ? customSeedColor : (_swatchPrimary[theme] ?? Colors.grey);
    final Color secondary;
    if (isCustom) {
      final hsl = HSLColor.fromColor(customSeedColor);
      secondary =
          hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    } else {
      secondary = _swatchSecondary[theme] ?? Colors.grey.shade700;
    }

    final String label = isCustom ? customThemeName : theme.displayName;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (theme == AppColorTheme.materialYou)
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            // Custom theme always shows an edit/add icon
            if (isCustom)
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  onTap: onCustomEdit,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 12),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: cs.onPrimary, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom theme picker dialog
// ---------------------------------------------------------------------------

class _CustomThemeDialog extends StatefulWidget {
  const _CustomThemeDialog({
    required this.initialColor,
    required this.initialName,
    required this.onSave,
  });

  final Color initialColor;
  final String initialName;
  final void Function(Color color, String name) onSave;

  @override
  State<_CustomThemeDialog> createState() => _CustomThemeDialogState();
}

class _CustomThemeDialogState extends State<_CustomThemeDialog> {
  late Color _pickedColor;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _pickedColor = widget.initialColor;
    _nameController = TextEditingController(
      text: widget.initialName == kDefaultCustomThemeName
          ? ''
          : widget.initialName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom theme'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPicker(
              pickerColor: _pickedColor,
              onColorChanged: (c) => setState(() => _pickedColor = c),
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.7,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Theme name',
                hintText: kDefaultCustomThemeName,
                border: const OutlineInputBorder(),
              ),
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSave(_pickedColor, _nameController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
