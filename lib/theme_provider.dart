// lib/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String themeKey = "theme_is_dark";
  static const String materialYouKey = "material_you_enabled"; // New key

  ThemeMode _themeMode = ThemeMode.light;
  bool _useMaterialYou = false; // New state variable

  ThemeMode get themeMode => _themeMode;
  bool get useMaterialYou => _useMaterialYou; // New getter

  ThemeProvider() {
    _loadPreferences();
  }

  // Load both theme and Material You preferences
  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(themeKey) ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

    // Load the Material You preference, defaulting to false
    _useMaterialYou = prefs.getBool(materialYouKey) ?? false;

    notifyListeners();
  }

  // Save a boolean preference to device storage
  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Toggle the theme and save the new preference
  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _savePreference(themeKey, isDarkMode);
    notifyListeners();
  }

  // Toggle Material You theme and save the preference
  void toggleMaterialYou(bool isEnabled) {
    _useMaterialYou = isEnabled;
    _savePreference(materialYouKey, isEnabled);
    notifyListeners();
  }
}