import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prefix used to store the remembered reschedule option per notification in SharedPreferences
const String rememberedRescheduleOptionKeyPrefix =
    'remembered_reschedule_option_';

/// Get the SharedPreferences key for a specific notification's remembered reschedule option
String getRememberedRescheduleOptionKey(String notificationId) {
  return '$rememberedRescheduleOptionKeyPrefix$notificationId';
}

// State class for app settings
class AppSettingsState {
  final bool showStockingButton;
  final bool enableAI; // Controls whether AI features are enabled
  final String? localeCode; // null means system default
  /// Language the AI should respond in.
  /// - null  → follow the app locale (uses [localeCode] to determine language)
  /// - ""    → no instruction (AI default, typically English)
  /// - other → explicit language name, e.g. "Portuguese"
  final String? aiResponseLanguage;
  final bool isLoading;
  final bool hasRememberedRescheduleOptions;
  final bool
  welcomeGridLayout; // Controls grid (true) vs list (false) on welcome screen
  final bool
  tankGridLayout; // Controls grid (true) vs list (false) on tank management screen
  final bool
  debugHideAds; // Debug-only: hides ads and references to removing them
  final bool tankHideIcon;
  final bool tankHideMetrics;
  final bool tankHideInhabitants;
  final bool tankHideNotes;
  final bool tankHideQuickLogs;
  final bool tankHideActivity;
  final bool tankHidePhotos;
  final bool
  tankHideHarmonyDelta; // Hide the +/-% harmony delta chip on tank cards (default false = show)
  final bool
  tankHideCardTags; // Hide the tank tag chips on tank cards (default false = show)
  final bool
  tankInhabitantGridView; // Show fish inhabitants as a grid of tiles (default false = list)
  /// Experience level for tailoring AI responses: 'beginner', 'intermediate', 'advanced', 'expert'.
  final String userExperienceLevel;

  AppSettingsState({
    required this.showStockingButton,
    this.enableAI = true, // Default to true (AI enabled)
    this.localeCode,
    this.aiResponseLanguage, // null = follow app language
    this.isLoading = true,
    this.hasRememberedRescheduleOptions = false,
    this.welcomeGridLayout = false, // Default to list layout
    this.tankGridLayout = false, // Default to list layout for tanks
    this.debugHideAds = false,
    this.tankHideIcon = false,
    this.tankHideMetrics = false,
    this.tankHideInhabitants = false,
    this.tankHideNotes = false,
    this.tankHideQuickLogs = false,
    this.tankHideActivity = false,
    this.tankHidePhotos = false,
    this.tankHideHarmonyDelta = false, // Default to showing delta
    this.tankHideCardTags = false, // Default to showing tags
    this.tankInhabitantGridView = false, // Default to list view for fish
    this.userExperienceLevel = 'beginner', // Default to beginner
  });
}

// Notifier for app settings
class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier()
    : super(
        AppSettingsState(
          showStockingButton: true, // Default to true (show button)
          enableAI: true, // Default to true (AI enabled)
          welcomeGridLayout: false, // Default to list layout
          tankGridLayout: false, // Default to list layout for tanks
          userExperienceLevel: 'beginner',
        ),
      ) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final showStockingButton = prefs.getBool('showStockingButton') ?? true;
    final enableAI = prefs.getBool('enableAI') ?? true; // Default to true
    final localeCode = prefs.getString(
      'localeCode',
    ); // null means system default
    // aiResponseLanguage: not present in prefs = null (follow app language)
    // stored as empty string = no instruction
    final aiResponseLanguage = prefs.containsKey('aiResponseLanguage')
        ? prefs.getString('aiResponseLanguage')
        : null;
    final hasRememberedRescheduleOptions = _hasAnyRememberedRescheduleOptions(
      prefs,
    );
    final welcomeGridLayout =
        prefs.getBool('welcomeGridLayout') ?? false; // Default to list
    final tankGridLayout =
        prefs.getBool('tankGridLayout') ?? false; // Default to list
    final debugHideAds = prefs.getBool('debugHideAds') ?? kDebugMode;
    final tankHideIcon = prefs.getBool('tankHideIcon') ?? false;
    final tankHideMetrics = prefs.getBool('tankHideMetrics') ?? false;
    final tankHideInhabitants = prefs.getBool('tankHideInhabitants') ?? false;
    final tankHideNotes = prefs.getBool('tankHideNotes') ?? false;
    final tankHideQuickLogs = prefs.getBool('tankHideQuickLogs') ?? false;
    final tankHideActivity = prefs.getBool('tankHideActivity') ?? false;
    final tankHidePhotos = prefs.getBool('tankHidePhotos') ?? false;
    final tankHideHarmonyDelta =
        prefs.getBool('tankHideHarmonyDelta') ?? false; // Default to showing
    final tankHideCardTags =
        prefs.getBool('tankHideCardTags') ?? false; // Default to showing
    final tankInhabitantGridView =
        prefs.getBool('tankInhabitantGridView') ?? false; // Default to list
    final userExperienceLevel =
        prefs.getString('userExperienceLevel') ?? 'beginner';

    state = AppSettingsState(
      showStockingButton: showStockingButton,
      enableAI: enableAI,
      localeCode: localeCode,
      aiResponseLanguage: aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: hasRememberedRescheduleOptions,
      welcomeGridLayout: welcomeGridLayout,
      tankGridLayout: tankGridLayout,
      debugHideAds: debugHideAds,
      tankHideIcon: tankHideIcon,
      tankHideMetrics: tankHideMetrics,
      tankHideInhabitants: tankHideInhabitants,
      tankHideNotes: tankHideNotes,
      tankHideQuickLogs: tankHideQuickLogs,
      tankHideActivity: tankHideActivity,
      tankHidePhotos: tankHidePhotos,
      tankHideHarmonyDelta: tankHideHarmonyDelta,
      tankHideCardTags: tankHideCardTags,
      tankInhabitantGridView: tankInhabitantGridView,
      userExperienceLevel: userExperienceLevel,
    );
  }

  /// Check if any remembered reschedule options exist
  bool _hasAnyRememberedRescheduleOptions(SharedPreferences prefs) {
    final keys = prefs.getKeys();
    return keys.any(
      (key) => key.startsWith(rememberedRescheduleOptionKeyPrefix),
    );
  }

  Future<void> setShowStockingButton(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showStockingButton', value);

    state = AppSettingsState(
      showStockingButton: value,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setEnableAI(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableAI', value);

    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: value,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
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
      enableAI: state.enableAI,
      localeCode: localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setAiResponseLanguage(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('aiResponseLanguage');
    } else {
      await prefs.setString('aiResponseLanguage', value);
    }
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: value,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setWelcomeGridLayout(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcomeGridLayout', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: value,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  /// Sets the debug hide-ads flag (only meaningful in debug builds).
  Future<void> setDebugHideAds(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debugHideAds', value);

    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: value,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankGridLayout(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankGridLayout', value);

    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: value,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankHideIcon(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankHideIcon', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: value,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankHideMetrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankHideMetrics', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: value,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankHideInhabitants(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankHideInhabitants', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: value,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankHideNotes(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankHideNotes', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: value,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankHideQuickLogs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankHideQuickLogs', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: value,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankHideActivity(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankHideActivity', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: value,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankHidePhotos(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankHidePhotos', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: value,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankHideHarmonyDelta(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankHideHarmonyDelta', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: value,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankHideCardTags(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankHideCardTags', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: value,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  Future<void> setTankInhabitantGridView(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tankInhabitantGridView', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,
      tankInhabitantGridView: value,
    );
  }

  Future<void> clearAllRememberedRescheduleOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();

    // Remove all keys that start with the prefix
    for (final key in keys) {
      if (key.startsWith(rememberedRescheduleOptionKeyPrefix)) {
        await prefs.remove(key);
      }
    }

    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: false,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  /// Refresh the state to check if any remembered reschedule options exist
  Future<void> refreshRememberedRescheduleOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRememberedRescheduleOptions = _hasAnyRememberedRescheduleOptions(
      prefs,
    );

    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }

  /// Export all reschedule preferences for backup
  /// Returns a map of notification ID to reschedule option index
  Future<Map<String, int>> exportReschedulePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final preferences = <String, int>{};

    for (final key in prefs.getKeys()) {
      if (key.startsWith(rememberedRescheduleOptionKeyPrefix)) {
        final notificationId = key.substring(
          rememberedRescheduleOptionKeyPrefix.length,
        );
        final value = prefs.getInt(key);
        if (value != null) {
          preferences[notificationId] = value;
        }
      }
    }

    return preferences;
  }

  /// Import reschedule preferences from backup
  /// Takes a map of notification ID to reschedule option index
  Future<void> importReschedulePreferences(Map<String, int> preferences) async {
    final prefs = await SharedPreferences.getInstance();

    // Clear existing preferences first
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith(rememberedRescheduleOptionKeyPrefix)) {
        await prefs.remove(key);
      }
    }

    // Import new preferences
    for (final entry in preferences.entries) {
      final key = getRememberedRescheduleOptionKey(entry.key);
      await prefs.setInt(key, entry.value);
    }

    // Update state
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: preferences.isNotEmpty,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: state.userExperienceLevel,
    );
  }
}

  Future<void> setUserExperienceLevel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userExperienceLevel', value);
    state = AppSettingsState(
      showStockingButton: state.showStockingButton,
      enableAI: state.enableAI,
      localeCode: state.localeCode,
      aiResponseLanguage: state.aiResponseLanguage,
      isLoading: false,
      hasRememberedRescheduleOptions: state.hasRememberedRescheduleOptions,
      welcomeGridLayout: state.welcomeGridLayout,
      tankGridLayout: state.tankGridLayout,
      debugHideAds: state.debugHideAds,
      tankHideIcon: state.tankHideIcon,
      tankHideMetrics: state.tankHideMetrics,
      tankHideInhabitants: state.tankHideInhabitants,
      tankHideNotes: state.tankHideNotes,
      tankHideQuickLogs: state.tankHideQuickLogs,
      tankHideActivity: state.tankHideActivity,
      tankHidePhotos: state.tankHidePhotos,
      tankHideHarmonyDelta: state.tankHideHarmonyDelta,
      tankHideCardTags: state.tankHideCardTags,
      tankInhabitantGridView: state.tankInhabitantGridView,
      userExperienceLevel: value,
    );
  }
}

// Provider for app settings
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
      (ref) => AppSettingsNotifier(),
    );
