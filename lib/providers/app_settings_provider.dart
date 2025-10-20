import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State class for app settings
class AppSettingsState {
  final bool showStockingButton;
  final String? localeCode; // null means system default
  final bool isLoading;

  AppSettingsState({
    required this.showStockingButton,
    this.localeCode,
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
    final localeCode = prefs.getString('localeCode'); // null means system default

    state = AppSettingsState(
      showStockingButton: showStockingButton,
      localeCode: localeCode,
      isLoading: false,
    );
  }

  Future<void> setShowStockingButton(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showStockingButton', value);

    state = AppSettingsState(
      showStockingButton: value,
      localeCode: state.localeCode,
      isLoading: false,
    );
  }

  Future<void> setLocale(String? localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (localeCode == null) {
      await prefs.remove('localeCode');
    } else {
      await prefs.setString('localeCode', localeCode);
    }

    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      localeCode: localeCode,
      isLoading: false,
    );
  }
}

// Provider for app settings
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  (ref) => AppSettingsNotifier(),
);
