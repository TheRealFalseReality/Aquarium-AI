import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
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
  late final TextEditingController _apiKeyController;
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the current state from the provider
    final models = ref.read(modelProvider);
    _geminiModelController = TextEditingController(text: models.geminiModel);
    _geminiImageModelController =
        TextEditingController(text: models.geminiImageModel);
    _apiKeyController = TextEditingController(text: models.apiKey);
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _geminiModelController.dispose();
    _geminiImageModelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      if (_apiKeyController.text != next.apiKey) {
        _apiKeyController.text = next.apiKey;
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Google Gemini Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: !_isApiKeyVisible,
                    decoration: InputDecoration(
                      labelText: 'Google AI API Key',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isApiKeyVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isApiKeyVisible = !_isApiKeyVisible;
                          });
                        },
                      ),
                    ),
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
                          final newImageModel =
                              _geminiImageModelController.text;
                          final newApiKey = _apiKeyController.text;

                          if (newTextModel.isNotEmpty &&
                              newImageModel.isNotEmpty) {
                            ref.read(modelProvider.notifier).setModels(
                                newTextModel, newImageModel, newApiKey);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Settings updated successfully!')),
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
                        label: const Text('Save Settings'),
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