import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/fish.dart';
import '../models/tank.dart';
import '../providers/purchase_provider.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/fish_data_service.dart';
import '../services/remote_config_service.dart';
import '../theme_colors.dart';
import '../theme_provider.dart';
import '../widgets/fish_image.dart';
import '../widgets/modern_chip.dart';
import '../widgets/remove_ads_dialog.dart';
import 'tank_creation_screen.dart' show InhabitantDialog;
import 'tank_volume_calculator.dart';

/// A six-step, skippable onboarding flow shown once on first launch.
///
/// Steps:
///   1. Choose Your Style  – theme and brightness mode selection
///   2. Welcome / Sign In  – upsells the community and account features
///   3. Create Your Tank   – simplified tank setup (name, type, size)
///   4. Add Inhabitants    – optionally populate the tank with fish
///   5. Discover AI Tools  – overview of the key AI features
///   6. Power Up Your AI   – API key explainer + Founder Aquarist upsell
///
/// Pass [initialPage] to start on a specific step (e.g. when resuming after
/// sign-in via [AuthScreen]).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.initialPage = 0});

  /// The step index to show first (0-based). Used when resuming after sign-in.
  final int initialPage;

  static const String _onboardingCompletedKey = 'onboarding_completed';

  /// Set the first time onboarding is displayed. Prevents re-showing if the
  /// user exits mid-flow without completing.
  static const String _onboardingSeenOnceKey = 'onboarding_seen_once';

  /// Returns `true` if the user has already completed or dismissed onboarding.
  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Persists the completed state so onboarding is never shown again.
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Returns `true` if onboarding has already been displayed at least once on
  /// this device. Used to prevent re-showing mid-flow on subsequent launches.
  static Future<bool> hasBeenSeenOnce() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenOnceKey) ?? false;
  }

  /// Marks that onboarding has been shown at least once.
  static Future<void> markSeenOnce() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenOnceKey, true);
  }

  /// Returns `true` when the device has existing user data (tanks), indicating
  /// this is an app update rather than a fresh install. In that case onboarding
  /// should be silently skipped.
  static Future<bool> isExistingUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_tanks');
  }

  /// Clears the completed flag – useful for revisiting onboarding from Settings.
  /// Does NOT clear [_onboardingSeenOnceKey] so the auto-check in
  /// WelcomeScreen does not re-trigger (Settings navigates directly instead).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
  }

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalPages = 5;

  late final PageController _pageController;
  int _currentPage = 0;

  // ── Per-step interaction tracking (used for smart Next/Skip label) ────────
  final Set<int> _interactedPages = {};

  // ── Step 2 state: tank creation ─────────────────────────────────────────
  final _tankNameController = TextEditingController();
  final _sizeGallonsController = TextEditingController();
  final _sizeLitersController = TextEditingController();
  final _tankNotesController = TextEditingController();
  String _selectedTankType = 'freshwater';
  bool _isReef = false;
  DateTime _tankCreatedDate = DateTime.now();

  // ── Step 3 state: inhabitants ────────────────────────────────────────────
  List<TankInhabitant> _inhabitants = [];
  List<Fish> _availableFish = [];

  // Track whether the tank has already been saved (guards double-save).
  bool _tankSaved = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage);
    // Mark earlier pages as already "interacted" when resuming mid-flow.
    for (var i = 0; i < _currentPage; i++) {
      _interactedPages.add(i);
    }
    AnalyticsService.logScreenView(screenName: 'onboarding_screen');
    _loadFishData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tankNameController.dispose();
    _sizeGallonsController.dispose();
    _sizeLitersController.dispose();
    _tankNotesController.dispose();
    super.dispose();
  }

  // ── Fish data ─────────────────────────────────────────────────────────────

  Future<void> _loadFishData() async {
    try {
      final fishDataService = ref.read(fishDataServiceProvider);
      final fishData = await fishDataService.loadFishData();
      final fishList = fishData[_selectedTankType] ?? [];
      if (mounted) setState(() => _availableFish = fishList);
    } catch (e) {
      debugPrint('OnboardingScreen: failed to load fish data: $e');
    }
  }

  // ── Interaction tracking ──────────────────────────────────────────────────

  /// Call whenever the user makes a meaningful input on a step.
  void _markInteracted([int? page]) {
    final p = page ?? _currentPage;
    if (!_interactedPages.contains(p)) {
      setState(() => _interactedPages.add(p));
    }
  }

  bool get _currentPageInteracted => _interactedPages.contains(_currentPage);

  // ── Navigation ────────────────────────────────────────────────────────────

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      // If leaving the tank-creation step (1) with no tank name, skip the
      // inhabitants step (2) since there is nothing to add inhabitants to.
      final skipInhabitants = _currentPage == 1 &&
          _tankNameController.text.trim().isEmpty;
      final targetPage = skipInhabitants ? 3 : _currentPage + 1;
      if (targetPage >= _totalPages) {
        _finish(skipped: false);
        return;
      }
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish(skipped: false);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Shows a confirmation dialog before skipping the entire onboarding flow.
  Future<void> _confirmSkip() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.onboardingSkipConfirmTitle),
        content: Text(l10n.onboardingSkipConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.onboardingSkipConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _finish(skipped: true);
    }
  }

  Future<void> _finish({required bool skipped}) async {
    await _saveTankIfNeeded();
    await OnboardingScreen.markCompleted();
    AnalyticsService.logFeatureUsed(
      featureName: skipped ? 'onboarding_skipped' : 'onboarding_completed',
      parameters: {'step': _currentPage.toString()},
    );
    if (!mounted) return;
    // Set a flag so the welcome screen shows the AquaPi promotion dialog
    // shortly after arriving there (whether onboarding was completed or skipped).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aquapi_show_after_onboarding', true);
    if (mounted) Navigator.of(context).pushReplacementNamed('/');
  }

  // ── Tank persistence ──────────────────────────────────────────────────────

  Future<void> _saveTankIfNeeded() async {
    if (_tankSaved) return;
    final name = _tankNameController.text.trim();
    if (name.isEmpty) return;
    _tankSaved = true;

    final gallons = double.tryParse(_sizeGallonsController.text.trim());
    final liters = double.tryParse(_sizeLitersController.text.trim());

    final tank = Tank.create(
      name: name,
      type: _selectedTankType,
      isReef: _isReef,
      sizeGallons: gallons,
      sizeLiters: liters,
      notes: _tankNotesController.text.trim().isEmpty
          ? null
          : _tankNotesController.text.trim(),
      createdAt: _tankCreatedDate,
      inhabitants: _inhabitants,
    );
    await ref.read(tankProvider.notifier).addTank(tank);
  }

  // ── Tank type change ──────────────────────────────────────────────────────

  void _onTankTypeChanged(String newType) {
    if (_selectedTankType == newType) return;

    if (_inhabitants.isNotEmpty) {
      final l10n = AppLocalizations.of(context)!;
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.changeTankType),
          content: Text(
            l10n.onboardingChangeTankTypeWarning,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true && mounted) {
          setState(() {
            _selectedTankType = newType;
            _inhabitants = [];
            if (newType != 'marine') _isReef = false;
          });
          _loadFishData();
        }
      });
    } else {
      setState(() {
        _selectedTankType = newType;
        if (newType != 'marine') _isReef = false;
      });
      _loadFishData();
    }
  }

  // ── Inhabitants ───────────────────────────────────────────────────────────

  void _addInhabitant() {
    showDialog(
      context: context,
      builder: (context) => InhabitantDialog(
        availableFish: _availableFish,
        onAdd: (inhabitant) {
          setState(() => _inhabitants.add(inhabitant));
          _markInteracted(2);
        },
      ),
    );
  }

  void _removeInhabitant(int index) =>
      setState(() => _inhabitants.removeAt(index));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, l10n, cs),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) {
                  // Capture direction BEFORE setState updates _currentPage.
                  final wasGoingBack = i < _currentPage;
                  setState(() => _currentPage = i);
                  // Auto-skip the inhabitants step (2) when no tank name was
                  // entered — only when going FORWARD (swiping), never back.
                  if (!wasGoingBack &&
                      i == 2 &&
                      _tankNameController.text.trim().isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _pageController.animateToPage(
                          3,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  }
                },
                children: [
                  _buildThemePage(context, l10n, cs),
                  _buildCreateTankPage(context, l10n, cs),
                  _buildInhabitantsPage(context, l10n, cs),
                  _buildDiscoverToolsPage(context, l10n, cs),
                  _buildApiKeyPage(context, l10n, cs),
                ],
              ),
            ),
            _buildBottomBar(context, l10n, cs),
          ],
        ),
      ),
    );
  }

  // ── Top bar (back · dots · skip) ──────────────────────────────────────────

  Widget _buildTopBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          // Back button – hidden on first step
          SizedBox(
            width: 48,
            child: _currentPage > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _previousPage,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  )
                : null,
          ),
          // Step indicator dots
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? cs.primary
                        : cs.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          // Skip button — shows confirmation dialog
          SizedBox(
            width: 64,
            child: TextButton(
              onPressed: _confirmSkip,
              child: Text(
                l10n.onboardingSkip,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar (next / get-started / skip-inhabitants) ───────────────────

  Widget _buildBottomBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    final isLastPage = _currentPage == _totalPages - 1;
    // On the last page the primary button always says "Get Started".
    // On the Discover Tools page (3) the button always says "Next" since
    // there is nothing to interact with on that page.
    // On the tank-creation page (1): "Add Inhabitants" when a tank name has
    // been typed; "Skip for now" when the field is still empty.
    // On other pages: "Next" once the user has interacted, "Skip for now" otherwise.
    const _discoverToolsPage = 3;
    const _tankPage = 1;
    final hasTankName = _tankNameController.text.trim().isNotEmpty;
    final primaryLabel = isLastPage
        ? l10n.onboardingGetStarted
        : _currentPage == _discoverToolsPage
            ? l10n.onboardingNext
            : (_currentPage == _tankPage && hasTankName)
                ? l10n.onboardingAddInhabitants
                : (_currentPageInteracted
                    ? l10n.onboardingNext
                    : l10n.onboardingSkipForNow);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared page header (icon inline with title + subtitle) ───────────────

  /// Builds a compact header with the hero [icon] beside the [title] and
  /// [subtitle], reducing vertical space compared to a centred hero layout.
  Widget _buildPageHeader(
    BuildContext context,
    ColorScheme cs, {
    required Widget heroContent,
    required BoxDecoration heroDecoration,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: heroDecoration,
          child: Center(child: heroContent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 1: Choose Your Style ────────────────────────────────────────────

  // Maps each non-custom theme to its two swatch preview colours.
  static const Map<AppColorTheme, Color> _swatchPrimary = {
    AppColorTheme.defaultTheme: AquaThemeColors.defaultSwatchPrimary,
    AppColorTheme.materialYou: Color(0xFF7C4DFF),
    AppColorTheme.oceanBlue: AquaThemeColors.oceanBlueSwatchPrimary,
    AppColorTheme.iceBlue: AquaThemeColors.iceBlueSwatchPrimary,
    AppColorTheme.gold: AquaThemeColors.goldSwatchPrimary,
    AppColorTheme.mulberry: AquaThemeColors.mulberrySwatchPrimary,
    AppColorTheme.midnight: AquaThemeColors.midnightSwatchPrimary,
    AppColorTheme.orange: AquaThemeColors.orangeSwatchPrimary,
    AppColorTheme.green: AquaThemeColors.greenSwatchPrimary,
    AppColorTheme.skyBlue: AquaThemeColors.skyBlueSwatchPrimary,
    AppColorTheme.royalBlue: AquaThemeColors.royalBlueSwatchPrimary,
    AppColorTheme.orchid: AquaThemeColors.orchidSwatchPrimary,
    AppColorTheme.hotPink: AquaThemeColors.hotPinkSwatchPrimary,
    AppColorTheme.crimson: AquaThemeColors.crimsonSwatchPrimary,
  };

  static const Map<AppColorTheme, Color> _swatchSecondary = {
    AppColorTheme.defaultTheme: AquaThemeColors.defaultSwatchSecondary,
    AppColorTheme.materialYou: Color(0xFF512DA8),
    AppColorTheme.oceanBlue: AquaThemeColors.oceanBlueSwatchSecondary,
    AppColorTheme.iceBlue: AquaThemeColors.iceBlueSwatchSecondary,
    AppColorTheme.gold: AquaThemeColors.goldSwatchSecondary,
    AppColorTheme.mulberry: AquaThemeColors.mulberrySwatchSecondary,
    AppColorTheme.midnight: AquaThemeColors.midnightSwatchSecondary,
    AppColorTheme.orange: AquaThemeColors.orangeSwatchSecondary,
    AppColorTheme.green: AquaThemeColors.greenSwatchSecondary,
    AppColorTheme.skyBlue: AquaThemeColors.skyBlueSwatchSecondary,
    AppColorTheme.royalBlue: AquaThemeColors.royalBlueSwatchSecondary,
    AppColorTheme.orchid: AquaThemeColors.orchidSwatchSecondary,
    AppColorTheme.hotPink: AquaThemeColors.hotPinkSwatchSecondary,
    AppColorTheme.crimson: AquaThemeColors.crimsonSwatchSecondary,
  };

  Widget _buildThemePage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    final themeState = ref.watch(themeProviderNotifierProvider);
    final themeNotifier = ref.read(themeProviderNotifierProvider.notifier);
    final isMaterialYouAvailable =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    // All themes, optionally excluding Material You on unsupported platforms.
    final themes = AppColorTheme.values
        .where(
          (t) =>
              t != AppColorTheme.custom &&
              (t != AppColorTheme.materialYou || isMaterialYouAvailable),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline header: icon + title + subtitle
          _buildPageHeader(
            context,
            cs,
            heroContent: const Text('🎨', style: TextStyle(fontSize: 30)),
            heroDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _swatchPrimary[themeState.colorTheme] ?? cs.primary,
                  _swatchSecondary[themeState.colorTheme] ??
                      cs.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            title: l10n.onboardingThemeTitle,
            subtitle: l10n.onboardingThemeSubtitle,
          ),
          const SizedBox(height: 20),

          // ── Brightness mode ─────────────────────────────────────────────
          _buildSectionLabel(
            context,
            cs,
            icon: Icons.brightness_6_outlined,
            containerColor: cs.secondaryContainer,
            iconColor: cs.onSecondaryContainer,
            label: l10n.onboardingThemeModeLabel,
          ),
          const SizedBox(height: 12),
          Center(
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(l10n.light),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: Text(l10n.system),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(l10n.dark),
                ),
              ],
              selected: {themeState.themeMode},
              onSelectionChanged: (modes) {
                themeNotifier.setThemeMode(modes.first);
                _markInteracted(0);
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── Colour palette ──────────────────────────────────────────────
          _buildSectionLabel(
            context,
            cs,
            icon: Icons.palette_outlined,
            containerColor: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
            label: l10n.colourTheme,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: themes.map((theme) {
              final primary = _swatchPrimary[theme] ?? cs.primary;
              final secondary = _swatchSecondary[theme] ?? cs.primaryContainer;
              final isSelected = themeState.colorTheme == theme;

              return GestureDetector(
                onTap: () {
                  themeNotifier.setColorTheme(theme);
                  _markInteracted(0);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: cs.onSurface,
                                width: 3,
                              )
                            : Border.all(
                                color: cs.outline.withOpacity(0.3),
                                width: 1.5,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primary.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: _contrastColor(primary),
                              size: 24,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 64,
                      child: Text(
                        theme.displayName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? cs.primary
                              : cs.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Returns black or white depending on which gives better contrast against [bg].
  static Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.35 ? Colors.black87 : Colors.white;
  }

    // ── Step 2: Create Tank ───────────────────────────────────────────────────

  Widget _buildCreateTankPage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline header: icon + title + subtitle
          _buildPageHeader(
            context,
            cs,
            heroContent: const Text('🐠', style: TextStyle(fontSize: 30)),
            heroDecoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            title: l10n.onboardingCreateTankTitle,
            subtitle: l10n.onboardingCreateTankSubtitle,
          ),
          const SizedBox(height: 20),

          // ── Tank Name ───────────────────────────────────────────────────
          _buildSectionLabel(
            context,
            cs,
            icon: Icons.water,
            containerColor: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
            label: l10n.onboardingTankNameLabel,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tankNameController,
            decoration: InputDecoration(
              hintText: l10n.onboardingTankNameHint,
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _markInteracted(1),
          ),
          const SizedBox(height: 24),

          // ── Tank Type ───────────────────────────────────────────────────
          _buildSectionLabel(
            context,
            cs,
            icon: Icons.category,
            containerColor: cs.primaryContainer,
            iconColor: cs.onPrimaryContainer,
            label: l10n.onboardingTankType,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: [
              ModernSelectableChip(
                label: l10n.freshwater,
                emoji: '🐟',
                selected: _selectedTankType == 'freshwater',
                onTap: () {
                  _onTankTypeChanged('freshwater');
                  _markInteracted(1);
                },
              ),
              ModernSelectableChip(
                label: l10n.saltwater,
                emoji: '🪼',
                selected: _selectedTankType == 'marine',
                onTap: () {
                  _onTankTypeChanged('marine');
                  _markInteracted(1);
                },
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _selectedTankType == 'marine'
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      children: [
                        ModernSelectableChip(
                          label: l10n.markAsReef,
                          emoji: '🪸',
                          selected: _isReef,
                          onTap: () => setState(() => _isReef = !_isReef),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // ── Tank Size ───────────────────────────────────────────────────
          Row(
            children: [
              _buildSectionLabel(
                context,
                cs,
                icon: Icons.straighten,
                containerColor: cs.secondaryContainer,
                iconColor: cs.onSecondaryContainer,
                label: l10n.onboardingTankSize,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.onboardingOptional,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sizeGallonsController,
                  decoration: InputDecoration(
                    labelText: l10n.gallons,
                    hintText: '55',
                    border: const OutlineInputBorder(),
                    suffixText: 'gal',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final gal = double.tryParse(value);
                      if (gal != null) {
                        _sizeLitersController.text =
                            (gal * 3.78541).toStringAsFixed(1);
                      }
                    } else {
                      _sizeLitersController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _sizeLitersController,
                  decoration: InputDecoration(
                    labelText: l10n.liters,
                    hintText: '208',
                    border: const OutlineInputBorder(),
                    suffixText: 'L',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final lit = double.tryParse(value);
                      if (lit != null) {
                        _sizeGallonsController.text =
                            (lit / 3.78541).toStringAsFixed(1);
                      }
                    } else {
                      _sizeGallonsController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Calculator tip ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withOpacity(0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.tertiary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: cs.tertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.onboardingCreateTankTip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onTertiaryContainer,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TankVolumeCalculator(
                          onSizeSelected: (gallons, liters) {
                            setState(() {
                              _sizeGallonsController.text =
                                  gallons.toStringAsFixed(1);
                              _sizeLitersController.text =
                                  liters.toStringAsFixed(1);
                            });
                            _markInteracted(1);
                          },
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.onboardingOpenCalculator,
                    style: TextStyle(
                      color: cs.tertiary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Date Created ────────────────────────────────────────────────
          _buildSectionLabel(
            context,
            cs,
            icon: Icons.calendar_today_outlined,
            containerColor: cs.tertiaryContainer,
            iconColor: cs.onTertiaryContainer,
            label: l10n.onboardingTankDateCreated,
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tankCreatedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _tankCreatedDate = picked);
                _markInteracted(1);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: cs.outline.withOpacity(0.6),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMd(
                            Localizations.localeOf(context).toString(),
                          ).format(_tankCreatedDate),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _tankAgeString(_tankCreatedDate, l10n),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_calendar_outlined, size: 18, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Notes ────────────────────────────────────────────────────────
          Row(
            children: [
              _buildSectionLabel(
                context,
                cs,
                icon: Icons.notes,
                containerColor: cs.secondaryContainer,
                iconColor: cs.onSecondaryContainer,
                label: l10n.onboardingTankNotes,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.onboardingOptional,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tankNotesController,
            decoration: InputDecoration(
              hintText: l10n.onboardingTankNotesHint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _markInteracted(1),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Returns a human-readable approximate age string for a tank created on [date].
  String _tankAgeString(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final days = now.difference(date).inDays;
    if (days == 0) return l10n.onboardingTankAgeToday;
    if (days < 7) {
      return l10n.onboardingTankAgeDays(days);
    }
    // Accurate month/year deltas via calendar arithmetic.
    int years = now.year - date.year;
    int months = now.month - date.month;
    if (now.day < date.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    final totalMonths = years * 12 + months;
    if (totalMonths < 1) {
      final weeks = (days / 7).floor();
      return l10n.onboardingTankAgeWeeks(weeks);
    } else if (totalMonths < 12) {
      return l10n.onboardingTankAgeMonths(totalMonths);
    } else {
      return l10n.onboardingTankAgeYears(years);
    }
  }

  Widget _buildInhabitantsPage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    final hasTankName = _tankNameController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline header: icon + title + subtitle
          _buildPageHeader(
            context,
            cs,
            heroContent: const Text('🐡', style: TextStyle(fontSize: 30)),
            heroDecoration: BoxDecoration(
              color: cs.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            title: l10n.onboardingInhabitantsTitle,
            subtitle: l10n.onboardingInhabitantsSubtitle,
          ),

          // Warn if no tank name so inhabitants cannot be saved
          if (!hasTankName) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: cs.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.onboardingInhabitantsTankRequired,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: cs.onErrorContainer,
                            height: 1.3,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Add inhabitant button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (hasTankName && _availableFish.isNotEmpty)
                  ? _addInhabitant
                  : null,
              icon: const Icon(Icons.add),
              label: Text(l10n.addInhabitant),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Inhabitant list (or empty-state)
          if (_inhabitants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pets,
                      size: 48,
                      color: cs.onSurfaceVariant.withOpacity(0.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.onboardingNoInhabitantsYet,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._inhabitants.asMap().entries.map((entry) {
              final index = entry.key;
              final inhabitant = entry.value;
              // Look up the Fish object to get its image.
              final fish = _availableFish.where(
                (f) => f.name == inhabitant.fishUnit,
              ).firstOrNull;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: SizedBox(
                    width: 44,
                    height: 44,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: fish != null
                          ? FishImage(fish: fish, fit: BoxFit.cover)
                          : Container(
                              color: cs.primaryContainer,
                              child: Center(
                                child: Text(
                                  inhabitant.fishUnit.isNotEmpty
                                      ? inhabitant.fishUnit[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  title: Text(inhabitant.customName),
                  subtitle: Text(
                    '${inhabitant.fishUnit} × ${inhabitant.quantity}',
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: cs.error,
                    ),
                    tooltip: l10n.delete,
                    onPressed: () => _removeInhabitant(index),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }


  // ── Step 4: Discover AI Tools ─────────────────────────────────────────────

  Widget _buildDiscoverToolsPage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline header: icon + title + subtitle
          _buildPageHeader(
            context,
            cs,
            heroContent: const Text('🛠️', style: TextStyle(fontSize: 30)),
            heroDecoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            title: l10n.onboardingDiscoverTitle,
            subtitle: l10n.onboardingDiscoverSubtitle,
          ),
          const SizedBox(height: 16),

          // ── AI Tools section ────────────────────────────────────────────
          _buildSectionChip(context, cs, Icons.auto_awesome, l10n.onboardingDiscoverSectionAI),
          const SizedBox(height: 10),
          _buildToolCard(
            context,
            cs,
            icon: '🐡',
            title: l10n.aiCompatibilityTool,
            description: l10n.aiCompatibilityDrawerDescription,
          ),
          const SizedBox(height: 8),
          _buildToolCard(
            context,
            cs,
            icon: '🤖',
            title: l10n.aiChatbot,
            description: l10n.aiChatbotDrawerDescription,
          ),
          const SizedBox(height: 8),
          _buildToolCard(
            context,
            cs,
            icon: '📷',
            title: l10n.photoAnalyzer,
            description: l10n.photoAnalyzerDrawerDescription,
          ),
          const SizedBox(height: 8),
          _buildToolCard(
            context,
            cs,
            icon: '🦐',
            title: l10n.aiStockingAssistant,
            description: l10n.aiStockingDrawerDescription,
          ),
          const SizedBox(height: 16),

          // ── Tank Tools section ──────────────────────────────────────────
          _buildSectionChip(context, cs, Icons.water, l10n.onboardingDiscoverSectionTank),
          const SizedBox(height: 10),
          _buildToolCard(
            context,
            cs,
            icon: '🐠',
            title: l10n.myTanks,
            description: l10n.onboardingDiscoverTankDesc,
          ),
          const SizedBox(height: 8),
          _buildToolCard(
            context,
            cs,
            icon: '🌊',
            title: l10n.communityTitle,
            description: l10n.communityDrawerDescription,
          ),
          const SizedBox(height: 16),

          // ── Calculators section ─────────────────────────────────────────
          _buildSectionChip(context, cs, Icons.calculate, l10n.onboardingDiscoverSectionCalc),
          const SizedBox(height: 10),
          _buildToolCard(
            context,
            cs,
            icon: '🧪',
            title: l10n.aquariumCalculators,
            description: l10n.aquariumCalculatorsDrawerDescription,
          ),
          const SizedBox(height: 8),
          _buildToolCard(
            context,
            cs,
            icon: '📐',
            title: l10n.tankVolumeCalculator,
            description: l10n.tankVolumeDrawerDescription,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionChip(
    BuildContext context,
    ColorScheme cs,
    IconData icon,
    String label,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: cs.onSecondaryContainer),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    ColorScheme cs, {
    required String icon,
    required String title,
    required String description,
  }) {
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  /// Inline section label with a leading icon badge.
  Widget _buildSectionLabel(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required Color containerColor,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ── Step 5: API Key & Founder Upsell ─────────────────────────────────────

  Widget _buildApiKeyPage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    final isFounder = ref.watch(isFounderProvider);
    final purchaseState = ref.watch(purchaseProvider);
    final maxPerMin = isFounder
        ? RemoteConfigService.founderMaxRequestsPerMinute
        : RemoteConfigService.maxRequestsPerMinute;
    final maxPerDay = isFounder
        ? RemoteConfigService.founderMaxRequestsPerDay
        : RemoteConfigService.maxRequestsPerDay;
    final maxPhotos = isFounder
        ? RemoteConfigService.founderMaxPhotoAnalysesPerDay
        : RemoteConfigService.maxPhotoAnalysesPerDay;
    final founderColor = AquaThemeColors.founderColor(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline header: icon + title + subtitle
          _buildPageHeader(
            context,
            cs,
            heroContent: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
            heroDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            title: l10n.onboardingApiTitle,
            subtitle: l10n.onboardingApiSubtitle,
          ),
          const SizedBox(height: 16),

          // ── Founder Aquarist upsell (shown first; only when not already a founder) ──
          if (!isFounder && !kIsWeb) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    founderColor.withOpacity(0.1),
                    cs.primaryContainer.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: founderColor.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.diamond, size: 18, color: founderColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.founderAquaristTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: founderColor,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingApiFounderDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildApiLimitRow(
                    context, cs,
                    icon: Icons.block,
                    label: l10n.founderPerkAdsRemoved,
                    color: founderColor,
                  ),
                  const SizedBox(height: 4),
                  _buildApiLimitRow(
                    context, cs,
                    icon: Icons.auto_awesome,
                    label: l10n.founderPerkIncreasedAILimits,
                    color: founderColor,
                  ),
                  const SizedBox(height: 4),
                  _buildApiLimitRow(
                    context, cs,
                    icon: Icons.border_outer,
                    label: l10n.founderPerkPostBorder,
                    color: founderColor,
                  ),
                  const SizedBox(height: 4),
                  _buildApiLimitRow(
                    context, cs,
                    icon: Icons.diamond,
                    label: l10n.founderPerkBadge,
                    color: founderColor,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: purchaseState.isPurchasing
                          ? null
                          : () => showRemoveAdsDialog(context),
                      icon: const Icon(Icons.diamond, size: 18),
                      label: Text(l10n.onboardingFounderCtaButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: founderColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Free Tier card ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isFounder
                  ? founderColor.withOpacity(0.06)
                  : Colors.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFounder
                    ? founderColor.withOpacity(0.35)
                    : Colors.amber.withOpacity(0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isFounder ? Icons.diamond : Icons.bolt,
                      size: 18,
                      color: isFounder ? founderColor : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isFounder
                            ? l10n.founderAquaristTitle
                            : l10n.onboardingApiFreeTierTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isFounder
                                  ? founderColor
                                  : Colors.amber.shade800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildApiLimitRow(
                  context,
                  cs,
                  icon: Icons.timer_outlined,
                  label: '$maxPerMin req / min',
                  color: isFounder ? founderColor : Colors.amber.shade800,
                ),
                const SizedBox(height: 5),
                _buildApiLimitRow(
                  context,
                  cs,
                  icon: Icons.today_outlined,
                  label: '$maxPerDay req / day',
                  color: isFounder ? founderColor : Colors.amber.shade800,
                ),
                const SizedBox(height: 5),
                _buildApiLimitRow(
                  context,
                  cs,
                  icon: Icons.photo_camera_outlined,
                  label: '$maxPhotos photo ${maxPhotos == 1 ? 'analysis' : 'analyses'} / day',
                  color: isFounder ? founderColor : Colors.amber.shade800,
                ),
                if (isFounder) ...[
                  const SizedBox(height: 5),
                  _buildApiLimitRow(
                    context,
                    cs,
                    icon: Icons.block,
                    label: l10n.founderPerkAdsRemoved,
                    color: founderColor,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Own API Key card ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.key, size: 18, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.onboardingApiOwnKeyTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.onboardingApiOwnKeyDesc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    // Navigate to Settings and immediately open AI Provider dialog.
                    onPressed: () => Navigator.of(context).pushNamed(
                      '/settings',
                      arguments: {'openAIProvider': true},
                    ),
                    icon: const Icon(Icons.key, size: 18),
                    label: Text(l10n.onboardingApiGoToSettings),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Disclaimer note ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.onboardingApiKeyNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// A small icon + label row used in the API key step's info cards.
  Widget _buildApiLimitRow(
    BuildContext context,
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color, height: 1.3),
          ),
        ),
      ],
    );
  }
}
