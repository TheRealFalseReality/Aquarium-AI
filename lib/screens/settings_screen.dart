import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../utils/dev_limits.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../providers/model_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/analytics_service.dart';
import '../utils/backup_restore_utils.dart';
import '../widgets/accessible_feedback.dart';

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
  AIProvider _selectedTextProvider = AIProvider.gemini;
  AIProvider _selectedImageProvider = AIProvider.gemini;

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
    _selectedTextProvider = models.activeTextProvider;
    _selectedImageProvider = models.activeImageProvider;
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

  void _showAIProviderDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.aiProvider,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: l10n.close,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _buildAIProviderContent(setDialogState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppSettingsDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_applications,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.appSettings,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: l10n.close,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _buildAppSettingsContent(setDialogState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDataManagementDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_sync,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.dataManagement,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: l10n.close,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _buildDataManagementContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// **Saves the settings after validation.**
  void _saveSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Validation Check: Ensure the API key for the selected text provider is not empty.
    if (_selectedTextProvider == AIProvider.gemini &&
        _geminiApiKeyController.text.trim().isEmpty) {
      context.showAccessibleMessage(l10n.enterGeminiApiKey);
      return; // Stop the function
    }
    if (_selectedTextProvider == AIProvider.openAI &&
        _openAIApiKeyController.text.trim().isEmpty) {
      context.showAccessibleMessage(l10n.enterOpenAIApiKey);
      return; // Stop the function
    }
    if (_selectedTextProvider == AIProvider.groq &&
        _groqApiKeyController.text.trim().isEmpty &&
        developerGroqApiKey.isEmpty) {
      context.showAccessibleMessage(l10n.enterGroqApiKey);
      return; // Stop the function
    }
    // Also validate API key for image provider if different from text provider
    if (_selectedImageProvider != _selectedTextProvider) {
      if (_selectedImageProvider == AIProvider.gemini &&
          _geminiApiKeyController.text.trim().isEmpty) {
        context.showAccessibleMessage(l10n.enterGeminiApiKey);
        return;
      }
      if (_selectedImageProvider == AIProvider.openAI &&
          _openAIApiKeyController.text.trim().isEmpty) {
        context.showAccessibleMessage(l10n.enterOpenAIApiKey);
        return;
      }
      if (_selectedImageProvider == AIProvider.groq &&
          _groqApiKeyController.text.trim().isEmpty &&
          developerGroqApiKey.isEmpty) {
        context.showAccessibleMessage(l10n.enterGroqApiKey);
        return;
      }
    }

    // Log settings save
    AnalyticsService.logFeatureUsed(
      featureName: 'settings_save',
      parameters: {
        'text_provider': _selectedTextProvider.toString(),
        'image_provider': _selectedImageProvider.toString(),
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
          newActiveTextProvider: _selectedTextProvider,
          newActiveImageProvider: _selectedImageProvider,
        );

    context.showAccessibleMessage(l10n.settingsUpdatedSuccess);
  }

  // Helper method to handle stocking button toggle
  void _handleStockingButtonToggle(bool value, StateSetter? setDialogState, AppSettingsState appSettings) {
    // Log settings change
    AnalyticsService.logSettingsChange(
      settingName: 'show_stocking_button',
      newValue: value.toString(),
      oldValue: appSettings.showStockingButton.toString(),
    );
    
    // Update the provider - this triggers ref.watch to rebuild
    ref.read(appSettingsProvider.notifier).setShowStockingButton(value);
    
    // Only call setDialogState if we're in a dialog, otherwise call setState
    // This prevents double updates that cause the double-tap behavior on mobile
    if (setDialogState != null) {
      setDialogState(() {});
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
      if (_selectedTextProvider != next.activeTextProvider) {
        setState(() {
          _selectedTextProvider = next.activeTextProvider;
        });
      }
      if (_selectedImageProvider != next.activeImageProvider) {
        setState(() {
          _selectedImageProvider = next.activeImageProvider;
        });
      }
    });

    return MainLayout(
      title: l10n.settings,
      child: _buildMainMenu(),
    );
  }

  Widget _buildMainMenu() {
    final l10n = AppLocalizations.of(context)!;
    final appSettings = ref.watch(appSettingsProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          l10n.settings,
          style: Theme.of(context)
              .textTheme
              .headlineLarge
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.chooseSection,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Enable AI toggle – lives directly on the root settings page
        Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: SwitchListTile(
            secondary: Icon(
              Icons.smart_toy_outlined,
              color: appSettings.enableAI
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(l10n.enableAI),
            subtitle: Text(l10n.enableAIDesc),
            value: appSettings.enableAI,
            onChanged: (value) {
              AnalyticsService.logSettingsChange(
                settingName: 'enable_ai',
                newValue: value.toString(),
                oldValue: appSettings.enableAI.toString(),
              );
              ref.read(appSettingsProvider.notifier).setEnableAI(value);
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: l10n.aiProvider,
          subtitle: l10n.configureAIProviders,
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
          onTap: () => _showAIProviderDialog(),
          enabled: appSettings.enableAI,
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: l10n.appSettings,
          subtitle: l10n.customizeAppBehavior,
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
          onTap: () => _showAppSettingsDialog(),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: l10n.dataManagement,
          subtitle: l10n.backupRestoreData,
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
          onTap: () => _showDataManagementDialog(),
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
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: InkWell(
          onTap: enabled ? onTap : null,
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
      ),
    );
  }

  Widget _buildAIProviderContent([StateSetter? setDialogState]) {
    final l10n = AppLocalizations.of(context)!;
    
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
                          l10n.activeAIProvider,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Text provider selector
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.textProvider,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<AIProvider>(
                    showSelectedIcon: false,
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
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 16),
                            const SizedBox(width: 4),
                            Text(l10n.gemini),
                          ],
                        ),
                      ),
                      ButtonSegment(
                        value: AIProvider.groq, 
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on, size: 16),
                            const SizedBox(width: 4),
                            Text(l10n.groq),
                          ],
                        ),
                      ),
                      ButtonSegment(
                        value: AIProvider.openAI, 
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology, size: 16),
                            const SizedBox(width: 4),
                            Text(l10n.openAI),
                          ],
                        ),
                      ),
                    ],
                    selected: {_selectedTextProvider},
                    onSelectionChanged: (newSelection) {
                      final oldProvider = _selectedTextProvider;
                      final newProvider = newSelection.first;
                      
                      AnalyticsService.logSettingsChange(
                        settingName: 'ai_text_provider',
                        newValue: newProvider.toString(),
                        oldValue: oldProvider.toString(),
                      );
                      
                      setState(() {
                        _selectedTextProvider = newProvider;
                      });
                      if (setDialogState != null) {
                        setDialogState(() {
                          _selectedTextProvider = newProvider;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Image provider selector
                  Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.imageProvider,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<AIProvider>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      selectedBackgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      selectedForegroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    segments: [
                      ButtonSegment(
                        value: AIProvider.gemini, 
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 16),
                            const SizedBox(width: 4),
                            Text(l10n.gemini),
                          ],
                        ),
                      ),
                      ButtonSegment(
                        value: AIProvider.groq, 
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on, size: 16),
                            const SizedBox(width: 4),
                            Text(l10n.groq),
                          ],
                        ),
                      ),
                      ButtonSegment(
                        value: AIProvider.openAI, 
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.psychology, size: 16),
                            const SizedBox(width: 4),
                            Text(l10n.openAI),
                          ],
                        ),
                      ),
                    ],
                    selected: {_selectedImageProvider},
                    onSelectionChanged: (newSelection) {
                      final oldProvider = _selectedImageProvider;
                      final newProvider = newSelection.first;
                      
                      AnalyticsService.logSettingsChange(
                        settingName: 'ai_image_provider',
                        newValue: newProvider.toString(),
                        oldValue: oldProvider.toString(),
                      );
                      
                      setState(() {
                        _selectedImageProvider = newProvider;
                      });
                      if (setDialogState != null) {
                        setDialogState(() {
                          _selectedImageProvider = newProvider;
                        });
                      }
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
                        const Icon(
                          Icons.star,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.geminiRecommended,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Free-tier rate limit notice (shown only when the developer key is active for at least one provider)
                  Builder(builder: (context) {
                    final models = ref.watch(modelProvider);
                    final devKeyInUse = models.usingDeveloperGroqKey &&
                        (models.activeTextProvider == AIProvider.groq ||
                            models.activeImageProvider == AIProvider.groq);
                    if (!devKeyInUse) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.speed, color: Colors.amber, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Free-tier limits',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '• $devMaxRequestsPerMinute AI requests per minute\n'
                            '• $devMaxPhotoAnalysesPerDay photo ${devMaxPhotoAnalysesPerDay == 1 ? 'analysis' : 'analyses'} per day',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Uses the fast llama-3.1-8b-instant model, which may not deliver the best results for text or image analysis.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'For best results, provide your own key. Recommended: llama-3.3-70b-versatile (text) and Gemini (image).',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Display settings for all providers that are in use
                  ..._buildProviderSettingsSections(setDialogState),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(modelProvider.notifier)
                              .resetModelsToDefaults();
                          context.showAccessibleMessage(l10n.modelsResetDefault);
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.resetModels),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _saveSettings(context), // Call the save function.
                        icon: const Icon(Icons.save),
                        label: Text(l10n.save),
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
    );
  }

  Widget _buildAppSettingsContent([StateSetter? setDialogState]) {
    final appSettings = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    
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
                          l10n.appSettings,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Language Selection
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(l10n.language),
                    subtitle: Text(_getLanguageDisplayName(appSettings.localeCode)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showLanguageDialog(setDialogState),
                  ),
                  const Divider(height: 24),
                  
                  SwitchListTile(
                    title: Text(l10n.showAIStockingButton),
                    subtitle: Text(l10n.showAIStockingButtonDesc),
                    value: appSettings.showStockingButton,
                    // Disable the toggle when AI is disabled
                    onChanged: appSettings.enableAI 
                      ? (value) => _handleStockingButtonToggle(value, setDialogState, appSettings)
                      : null,
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: Icon(
                      Icons.label,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(l10n.speciesTags),
                    subtitle: Text(l10n.speciesTagsDesc),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/species-tags');
                    },
                  ),
                  const Divider(height: 24),
                  
                  // Reset Remembered Reschedule Options
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.notifications_active,
                          color: appSettings.hasRememberedRescheduleOptions
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text(l10n.resetReschedulePreference),
                        subtitle: Text(
                          appSettings.hasRememberedRescheduleOptions
                              ? l10n.resetReschedulePreferenceDescActive
                              : l10n.resetReschedulePreferenceDescInactive,
                        ),
                      ),
                      if (appSettings.hasRememberedRescheduleOptions)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // Log settings change
                                AnalyticsService.logSettingsChange(
                                  settingName: 'reset_reschedule_preference',
                                  newValue: 'cleared',
                                  oldValue: 'set',
                                );
                                
                                await ref.read(appSettingsProvider.notifier).clearAllRememberedRescheduleOptions();
                                
                                if (context.mounted) {
                                  context.showAccessibleMessage(l10n.reschedulePreferenceCleared);
                                }
                                
                                if (setDialogState != null) {
                                  setDialogState(() {});
                                } else {
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.resetAll),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // Translation Community Section
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.2),
                          Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.translate,
                              color: Theme.of(context).colorScheme.tertiary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.translationCommunityTitle,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translationCommunityMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            launchUrl(Uri.parse('https://github.com/TheRealFalseReality/Aquarium-AI/blob/main/TRANSLATION_GUIDE.md'));
                          },
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text(l10n.visitGitHub),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.tertiary,
                            foregroundColor: Theme.of(context).colorScheme.onTertiary,
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
    );
  }

  Widget _buildDataManagementContent() {
    final l10n = AppLocalizations.of(context)!;
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadBackupStatistics(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        
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
                            l10n.dataManagement,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Backup Statistics
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.backupStatistics,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (stats['lastBackupTime'] != null) ...[
                              _buildStatRow(
                                context,
                                Icons.backup,
                                l10n.lastBackup,
                                stats['lastBackupTime'] as String,
                                Colors.blue,
                              ),
                              if (stats['lastBackupTankCount'] != null) ...[
                                const SizedBox(height: 8),
                                _buildStatRow(
                                  context,
                                  Icons.water_drop,
                                  l10n.tanksBackedUp,
                                  '${stats['lastBackupTankCount']} tank(s)',
                                  Colors.cyan,
                                ),
                              ],
                            ],
                            if (stats['lastRestoreTime'] != null) ...[
                              if (stats['lastBackupTime'] != null) const SizedBox(height: 8),
                              _buildStatRow(
                                context,
                                Icons.restore,
                                l10n.lastRestore,
                                stats['lastRestoreTime'] as String,
                                Colors.green,
                              ),
                            ],
                            if (stats['lastBackupTime'] == null && stats['lastRestoreTime'] == null)
                              Text(
                                l10n.noBackupHistory,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    
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
                      title: Text(l10n.backupData),
                      subtitle: Text(l10n.backupDataDesc),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await BackupRestoreUtils.exportData(context, ref, source: 'settings');
                        // Rebuild to refresh statistics
                        if (mounted) setState(() {});
                      },
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
                      title: Text(l10n.restoreData),
                      subtitle: Text(l10n.restoreDataDesc),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await BackupRestoreUtils.importData(context, ref, source: 'settings');
                        // Rebuild to refresh statistics
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(BuildContext context, IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _loadBackupStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = <String, dynamic>{};
      
      final lastBackupTimeStr = prefs.getString('last_backup_time');
      if (lastBackupTimeStr != null) {
        final lastBackupTime = DateTime.parse(lastBackupTimeStr);
        stats['lastBackupTime'] = _formatDateTime(lastBackupTime);
        
        final lastBackupTankCount = prefs.getInt('last_backup_tank_count');
        if (lastBackupTankCount != null) {
          stats['lastBackupTankCount'] = lastBackupTankCount;
        }
      }
      
      final lastRestoreTimeStr = prefs.getString('last_restore_time');
      if (lastRestoreTimeStr != null) {
        final lastRestoreTime = DateTime.parse(lastRestoreTimeStr);
        stats['lastRestoreTime'] = _formatDateTime(lastRestoreTime);
      }
      
      return stats;
    } catch (e) {
      return {};
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      // Format as date
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final year = dateTime.year;
      return '$month/$day/$year';
    }
  }

  /// Builds provider settings sections for all providers in use (text and/or image).
  /// Shows each provider's section at most once even if selected for both.
  List<Widget> _buildProviderSettingsSections([StateSetter? setDialogState]) {
    final selectedProviders = <AIProvider>{_selectedTextProvider, _selectedImageProvider};
    final widgets = <Widget>[];
    for (final provider in AIProvider.values) {
      if (selectedProviders.contains(provider)) {
        switch (provider) {
          case AIProvider.gemini:
            widgets.add(_buildGeminiSettings(setDialogState));
            break;
          case AIProvider.openAI:
            widgets.add(_buildOpenAISettings(setDialogState));
            break;
          case AIProvider.groq:
            widgets.add(_buildGroqSettings(setDialogState));
            break;
        }
      }
    }
    return widgets;
  }

  Widget _buildGeminiSettings([StateSetter? setDialogState]) {
    final l10n = AppLocalizations.of(context)!;
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
                final newVisibility = !_isGeminiApiKeyVisible;
                setState(() {
                  _isGeminiApiKeyVisible = newVisibility;
                });
                if (setDialogState != null) {
                  setDialogState(() {
                    _isGeminiApiKeyVisible = newVisibility;
                  });
                }
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
            Text(l10n.googleAIStudioStep1),
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
            Text(l10n.googleAIStudioStep2),
            Text(l10n.googleAIStudioStep3),
            Text(l10n.googleAIStudioStep4),
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
        const SizedBox(height: 8),
        _buildApiKeyGuide(
          title: 'Gemini Models & Rate Limits:',
          children: [
            const Text('View available models and free-tier rate limits:'),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://ai.google.dev/gemini-api/docs/models/gemini')),
              child: Text(
                'ai.google.dev/gemini-api/docs/models/gemini',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://ai.google.dev/gemini-api/docs/rate-limits')),
              child: Text(
                'Rate Limits',
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

  Widget _buildOpenAISettings([StateSetter? setDialogState]) {
    final l10n = AppLocalizations.of(context)!;
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
                final newVisibility = !_isOpenAIApiKeyVisible;
                setState(() {
                  _isOpenAIApiKeyVisible = newVisibility;
                });
                if (setDialogState != null) {
                  setDialogState(() {
                    _isOpenAIApiKeyVisible = newVisibility;
                  });
                }
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
            Text(l10n.openAIStep1),
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
            Text(l10n.openAIStep2),
            Text(l10n.openAIStep3),
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
        const SizedBox(height: 8),
        _buildApiKeyGuide(
          title: 'OpenAI Models & Rate Limits:',
          children: [
            const Text('View available models and usage limits:'),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://platform.openai.com/docs/models')),
              child: Text(
                'platform.openai.com/docs/models',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://platform.openai.com/docs/guides/rate-limits')),
              child: Text(
                'Rate Limits',
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

  Widget _buildGroqSettings([StateSetter? setDialogState]) {
    final l10n = AppLocalizations.of(context)!;
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
            labelText: developerGroqApiKey.isNotEmpty
                ? 'Groq API Key (Optional)'
                : 'Groq API Key',
            border: const OutlineInputBorder(),
            helperText: developerGroqApiKey.isNotEmpty
                ? 'Add your own key for dedicated rate limits and better performance.'
                : null,
            helperMaxLines: 2,
            suffixIcon: IconButton(
              icon: Icon(
                _isGroqApiKeyVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                final newVisibility = !_isGroqApiKeyVisible;
                setState(() {
                  _isGroqApiKeyVisible = newVisibility;
                });
                if (setDialogState != null) {
                  setDialogState(() {
                    _isGroqApiKeyVisible = newVisibility;
                  });
                }
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
            helperText: 'Must be a vision-capable model for photo analysis (e.g. meta-llama/llama-4-scout-17b-16e-instruct)',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 16),
        _buildApiKeyGuide(
          title: 'How to get your Groq API key:',
          children: [
            Text(l10n.groqCloudStep1),
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
            Text(l10n.groqCloudStep2),
            Text(l10n.groqCloudStep3),
            Text(l10n.groqCloudStep4),
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
        const SizedBox(height: 8),
        _buildApiKeyGuide(
          title: 'Groq Models & Rate Limits:',
          children: [
            const Text('View available models and free-tier rate limits:'),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://console.groq.com/docs/models')),
              child: Text(
                'console.groq.com/docs/models',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://console.groq.com/docs/rate-limits')),
              child: Text(
                'Rate Limits',
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

  String _getLanguageDisplayName(String? localeCode) {
    final l10n = AppLocalizations.of(context)!;
    
    if (localeCode == null) {
      return l10n.languageSystemDefault;
    }
    
    switch (localeCode) {
      case 'en':
        return l10n.languageEnglish;
      case 'es':
        return l10n.languageSpanish;
      case 'fr':
        return l10n.languageFrench;
      case 'de':
        return l10n.languageGerman;
      default:
        return l10n.languageSystemDefault;
    }
  }

  void _showLanguageDialog([StateSetter? parentSetDialogState]) {
    final l10n = AppLocalizations.of(context)!;
    final appSettings = ref.read(appSettingsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: Text(l10n.languageSystemDefault),
              value: null,
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setLocale(value);
                
                // Log settings change
                AnalyticsService.logSettingsChange(
                  settingName: 'language',
                  newValue: 'system',
                  oldValue: appSettings.localeCode ?? 'system',
                );
                
                Navigator.of(context).pop();
                if (parentSetDialogState != null) {
                  parentSetDialogState(() {});
                }
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setLocale(value);
                
                // Log settings change
                AnalyticsService.logSettingsChange(
                  settingName: 'language',
                  newValue: value ?? 'system',
                  oldValue: appSettings.localeCode ?? 'system',
                );
                
                Navigator.of(context).pop();
                if (parentSetDialogState != null) {
                  parentSetDialogState(() {});
                }
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageSpanish),
              value: 'es',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setLocale(value);
                
                // Log settings change
                AnalyticsService.logSettingsChange(
                  settingName: 'language',
                  newValue: value ?? 'system',
                  oldValue: appSettings.localeCode ?? 'system',
                );
                
                Navigator.of(context).pop();
                if (parentSetDialogState != null) {
                  parentSetDialogState(() {});
                }
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageFrench),
              value: 'fr',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setLocale(value);
                
                // Log settings change
                AnalyticsService.logSettingsChange(
                  settingName: 'language',
                  newValue: value ?? 'system',
                  oldValue: appSettings.localeCode ?? 'system',
                );
                
                Navigator.of(context).pop();
                if (parentSetDialogState != null) {
                  parentSetDialogState(() {});
                }
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageGerman),
              value: 'de',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setLocale(value);
                
                // Log settings change
                AnalyticsService.logSettingsChange(
                  settingName: 'language',
                  newValue: value ?? 'system',
                  oldValue: appSettings.localeCode ?? 'system',
                );
                
                Navigator.of(context).pop();
                if (parentSetDialogState != null) {
                  parentSetDialogState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

}
