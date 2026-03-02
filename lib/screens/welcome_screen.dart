// ignore_for_file: unused_element

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';

import '../main_layout.dart';
import '../widgets/gradient_text.dart';
import '../widgets/ad_component.dart';
import 'changelog_screen.dart';
import '../providers/model_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/community_provider.dart';
import '../widgets/remove_ads_dialog.dart';
import '../providers/tank_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/fish_compatibility_provider.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/app_promotion_dialog.dart';
import '../widgets/aquapi_promotion_dialog.dart';
import '../theme_provider.dart';
import '../services/analytics_service.dart';
import '../services/in_app_review_service.dart';
import '../services/in_app_update_service.dart';
import '../utils/tank_harmony_calculator.dart';
import '../models/tank.dart';
import '../models/community_post.dart';

class ToolChipInfo {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ToolChipInfo({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class FeatureInfo {
  final String icon;
  final String title;
  final String description;
  final String? shortDescription;
  final String routeName;
  final Duration delay;
  final bool openPhotoAnalyzer;
  final String? url;
  final String? imagePath;
  final List<ToolChipInfo>? toolChips;
  final bool fullWidth;

  FeatureInfo({
    required this.icon,
    required this.title,
    required this.description,
    this.shortDescription,
    required this.routeName,
    required this.delay,
    this.openPhotoAnalyzer = false,
    this.url,
    this.imagePath,
    this.toolChips,
    this.fullWidth = false,
  });

  /// Unique identifier for this feature card. Uses routeName for most cards,
  /// or 'aquapi_store' for the full-width AquaPi Store card (which has an empty routeName).
  String get id => fullWidth ? 'aquapi_store' : routeName;
}

// Converted to ConsumerStatefulWidget to use initState
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();

  // Static method to reset promotion dialog preference for testing and debugging
  static Future<void> resetPromotionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_WelcomeScreenState._promotionDialogTimestampKey);
      debugPrint('Promotion dialog timestamp reset');
    } catch (e) {
      debugPrint('Error resetting promotion dialog preference: $e');
    }
  }

  // Static method to manually set timestamp for testing (useful for debugging)
  static Future<void> setPromotionDialogTimestamp(int timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_WelcomeScreenState._promotionDialogTimestampKey, timestamp);
      debugPrint('Promotion dialog timestamp set to: $timestamp');
    } catch (e) {
      debugPrint('Error setting promotion dialog timestamp: $e');
    }
  }

  // Static method to check current timestamp for debugging
  static Future<void> checkPromotionDialogStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShownTimestamp = prefs.getInt(_WelcomeScreenState._promotionDialogTimestampKey) ?? 0;
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastShown = (currentTimestamp - lastShownTimestamp) / (1000 * 60 * 60);
      
      debugPrint('Promotion dialog status:');
      debugPrint('  Last shown timestamp: $lastShownTimestamp');
      debugPrint('  Current timestamp: $currentTimestamp');
      debugPrint('  Hours since last shown: ${hoursSinceLastShown.toStringAsFixed(1)}');
      debugPrint('  Will show dialog: ${hoursSinceLastShown >= _WelcomeScreenState._promotionDialogCooldownHours}');
    } catch (e) {
      debugPrint('Error checking promotion dialog status: $e');
    }
  }
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const String _promotionDialogTimestampKey = 'promotion_dialog_timestamp';
  static const int _promotionDialogCooldownHours = 48;
  static const String _aquapiPromotionDialogTimestampKey = 'aquapi_promotion_dialog_timestamp';
  static const int _aquapiPromotionDialogCooldownHours = 72; // Show again after 72 hours have elapsed
  static const String _changelogShownVersionKey = 'changelog_shown_version';
  static const String _changelogBannerShownAtKey = 'changelog_banner_shown_at';
  static const int _changelogBannerAutoDismissDays = 3;
  static const String _hiddenFeaturesKey = 'hiddenWelcomeFeatures';
  static const String _showCommunityCardKey = 'welcomeShowCommunityCard';

  bool _showChangelogBanner = false;
  String _changelogBannerVersion = '';

  // Version info for footer
  String _version = '';
  bool _checkingUpdate = false;

  // Store the random tank index to persist across rebuilds (e.g., theme changes)
  int? _selectedTankIndex;

  // Hidden feature card IDs
  Set<String> _hiddenFeatures = {};

  // Community card state
  bool _showCommunityCard = false;
  PostType? _communityCardFilterType; // null = show all post types
  
  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadHiddenFeatures();
    // Record the first launch timestamp (no-op after the very first call)
    InAppReviewService.recordFirstLaunch();
    // Request an in-app review if conditions are met (≥3 days since first launch)
    InAppReviewService.maybeRequestReview();
    // Check if we should show the app promotion dialog on web
    if (kIsWeb) {
      _checkShowPromotionDialog();
    }
    // Check if we should show the AquaPi promotion dialog
    _checkShowAquaPiPromotionDialog();
    // Check if we should show the changelog dialog (once per version)
    _checkShowChangelogDialog();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset selected tank index when navigating back to this screen
    // This will be null on first build, causing a new random selection
  }

  Future<void> _loadHiddenFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_hiddenFeaturesKey) ?? '';
      if (stored.isNotEmpty) {
        setState(() {
          _hiddenFeatures = stored.split(',').where((s) => s.isNotEmpty).toSet();
        });
      }
      final showCard = prefs.getBool(_showCommunityCardKey) ?? false;
      if (mounted) {
        setState(() => _showCommunityCard = showCard);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveCommunityCardVisible(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showCommunityCardKey, value);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveHiddenFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_hiddenFeaturesKey, _hiddenFeatures.join(','));
    } catch (e) {
      // ignore
    }
  }

  void _showCardFilterSheet(BuildContext context, List<FeatureInfo> allFeatures, bool adsRemoved) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.visibleCards, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Community card toggle (always first)
                  CheckboxListTile(
                    value: _showCommunityCard,
                    title: Text(l10n.communityCardLabel),
                    onChanged: (val) {
                      setState(() => _showCommunityCard = val ?? false);
                      setSheetState(() {});
                      _saveCommunityCardVisible(val ?? false);
                    },
                  ),
                  const Divider(),
                  ...allFeatures.map((f) {
                    final isAquaPiStore = f.fullWidth;
                    final isDisabled = isAquaPiStore && !adsRemoved;
                    final isHidden = _hiddenFeatures.contains(f.id);
                    return CheckboxListTile(
                      value: !isHidden,
                      title: Text(f.title),
                      enabled: !isDisabled,
                      subtitle: isDisabled ? Text(l10n.purchaseToHideCard) : null,
                      onChanged: isDisabled ? null : (val) {
                        setState(() {
                          if (val == true) {
                            _hiddenFeatures = {..._hiddenFeatures}..remove(f.id);
                          } else {
                            _hiddenFeatures = {..._hiddenFeatures, f.id};
                          }
                        });
                        setSheetState(() {});
                        _saveHiddenFeatures();
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkShowPromotionDialog() async {
    try {
      // Check if user has chosen to never show the dialog again
      final shouldShow = await AppPromotionDialog.shouldShowDialog();
      if (!shouldShow) {
        debugPrint('Promotion dialog will not be shown (user selected never show again)');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastShownTimestamp = prefs.getInt(_promotionDialogTimestampKey) ?? 0;
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastShown = (currentTimestamp - lastShownTimestamp) / (1000 * 60 * 60);
      
      debugPrint('Promotion dialog check: Last shown timestamp: $lastShownTimestamp, Hours since: ${hoursSinceLastShown.toStringAsFixed(1)}, Cooldown: $_promotionDialogCooldownHours hours');
      
      // Show the dialog if it has never been shown or if 48 hours have passed
      if (hoursSinceLastShown >= _promotionDialogCooldownHours && mounted) {
        debugPrint('Promotion dialog will be shown (cooldown period elapsed)');
        // Show the popup after a short delay to allow the screen to load
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            _showPromotionDialog();
          }
        });
      } else {
        debugPrint('Promotion dialog will not be shown (cooldown period not elapsed)');
      }
    } catch (e) {
      // If there's an error with SharedPreferences, silently continue
      debugPrint('Error checking promotion dialog preference: $e');
    }
  }

  Future<void> _showPromotionDialog() async {
    try {
      final ctx = context;
      final prefs = await SharedPreferences.getInstance();
      // Store the current timestamp when showing the dialog
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_promotionDialogTimestampKey, currentTimestamp);
      debugPrint('Promotion dialog shown, timestamp saved: $currentTimestamp');
      
      // Log app promotion dialog shown
      AnalyticsService.logAppPromotion(
        action: 'dialog_shown',
        source: 'welcome_screen_auto',
      );
      
      if (!ctx.mounted) return;
      showDialog(
        context: ctx,
        barrierDismissible: true,
        builder: (context) => const AppPromotionDialog(),
      );
    } catch (e) {
      debugPrint('Error showing promotion dialog: $e');
    }
  }

  Future<void> _checkShowAquaPiPromotionDialog() async {
    try {
      // Check if user has chosen to never show the dialog again
      final shouldShow = await AquaPiPromotionDialog.shouldShowDialog();
      if (!shouldShow) {
        debugPrint('AquaPi promotion dialog will not be shown (user selected never show again)');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastShownTimestamp = prefs.getInt(_aquapiPromotionDialogTimestampKey) ?? 0;
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastShown = (currentTimestamp - lastShownTimestamp) / (1000 * 60 * 60);
      
      debugPrint('AquaPi promotion dialog check: Last shown timestamp: $lastShownTimestamp, Hours since: ${hoursSinceLastShown.toStringAsFixed(1)}, Cooldown: $_aquapiPromotionDialogCooldownHours hours');
      
      // Show the dialog if it has never been shown or if cooldown period has passed
      if (hoursSinceLastShown >= _aquapiPromotionDialogCooldownHours && mounted) {
        debugPrint('AquaPi promotion dialog will be shown (cooldown period elapsed)');
        // Show the popup after a delay to allow the screen to load
        // Use a longer delay to avoid showing both popups at once
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            _showAquaPiPromotionDialog();
          }
        });
      } else {
        debugPrint('AquaPi promotion dialog will not be shown (cooldown period not elapsed)');
      }
    } catch (e) {
      // If there's an error with SharedPreferences, silently continue
      debugPrint('Error checking AquaPi promotion dialog preference: $e');
    }
  }

  Future<void> _showAquaPiPromotionDialog() async {
    try {
      final ctx = context;
      final prefs = await SharedPreferences.getInstance();
      // Store the current timestamp when showing the dialog
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_aquapiPromotionDialogTimestampKey, currentTimestamp);
      debugPrint('AquaPi promotion dialog shown, timestamp saved: $currentTimestamp');
      
      // Log AquaPi promotion dialog shown
      AnalyticsService.logAppPromotion(
        action: 'aquapi_dialog_shown',
        source: 'welcome_screen_auto',
      );
      
      if (!ctx.mounted) return;
      showDialog(
        context: ctx,
        barrierDismissible: true,
        builder: (context) => const AquaPiPromotionDialog(),
      );
    } catch (e) {
      debugPrint('Error showing AquaPi promotion dialog: $e');
    }
  }

  // Debug method to reset promotion dialog preference
  // This can be called from settings or debug menu if needed
  // Note: This is now also available as WelcomeScreen.resetPromotionDialog()
  static Future<void> resetPromotionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_promotionDialogTimestampKey);
    } catch (e) {
      debugPrint('Error resetting promotion dialog preference: $e');
    }
  }

  Future<void> _checkShowChangelogDialog() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      final prefs = await SharedPreferences.getInstance();
      final lastShownVersion = prefs.getString(_changelogShownVersionKey);
      debugPrint('Changelog banner check: current=$currentVersion, lastShown=$lastShownVersion');

      if (lastShownVersion == currentVersion) {
        // Same version – show banner only if still within the 3-day auto-dismiss window
        final shownAt = prefs.getInt(_changelogBannerShownAtKey);
        if (shownAt == null) return; // Already dismissed by user
        final daysSinceShown =
            (DateTime.now().millisecondsSinceEpoch - shownAt) /
                (1000 * 60 * 60 * 24);
        if (daysSinceShown >= _changelogBannerAutoDismissDays) {
          // Auto-dismiss: clean up the timestamp and don't show
          await prefs.remove(_changelogBannerShownAtKey);
          return;
        }
        if (mounted) {
          setState(() {
            _showChangelogBanner = true;
            _changelogBannerVersion = currentVersion;
          });
        }
        return;
      }

      // New version detected – save version + timestamp and show the banner
      await prefs.setString(_changelogShownVersionKey, currentVersion);
      await prefs.setInt(
          _changelogBannerShownAtKey, DateTime.now().millisecondsSinceEpoch);
      if (mounted) {
        setState(() {
          _showChangelogBanner = true;
          _changelogBannerVersion = currentVersion;
        });
      }
    } catch (e) {
      debugPrint('Error checking changelog banner: $e');
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = info.version);
      }
    } catch (e) {
      debugPrint('Failed to load app version: $e');
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final info = await InAppUpdateService.checkForUpdate();
      if (!mounted) return;
      if (info == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Unable to check for updates.')),
        );
        return;
      }
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdateService.startFlexibleUpdate();
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text("You're already on the latest version!")),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _dismissChangelogBanner() async {
    setState(() => _showChangelogBanner = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_changelogBannerShownAtKey);
    } catch (e) {
      debugPrint('Error dismissing changelog banner: $e');
    }
  }

  Widget _buildChangelogBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return _ChangelogBannerSlide(
      child: Material(
        color: cs.primaryContainer,
        child: Row(
          children: [
            // Tappable area – opens ChangelogScreen
            Expanded(
              child: InkWell(
                key: const Key('changelog_banner_tap_area'),
                onTap: () async {
                  final ctx = context;
                  await _dismissChangelogBanner();
                  if (!ctx.mounted) return;
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (c) => const ChangelogScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.new_releases, color: cs.primary, size: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '${l10n.changelog} · v$_changelogBannerVersion',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: cs.onPrimaryContainer.withOpacity(0.7), size: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Dismiss button – only closes the banner
            IconButton(
              key: const Key('changelog_banner_dismiss'),
              icon: Icon(Icons.close,
                  color: cs.onPrimaryContainer.withOpacity(0.7), size: 22),
              onPressed: _dismissChangelogBanner,
              tooltip: l10n.close,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Listen to the provider for changes.
    ref.listen<ModelState>(modelProvider, (previous, next) async {
      // Show the API key dialog once loading completes if:
      //   • the user has no own key for any provider, OR
      //     the user is relying on the in-app developer Groq key (free tier)
      //     for any provider, AND
      //   • AI features are enabled, AND
      //   • the 1-week cooldown has elapsed (or the user hasn't seen it before)
      final noOwnKey = next.geminiApiKey.isEmpty &&
          next.openAIApiKey.isEmpty &&
          next.groqApiKey.isEmpty;
      final usingDeveloperGroqKeyForAny = next.usingDeveloperGroqKeyForAny;
      if (previous!.isLoading && !next.isLoading &&
          (noOwnKey || usingDeveloperGroqKeyForAny) &&
          ref.read(appSettingsProvider).enableAI) {
        final ctx = context;
        final shouldShow = await ApiKeyDialog.shouldShowDialog();
        if (!shouldShow) return;
        if (!ctx.mounted) return;
        showDialog(
          context: ctx,
          builder: (context) => const ApiKeyDialog(),
        );
        // Record after showDialog so the cooldown only starts when the dialog
        // is actually presented to the user.
        ApiKeyDialog.recordDialogShown();
      }
    });

    final modelState = ref.watch(modelProvider);
    final isLoading = ref.watch(modelProviderLoading);
    
    // Watch tank state for My Tanks section
    final tankState = ref.watch(tankProvider);
    final tankCount = tankState.tanks.length;
    
    // Get fish data for harmony calculation
    final fishCompatibilityState = ref.watch(fishCompatibilityProvider);
    final fishData = fishCompatibilityState.fishData.value;
    
    // Watch app settings for AI toggle
    final appSettings = ref.watch(appSettingsProvider);

    final List<FeatureInfo> features = [
      if (appSettings.enableAI) ...[
        FeatureInfo(
          icon: '🐡',
          title: l10n.aiCompatibilityTool,
          description: l10n.aiCompatibilityDescription,
          shortDescription: l10n.aiCompatibilityDrawerDescription,
          routeName: '/compat-ai',
          delay: const Duration(milliseconds: 650),
        ),
        FeatureInfo(
          icon: '🤖',
          title: l10n.aiChatbot,
          description: l10n.aiChatbotDescription,
          shortDescription: l10n.aiChatbotDrawerDescription,
          routeName: '/chatbot',
          delay: const Duration(milliseconds: 700),
          toolChips: [
            ToolChipInfo(
              label: l10n.waterAnalysis,
              icon: Icons.water_drop_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                '/chatbot',
                arguments: {'openWaterAnalysis': true},
              ),
            ),
            ToolChipInfo(
              label: l10n.fishInfo,
              icon: Icons.manage_search_outlined,
              onTap: () => Navigator.pushNamed(
                context,
                '/chatbot',
                arguments: {'openFishInfo': true},
              ),
            ),
          ],
        ),
        FeatureInfo(
          icon: '📷',
          title: l10n.photoAnalyzer,
          description: l10n.photoAnalyzerDescription,
          shortDescription: l10n.photoAnalyzerDrawerDescription,
          routeName: '/chatbot',
          openPhotoAnalyzer: true,
          delay: const Duration(milliseconds: 750),
        ),
        FeatureInfo(
          icon: '🦐',
          title: l10n.aiStockingAssistant,
          description: l10n.aiStockingDescription,
          shortDescription: l10n.aiStockingDrawerDescription,
          routeName: '/stocking',
          delay: const Duration(milliseconds: 800),
        ),
      ],
      FeatureInfo(
        icon: '🧪',
        title: l10n.aquariumCalculators,
        description: l10n.aquariumCalculatorsDescription,
        shortDescription: l10n.aquariumCalculatorsDrawerDescription,
        routeName: '/calculators',
        delay: const Duration(milliseconds: 850),
      ),
      FeatureInfo(
        icon: '📏',
        title: l10n.tankVolumeCalculator,
        description: l10n.tankVolumeDescription,
        shortDescription: l10n.tankVolumeDrawerDescription,
        routeName: '/tank-volume',
        delay: const Duration(milliseconds: 900),
      ),
      FeatureInfo(
        icon: '🌊',
        title: l10n.communityTitle,
        description: l10n.communityDrawerDescription,
        routeName: '/community',
        delay: const Duration(milliseconds: 925),
      ),
      FeatureInfo(
        icon: '🛒',
        title: l10n.aquaPiStore,
        description: l10n.aquaPiStoreDescription,
        routeName: '',
        url: 'https://www.capitalcityaquatics.com/store/aquapi',
        delay: const Duration(milliseconds: 950),
        imagePath: 'assets/AquaPiEssentials.jpg',
        fullWidth: true,
      ),
    ];

    return MainLayout(
      title: l10n.welcomeTitle,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: _showChangelogBanner
                ? _buildChangelogBanner(context)
                : const SizedBox.shrink(),
          ),
          const AdBanner(),
        ],
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      const AnimatedHeader(),
                      const SizedBox(height: 16),
                      AnimatedText(
                        l10n.welcomeSubtitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        delay: const Duration(milliseconds: 520),
                      ),
                      const SizedBox(height: 32),
                      
                      // Prominent My Tanks Section
                      _buildMyTanksSection(context, tankState, tankCount, fishData),
                      
                      // Remove Ads hint below My Tanks
                      _buildRemoveAdsHint(context),
                      
                      // Community Card (shown above feature cards when enabled)
                      if (_showCommunityCard) ...[
                        const SizedBox(height: 16),
                        _buildCommunityCard(context),
                        _buildCommunityCardAd(),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Feature Cards section header with layout toggle
                      Builder(builder: (context) {
                        final useGrid = appSettings.welcomeGridLayout;
                        final adsRemoved = ref.watch(purchaseProvider).adsRemoved;

                        // Apply hidden features filter
                        final visibleFeatures = features.where((f) => !_hiddenFeatures.contains(f.id)).toList();

                        // Separate full-width cards (e.g. AquaPi Store) from grid cards
                        final gridFeatures = visibleFeatures.where((f) => !f.fullWidth).toList();
                        final fullWidthFeatures = visibleFeatures.where((f) => f.fullWidth).toList();

                        // Split point for the native ad (between AI tools and calculators)
                        final splitIndex = gridFeatures.indexWhere(
                          (f) => f.routeName == '/calculators',
                        );
                        final topFeatures = splitIndex > 0
                            ? gridFeatures.sublist(0, splitIndex)
                            : (splitIndex < 0 ? gridFeatures : <FeatureInfo>[]);
                        final bottomFeatures = splitIndex >= 0 ? gridFeatures.sublist(splitIndex) : <FeatureInfo>[];

                        return Column(
                          children: [
                            // Layout toggle row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.tune, size: 20),
                                  tooltip: l10n.filterCards,
                                  onPressed: () => _showCardFilterSheet(context, features, adsRemoved),
                                ),
                                IconButton(
                                  icon: Icon(
                                    useGrid ? Icons.view_list : Icons.grid_view,
                                    size: 20,
                                  ),
                                  tooltip: useGrid ? l10n.switchToListView : l10n.switchToGridView,
                                  onPressed: () {
                                    ref.read(appSettingsProvider.notifier).setWelcomeGridLayout(!useGrid);
                                  },
                                ),
                              ],
                            ),
                            if (adsRemoved) ...[
                              // No ad break — render all grid features as one continuous mosaic
                              if (gridFeatures.isNotEmpty)
                                _buildFeatureGrid(context, gridFeatures, useGrid: useGrid),
                            ] else ...[
                              // Show ad between top and bottom feature groups
                              if (topFeatures.isNotEmpty) ...[
                                _buildFeatureGrid(context, topFeatures, useGrid: useGrid),
                              ],
                              _buildWelcomeNativeAd(),
                              if (bottomFeatures.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildFeatureGrid(context, bottomFeatures, useGrid: useGrid),
                              ],
                            ],
                            // Full-width cards (e.g. AquaPi Store) always rendered single-column
                            if (fullWidthFeatures.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildFeatureGrid(context, fullWidthFeatures, useGrid: useGrid, forceSingleColumn: true),
                            ],
                          ],
                        );
                      }),
                      
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Column(
                          children: [
                            Text(
                              'Currently using the following models:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_getTextModelName(modelState)} (text)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${_getImageModelName(modelState)} (image)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 16),
                            if (_version.isNotEmpty)
                              Text(
                                'Version $_version',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (!kIsWeb && Platform.isAndroid) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: _checkingUpdate
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.system_update_outlined, size: 18),
                                label: const Text('Check for Update'),
                                onPressed: _checkingUpdate ? null : _checkForUpdate,
                              ),
                            ],
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  String _getTextModelName(ModelState modelState) {
    switch (modelState.activeTextProvider) {
      case AIProvider.gemini:
        return modelState.geminiModel;
      case AIProvider.openAI:
        return modelState.chatGPTModel;
      case AIProvider.groq:
        return modelState.groqModel;
    }
  }

  String _getImageModelName(ModelState modelState) {
    switch (modelState.activeImageProvider) {
      case AIProvider.gemini:
        return modelState.geminiImageModel;
      case AIProvider.openAI:
        return modelState.chatGPTImageModel;
      case AIProvider.groq:
        return modelState.groqImageModel;
    }
  }

  Widget _buildMyTanksSection(BuildContext context, TankState tankState, int tankCount, Map<String, List<dynamic>>? fishData) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    
    // Select a random tank if available, but persist selection across rebuilds
    Tank? randomTank;
    if (tankCount > 0) {
      // Initialize or validate the selected tank index
      if (_selectedTankIndex == null || _selectedTankIndex! >= tankCount) {
        _selectedTankIndex = Random().nextInt(tankCount);
      }
      randomTank = tankState.tanks[_selectedTankIndex!];
    } else {
      _selectedTankIndex = null;
    }
    
    // Get custom background photo if set
    TankPhoto? backgroundPhoto;
    if (randomTank != null && randomTank.customBackgroundPhotoId != null) {
      try {
        backgroundPhoto = randomTank.photos.firstWhere(
          (photo) => photo.id == randomTank?.customBackgroundPhotoId,
        );
      } catch (e) {
        // Photo not found, use default
      }
    }
    
    // Determine gradient colors based on tank type (matching tank management style)
    List<Color> gradientColors;
    if (randomTank != null && randomTank.type == 'freshwater') {
      // Freshwater: blue/cyan gradient
      gradientColors = [
        Colors.blue.shade400.withOpacity(0.15),
        Colors.cyan.shade300.withOpacity(0.15),
        cs.primaryContainer.withOpacity(0.5),
      ];
    } else if (randomTank != null) {
      // Saltwater/Marine: indigo/purple gradient
      gradientColors = [
        Colors.indigo.shade400.withOpacity(0.15),
        Colors.purple.shade300.withOpacity(0.15),
        cs.secondaryContainer.withOpacity(0.5),
      ];
    } else {
      // No tank: default gradient
      gradientColors = [
        cs.secondary.withOpacity(0.3),
        cs.primaryContainer.withOpacity(0.8),
      ];
    }
    
    return AnimatedFeatureCard(
      delay: const Duration(milliseconds: 600),
      child: Container(
        decoration: BoxDecoration(
          gradient: backgroundPhoto == null ? LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          image: backgroundPhoto != null ? DecorationImage(
            image: (backgroundPhoto.imageUrl?.startsWith('http') ?? false)
                ? CachedNetworkImageProvider(backgroundPhoto.imageUrl!) as ImageProvider
                : FileImage(File(backgroundPhoto.imagePath!)),
            fit: BoxFit.cover,
            opacity: 0.8,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ) : null,
          color: backgroundPhoto != null ? cs.surfaceContainerHighest : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              AnalyticsService.logFeatureUsed(
                featureName: 'my_tanks',
                parameters: {
                  'source': 'welcome_screen',
                  'route': '/tank-management',
                },
              );
              // Reset tank selection when navigating away
              await Navigator.pushNamed(context, '/tank-management');
              // After returning, reset the index so a new random tank is selected
              if (mounted) {
                setState(() {
                  _selectedTankIndex = null;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🐠', style: TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.myTanks,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tankCount == 0 
                                  ? l10n.noTanksYet 
                                  : '$tankCount ${tankCount == 1 ? l10n.tank : l10n.tanks}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: cs.onSurface,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: cs.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  if (tankCount == 0) ...[
                    Text(
                      l10n.myTanksDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/tank-management');
                        },
                        icon: const Icon(Icons.add),
                        label: Text(l10n.createFirstTank),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                      ),
                    ),
                  ] else if (randomTank != null) ...[
                    _buildTankPreview(context, randomTank, cs),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // List of available tank icons (same as in tank_management_screen.dart)
  static const List<IconData> _tankIcons = [
    Icons.water_drop,
    Icons.waves,
    Icons.pets,
    Icons.grass,
    Icons.eco,
    Icons.park,
    Icons.nature,
    Icons.spa,
    Icons.local_florist,
    Icons.filter_vintage,
  ];

  IconData? _getIconFromCodePoint(int? codePoint) {
    if (codePoint == null) return null;
    try {
      return _tankIcons.firstWhere((icon) => icon.codePoint == codePoint);
    } catch (e) {
      return null;
    }
  }

  Widget _buildTankIcon(Tank tank, ColorScheme cs) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: tank.customIconCodePoint == null && tank.customIconPhotoId == null
            ? LinearGradient(
                colors: tank.type == 'freshwater'
                    ? [Colors.blue.shade300, Colors.cyan.shade400]
                    : [Colors.indigo.shade300, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: tank.customIconCodePoint == null && tank.customIconPhotoId != null
            ? Colors.grey.shade300
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (tank.type == 'freshwater' 
                ? Colors.blue 
                : Colors.purple).withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tank.customIconCodePoint != null
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tank.type == 'freshwater'
                      ? [Colors.blue.shade300, Colors.cyan.shade400]
                      : [Colors.indigo.shade300, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconFromCodePoint(tank.customIconCodePoint) ?? 
                    (tank.type == 'freshwater' ? Icons.water_drop : Icons.waves),
                size: 20,
                color: Colors.white,
              ),
            )
          : (tank.customIconPhotoId != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: () {
                    try {
                      final photo = tank.photos.firstWhere(
                        (p) => p.id == tank.customIconPhotoId,
                      );
                      final imageUrl = photo.imageUrl ?? photo.imagePath;
                      return imageUrl != null
                          ? (imageUrl.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl, 
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Icon(
                                    tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                )
                              : Image.file(File(imageUrl), fit: BoxFit.cover))
                          : Icon(
                              tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                              size: 20,
                              color: Colors.white,
                            );
                    } catch (e) {
                      return Icon(
                        tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                        size: 20,
                        color: Colors.white,
                      );
                    }
                  }(),
                )
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                    size: 20,
                    color: Colors.white,
                  ),
                )),
    );
  }

  Widget _buildTankPreview(BuildContext context, Tank tank, ColorScheme cs) {
    // Use cached harmony score from tank object
    final harmonyScore = tank.harmonyScore;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Tank icon
            _buildTankIcon(tank, cs),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tank.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tank.type == 'freshwater' ? 'Freshwater' : 'Saltwater',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (tank.sizeGallons != null || tank.sizeLiters != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tank.sizeGallons != null 
                      ? '${tank.sizeGallons!.toStringAsFixed(0)} gal'
                      : '${tank.sizeLiters!.toStringAsFixed(0)} L',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (tank.inhabitants.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.pets,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '${_getTotalInhabitantCount(tank.inhabitants)} inhabitant${_getTotalInhabitantCount(tank.inhabitants) == 1 ? '' : 's'}, ${_groupInhabitantsByFishType(tank.inhabitants).length} type${_groupInhabitantsByFishType(tank.inhabitants).length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (harmonyScore != null) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getHarmonyColor(harmonyScore).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getHarmonyColor(harmonyScore),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getHarmonyIcon(harmonyScore),
                        size: 14,
                        color: _getHarmonyColor(harmonyScore),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${TankHarmonyCalculator.getHarmonyLabel(harmonyScore)} ${(harmonyScore * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getHarmonyColor(harmonyScore),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ] else ...[
          Text(
            'No inhabitants yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (tank.notes != null && tank.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            tank.notes!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
  
  Color _getHarmonyColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.yellow.shade700;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getHarmonyIcon(double score) {
    if (score >= 0.8) return Icons.check_circle;
    if (score >= 0.6) return Icons.info;
    if (score >= 0.4) return Icons.warning;
    return Icons.error;
  }
  
  int _getTotalInhabitantCount(List<TankInhabitant> inhabitants) {
    return inhabitants.fold(0, (total, inhabitant) => total + inhabitant.quantity);
  }

  Map<String, List<TankInhabitant>> _groupInhabitantsByFishType(List<TankInhabitant> inhabitants) {
    final grouped = <String, List<TankInhabitant>>{};
    for (final inhabitant in inhabitants) {
      final fishType = inhabitant.fishUnit;
      if (!grouped.containsKey(fishType)) {
        grouped[fishType] = [];
      }
      grouped[fishType]!.add(inhabitant);
    }
    return grouped;
  }
  
  Widget _buildRemoveAdsHint(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;
    if (adsRemoved) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => showRemoveAdsDialog(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              l10n.removeAds,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final postsAsync = ref.watch(welcomeCommunityPostsProvider(_communityCardFilterType));

    return AnimatedFeatureCard(
      delay: const Duration(milliseconds: 580),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade400.withOpacity(0.12),
              Colors.blue.shade300.withOpacity(0.12),
              cs.primaryContainer.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🌊', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.communityTitle,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.communityCardLatestPosts,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/community'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.communityCardViewAll),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Post-type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _communityFilterChip(context, l10n.communityFilterAll, null),
                      const SizedBox(width: 8),
                      _communityFilterChip(context, l10n.communityPostTypeTankShowcase, PostType.tankShowcase),
                      const SizedBox(width: 8),
                      _communityFilterChip(context, l10n.communityPostTypeTip, PostType.tip),
                      const SizedBox(width: 8),
                      _communityFilterChip(context, l10n.communityPostTypeQuestion, PostType.question),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Posts list
                postsAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            l10n.communityCardNoPostsYet,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: posts
                          .take(5)
                          .map((post) => _buildCommunityPostTile(context, post, cs))
                          .toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _communityFilterChip(BuildContext context, String label, PostType? type) {
    final isSelected = _communityCardFilterType == type;
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _communityCardFilterType = type),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
    );
  }

  Widget _buildCommunityPostTile(BuildContext context, CommunityPost post, ColorScheme cs) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.pushNamed(context, '/community'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: _postTypeColor(post.type),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        post.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Icon(Icons.favorite_outline, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text(
                        '${post.likes}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.comment_outlined, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text(
                        '${post.commentCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _postTypeColor(PostType type) {
    switch (type) {
      case PostType.tankShowcase:
        return Colors.blue.shade400;
      case PostType.tip:
        return Colors.green.shade400;
      case PostType.question:
        return Colors.orange.shade400;
    }
  }

  Widget _buildCommunityCardAd() {
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;
    if (adsRemoved) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(top: 16),
      child: NativeAdWidget(),
    );
  }

  Widget _buildWelcomeNativeAd() {
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;
    if (adsRemoved) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: NativeAdWidget(),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, List<FeatureInfo> features, {bool useGrid = true, bool forceSingleColumn = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;
    
    // Determine column count based on screen size and layout preference
    final crossAxisCount = forceSingleColumn ? 1 : (isLargeScreen ? 3 : (isMediumScreen ? 2 : (useGrid ? 2 : 1)));
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return AnimatedFeatureCard(
              delay: feature.delay,
              child: FeatureCard(
                icon: feature.icon,
                title: feature.title,
                description: feature.description,
                shortDescription: feature.shortDescription,
                imagePath: feature.imagePath,
                toolChips: feature.toolChips,
                compact: !forceSingleColumn && useGrid && !isMediumScreen,
                onTap: () {
                  // Log feature usage
                  AnalyticsService.logFeatureUsed(
                    featureName: feature.title.toLowerCase().replaceAll(' ', '_'),
                    parameters: {
                      'source': 'welcome_screen',
                      'route': feature.routeName,
                    },
                  );
                  
                  if (feature.url != null) {
                    _launchURL(feature.url!);
                  } else if (feature.openPhotoAnalyzer) {
                    Navigator.pushNamed(
                      context,
                      feature.routeName,
                      arguments: {'openPhotoAnalyzer': true},
                    );
                  } else {
                    Navigator.pushNamed(context, feature.routeName);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AnimatedHeader extends StatefulWidget {
  const AnimatedHeader({super.key});

  @override
  AnimatedHeaderState createState() => AnimatedHeaderState();
}

class AnimatedHeaderState extends State<AnimatedHeader> {
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isAnimated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isAnimated ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/AquaAi Logo.png', height: 125),
          const SizedBox(width: 16),
          GradientText(
            'Aquarium\nAI',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
            gradient: LinearGradient(colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ]),
          ),
        ],
      ),
    );
  }
}

class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration delay;

  const AnimatedText(this.text, {super.key, this.style, required this.delay});

  @override
  AnimatedTextState createState() => AnimatedTextState();
}

class AnimatedTextState extends State<AnimatedText> {
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _isAnimated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isAnimated ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class AnimatedFeatureCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedFeatureCard(
      {super.key, required this.child, required this.delay});

  @override
  AnimatedFeatureCardState createState() => AnimatedFeatureCardState();
}

class AnimatedFeatureCardState extends State<AnimatedFeatureCard> {
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _isAnimated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isAnimated ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 480),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 480),
        transform: Matrix4.translationValues(0, _isAnimated ? 0 : 20, 0),
        child: widget.child,
      ),
    );
  }
}

/// Wraps a changelog banner child and slides it up from below when first built.
class _ChangelogBannerSlide extends StatefulWidget {
  final Widget child;
  const _ChangelogBannerSlide({required this.child});

  @override
  State<_ChangelogBannerSlide> createState() => _ChangelogBannerSlideState();
}

class _ChangelogBannerSlideState extends State<_ChangelogBannerSlide> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      child: widget.child,
    );
  }
}

class FeatureCard extends ConsumerWidget {
  final String icon;
  final String title;
  final String description;
  final String? shortDescription;
  final VoidCallback onTap;
  final String? imagePath;
  final List<ToolChipInfo>? toolChips;
  final bool compact;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.shortDescription,
    required this.onTap,
    this.imagePath,
    this.toolChips,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeState = ref.watch(themeProviderNotifierProvider);
    final isMaterialYou = themeState.useMaterialYou;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isMaterialYou ? 3 : 2,
      shadowColor: cs.shadow.withOpacity(0.2),
      color: isMaterialYou ? cs.surface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isMaterialYou 
                ? [
                    cs.primaryContainer.withOpacity(0.3),
                    cs.secondaryContainer.withOpacity(0.2),
                    cs.tertiaryContainer.withOpacity(0.1),
                  ]
                : [
                    cs.primaryContainer.withOpacity(0.15),
                    cs.secondaryContainer.withOpacity(0.1),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          splashColor: cs.primary.withOpacity(0.1),
          child: Padding(
            padding: EdgeInsets.all(compact ? 14.0 : 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                if (compact) ...[
                  // Compact (grid on mobile): icon centered, title below
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isMaterialYou ? cs.onSurface : cs.primary,
                        ),
                  ),
                ] else ...[
                  // Default (list / large screen): icon + title in a row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isMaterialYou ? cs.onSurface : cs.primary,
                              ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: cs.primary.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  compact ? (shortDescription ?? description) : description,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (toolChips != null && toolChips!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (compact)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: toolChips!.map((chip) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: chip.onTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withOpacity(0.5),
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.primary.withOpacity(0.3)),
                            ),
                            child: Icon(chip.icon, size: 16, color: cs.primary),
                          ),
                        ),
                      )).toList(),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: toolChips!.map((chip) {
                        return ActionChip(
                          avatar: Icon(chip.icon, size: 16, color: cs.primary),
                          label: Text(
                            chip.label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          backgroundColor: cs.primaryContainer.withOpacity(0.5),
                          side: BorderSide(
                            color: cs.primary.withOpacity(0.3),
                            width: 1,
                          ),
                          onPressed: chip.onTap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                    ),
                ],
                if (imagePath != null) ...[
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final path = imagePath!;
                    final isNetworkImage =
                        Uri.tryParse(path)?.hasAbsolutePath == true &&
                        (path.startsWith('http://') ||
                            path.startsWith('https://'));
                    final errorPlaceholder = Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: cs.onSurfaceVariant,
                        size: 48,
                      ),
                    );
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: isNetworkImage
                            ? CachedNetworkImage(
                                imageUrl: path,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                placeholder: (context, url) => const SizedBox(
                                  height: 300,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) =>
                                    errorPlaceholder,
                              )
                            : Image.asset(
                                path,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) =>
                                    errorPlaceholder,
                              ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
