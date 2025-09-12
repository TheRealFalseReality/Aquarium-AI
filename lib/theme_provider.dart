import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProviderNotifierProvider = NotifierProvider<ThemeProviderNotifier, ThemeProviderState>(ThemeProviderNotifier.new);

class ThemeProviderState {
  final ThemeMode themeMode;
  final bool useMaterialYou;

  ThemeProviderState({this.themeMode = ThemeMode.system, this.useMaterialYou = true});

  ThemeProviderState copyWith({ThemeMode? themeMode, bool? useMaterialYou}) {
    return ThemeProviderState(
      themeMode: themeMode ?? this.themeMode,
      useMaterialYou: useMaterialYou ?? this.useMaterialYou,
    );
  }
}

class ThemeProviderNotifier extends Notifier<ThemeProviderState> {
  static const String themeModeKey = "theme_mode";
  static const String materialYouKey = "material_you_enabled";

  @override
  ThemeProviderState build() {
    _loadPreferences();
    return ThemeProviderState();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(themeModeKey) ?? 0; // Default to System
    final useMaterialYou = prefs.getBool(materialYouKey) ?? true;
    
    state = state.copyWith(
      themeMode: ThemeMode.values[themeIndex],
      useMaterialYou: useMaterialYou,
    );
  }

  Future<void> _saveThemePreference(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }
  
  Future<void> _saveMaterialYouPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveThemePreference(themeModeKey, mode.index);
  }

  void toggleMaterialYou(bool isEnabled) {
    state = state.copyWith(useMaterialYou: isEnabled);
    _saveMaterialYouPreference(materialYouKey, isEnabled);
  }
}