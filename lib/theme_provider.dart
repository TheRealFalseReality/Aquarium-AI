import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProviderNotifierProvider = NotifierProvider<ThemeProviderNotifier, ThemeProviderState>(ThemeProviderNotifier.new);

class ThemeProviderState {
  final ThemeMode themeMode;
  final bool useMaterialYou;

  ThemeProviderState({this.themeMode = ThemeMode.system, this.useMaterialYou = true}); // Changed default to ThemeMode.system

  ThemeProviderState copyWith({ThemeMode? themeMode, bool? useMaterialYou}) {
    return ThemeProviderState(
      themeMode: themeMode ?? this.themeMode,
      useMaterialYou: useMaterialYou ?? this.useMaterialYou,
    );
  }
}

class ThemeProviderNotifier extends Notifier<ThemeProviderState> {
  static const String themeKey = "theme_is_dark";
  static const String materialYouKey = "material_you_enabled";

  @override
  ThemeProviderState build() {
    _loadPreferences();
    return ThemeProviderState();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(themeKey);
    final useMaterialYou = prefs.getBool(materialYouKey) ?? true;
    
    ThemeMode themeMode;
    if (isDarkMode == null) {
      themeMode = ThemeMode.system;
    } else {
      themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }

    state = state.copyWith(
      themeMode: themeMode,
      useMaterialYou: useMaterialYou,
    );
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void toggleTheme(bool isDarkMode) {
    state = state.copyWith(themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light);
    _savePreference(themeKey, isDarkMode);
  }

  void toggleMaterialYou(bool isEnabled) {
    state = state.copyWith(useMaterialYou: isEnabled);
    _savePreference(materialYouKey, isEnabled);
  }
}