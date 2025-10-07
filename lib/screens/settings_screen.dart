import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main_layout.dart';
import '../providers/model_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/accessible_feedback.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

enum SettingsSection {
  menu,
  aiProvider,
  appSettings,
  dataManagement,
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
  bool _isOpenAIApiKeyVisible = false;
  bool _isGroqApiKeyVisible = false;
  
  SettingsSection _currentSection = SettingsSection.menu;

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
      context.showAccessibleMessage('Please enter a Gemini API key before saving.');
      return; // Stop the function
    }
    if (_selectedProvider == AIProvider.openAI &&
        _openAIApiKeyController.text.trim().isEmpty) {
      context.showAccessibleMessage('Please enter an OpenAI API key before saving.');
      return; // Stop the function
    }
    if (_selectedProvider == AIProvider.groq &&
        _groqApiKeyController.text.trim().isEmpty) {
      context.showAccessibleMessage('Please enter a Groq API key before saving.');
      return; // Stop the function
    }

    // Log settings save
    AnalyticsService.logFeatureUsed(
      featureName: 'settings_save',
      parameters: {
        'provider': _selectedProvider.toString(),
        'has_api_key': 'true', // We validated it exists above
      },
    );

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

    context.showAccessibleMessage('Settings updated successfully!');
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
      title: _currentSection == SettingsSection.menu 
          ? 'Settings' 
          : _currentSection == SettingsSection.aiProvider
              ? 'AI Provider'
              : _currentSection == SettingsSection.appSettings
                  ? 'App Settings'
                  : 'Data Management',
      child: WillPopScope(
        onWillPop: () async {
          if (_currentSection != SettingsSection.menu) {
            setState(() {
              _currentSection = SettingsSection.menu;
            });
            return false;
          }
          return true;
        },
        child: _currentSection == SettingsSection.menu
            ? _buildMainMenu()
            : _currentSection == SettingsSection.aiProvider
                ? _buildAIProviderSection()
                : _currentSection == SettingsSection.appSettings
                    ? _buildAppSettingsSection()
                    : _buildDataManagementSection(),
      ),
    );
  }

  Widget _buildMainMenu() {
    return ListView(
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
        const SizedBox(height: 8),
        Text(
          'Choose a section to configure',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildMenuCard(
          context: context,
          title: 'AI Provider',
          subtitle: 'Configure Gemini, OpenAI, or Groq',
          icon: Icons.smart_toy,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Theme.of(context).colorScheme.primary,
          onTap: () {
            setState(() {
              _currentSection = SettingsSection.aiProvider;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: 'App Settings',
          subtitle: 'Customize app behavior and features',
          icon: Icons.settings_applications,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Theme.of(context).colorScheme.secondary,
          onTap: () {
            setState(() {
              _currentSection = SettingsSection.appSettings;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: 'Data Management',
          subtitle: 'Backup and restore your data',
          icon: Icons.cloud_sync,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Theme.of(context).colorScheme.tertiary,
          onTap: () {
            setState(() {
              _currentSection = SettingsSection.dataManagement;
            });
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIProviderSection() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // AI Provider Settings Section
        Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Active AI Provider',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<AIProvider>(
                    showSelectedIcon: false, // Remove checkmarks
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      selectedBackgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                      selectedForegroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    segments: [
                      ButtonSegment(
                        value: AIProvider.gemini, 
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 16),
                            SizedBox(width: 4),
                            Text('Gemini'),
                          ],
                        ),
                      ),
                      ButtonSegment(
                        value: AIProvider.openAI, 
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.psychology, size: 16),
                            SizedBox(width: 4),
                            Text('OpenAI'),
                          ],
                        ),
                      ),
                      ButtonSegment(
                        value: AIProvider.groq, 
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on, size: 16),
                            SizedBox(width: 4),
                            Text('Groq'),
                          ],
                        ),
                      ),
                    ],
                    selected: {_selectedProvider},
                    onSelectionChanged: (newSelection) {
                      final oldProvider = _selectedProvider;
                      final newProvider = newSelection.first;
                      
                      // Log settings change
                      AnalyticsService.logSettingsChange(
                        settingName: 'ai_provider',
                        newValue: newProvider.toString(),
                        oldValue: oldProvider.toString(),
                      );
                      
                      setState(() {
                        _selectedProvider = newProvider;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Gemini is recommended and free',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Display settings based on the selected provider.
                  ExpansionTile(
                    title: Text(
                      'Configure API Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('API keys, models, and configuration'),
                    leading: const Icon(Icons.tune),
                    initiallyExpanded: false,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            if (_selectedProvider == AIProvider.gemini)
                              _buildGeminiSettings()
                            else if (_selectedProvider == AIProvider.openAI)
                              _buildOpenAISettings()
                            else
                              _buildGroqSettings(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(modelProvider.notifier)
                              .resetModelsToDefaults();
                          context.showAccessibleMessage('Models reset to default.');
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: Tank management (including harmony score) and all calculators (tank volume calculator, etc.) work without an AI key.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildAppSettingsSection() {
    final appSettings = ref.watch(appSettingsProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // App Settings Section
        Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                          Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_applications,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'App Settings',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Show AI Stocking Button'),
                    subtitle: const Text('Display the full "AI Stocking Recommendations" button on tank cards. The option remains available in the menu.'),
                    value: appSettings.showStockingButton,
                    onChanged: (value) {
                      // Log settings change
                      AnalyticsService.logSettingsChange(
                        settingName: 'show_stocking_button',
                        newValue: value.toString(),
                        oldValue: appSettings.showStockingButton.toString(),
                      );
                      
                      ref.read(appSettingsProvider.notifier).setShowStockingButton(value);
                    },
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: Icon(
                      Icons.label,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Species Tags'),
                    subtitle: const Text('Manage searchable species names for fish types'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/species-tags');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Data Management Section
        Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                          Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_sync,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Data Management',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.backup,
                        color: Colors.blue,
                      ),
                    ),
                    title: const Text('Backup Data'),
                    subtitle: const Text('Save tanks and species tags to file'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _exportData(context, ref),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restore,
                        color: Colors.green,
                      ),
                    ),
                    title: const Text('Restore Data'),
                    subtitle: const Text('Load tanks and species tags from backup'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _importData(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.purple.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Gemini',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Google\'s most capable AI model',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              child: Text(
                'https://aistudio.google.com/app/apikey',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
              ),
            ),
            const Text('2. Sign in with your Google account.'),
            const Text(
                '3. Click "Create API key in new project" or "Get API key".'),
            const Text('4. Copy the generated API key and paste it above.'),
            InkWell(
              onTap: () =>
                  launchUrl(Uri.parse('https://www.merge.dev/blog/gemini-api-key')),
              child: Text(
                'See Guide',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpenAISettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.1),
                Colors.teal.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OpenAI',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'ChatGPT and GPT models by OpenAI',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _openAIApiKeyController,
          enabled: true,
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
              onPressed: () {
                setState(() {
                  _isOpenAIApiKeyVisible = !_isOpenAIApiKeyVisible;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _chatGPTModelController,
          enabled: true,
          decoration: const InputDecoration(
            labelText: 'ChatGPT Text Model',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _chatGPTImageModelController,
          enabled: true,
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
              onTap: () =>
                  launchUrl(Uri.parse('https://platform.openai.com/api-keys')),
              child: Text(
                'https://platform.openai.com/api-keys',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text('2. Sign in and create a new secret key.'),
            const Text('3. Copy the generated API key and paste it above.'),
            InkWell(
              onTap: () =>
                  launchUrl(Uri.parse('https://medium.com/@lorenzozar/how-to-get-your-own-openai-api-key-f4d44e60c327')),
              child: Text(
                'See Guide',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroqSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.1),
                Colors.red.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Groq',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Lightning-fast LLM inference',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
              onTap: () =>
                  launchUrl(Uri.parse('https://console.groq.com/keys')),
              child: Text(
                'https://console.groq.com/keys',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
              ),
            ),
            const Text('2. Sign in and navigate to the API Keys section.'),
            const Text('3. Click "Create API Key" to create a new secret key.'),
            const Text('4. Copy the generated API key and paste it above.'),
            InkWell(
              onTap: () =>
                  launchUrl(Uri.parse('https://docs.aicontentlabs.com/articles/groq-api-key/')),
              child: Text(
                'See Guide',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold),
              ),
            ),
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

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final tankNotifier = ref.read(tankProvider.notifier);
    final tankState = ref.read(tankProvider);

    // Show confirmation dialog with backup info
    final backupInfo = tankNotifier.createBackupInfo();
    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.blue),
            SizedBox(width: 8),
            Text('Backup Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will create a backup file containing:'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text('${backupInfo['tankCount']} tank(s)'),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('All fish and configurations'),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Species tags'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Export date: ${DateTime.now().toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The backup file will be saved to your device.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.backup),
            label: const Text('Create Backup'),
          ),
        ],
      ),
    );

    if (shouldExport == true && context.mounted) {
      final filePath = await tankNotifier.exportTanksToFile();
      
      if (context.mounted) {
        if (filePath != null) {
          context.showAccessibleMessage(
            'Backup created successfully!\nSaved to: ${filePath.split('/').last}',
            duration: const Duration(seconds: 4),
          );
          
          // Log backup action
          AnalyticsService.logFeatureUsed(
            featureName: 'settings_backup',
            parameters: {
              'tank_count': backupInfo['tankCount'],
              'source': 'settings_screen',
            },
          );
        } else {
          final error = ref.read(tankProvider).error;
          if (error != null) {
            context.showAccessibleMessage(
              'Failed to create backup: $error',
              duration: const Duration(seconds: 4),
            );
          }
        }
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    // Show warning dialog first
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.green),
            SizedBox(width: 8),
            Text('Restore Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Important',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Restoring from backup will:'),
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text('Replace ALL current tanks')),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text('Replace ALL species tags')),
              ],
            ),
            const SizedBox(height: 6),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text('Cannot be undone')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Make sure you have a current backup before proceeding.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.restore),
            label: const Text('Choose File'),
          ),
        ],
      ),
    );

    if (shouldImport == true && context.mounted) {
      final success = await ref.read(tankProvider.notifier).importTanksFromFile();
      
      if (context.mounted) {
        if (success) {
          context.showAccessibleMessage(
            'Data restored successfully!',
            duration: const Duration(seconds: 3),
          );
          
          // Log restore action
          AnalyticsService.logFeatureUsed(
            featureName: 'settings_restore',
            parameters: {
              'source': 'settings_screen',
            },
          );
        } else {
          final error = ref.read(tankProvider).error;
          if (error != null) {
            context.showAccessibleMessage(
              error,
              duration: const Duration(seconds: 4),
            );
          }
        }
      }
    }
  }
}