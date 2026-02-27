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
}
