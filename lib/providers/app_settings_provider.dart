import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used to store the remembered reschedule option in SharedPreferences
const String _rememberedRescheduleOptionKey = 'remembered_reschedule_option';

// State class for app settings
class AppSettingsState {
  final bool showStockingButton;
  final String? localeCode; // null means system default
  final bool isLoading;
  final bool hasRememberedRescheduleOption;

  AppSettingsState({
    required this.showStockingButton,
    this.localeCode,
    this.isLoading = true,
    this.hasRememberedRescheduleOption = false,
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
    final hasRememberedRescheduleOption = prefs.containsKey(_rememberedRescheduleOptionKey);

    state = AppSettingsState(
      showStockingButton: showStockingButton,
      localeCode: localeCode,
      isLoading: false,
      hasRememberedRescheduleOption: hasRememberedRescheduleOption,
    );
  }

  Future<void> setShowStockingButton(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showStockingButton', value);

    state = AppSettingsState(
      showStockingButton: value,
      localeCode: state.localeCode,
      isLoading: false,
      hasRememberedRescheduleOption: state.hasRememberedRescheduleOption,
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
      hasRememberedRescheduleOption: state.hasRememberedRescheduleOption,
    );
  }

  /// Clear the remembered reschedule option preference
  Future<void> clearRememberedRescheduleOption() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberedRescheduleOptionKey);

    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      localeCode: state.localeCode,
      isLoading: false,
      hasRememberedRescheduleOption: false,
    );
  }

  /// Refresh the state to check if a remembered reschedule option exists
  Future<void> refreshRememberedRescheduleOption() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRememberedRescheduleOption = prefs.containsKey(_rememberedRescheduleOptionKey);

    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      localeCode: state.localeCode,
      isLoading: false,
      hasRememberedRescheduleOption: hasRememberedRescheduleOption,
    );
  }
}

// Provider for app settings
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  (ref) => AppSettingsNotifier(),
);
