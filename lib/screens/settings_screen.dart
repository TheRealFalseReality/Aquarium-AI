import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main_layout.dart';
import '../providers/model_provider.dart';
import '../providers/prompt_provider.dart';

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
  bool _isOpenAIApiKeyVisible = false;
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
    if (_selectedProvider == AIProvider.openAI &&
        _openAIApiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter an OpenAI API key before saving.')),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Active AI Provider',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
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
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Gemini is recommended and free.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          // Prompt Settings Card
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'AI Prompt Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Customize the prompts used by the AI for different tasks.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPromptSettings(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _showResetPromptsDialog();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset All Prompts'),
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

  Widget _buildGeminiSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Google Gemini Settings',
            style: Theme.of(context).textTheme.titleLarge,
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
                    decoration: TextDecoration.underline),
              ),
            ),
            const Text('2. Sign in with your Google account.'),
            const Text(
                '3. Click "Create API key in new project" or "Get API key".'),
            const Text('4. Copy the generated API key and paste it above.'),
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
        const SizedBox(height: 24),
        Center(
          child: Text(
            'OpenAI Settings',
            style: Theme.of(context).textTheme.titleLarge,
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
                    decoration: TextDecoration.underline),
              ),
            ),
            const Text('2. Sign in and create a new secret key.'),
            const Text('3. Copy the generated API key and paste it above.'),
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
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Groq Settings',
            style: Theme.of(context).textTheme.titleLarge,
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
                    decoration: TextDecoration.underline),
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

  Widget _buildPromptSettings() {
    return Consumer(
      builder: (context, ref, child) {
        final promptState = ref.watch(promptProvider);
        final promptNotifier = ref.read(promptProvider.notifier);
        final promptTitles = promptNotifier.getPromptTitles();
        
        if (promptState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: PromptType.values.map((promptType) {
            final title = promptTitles[promptType] ?? promptType.name;
            final hasCustom = promptNotifier.hasCustomPrompt(promptType);
            
            // Disable system prompt editing
            final isSystemPrompt = promptType == PromptType.system;
            final isDisabled = isSystemPrompt;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(title),
                          if (isSystemPrompt) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'DISABLED',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasCustom && !isDisabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Custom',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                children: [
                  _buildPromptEditor(promptType, ref),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPromptEditor(PromptType promptType, WidgetRef ref) {
    final promptNotifier = ref.read(promptProvider.notifier);
    final currentPrompt = promptNotifier.getPrompt(promptType);
    final defaultPrompt = promptNotifier.getDefaultPrompt(promptType);
    final hasCustom = promptNotifier.hasCustomPrompt(promptType);
    
    // Disable system prompt editing
    final isSystemPrompt = promptType == PromptType.system;
    final isDisabled = isSystemPrompt;
    
    final TextEditingController controller = TextEditingController(text: currentPrompt);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isSystemPrompt) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'System Prompt editing is disabled for security reasons',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!isSystemPrompt && !hasCustom) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'USE WITH CAUTION!! Modifying prompts may affect AI behavior',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  hasCustom && !isDisabled ? 'Custom Prompt' : 'Default Prompt (Read-only)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (hasCustom && !isDisabled)
                TextButton.icon(
                  onPressed: () {
                    _showRestorePromptDialog(promptType, ref);
                  },
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Restore Default'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              readOnly: true, // Always read-only, editing happens in dialog
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                hintText: hasCustom && !isDisabled ? 'Custom prompt (click Edit to modify)' : 'Default prompt (read-only)',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!hasCustom && !isDisabled)
            ElevatedButton.icon(
              onPressed: () {
                _showPromptEditor(promptType, ref);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Create Custom Version'),
            )
          else if (hasCustom && !isDisabled)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showPromptEditor(promptType, ref);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showPromptPreview(promptType, controller.text);
                    },
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                  ),
                ),
              ],
            ),
          if ((hasCustom || isSystemPrompt) && !isDisabled) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('View Default Prompt'),
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      defaultPrompt,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isSystemPrompt) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('View System Prompt'),
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      defaultPrompt,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRestorePromptDialog(PromptType promptType, WidgetRef ref) {
    final promptTitles = ref.read(promptProvider.notifier).getPromptTitles();
    final title = promptTitles[promptType] ?? promptType.name;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Default Prompt'),
        content: Text('Are you sure you want to restore the default prompt for "$title"? This will delete your custom prompt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(promptProvider.notifier).resetPromptToDefault(promptType);
              Navigator.of(context).pop();
              setState(() {}); // Force rebuild
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title restored to default')),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showResetPromptsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Prompts'),
        content: const Text('Are you sure you want to reset all prompts to their defaults? This will delete all your custom prompts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(promptProvider.notifier).resetAllPromptsToDefaults();
              Navigator.of(context).pop();
              setState(() {}); // Force rebuild
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All prompts reset to defaults')),
              );
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _showPromptPreview(PromptType promptType, String prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prompt Preview'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(prompt),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPromptEditor(PromptType promptType, WidgetRef ref) {
    final promptNotifier = ref.read(promptProvider.notifier);
    final promptTitles = promptNotifier.getPromptTitles();
    final title = promptTitles[promptType] ?? promptType.name;
    final defaultPrompt = promptNotifier.getDefaultPrompt(promptType);
    
    // Use existing custom prompt if available, otherwise use default
    final initialPrompt = promptNotifier.hasCustomPrompt(promptType) 
        ? promptNotifier.getPrompt(promptType)
        : defaultPrompt;
    
    final TextEditingController editorController = TextEditingController(text: initialPrompt);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit $title',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'USE WITH CAUTION!! Modifying prompts may affect AI behavior',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Template Variables:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Use variables like {userNote}, {temp}, {tempUnit}, {tankType}, etc. in your prompt. These will be replaced with actual values when the prompt is used.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: editorController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintText: 'Enter your custom prompt here...',
                    ),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final customPrompt = editorController.text.trim();
                        if (customPrompt.isNotEmpty) {
                          await promptNotifier.setCustomPrompt(promptType, customPrompt);
                          Navigator.of(context).pop();
                          setState(() {}); // Force rebuild
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Custom $title saved and is now active!')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Prompt cannot be empty')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save & Use'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}