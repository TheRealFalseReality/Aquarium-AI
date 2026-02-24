// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme_provider.dart';
import '../providers/tank_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/purchase_provider.dart';
import '../models/tank.dart';
import '../utils/tank_harmony_calculator.dart';
import '../services/analytics_service.dart';
import 'gradient_text.dart';
import 'animated_drawer_item.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isAppearanceExpanded = false;
  bool _isSpringAnimation = false;
  bool _isCollapsingSpring = false;
  int? _randomTankIndex;

  static const Duration _expandDuration = Duration(milliseconds: 900);
  static const Duration _collapseDuration = Duration(milliseconds: 750);
  static const Duration _normalDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _checkFirstLaunchAnimation();
  }

  Future<void> _checkFirstLaunchAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownAnimation =
        prefs.getBool('drawer_appearance_animation_shown') ?? false;
    if (!hasShownAnimation) {
      // Wait for the drawer to finish opening before starting the animation
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      // Mark animation as shown only once it actually starts
      await prefs.setBool('drawer_appearance_animation_shown', true);
      setState(() {
        _isSpringAnimation = true;
        _isCollapsingSpring = false;
        _isAppearanceExpanded = true;
      });
      // Hold the section open so users can read it
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        _isCollapsingSpring = true;
        _isAppearanceExpanded = false;
      });
      // Wait for the collapse animation to finish
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _isSpringAnimation = false;
        _isCollapsingSpring = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Tank quick summary from provider
    final tankState = ref.watch(tankProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final tankCount = tankState.tanks.length;
    // Show a random tank instead of the last tank
    // Initialize random index on first build or when tank count changes
    if (_randomTankIndex == null || _randomTankIndex! >= tankCount) {
      _randomTankIndex = tankCount > 0 ? Random().nextInt(tankCount) : null;
    }
    final randomTank = _randomTankIndex != null && tankCount > 0
        ? tankState.tanks[_randomTankIndex!]
        : null;

    void navigate(String routeName) {
      // Log navigation analytics
      final currentRoute = AnalyticsService.currentScreen;
      final targetScreen = AnalyticsService.routeToScreenName(routeName);
      AnalyticsService.logNavigation(
        from: currentRoute,
        to: targetScreen,
        method: 'drawer_menu',
      );
      
      Navigator.pop(context); // Close the drawer first
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        if (ModalRoute.of(context)?.settings.name != routeName) {
          Navigator.pushNamed(context, routeName);
        }
      });
    }

    // Build harmony score widget for random tank using cached harmony score
    Widget? harmonyScoreWidget;
    if (randomTank != null && randomTank.inhabitants.isNotEmpty) {
      final harmonyScore = randomTank.harmonyScore;
      if (harmonyScore != null) {
        final percentage = (harmonyScore * 100).toStringAsFixed(0);
        final label = TankHarmonyCalculator.getHarmonyLabel(harmonyScore);
        
        Color chipColor;
        Color textColor;
        if (harmonyScore >= 0.8) {
          chipColor = Colors.green.shade100;
          textColor = Colors.green.shade800;
        } else if (harmonyScore >= 0.7) {
          chipColor = Colors.yellow.shade100;
          textColor = Colors.yellow.shade800;
        } else if (harmonyScore >= 0.6) {
          chipColor = Colors.orange.shade100;
          textColor = Colors.orange.shade800;
        } else {
          chipColor = Colors.red.shade100;
          textColor = Colors.red.shade800;
        }

        harmonyScoreWidget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$label $percentage%',
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context, isDarkMode, () => navigate('/')),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 180),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: randomTank != null
                            ? (randomTank.type == 'freshwater'
                                ? [
                                    Colors.blue.shade400.withOpacity(0.15),
                                    Colors.cyan.shade300.withOpacity(0.15),
                                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                                  ]
                                : [
                                    Colors.indigo.shade400.withOpacity(0.15),
                                    Colors.purple.shade300.withOpacity(0.15),
                                    Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                                  ])
                            : [
                                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => navigate('/tank-management'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  _buildTankIconWithCount(randomTank),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          l10n.myTanks,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tankCount == 0
                                              ? l10n.noTanksYet
                                              : 'Total: $tankCount\n${randomTank != null ? randomTank.name : ""}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (harmonyScoreWidget != null) ...[
                                          const SizedBox(height: 6),
                                          harmonyScoreWidget,
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // if (randomTank != null && randomTank.photos.isNotEmpty)
                          //   Positioned(
                          //     bottom: 8,
                          //     right: 8,
                          //     child: _buildThumbnail(randomTank),
                          //   ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (appSettings.enableAI) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Tools',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedDrawerItem(
                    delay: const Duration(milliseconds: 250),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.calculate, color: Theme.of(context).colorScheme.primary),
                        title: Text(l10n.aiCompatibilityTool),
                        subtitle:
                            Text(l10n.aiCompatibilityDrawerDescription),
                        onTap: () => navigate('/compat-ai'),
                      ),
                    ),
                  ),
                  AnimatedDrawerItem(
                    delay: const Duration(milliseconds: 300),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.chat, color: Theme.of(context).colorScheme.secondary),
                        title: Text(l10n.aiChatbot),
                        subtitle: Text(l10n.aiChatbotDrawerDescription),
                        onTap: () => navigate('/chatbot'),
                      ),
                    ),
                  ),
                  AnimatedDrawerItem(
                    delay: const Duration(milliseconds: 350),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.tertiary),
                        title: Text(l10n.aiStockingAssistant),
                        subtitle: Text(l10n.aiStockingDrawerDescription),
                        onTap: () => navigate('/stocking'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      thickness: 1,
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tools & Resources',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.science, color: Theme.of(context).colorScheme.primary),
                      title: Text(l10n.aquariumCalculators),
                      subtitle:
                          Text(l10n.aquariumCalculatorsDrawerDescription),
                      onTap: () => navigate('/calculators'),
                    ),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 450),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.view_in_ar, color: Theme.of(context).colorScheme.secondary),
                      title: Text(l10n.tankVolumeCalculator),
                      subtitle:
                          Text(l10n.tankVolumeDrawerDescription),
                      onTap: () => navigate('/tank-volume'),
                    ),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 500),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.library_books, color: Theme.of(context).colorScheme.tertiary),
                      title: Text(l10n.information),
                      subtitle: Text(l10n.informationDescription),
                      onTap: () => navigate('/information'),
                    ),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 550),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Analysis History'),
                      subtitle: const Text('View saved AI analysis reports'),
                      onTap: () => navigate('/analysis-history'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Remove Ads entry (hidden when ads already removed)
          if (!ref.watch(purchaseProvider).adsRemoved) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            AnimatedDrawerItem(
              delay: const Duration(milliseconds: 540),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.block, color: Colors.green.shade600, size: 22),
                  title: Text(
                    'Remove Ads',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'One-time purchase · Support the app',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // close drawer
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (!mounted) return;
                      Navigator.pushNamed(
                        context,
                        '/settings',
                        arguments: {'openRemoveAds': true},
                      );
                    });
                  },
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
              thickness: 1,
            ),
          ),
          AnimatedDrawerItem(
            delay: const Duration(milliseconds: 550),
            child: _buildCollapsibleThemeMenu(),
          ),
          _buildDrawerFooter(context, navigate),
        ],
      ),
    );
  }

  Widget _buildCollapsibleThemeMenu() {
    final themeState = ref.watch(themeProviderNotifierProvider);
    final themeNotifier = ref.read(themeProviderNotifierProvider.notifier);
    final themeModes = [ThemeMode.light, ThemeMode.system, ThemeMode.dark];
    final isMaterialYouAvailable = !kIsWeb && (Platform.isAndroid);

    final collapsibleContent = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          ToggleButtons(
            isSelected: [
              themeState.themeMode == ThemeMode.light,
              themeState.themeMode == ThemeMode.system,
              themeState.themeMode == ThemeMode.dark,
            ],
            onPressed: (index) {
              themeNotifier.setThemeMode(themeModes[index]);
            },
            borderRadius: BorderRadius.circular(8.0),
            constraints: const BoxConstraints(
              minHeight: 36.0,
              minWidth: 48.0,
            ),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Tooltip(
                    message: 'Light Mode',
                    child: Icon(Icons.light_mode_outlined, size: 18)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Tooltip(
                    message: 'System Default',
                    child: Icon(Icons.brightness_auto_outlined, size: 18)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Tooltip(
                    message: 'Dark Mode',
                    child: Icon(Icons.dark_mode_outlined, size: 18)),
              ),
            ],
          ),
          if (isMaterialYouAvailable) ...[
            const SizedBox(height: 6),
            FilterChip(
              label: const Text('Material You'),
              labelStyle:
                  TextStyle(color: Theme.of(context).colorScheme.onSurface),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                themeState.useMaterialYou 
                    ? Icons.check_circle 
                    : Icons.color_lens_outlined, 
                size: 16,
                color: themeState.useMaterialYou 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
              ),
              selected: themeState.useMaterialYou,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
              onSelected: (isSelected) {
                themeNotifier.toggleMaterialYou(isSelected);
              },
            ),
          ]
        ],
      ),
    );

    return Column(
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: Icon(
            Icons.palette_outlined,
            color: Theme.of(context).colorScheme.tertiary,
            size: 20,
          ),
          title: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            setState(() {
              _isAppearanceExpanded = !_isAppearanceExpanded;
            });
          },
          trailing: AnimatedRotation(
            turns: _isAppearanceExpanded ? 0.5 : 0.0,
            duration: _isSpringAnimation
                ? (_isCollapsingSpring ? _collapseDuration : _expandDuration)
                : _normalDuration,
            curve: _isSpringAnimation
                ? (_isCollapsingSpring
                    ? Curves.easeInOutCubic
                    : Curves.easeOutCubic)
                : Curves.easeInOut,
            child: Icon(
              Icons.expand_more,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ),
        AnimatedSize(
          duration: _isSpringAnimation
              ? (_isCollapsingSpring ? _collapseDuration : _expandDuration)
              : _normalDuration,
          curve: _isSpringAnimation
              ? (_isCollapsingSpring
                  ? Curves.easeInOutCubic
                  : Curves.easeOutCubic)
              : Curves.easeInOut,
          child:
              _isAppearanceExpanded ? collapsibleContent : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDrawerHeader(
      BuildContext context, bool isDarkMode, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;

    return DrawerHeader(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [colorScheme.surfaceContainerHighest, colorScheme.primary]
                  : [colorScheme.primaryContainer, colorScheme.secondaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/AquaAi Logo.png', height: 100),
                const SizedBox(width: 12),
                GradientText(
                  'Aquarium\nAI',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black26,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            Colors.white,
                            const Color.fromARGB(255, 220, 230, 255),
                          ]
                        : [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(
      BuildContext context, void Function(String) navigate) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16.0, 8.0, 16.0, bottomPadding > 0 ? bottomPadding : 16.0),
      child: AnimatedDrawerItem(
        delay: const Duration(milliseconds: 600),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => navigate('/'),
                tooltip: 'Home',
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () => navigate('/about'),
                tooltip: 'About',
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                onPressed: () => navigate('/settings'),
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tank icons list (matching tank management screen)
  static const List<IconData> _tankIcons = [
    Icons.water_drop,
    Icons.waves,
    Icons.pool,
    Icons.bubble_chart,
    Icons.water,
    Icons.shower,
    Icons.opacity,
    Icons.water_damage,
    Icons.pets,
    Icons.set_meal,
    Icons.spa,
    Icons.emoji_nature,
    Icons.grass,
    Icons.eco,
    Icons.forest,
    Icons.park,
  ];

  IconData? _getIconFromCodePoint(int? codePoint) {
    if (codePoint == null) return null;
    try {
      return _tankIcons.firstWhere((icon) => icon.codePoint == codePoint);
    } catch (e) {
      return null;
    }
  }

  Widget _buildTankIcon(Tank? tank, {double size = 48}) {
    if (tank == null) {
      return Icon(Icons.water, size: size * 0.75);
    }

    final iconSize = size * .75;
    final padding = size * 0.1;

    return Container(
      width: size,
      height: size,
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
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: (tank.type == 'freshwater' 
                ? Colors.blue 
                : Colors.purple).withOpacity(0.2),
            blurRadius: size * 0.125,
            offset: Offset(0, size * 0.042),
          ),
        ],
      ),
      child: tank.customIconCodePoint != null
          ? Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tank.type == 'freshwater'
                      ? [Colors.blue.shade300, Colors.cyan.shade400]
                      : [Colors.indigo.shade300, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
              child: Icon(
                _getIconFromCodePoint(tank.customIconCodePoint) ?? 
                    (tank.type == 'freshwater' ? Icons.water_drop : Icons.waves),
                size: iconSize,
                color: Colors.white,
              ),
            )
          : (tank.customIconPhotoId != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(size * 0.25),
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
                                  width: size, 
                                  height: size,
                                  errorWidget: (context, url, error) => Icon(
                                    tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                )
                              : Image.file(File(imageUrl), fit: BoxFit.cover, width: size, height: size))
                          : Icon(
                              tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                              size: iconSize,
                              color: Colors.white,
                            );
                    } catch (e) {
                      return Icon(
                        tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                        size: iconSize,
                        color: Colors.white,
                      );
                    }
                  }(),
                )
              : Padding(
                  padding: EdgeInsets.all(padding),
                  child: Icon(
                    tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                    size: iconSize,
                    color: Colors.white,
                  ),
                )),
    );
  }

  Widget _buildTankIconWithCount(Tank? tank) {
    if (tank == null) {
      return const Icon(Icons.water, size: 52);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTankIcon(tank, size: 52),
        const SizedBox(height: 4),
        if (tank.inhabitants.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                size: 8,
                color: Theme.of(context)
                    .colorScheme
                    .onTertiaryContainer
                    .withOpacity(0.6),
              ),
              const SizedBox(width: 1),
              Text(
                '${_getTotalInhabitantCount(tank.inhabitants)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .onTertiaryContainer
                      .withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.category,
                size: 8,
                color: Theme.of(context)
                    .colorScheme
                    .onTertiaryContainer
                    .withOpacity(0.6),
              ),
              const SizedBox(width: 1),
              Text(
                '${_groupInhabitantsByFishType(tank.inhabitants).length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .onTertiaryContainer
                      .withOpacity(0.7),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Map<String, List<dynamic>> _groupInhabitantsByFishType(List<dynamic> inhabitants) {
    final grouped = <String, List<dynamic>>{};
    for (final inhabitant in inhabitants) {
      final fishType = inhabitant.fishUnit as String? ?? 'unknown';
      if (!grouped.containsKey(fishType)) {
        grouped[fishType] = [];
      }
      grouped[fishType]!.add(inhabitant);
    }
    return grouped;
  }


  int _getTotalInhabitantCount(List<dynamic> inhabitants) {
    return inhabitants.fold(0, (total, inhabitant) => total + (inhabitant.quantity as int? ?? 0));
  }
}
