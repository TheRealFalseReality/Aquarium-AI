import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/fish.dart';
import '../models/tank.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../services/fish_data_service.dart';
import '../theme_colors.dart';
import '../theme_provider.dart';
import '../widgets/modern_chip.dart';
import 'tank_creation_screen.dart' show InhabitantDialog;
import 'tank_volume_calculator.dart';

import '../widgets/fish_image.dart';

/// A five-step, skippable onboarding flow shown once on first launch.
///
/// Steps:
///   1. Choose Your Style  – theme and brightness mode selection
///   2. Welcome / Sign In  – upsells the community and account features
///   3. Create Your Tank   – simplified tank setup (name, type, size)
///   4. Add Inhabitants    – optionally populate the tank with fish
///   5. Discover AI Tools  – overview of the key AI features
///
/// Pass [initialPage] to start on a specific step (e.g. when resuming after
/// sign-in via [AuthScreen]).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.initialPage = 0});

  /// The step index to show first (0-based). Used when resuming after sign-in.
  final int initialPage;

  static const String _onboardingCompletedKey = 'onboarding_completed';

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

  /// Clears the completed flag – useful for revisiting onboarding from Settings.
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

  // ── Step 3 state: tank creation ─────────────────────────────────────────
  final _tankNameController = TextEditingController();
  final _sizeGallonsController = TextEditingController();
  final _sizeLitersController = TextEditingController();
  String _selectedTankType = 'freshwater';
  bool _isReef = false;

  // ── Step 4 state: inhabitants ────────────────────────────────────────────
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
      // If leaving the tank-creation step (2) with no tank name, skip the
      // inhabitants step (3) since there is nothing to add inhabitants to.
      final skipInhabitants = _currentPage == 2 &&
          _tankNameController.text.trim().isEmpty;
      final targetPage = skipInhabitants ? 4 : _currentPage + 1;
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
          _markInteracted(3);
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
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildThemePage(context, l10n, cs),
                  _buildWelcomePage(context, l10n, cs),
                  _buildCreateTankPage(context, l10n, cs),
                  _buildInhabitantsPage(context, l10n, cs),
                  _buildDiscoverToolsPage(context, l10n, cs),
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
    // On other pages: if the user has interacted on this step, show "Next";
    // if not, show "Skip for now" to make it clear the step is optional.
    final primaryLabel = isLastPage
        ? l10n.onboardingGetStarted
        : (_currentPageInteracted ? l10n.onboardingNext : l10n.onboardingSkipForNow);

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
          // Hero circle
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
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
              child: const Center(
                child: Text('🎨', style: TextStyle(fontSize: 38)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboardingThemeTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.onboardingThemeSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

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

  // ── Step 2: Welcome / Sign In ─────────────────────────────────────────────

  Widget _buildWelcomePage(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero circle
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer,
                    cs.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌊', style: TextStyle(fontSize: 52)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingWelcomeTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          // Sign-in upsell card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withOpacity(0.55),
                  cs.secondaryContainer.withOpacity(0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.onboardingSignInTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBenefit(context, cs, '🌐', l10n.onboardingSignInBenefit2),
                const SizedBox(height: 10),
                _buildBenefit(context, cs, '💡', l10n.onboardingSignInBenefit3),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _markInteracted(1);
                      // Navigate to auth; on success the user goes to their
                      // profile where a banner prompts them to continue onboarding.
                      Navigator.pushNamed(
                        context,
                        '/auth',
                        arguments: {
                          'returnRoute': '/profile',
                          'returnRouteArgs': {
                            'fromOnboarding': true,
                            'onboardingNextPage': 2,
                          },
                        },
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: Text(l10n.authSignIn),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // "Continue without account" secondary link
          Center(
            child: TextButton(
              onPressed: () {
                _markInteracted(1);
                _nextPage();
              },
              child: Text(
                l10n.authContinueAnonymously,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBenefit(
    BuildContext context,
    ColorScheme cs,
    String emoji,
    String text,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurface, height: 1.4),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Create Tank ───────────────────────────────────────────────────

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
          // Hero circle
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🐠', style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboardingCreateTankTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.onboardingCreateTankSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

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
            onChanged: (_) => _markInteracted(2),
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
                  _markInteracted(2);
                },
              ),
              ModernSelectableChip(
                label: l10n.saltwater,
                emoji: '🪼',
                selected: _selectedTankType == 'marine',
                onTap: () {
                  _onTankTypeChanged('marine');
                  _markInteracted(2);
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
                            _markInteracted(2);
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
        ],
      ),
    );
  }

  // ── Step 4: Add Inhabitants ───────────────────────────────────────────────

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
          // Hero circle
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🐡', style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboardingInhabitantsTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.onboardingInhabitantsSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
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
              onPressed: _availableFish.isEmpty ? null : _addInhabitant,
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


  // ── Step 5: Discover AI Tools ─────────────────────────────────────────────

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
          // Hero circle
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboardingDiscoverTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.onboardingDiscoverSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // AI tool cards
          _buildToolCard(
            context,
            cs,
            icon: '🐡',
            title: l10n.aiCompatibilityTool,
            description: l10n.aiCompatibilityDrawerDescription,
            routeName: '/compat-ai',
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            context,
            cs,
            icon: '🤖',
            title: l10n.aiChatbot,
            description: l10n.aiChatbotDrawerDescription,
            routeName: '/chatbot',
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            context,
            cs,
            icon: '📷',
            title: l10n.photoAnalyzer,
            description: l10n.photoAnalyzerDrawerDescription,
            routeName: '/chatbot',
            routeArgs: const {'openPhotoAnalyzer': true},
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            context,
            cs,
            icon: '🦐',
            title: l10n.aiStockingAssistant,
            description: l10n.aiStockingDrawerDescription,
            routeName: '/stocking',
          ),
          const SizedBox(height: 10),
          _buildToolCard(
            context,
            cs,
            icon: '🌊',
            title: l10n.communityTitle,
            description: l10n.communityDrawerDescription,
            routeName: '/community',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    ColorScheme cs, {
    required String icon,
    required String title,
    required String description,
    required String routeName,
    Map<String, dynamic>? routeArgs,
  }) {
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            Navigator.pushNamed(context, routeName, arguments: routeArgs),
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
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
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
}
