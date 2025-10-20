import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State class for app settings
class AppSettingsState {
  final bool showStockingButton;
  final bool isLoading;
  final Locale? locale; // null means system default

  AppSettingsState({
    required this.showStockingButton,
    this.isLoading = true,
    this.locale,
  });
}

// Notifier for app settings
class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier()
      : super(AppSettingsState(
          showStockingButton: true, // Default to true (show button)
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final showStockingButton = prefs.getBool('showStockingButton') ?? true;
    final localeCode = prefs.getString('locale');
    final Locale? locale = localeCode != null ? Locale(localeCode) : null;

    state = AppSettingsState(
      showStockingButton: showStockingButton,
      locale: locale,
      isLoading: false,
    );
  }

  Future<void> setShowStockingButton(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showStockingButton', value);

    state = AppSettingsState(
      showStockingButton: value,
      locale: state.locale,
      isLoading: false,
    );
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove('locale');
    } else {
      await prefs.setString('locale', locale.languageCode);
    }

    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      locale: locale,
      isLoading: false,
    );
  }
}

// Provider for app settings
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  (ref) => AppSettingsNotifier(),
);
