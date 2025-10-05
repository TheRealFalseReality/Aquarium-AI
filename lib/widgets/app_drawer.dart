// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme_provider.dart';
import '../providers/tank_provider.dart';
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
  int? _randomTankIndex;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Tank quick summary from provider
    final tankState = ref.watch(tankProvider);
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
                  child: Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Stack(
                      children: [
                        ListTile(
                          leading: _buildTankIconWithCount(randomTank),
                          title: Text(
                            'My Tanks',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: tankCount == 0
                              ? const Text('No tanks yet. Tap to add one!')
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total: $tankCount\n'
                                      '${randomTank != null ? randomTank.name : ""}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    if (harmonyScoreWidget != null) ...[
                                      const SizedBox(height: 4),
                                      harmonyScoreWidget,
                                    ],
                                  ],
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => navigate('/tank-management'),
                          isThreeLine: tankCount > 0,
                        ),
                        if (randomTank != null && randomTank.photos.isNotEmpty)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: _buildThumbnail(randomTank),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 250),
                  child: ListTile(
                    leading: const Icon(Icons.calculate),
                    title: const Text('AI Compatibility Tool'),
                    subtitle:
                        const Text('Check fish compatibility with an AI report.'),
                    onTap: () => navigate('/compat-ai'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 200),
                  child: ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('AI Chatbot'),
                    subtitle: const Text(
                        'Ask questions, analyze parameters, and more.'),
                    onTap: () => navigate('/chatbot'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 300),
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: const Text('Stocking Assistant'),
                    subtitle: const Text(
                        'Get personalized stocking recommendations for your aquarium.'),
                    onTap: () => navigate('/stocking'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 300),
                  child: ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Aquarium Calculators'),
                    subtitle:
                        const Text('Essential tools for salinity, CO₂, and more.'),
                    onTap: () => navigate('/calculators'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 350),
                  child: ListTile(
                    leading: const Icon(Icons.view_in_ar),
                    title: const Text('Tank Volume'),
                    subtitle:
                        const Text('Calculate the volume of your aquarium.'),
                    onTap: () => navigate('/tank-volume'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          AnimatedDrawerItem(
            delay: const Duration(milliseconds: 400),
            child: _buildCollapsibleThemeMenu(),
          ),
          const Divider(height: 1),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Tooltip(
                    message: 'Light Mode',
                    child: Icon(Icons.light_mode_outlined, size: 20)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Tooltip(
                    message: 'System Default',
                    child: Icon(Icons.brightness_auto_outlined, size: 20)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Tooltip(
                    message: 'Dark Mode',
                    child: Icon(Icons.dark_mode_outlined, size: 20)),
              ),
            ],
          ),
          if (isMaterialYouAvailable) ...[
            const SizedBox(height: 8),
            FilterChip(
              label: const Text('Material You'),
              labelStyle:
                  TextStyle(color: Theme.of(context).colorScheme.onSurface),
              avatar: const Icon(Icons.color_lens_outlined, size: 18),
              selected: themeState.useMaterialYou,
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
          title: Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
          onTap: () {
            setState(() {
              _isAppearanceExpanded = !_isAppearanceExpanded;
            });
          },
          trailing: AnimatedRotation(
            turns: _isAppearanceExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.expand_more),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
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
                Image.asset('assets/AquaPi Logo.png', height: 100),
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
        delay: const Duration(milliseconds: 450),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () => navigate('/'),
              tooltip: 'Home',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => navigate('/about'),
              tooltip: 'About',
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => navigate('/settings'),
              tooltip: 'Settings',
            ),
          ],
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

    final iconSize = size * 0.42;
    final padding = size * 0.21;

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
                              ? Image.network(imageUrl, fit: BoxFit.cover, width: size, height: size)
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
      return const Icon(Icons.water, size: 36);
    }

    return SizedBox(
      width: 40,
      height: 56,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 4),
          _buildTankIcon(tank, size: 40),
          const SizedBox(height: 16),
          if (tank.inhabitants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 8,
                    color: Theme.of(context).colorScheme.onTertiaryContainer.withOpacity(0.6),
                  ),
                  const SizedBox(width: 1),
                  Text(
                    '${_getTotalInhabitantCount(tank.inhabitants)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onTertiaryContainer.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.category,
                    size: 8,
                    color: Theme.of(context).colorScheme.onTertiaryContainer.withOpacity(0.6),
                  ),
                  const SizedBox(width: 1),
                  Text(
                    '${_groupInhabitantsByFishType(tank.inhabitants).length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onTertiaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
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

  Widget _buildThumbnail(Tank tank) {
    // Get the most recent photo
    if (tank.photos.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentPhoto = tank.photos.reduce((a, b) => 
      a.dateTaken.isAfter(b.dateTaken) ? a : b
    );

    final imageUrl = recentPhoto.imageUrl ?? recentPhoto.imagePath;
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: imageUrl != null
            ? (imageUrl.startsWith('http')
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Image.file(File(imageUrl), fit: BoxFit.cover))
            : Icon(
                Icons.image,
                size: 16,
                color: Theme.of(context).colorScheme.onTertiaryContainer.withOpacity(0.5),
              ),
      ),
    );
  }

  int _getTotalInhabitantCount(List<dynamic> inhabitants) {
    return inhabitants.fold(0, (total, inhabitant) => total + (inhabitant.quantity as int? ?? 0));
  }
}