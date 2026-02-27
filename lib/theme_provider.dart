import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './services/analytics_service.dart';

final themeProviderNotifierProvider =
    StateNotifierProvider<ThemeProviderNotifier, ThemeProviderState>((ref) {
  return ThemeProviderNotifier();
});

/// The available color themes for the app.
enum AppColorTheme {
  /// Default aquarium teal/blue scheme (original app theme).
  defaultTheme,

  /// Uses the phone's system accent color (Android 12+ / Material You).
  materialYou,

  /// Ocean blue – primary color #81B2E8.
  oceanBlue,

  /// Ice blue – primary color #D8F3FF.
  iceBlue,

  /// Gold – primary color #E19F20.
  gold,

  /// Mulberry – primary color #75344E.
  mulberry,

  /// Midnight – primary color #0F1623.
  midnight,
}

extension AppColorThemeExt on AppColorTheme {
  String get displayName {
    switch (this) {
      case AppColorTheme.defaultTheme:
        return 'Default';
      case AppColorTheme.materialYou:
        return 'Material You';
      case AppColorTheme.oceanBlue:
        return 'Ocean Blue';
      case AppColorTheme.iceBlue:
        return 'Ice Blue';
      case AppColorTheme.gold:
        return 'Gold';
      case AppColorTheme.mulberry:
        return 'Mulberry';
      case AppColorTheme.midnight:
        return 'Midnight';
    }
  }

  /// The primary seed color for non-Material-You themes.
  Color get seedColor {
    switch (this) {
      case AppColorTheme.defaultTheme:
        return const Color(0xFF005f73);
      case AppColorTheme.materialYou:
        return const Color(0xFF005f73); // fallback; overridden by dynamic color
      case AppColorTheme.oceanBlue:
        return const Color(0xFF81B2E8);
      case AppColorTheme.iceBlue:
        return const Color(0xFFD8F3FF);
      case AppColorTheme.gold:
        return const Color(0xFFE19F20);
      case AppColorTheme.mulberry:
        return const Color(0xFF75344E);
      case AppColorTheme.midnight:
        return const Color(0xFF0F1623);
    }
  }
}

class ThemeProviderNotifier extends StateNotifier<ThemeProviderState> {
  ThemeProviderNotifier()
      : super(ThemeProviderState(
            themeMode: ThemeMode.system,
            useMaterialYou: false,
            colorTheme: AppColorTheme.defaultTheme)) {
    _loadTheme();
  }

  ThemeData getLightTheme(ColorScheme? lightDynamic) {
    final colorScheme = lightDynamic ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF3498DB),
          brightness: Brightness.light,
        );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'NotoSans',
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      chipTheme: _chipTheme(colorScheme),
    );
  }

  ThemeData getDarkTheme(ColorScheme? darkDynamic) {
    final colorScheme = darkDynamic ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF3498DB),
          brightness: Brightness.dark,
        );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'NotoSans',
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      chipTheme: _chipTheme(colorScheme),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }

  static ChipThemeData _chipTheme(ColorScheme cs) {
    return ChipThemeData(
      backgroundColor: cs.surfaceContainerHighest,
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.onPrimaryContainer,
      side: BorderSide(color: cs.outline.withOpacity(0.5)),
    );
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 2; // Default to system
    final useMaterialYou = prefs.getBool('useMaterialYou') ?? false;

    // Prefer name-based storage (resilient to enum reordering); fall back to
    // the legacy index-based key for backwards compatibility.
    final colorThemeName = prefs.getString('colorThemeName');
    AppColorTheme colorTheme;
    if (colorThemeName != null) {
      colorTheme = AppColorTheme.values.firstWhere(
        (t) => t.name == colorThemeName,
        orElse: () => AppColorTheme.defaultTheme,
      );
    } else {
      final colorThemeIndex =
          prefs.getInt('colorTheme') ?? AppColorTheme.defaultTheme.index;
      colorTheme = colorThemeIndex < AppColorTheme.values.length
          ? AppColorTheme.values[colorThemeIndex]
          : AppColorTheme.defaultTheme;
    }

    state = ThemeProviderState(
        themeMode: ThemeMode.values[themeIndex],
        useMaterialYou: useMaterialYou,
        colorTheme: colorTheme);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final oldMode = state.themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    state = ThemeProviderState(
        themeMode: mode,
        useMaterialYou: state.useMaterialYou,
        colorTheme: state.colorTheme);

    // Log theme change
    AnalyticsService.logSettingsChange(
      settingName: 'theme_mode',
      newValue: mode.toString(),
      oldValue: oldMode.toString(),
    );
  }

  Future<void> toggleMaterialYou(bool value) async {
    final oldValue = state.useMaterialYou;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useMaterialYou', value);
    // When enabling Material You, switch to the materialYou color theme;
    // when disabling, fall back to defaultTheme if currently on materialYou.
    AppColorTheme newColorTheme = state.colorTheme;
    if (value) {
      newColorTheme = AppColorTheme.materialYou;
    } else if (state.colorTheme == AppColorTheme.materialYou) {
      newColorTheme = AppColorTheme.defaultTheme;
    }
    await prefs.setInt('colorTheme', newColorTheme.index);
    await prefs.setString('colorThemeName', newColorTheme.name);
    state = ThemeProviderState(
        themeMode: state.themeMode,
        useMaterialYou: value,
        colorTheme: newColorTheme);

    // Log Material You toggle
    AnalyticsService.logSettingsChange(
      settingName: 'material_you',
      newValue: value.toString(),
      oldValue: oldValue.toString(),
    );
  }

  /// Switch to a specific [AppColorTheme]. Automatically updates [useMaterialYou].
  Future<void> setColorTheme(AppColorTheme theme) async {
    final oldTheme = state.colorTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorTheme', theme.index);
    await prefs.setString('colorThemeName', theme.name);
    // Material You flag follows the materialYou theme selection.
    final useMaterialYou = theme == AppColorTheme.materialYou;
    await prefs.setBool('useMaterialYou', useMaterialYou);
    state = ThemeProviderState(
        themeMode: state.themeMode,
        useMaterialYou: useMaterialYou,
        colorTheme: theme);

    AnalyticsService.logSettingsChange(
      settingName: 'color_theme',
      newValue: theme.name,
      oldValue: oldTheme.name,
    );
  }
}

class ThemeProviderState {
  final ThemeMode themeMode;
  final bool useMaterialYou;
  final AppColorTheme colorTheme;

  ThemeProviderState({
    required this.themeMode,
    required this.useMaterialYou,
    required this.colorTheme,
  });
}
