import 'package:riverpod/riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State class for app settings
class AppSettingsState {
  final bool showStockingButton;
  final bool isLoading;

  AppSettingsState({
    required this.showStockingButton,
    this.isLoading = true,
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

    state = AppSettingsState(
      showStockingButton: showStockingButton,
      isLoading: false,
    );
  }

  Future<void> setShowStockingButton(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showStockingButton', value);

    state = AppSettingsState(
      showStockingButton: value,
      isLoading: false,
    );
  }
}

// Provider for app settings
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  (ref) => AppSettingsNotifier(),
);
