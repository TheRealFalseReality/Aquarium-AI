// lib/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String themeKey = "theme_is_dark";
  ThemeMode _themeMode = ThemeMode.light; // 1. Default to light theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme(); // 2. Load saved theme when the provider is created
  }

  // Load theme preference from device storage
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Read the saved boolean. If it doesn't exist, default to 'false' (light mode).
    final isDarkMode = prefs.getBool(themeKey) ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Save theme preference to device storage
  Future<void> _saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, isDarkMode);
  }

  // Toggle the theme and save the new preference
  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _saveTheme(isDarkMode); // 3. Save the new state
    notifyListeners();
  }
}