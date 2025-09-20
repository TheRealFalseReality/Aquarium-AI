// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme_provider.dart';
import '../providers/tank_provider.dart';
import '../providers/fish_compatibility_provider.dart';
import '../utils/tank_harmony_calculator.dart';
import 'gradient_text.dart';
import 'animated_drawer_item.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isAppearanceExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Tank quick summary from provider
    final tankState = ref.watch(tankProvider);
    final tankCount = tankState.tanks.length;
    final lastTank = tankState.tanks.isNotEmpty ? tankState.tanks.last : null;

    // Get fish data for harmony calculation
    final fishCompatibilityState = ref.watch(fishCompatibilityProvider);
    final fishData = fishCompatibilityState.fishData.value;

    void navigate(String routeName) {
      Navigator.pop(context); // Close the drawer first
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        if (ModalRoute.of(context)?.settings.name != routeName) {
          Navigator.pushNamed(context, routeName);
        }
      });
    }

    // Build harmony score widget for last tank
    Widget? harmonyScoreWidget;
    if (lastTank != null && lastTank.inhabitants.isNotEmpty && fishData != null) {
      final harmonyScore = TankHarmonyCalculator.calculateTankHarmonyScore(lastTank, fishData);
      if (harmonyScore != null) {
        final percentage = (harmonyScore * 100).toStringAsFixed(0);
        final label = TankHarmonyCalculator.getHarmonyLabel(harmonyScore);
        
        Color chipColor;
        Color textColor;
        if (harmonyScore >= 0.8) {
          chipColor = Colors.green.shade100;
          textColor = Colors.green.shade800;
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
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.water, size: 36),
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
                                  '${lastTank != null ? "Latest: ${lastTank.name}" : ""}',
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
                    title: const Text('AI Stocking Assistant'),
                    subtitle: const Text(
                        'Get personalized stocking recommendations for your aquarium.'),
                    onTap: () => navigate('/stocking'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 325),
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
                    leading: const Icon(Icons.opacity),
                    title: const Text('Tank Volume'),
                    subtitle:
                        const Text('Calculate the volume of your aquarium.'),
                    onTap: () => navigate('/tank-volume'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 275),
                  child: ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Fish Data Editor'),
                    subtitle:
                        const Text('Edit and customize fish compatibility data.'),
                    onTap: () => navigate('/fish-editor'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          AnimatedDrawerItem(
            delay: const Duration(milliseconds: 425),
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
        delay: const Duration(milliseconds: 475),
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
}