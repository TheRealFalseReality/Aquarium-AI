import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './services/analytics_service.dart';

final themeProviderNotifierProvider =
    StateNotifierProvider<ThemeProviderNotifier, ThemeProviderState>((ref) {
  return ThemeProviderNotifier();
});

class ThemeProviderNotifier extends StateNotifier<ThemeProviderState> {
  ThemeProviderNotifier()
      : super(ThemeProviderState(
            themeMode: ThemeMode.system, useMaterialYou: false)) {
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
      fontFamily: 'NotoSans', // Use NotoSans as the default font
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
      fontFamily: 'NotoSans', // Use NotoSans as the default font
    );
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 2; // Default to system
    final useMaterialYou = prefs.getBool('useMaterialYou') ?? false;
    state = ThemeProviderState(
        themeMode: ThemeMode.values[themeIndex],
        useMaterialYou: useMaterialYou);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final oldMode = state.themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    state = ThemeProviderState(themeMode: mode, useMaterialYou: state.useMaterialYou);
    
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
    state = ThemeProviderState(themeMode: state.themeMode, useMaterialYou: value);
    
    // Log Material You toggle
    AnalyticsService.logSettingsChange(
      settingName: 'material_you',
      newValue: value.toString(),
      oldValue: oldValue.toString(),
    );
  }
}

class ThemeProviderState {
  final ThemeMode themeMode;
  final bool useMaterialYou;

  ThemeProviderState({required this.themeMode, required this.useMaterialYou});
}