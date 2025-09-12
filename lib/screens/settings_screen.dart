import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProviderNotifierProvider);
    final themeNotifier = ref.read(themeProviderNotifierProvider.notifier);
    // Determine if the current theme is dark. If system, check platform brightness.
    final isDarkMode = themeState.themeMode == ThemeMode.dark ||
        (themeState.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return MainLayout(
      title: 'Settings',
      // No bottomNavigationBar to remove the ad banner
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Settings',
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Enable or disable dark theme'),
                  value: isDarkMode,
                  onChanged: (value) {
                    themeNotifier.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light);
                  },
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
                if (!kIsWeb && Platform.isAndroid)
                  SwitchListTile(
                    title: const Text('Dynamic Color'),
                    subtitle: const Text('Use colors from your wallpaper'),
                    value: themeState.useMaterialYou,
                    onChanged: (value) {
                      themeNotifier.toggleMaterialYou(value);
                    },
                    secondary: const Icon(Icons.color_lens_outlined),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}