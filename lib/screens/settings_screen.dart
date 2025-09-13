import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../theme_provider.dart';
import '../providers/model_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Define controllers here
  late final TextEditingController _geminiModelController;
  late final TextEditingController _geminiImageModelController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the current state from the provider
    final models = ref.read(modelProvider);
    _geminiModelController = TextEditingController(text: models.geminiModel);
    _geminiImageModelController =
        TextEditingController(text: models.geminiImageModel);
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _geminiModelController.dispose();
    _geminiImageModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProviderNotifierProvider);
    final themeNotifier = ref.read(themeProviderNotifierProvider.notifier);
    final isDarkMode = themeState.themeMode == ThemeMode.dark ||
        (themeState.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // Watch the model provider for changes
    final models = ref.watch(modelProvider);

    // Listen for state changes to update controllers, e.g., after a reset
    ref.listen<ModelState>(modelProvider, (previous, next) {
      if (_geminiModelController.text != next.geminiModel) {
        _geminiModelController.text = next.geminiModel;
      }
      if (_geminiImageModelController.text != next.geminiImageModel) {
        _geminiImageModelController.text = next.geminiImageModel;
      }
    });

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
                    themeNotifier
                        .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
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
                  TextField(
                    controller: _geminiModelController,
                    decoration: const InputDecoration(
                      labelText: 'Gemini Text Model',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _geminiImageModelController,
                    decoration: const InputDecoration(
                      labelText: 'Gemini Image Model',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // *** NEW BUTTON ***
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(modelProvider.notifier).resetToDefaults();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Models reset to default.')),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final newTextModel = _geminiModelController.text;
                          final newImageModel = _geminiImageModelController.text;

                          if (newTextModel.isNotEmpty &&
                              newImageModel.isNotEmpty) {
                            ref
                                .read(modelProvider.notifier)
                                .setModels(newTextModel, newImageModel);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Models updated successfully!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Model names cannot be empty.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Models'),
                      ),
                    ],
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