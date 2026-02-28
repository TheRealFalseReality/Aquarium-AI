import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../theme_colors.dart';
import '../theme_provider.dart';

/// A full-page screen that lets the user choose the app colour theme and
/// light / dark / system mode.
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
                    onSelected: (theme) => themeNotifier.setColorTheme(theme),
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
}

// ---------------------------------------------------------------------------
// Theme grid
// ---------------------------------------------------------------------------

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({
    required this.selected,
    required this.isMaterialYouAvailable,
    required this.onSelected,
  });

  final AppColorTheme selected;
  final bool isMaterialYouAvailable;
  final ValueChanged<AppColorTheme> onSelected;

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
                onTap: () => onSelected(t),
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
    required this.onTap,
  });

  final AppColorTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  static const _swatch = {
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

  static const _swatchDarker = {
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
    final primary = _swatch[theme]!;
    final secondary = _swatchDarker[theme]!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The label strip background is always white-ish (light) or dark, so
    // text contrast should be based on that container, not the swatch color.

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
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
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
                  theme.displayName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        // Container is white-ish in light mode, dark in dark mode.
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
