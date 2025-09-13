import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../theme_provider.dart';
import '../providers/model_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProviderNotifierProvider);
    final themeNotifier = ref.read(themeProviderNotifierProvider.notifier);
    final isDarkMode = themeState.themeMode == ThemeMode.dark ||
        (themeState.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // Watch the model provider
    final models = ref.watch(modelProvider);
    final modelNotifier = ref.read(modelProvider.notifier);

    // Create text controllers
    final geminiModelController = TextEditingController(text: models.geminiModel);
    final geminiImageModelController =
        TextEditingController(text: models.geminiImageModel);

    return MainLayout(
      title: 'Settings',
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
          const SizedBox(height: 24),
          // New Card for Model Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Model Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // Display current models as chips
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      Chip(
                        label: Text('Current Text Model: ${models.geminiModel}'),
                        avatar: const Icon(Icons.text_fields),
                      ),
                      Chip(
                        label: Text(
                            'Current Image Model: ${models.geminiImageModel}'),
                        avatar: const Icon(Icons.image),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Text fields for model input
                  TextField(
                    controller: geminiModelController,
                    decoration: const InputDecoration(
                      labelText: 'Gemini Text Model',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: geminiImageModelController,
                    decoration: const InputDecoration(
                      labelText: 'Gemini Image Model',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Save button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final newTextModel = geminiModelController.text;
                        final newImageModel = geminiImageModelController.text;

                        if (newTextModel.isNotEmpty &&
                            newImageModel.isNotEmpty) {
                          modelNotifier.setModels(newTextModel, newImageModel);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Models updated successfully!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Model names cannot be empty.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Models'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}