import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import '../main_layout.dart';
import '../providers/model_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _geminiModelController;
  late final TextEditingController _geminiImageModelController;
  late final TextEditingController _geminiApiKeyController;
  late final TextEditingController _chatGPTModelController;
  late final TextEditingController _chatGPTImageModelController;
  late final TextEditingController _openAIApiKeyController;
  late final TextEditingController _groqModelController;
  late final TextEditingController _groqImageModelController;
  late final TextEditingController _groqApiKeyController;
  AIProvider _selectedProvider = AIProvider.gemini;

  bool _isGeminiApiKeyVisible = false;
  final bool _isOpenAIApiKeyVisible = false;
  bool _isGroqApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    final models = ref.read(modelProvider);
    _geminiModelController = TextEditingController(text: models.geminiModel);
    _geminiImageModelController =
        TextEditingController(text: models.geminiImageModel);
    _geminiApiKeyController = TextEditingController(text: models.geminiApiKey);
    _chatGPTModelController = TextEditingController(text: models.chatGPTModel);
    _chatGPTImageModelController =
        TextEditingController(text: models.chatGPTImageModel);
    _openAIApiKeyController = TextEditingController(text: models.openAIApiKey);
    _groqModelController = TextEditingController(text: models.groqModel);
    _groqImageModelController =
        TextEditingController(text: models.groqImageModel);
    _groqApiKeyController = TextEditingController(text: models.groqApiKey);
    _selectedProvider = models.activeProvider;
  }

  @override
  void dispose() {
    _geminiModelController.dispose();
    _geminiImageModelController.dispose();
    _geminiApiKeyController.dispose();
    _chatGPTModelController.dispose();
    _chatGPTImageModelController.dispose();
    _openAIApiKeyController.dispose();
    _groqModelController.dispose();
    _groqImageModelController.dispose();
    _groqApiKeyController.dispose();
    super.dispose();
  }

  /// **Saves the settings after validation.**
  void _saveSettings() {
    // Validation Check: Ensure the API key for the selected provider is not empty.
    if (_selectedProvider == AIProvider.gemini &&
        _geminiApiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a Gemini API key before saving.')),
      );
      return; // Stop the function
    }
    if (_selectedProvider == AIProvider.groq &&
        _groqApiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a Groq API key before saving.')),
      );
      return; // Stop the function
    }
    // Note: OpenAI is currently disabled, so no validation is needed for it.

    // If validation passes, proceed to save the settings.
    ref.read(modelProvider.notifier).setModels(
          newGeminiModel: _geminiModelController.text,
          newGeminiImageModel: _geminiImageModelController.text,
          newGeminiApiKey: _geminiApiKeyController.text,
          newChatGPTModel: _chatGPTModelController.text,
          newChatGPTImageModel: _chatGPTImageModelController.text,
          newOpenAIApiKey: _openAIApiKeyController.text,
          newGroqModel: _groqModelController.text,
          newGroqImageModel: _groqImageModelController.text,
          newGroqApiKey: _groqApiKeyController.text,
          newActiveProvider: _selectedProvider,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ModelState>(modelProvider, (previous, next) {
      // Update text controllers if the state changes from outside.
      if (_geminiModelController.text != next.geminiModel) {
        _geminiModelController.text = next.geminiModel;
      }
      if (_geminiImageModelController.text != next.geminiImageModel) {
        _geminiImageModelController.text = next.geminiImageModel;
      }
      if (_geminiApiKeyController.text != next.geminiApiKey) {
        _geminiApiKeyController.text = next.geminiApiKey;
      }
      if (_chatGPTModelController.text != next.chatGPTModel) {
        _chatGPTModelController.text = next.chatGPTModel;
      }
      if (_chatGPTImageModelController.text != next.chatGPTImageModel) {
        _chatGPTImageModelController.text = next.chatGPTImageModel;
      }
      if (_openAIApiKeyController.text != next.openAIApiKey) {
        _openAIApiKeyController.text = next.openAIApiKey;
      }
      if (_groqModelController.text != next.groqModel) {
        _groqModelController.text = next.groqModel;
      }
      if (_groqImageModelController.text != next.groqImageModel) {
        _groqImageModelController.text = next.groqImageModel;
      }
      if (_groqApiKeyController.text != next.groqApiKey) {
        _groqApiKeyController.text = next.groqApiKey;
      }
      if (_selectedProvider != next.activeProvider) {
        setState(() {
          _selectedProvider = next.activeProvider;
        });
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
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active AI Provider',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<AIProvider>(
                    segments: const [
                      ButtonSegment(
                          value: AIProvider.gemini, label: Text('Gemini')),
                      ButtonSegment(
                          value: AIProvider.openAI, label: Text('OpenAI')),
                      ButtonSegment(value: AIProvider.groq, label: Text('Groq')),
                    ],
                    selected: {_selectedProvider},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedProvider = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Display settings based on the selected provider.
                  if (_selectedProvider == AIProvider.gemini)
                    _buildGeminiSettings()
                  else if (_selectedProvider == AIProvider.openAI)
                    _buildOpenAISettings()
                  else
                    _buildGroqSettings(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(modelProvider.notifier)
                              .resetModelsToDefaults();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Models reset to default.')),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Models'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _saveSettings, // Call the save function.
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

  // ... rest of the unchanged widgets (_buildGeminiSettings, _buildOpenAISettings, etc.)

  Widget _buildGeminiSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 24),
        Text(
          'Google Gemini Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _geminiApiKeyController,
          obscureText: !_isGeminiApiKeyVisible,
          decoration: InputDecoration(
            labelText: 'Google AI API Key',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _isGeminiApiKeyVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isGeminiApiKeyVisible = !_isGeminiApiKeyVisible;
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
            labelText: 'Gemini Multimedia Model',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildApiKeyGuide(
          title: 'How to get your Google AI API key:',
          children: [
            const Text('1. Go to the Google AI Studio website.'),
            InkWell(
              onTap: () =>
                  launchUrl(Uri.parse('https://aistudio.google.com/app/apikey')),
              child: const Text(
                'Google AI Studio',
                style: TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const Text('2. Sign in with your Google account.'),
            const Text(
                '3. Click "Create API key in new project" or "Get API key".'),
            const Text('4. Copy the generated API key and paste it above.'),
            InkWell(
              onTap: () => launchUrl(
                  Uri.parse('https://www.merge.dev/blog/gemini-api-key')),
              child: const Text(
                'View Full Guide',
                style: TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpenAISettings() {
    return Stack(
      children: [
        // The disabled settings section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'OpenAI Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _openAIApiKeyController,
              enabled: false,
              obscureText: !_isOpenAIApiKeyVisible,
              decoration: InputDecoration(
                labelText: 'OpenAI API Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isOpenAIApiKeyVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _chatGPTModelController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'ChatGPT Text Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _chatGPTImageModelController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'ChatGPT Multimedia Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildApiKeyGuide(
              title: 'How to get your OpenAI API key:',
              children: [
                const Text('1. Go to the OpenAI API keys page.'),
                InkWell(
                  onTap: () => launchUrl(
                      Uri.parse('https://platform.openai.com/account/api-keys')),
                  child: const Text(
                    'OpenAI API Keys',
                    style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                ),
                const Text('2. Sign in and create a new secret key.'),
                const Text('3. Copy the generated API key and paste it above.'),
                InkWell(
                  onTap: () => launchUrl(
                      Uri.parse('https://www.merge.dev/blog/chatgpt-api-key')),
                  child: const Text(
                    'View Full Guide',
                    style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ],
        ),
        // The creative "Coming Soon" overlay
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.black.withOpacity(0.1),
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'Coming Soon!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroqSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 24),
        Text(
          'Groq Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _groqApiKeyController,
          obscureText: !_isGroqApiKeyVisible,
          decoration: InputDecoration(
            labelText: 'Groq API Key',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _isGroqApiKeyVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isGroqApiKeyVisible = !_isGroqApiKeyVisible;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _groqModelController,
          decoration: const InputDecoration(
            labelText: 'Groq Text Model',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _groqImageModelController,
          decoration: const InputDecoration(
            labelText: 'Groq Multimedia Model',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildApiKeyGuide(
          title: 'How to get your Groq API key:',
          children: [
            const Text('1. Go to the GroqCloud Console website.'),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://console.groq.com/keys')),
              child: const Text(
                'GroqCloud Console',
                style: TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const Text('2. Sign in and navigate to the API Keys section.'),
            const Text('3. Click "Create API Key" to create a new secret key.'),
            const Text('4. Copy the generated API key and paste it above.'),
          ],
        ),
      ],
    );
  }

  Widget _buildApiKeyGuide(
      {required String title, required List<Widget> children}) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: children.map((child) {
        return Padding(
          padding: const EdgeInsets.only(
              left: 16.0, top: 4.0, bottom: 4.0, right: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        );
      }).toList(),
    );
  }
}