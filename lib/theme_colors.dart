import 'package:flutter/material.dart';

/// Central colour constants for all app themes.
///
/// Edit the seed colours in this file to adjust palettes globally.
/// They are used both for theme generation in [main.dart] (via [AppColorTheme])
/// and for the preview swatches in the Appearance screen.
class AquaThemeColors {
  AquaThemeColors._();

  // ── Seed colours (used for M3 tonal-palette generation) ─────────────────
  // Changing a seed colour here automatically updates both the generated theme
  // and the preview swatch in the Appearance screen.

  /// Default aquarium teal – the original app primary.
  static const Color defaultSeed = Color(0xFF005F73);

  /// Ocean blue seed.
  static const Color oceanBlueSeed = Color(0xFF81B2E8);

  /// Ice blue seed.
  static const Color iceBlueSeed = Color(0xFFD8F3FF);

  /// Gold seed.
  static const Color goldSeed = Color(0xFFE19F20);

  /// Mulberry seed.
  static const Color mulberrySeed = Color(0xFF75344E);

  /// Midnight seed.
  static const Color midnightSeed = Color(0xFF0F1623);

  /// Orange seed – #FF8C00.
  static const Color orangeSeed = Color(0xFFFF8C00);

  /// Green seed – #32CD32 (merged from lawn green & lime green).
  static const Color greenSeed = Color(0xFF32CD32);

  /// Sky blue seed – #00BFFF.
  static const Color skyBlueSeed = Color(0xFF00BFFF);

  /// Royal blue seed – #4169E1.
  static const Color royalBlueSeed = Color(0xFF4169E1);

  /// Orchid seed – #BA55D3.
  static const Color orchidSeed = Color(0xFFBA55D3);

  /// Hot pink seed – #FF69B4.
  static const Color hotPinkSeed = Color(0xFFFF69B4);

  /// Crimson seed – #DC143C (merged from firebrick & crimson).
  static const Color crimsonSeed = Color(0xFFDC143C);

  // ── Swatch preview pairs (top-left → bottom-right gradient) ─────────────
  // These are purely visual; they don't affect theme generation.

  static const Color defaultSwatchPrimary = Color(0xFF0A9396);
  static const Color defaultSwatchSecondary = Color(0xFF005F73);

  static const Color oceanBlueSwatchPrimary = Color(0xFF81B2E8);
  static const Color oceanBlueSwatchSecondary = Color(0xFF4A85C4);

  static const Color iceBlueSwatchPrimary = Color(0xFFD8F3FF);
  static const Color iceBlueSwatchSecondary = Color(0xFF90C9E8);

  static const Color goldSwatchPrimary = Color(0xFFE19F20);
  static const Color goldSwatchSecondary = Color(0xFFB07818);

  static const Color mulberrySwatchPrimary = Color(0xFF75344E);
  static const Color mulberrySwatchSecondary = Color(0xFF52243A);

  static const Color midnightSwatchPrimary = Color(0xFF0F1623);
  static const Color midnightSwatchSecondary = Color(0xFF0A0F18);

  static const Color orangeSwatchPrimary = Color(0xFFFF8C00);
  static const Color orangeSwatchSecondary = Color(0xFFCC7000);

  static const Color greenSwatchPrimary = Color(0xFF32CD32);
  static const Color greenSwatchSecondary = Color(0xFF22A322);

  static const Color skyBlueSwatchPrimary = Color(0xFF00BFFF);
  static const Color skyBlueSwatchSecondary = Color(0xFF008CCC);

  static const Color royalBlueSwatchPrimary = Color(0xFF4169E1);
  static const Color royalBlueSwatchSecondary = Color(0xFF2B4DB0);

  static const Color orchidSwatchPrimary = Color(0xFFBA55D3);
  static const Color orchidSwatchSecondary = Color(0xFF8A2FB0);

  static const Color hotPinkSwatchPrimary = Color(0xFFFF69B4);
  static const Color hotPinkSwatchSecondary = Color(0xFFCC3380);

  static const Color crimsonSwatchPrimary = Color(0xFFDC143C);
  static const Color crimsonSwatchSecondary = Color(0xFFA00A28);

  // ── Founder Aquarist ────────────────────────────────────────────────────────
  /// Deep purple used for Founder Aquarist badges, borders, and accents
  /// in light mode.
  static const Color founderPurple = Color(0xFF6A1B9A);

  /// Lighter purple tint for Founder Aquarist UI on dark backgrounds / in
  /// dark mode — provides better contrast than [founderPurple].
  static const Color founderPurpleLight = Color(0xFFCE93D8);

  /// Returns [founderPurple] in light mode and [founderPurpleLight] in dark
  /// mode so all Founder UI maintains adequate contrast regardless of theme
  /// brightness. Use this instead of the bare constants wherever a
  /// [BuildContext] is available.
  static Color founderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? founderPurpleLight
      : founderPurple;
}
