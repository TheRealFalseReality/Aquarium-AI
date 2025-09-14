import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme_provider.dart';
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

    void navigate(String routeName) {
      Navigator.pop(context); // Close the drawer
      if (ModalRoute.of(context)?.settings.name != routeName) {
        Navigator.pushNamed(context, routeName);
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
                  delay: const Duration(milliseconds: 250),
                  child: ListTile(
                    leading: const Icon(Icons.calculate),
                    title: const Text('AI Compatibility Tool'),
                    subtitle: const Text('Check fish compatibility with an AI report.'),
                    onTap: () => navigate('/compat-ai'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 200),
                  child: ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('AI Chatbot'),
                    subtitle: const Text('Ask questions, analyze parameters, and more.'),
                    onTap: () => navigate('/chatbot'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 300),
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: const Text('Stocking Assistant'),
                    subtitle: const Text('Get personalized stocking recommendations for your aquarium.'),
                    onTap: () => navigate('/stocking'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 300),
                  child: ListTile(
                    leading: const Icon(Icons.science),
                    title: const Text('Aquarium Calculators'),
                    subtitle: const Text('Essential tools for salinity, CO₂, and more.'),
                    onTap: () => navigate('/calculators'),
                  ),
                ),
                AnimatedDrawerItem(
                  delay: const Duration(milliseconds: 350),
                  child: ListTile(
                    leading: const Icon(Icons.opacity),
                    title: const Text('Tank Volume'),
                    subtitle: const Text('Calculate the volume of your aquarium.'),
                    onTap: () => navigate('/tank-volume'),
                  ),
                ),
              ],
            ),
          ),
          // --- FOOTER SECTION ---
          // This section is now outside the Expanded ListView, so it sticks to the bottom.
          const Divider(height: 1),
          _buildCollapsibleThemeMenu(),
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
    final isMaterialYouAvailable = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Column(
      children: [
        ListTile(
          title: Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
          onTap: () {
            setState(() {
              _isAppearanceExpanded = !_isAppearanceExpanded;
            });
          },
          trailing: Icon(
            _isAppearanceExpanded ? Icons.expand_less : Icons.expand_more,
          ),
        ),
        AnimatedCrossFade(
          firstChild: Container(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
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
                      child: Tooltip(message: 'Light Mode', child: Icon(Icons.light_mode_outlined, size: 20)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Tooltip(message: 'System Default', child: Icon(Icons.brightness_auto_outlined, size: 20)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Tooltip(message: 'Dark Mode', child: Icon(Icons.dark_mode_outlined, size: 20)),
                    ),
                  ],
                ),
                if (isMaterialYouAvailable) ...[
                  const SizedBox(height: 8),
                  FilterChip(
                    label: const Text('Material You'),
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    avatar: const Icon(Icons.color_lens_outlined, size: 18),
                    selected: themeState.useMaterialYou,
                    onSelected: (isSelected) {
                      themeNotifier.toggleMaterialYou(isSelected);
                    },
                  ),
                ]
              ],
            ),
          ),
          crossFadeState: _isAppearanceExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildDrawerHeader(
      BuildContext context, bool isDarkMode, VoidCallback onTap) {
    return DrawerHeader(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [const Color(0xFF0D47A1), const Color(0xFF00ACC1)]
                  : [const Color(0xFF7FB3C8), const Color(0xFFC4B1C5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/AquaPi Logo.png', height: 60),
                const SizedBox(width: 12),
                const GradientText(
                  'Fish.AI',
                  style: TextStyle(
                    fontSize: 50,
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
                    colors: [
                      Colors.white,
                      Color.fromARGB(255, 220, 230, 255),
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
  
  // --- SPACING FIX IS HERE ---
  Widget _buildDrawerFooter(
      BuildContext context, void Function(String) navigate) {
    // Get the device's safe area padding at the bottom.
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // The SafeArea widget is removed from here.
    return Padding(
      // We apply padding manually. We use the device's safe area padding
      // if it's greater than 0, otherwise, we fall back to a default small padding.
      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, bottomPadding > 0 ? bottomPadding : 16.0),
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
}