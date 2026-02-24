import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../providers/model_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/remote_config_service.dart';
import '../utils/backup_restore_utils.dart';
import '../widgets/accessible_feedback.dart';
import 'changelog_screen.dart';

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
  bool _useDevGroqKeyForText = false;
  bool _useDevGroqKeyForImage = false;
  int _chatHistoryLimit = defaultChatHistoryLimit;

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
    _chatHistoryLimit = models.chatHistoryLimit;
    _useDevGroqKeyForText = models.useDevGroqKeyForText;
    _useDevGroqKeyForImage = models.useDevGroqKeyForImage;

    // Auto-open the Remove Ads dialog if requested via route arguments.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['openRemoveAds'] == true) {
        _showRemoveAdsDialog();
      }
    });
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
    // Reset local state to match the last-persisted provider state so that
    // any unsaved changes from a previous (abandoned) dialog session are
    // discarded before the dialog opens.
    final models = ref.read(modelProvider);
    setState(() {
      _selectedTextProvider = models.activeTextProvider;
      _selectedImageProvider = models.activeImageProvider;
      _useDevGroqKeyForText = models.useDevGroqKeyForText;
      _useDevGroqKeyForImage = models.useDevGroqKeyForImage;
      _groqModelController.text = models.groqModel;
      _groqImageModelController.text = models.groqImageModel;
      _groqApiKeyController.text = models.groqApiKey;
      _geminiModelController.text = models.geminiModel;
      _geminiImageModelController.text = models.geminiImageModel;
      _geminiApiKeyController.text = models.geminiApiKey;
      _chatGPTModelController.text = models.chatGPTModel;
      _chatGPTImageModelController.text = models.chatGPTImageModel;
      _openAIApiKeyController.text = models.openAIApiKey;
      _chatHistoryLimit = models.chatHistoryLimit;
    });

    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _handleDialogClose(dialogContext, setDialogState);
          },
          child: Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: SizedBox(
              width: MediaQuery.of(dialogContext).size.width,
              height: MediaQuery.of(dialogContext).size.height * 0.9,
              child: Column(
                children: [
                  // Header with close button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(dialogContext).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: Theme.of(dialogContext).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.aiProvider,
                            style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _handleDialogClose(dialogContext, setDialogState),
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
  /// Saves Text/Chat provider settings independently (validates text key only).
  void _saveTextSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveFreeText = RemoteConfigService.freeAiEnabled && _useDevGroqKeyForText;

    if (!effectiveFreeText) {
      if (_selectedTextProvider == AIProvider.gemini &&
          _geminiApiKeyController.text.trim().isEmpty) {
        context.showAccessibleMessage(l10n.enterGeminiApiKey);
        return;
      }
      if (_selectedTextProvider == AIProvider.openAI &&
          _openAIApiKeyController.text.trim().isEmpty) {
        context.showAccessibleMessage(l10n.enterOpenAIApiKey);
        return;
      }
      if (_selectedTextProvider == AIProvider.groq &&
          _groqApiKeyController.text.trim().isEmpty) {
        context.showAccessibleMessage(l10n.enterGroqApiKey);
        return;
      }
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'settings_save_text',
      parameters: {
        'text_provider': _selectedTextProvider.toString(),
        'has_api_key': 'true',
      },
    );

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
          newChatHistoryLimit: _chatHistoryLimit,
          newUseDevGroqKeyForText: _useDevGroqKeyForText,
          newUseDevGroqKeyForImage: _useDevGroqKeyForImage,
        );

    CrashlyticsService.setAITextProvider(_selectedTextProvider.name);
    final textModel = switch (_selectedTextProvider) {
      AIProvider.gemini => _geminiModelController.text,
      AIProvider.openAI => _chatGPTModelController.text,
      AIProvider.groq => _groqModelController.text,
    };
    CrashlyticsService.setAITextModel(textModel);

    context.showAccessibleMessage(l10n.settingsUpdatedSuccess);
  }

  /// Saves Image/Multimedia provider settings independently (validates image key only).
  void _saveImageSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveFreeImage = RemoteConfigService.freeAiEnabled && _useDevGroqKeyForImage;

    if (!effectiveFreeImage) {
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
          _groqApiKeyController.text.trim().isEmpty) {
        context.showAccessibleMessage(l10n.enterGroqApiKey);
        return;
      }
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'settings_save_image',
      parameters: {
        'image_provider': _selectedImageProvider.toString(),
        'has_api_key': 'true',
      },
    );

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
          newChatHistoryLimit: _chatHistoryLimit,
          newUseDevGroqKeyForText: _useDevGroqKeyForText,
          newUseDevGroqKeyForImage: _useDevGroqKeyForImage,
        );

    CrashlyticsService.setAIImageProvider(_selectedImageProvider.name);
    final imageModel = switch (_selectedImageProvider) {
      AIProvider.gemini => _geminiImageModelController.text,
      AIProvider.openAI => _chatGPTImageModelController.text,
      AIProvider.groq => _groqImageModelController.text,
    };
    CrashlyticsService.setAIImageModel(imageModel);

    context.showAccessibleMessage(l10n.settingsUpdatedSuccess);
  }

  /// Returns a list of validation error messages for the current dialog state.
  /// A key is required for a provider when its Free AI toggle is OFF and that
  /// provider is currently selected for text or image use.
  /// When freeAiEnabled is false, Free AI is treated as OFF regardless of toggle state.
  List<String> _getValidationErrors() {
    final l10n = AppLocalizations.of(context)!;
    final errors = <String>[];
    final effectiveFreeText = RemoteConfigService.freeAiEnabled && _useDevGroqKeyForText;
    final effectiveFreeImage = RemoteConfigService.freeAiEnabled && _useDevGroqKeyForImage;

    // Gemini key required when selected (text or image) and Free AI is off
    final geminiNeededForText =
        !effectiveFreeText && _selectedTextProvider == AIProvider.gemini;
    final geminiNeededForImage =
        !effectiveFreeImage && _selectedImageProvider == AIProvider.gemini;
    if ((geminiNeededForText || geminiNeededForImage) &&
        _geminiApiKeyController.text.trim().isEmpty) {
      errors.add(l10n.enterGeminiApiKey);
    }

    // OpenAI key required when selected (text or image) and Free AI is off
    final openAINeededForText =
        !effectiveFreeText && _selectedTextProvider == AIProvider.openAI;
    final openAINeededForImage =
        !effectiveFreeImage && _selectedImageProvider == AIProvider.openAI;
    if ((openAINeededForText || openAINeededForImage) &&
        _openAIApiKeyController.text.trim().isEmpty) {
      errors.add(l10n.enterOpenAIApiKey);
    }

    // Groq key required when selected (text or image) and Free AI is off
    final groqNeededForText =
        !effectiveFreeText && _selectedTextProvider == AIProvider.groq;
    final groqNeededForImage =
        !effectiveFreeImage && _selectedImageProvider == AIProvider.groq;
    if ((groqNeededForText || groqNeededForImage) &&
        _groqApiKeyController.text.trim().isEmpty) {
      errors.add(l10n.enterGroqApiKey);
    }

    return errors;
  }

  /// Saves all three API keys (and full provider/model state).
  /// Returns true on success, false if validation fails.
  bool _saveApiKeys(BuildContext context, [StateSetter? setDialogState]) {
    final errors = _getValidationErrors();
    if (errors.isNotEmpty) {
      context.showAccessibleMessage(errors.first);
      return false;
    }
    final l10n = AppLocalizations.of(context)!;
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
          newChatHistoryLimit: _chatHistoryLimit,
          newUseDevGroqKeyForText: _useDevGroqKeyForText,
          newUseDevGroqKeyForImage: _useDevGroqKeyForImage,
        );
    context.showAccessibleMessage(l10n.settingsUpdatedSuccess);
    setDialogState?.call(() {});
    return true;
  }

  /// Clears one API key after a confirmation dialog, bypassing validation.
  /// [keyName] must be 'geminiApiKey', 'openAIApiKey', or 'groqApiKey'.
  Future<void> _clearApiKey(
    BuildContext context,
    String keyName,
    String label, [
    StateSetter? setDialogState,
  ]) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear API Key'),
        content: Text('Are you sure you want to clear the $label? You will need to re-enter the key to use it again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Clear the controller and persist immediately (no validation).
    switch (keyName) {
      case 'geminiApiKey':
        _geminiApiKeyController.clear();
      case 'openAIApiKey':
        _openAIApiKeyController.clear();
      case 'groqApiKey':
        _groqApiKeyController.clear();
    }
    setState(() {});
    setDialogState?.call(() {});
    await ref.read(modelProvider.notifier).clearApiKey(keyName);
    if (context.mounted) {
      context.showAccessibleMessage('$label cleared.');
    }
  }

  /// Returns true if any field in the AI Provider dialog differs from saved state.
  bool _hasUnsavedChanges() {
    final saved = ref.read(modelProvider);
    return _selectedTextProvider != saved.activeTextProvider ||
        _selectedImageProvider != saved.activeImageProvider ||
        _geminiModelController.text != saved.geminiModel ||
        _geminiImageModelController.text != saved.geminiImageModel ||
        _chatGPTModelController.text != saved.chatGPTModel ||
        _chatGPTImageModelController.text != saved.chatGPTImageModel ||
        _groqModelController.text != saved.groqModel ||
        _groqImageModelController.text != saved.groqImageModel ||
        _geminiApiKeyController.text != saved.geminiApiKey ||
        _openAIApiKeyController.text != saved.openAIApiKey ||
        _groqApiKeyController.text != saved.groqApiKey;
  }

  /// Shows an "Unsaved Changes" alert if there are pending changes, otherwise pops.
  void _handleDialogClose(BuildContext dialogContext, [StateSetter? setDialogState]) {
    if (!_hasUnsavedChanges()) {
      Navigator.of(dialogContext).pop();
      return;
    }

    final saved = ref.read(modelProvider);
    final providerChanged = _selectedTextProvider != saved.activeTextProvider;
    final imageProviderChanged = _selectedImageProvider != saved.activeImageProvider;
    final textModelChanged = _geminiModelController.text != saved.geminiModel ||
        _chatGPTModelController.text != saved.chatGPTModel ||
        _groqModelController.text != saved.groqModel;
    final imageModelChanged = _geminiImageModelController.text != saved.geminiImageModel ||
        _chatGPTImageModelController.text != saved.chatGPTImageModel ||
        _groqImageModelController.text != saved.groqImageModel;
    final keysChanged = _geminiApiKeyController.text != saved.geminiApiKey ||
        _openAIApiKeyController.text != saved.openAIApiKey ||
        _groqApiKeyController.text != saved.groqApiKey;
    final validationErrors = _getValidationErrors();

    showDialog<void>(
      context: dialogContext,
      builder: (alertContext) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (providerChanged) const Text('• Text provider changed'),
            if (imageProviderChanged) const Text('• Image provider changed'),
            if (textModelChanged) const Text('• Text model changed'),
            if (imageModelChanged) const Text('• Image model changed'),
            if (keysChanged) const Text('• API keys updated'),
            if (validationErrors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade700, size: 16),
                const SizedBox(width: 6),
                Text('Cannot save — fix these first:',
                    style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ]),
              ...validationErrors.map((e) => Text('  • $e',
                  style: TextStyle(color: Colors.amber.shade900, fontSize: 12))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(alertContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Discard'),
            onPressed: () {
              Navigator.of(alertContext).pop();
              Navigator.of(dialogContext).pop();
            },
          ),
          if (validationErrors.isEmpty)
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save All & Close'),
              onPressed: () {
                final saved = _saveApiKeys(dialogContext, setDialogState);
                Navigator.of(alertContext).pop();
                if (saved) Navigator.of(dialogContext).pop();
              },
            ),
        ],
      ),
    );
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
      if (_useDevGroqKeyForText != next.useDevGroqKeyForText ||
          _useDevGroqKeyForImage != next.useDevGroqKeyForImage) {
        setState(() {
          _useDevGroqKeyForText = next.useDevGroqKeyForText;
          _useDevGroqKeyForImage = next.useDevGroqKeyForImage;
        });
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
      if (_chatHistoryLimit != next.chatHistoryLimit) {
        setState(() {
          _chatHistoryLimit = next.chatHistoryLimit;
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
    final models = ref.watch(modelProvider);
    
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
              CrashlyticsService.setAIEnabled(value);
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
        // Indicator: show when the app is using the built-in dev API key
        if (appSettings.enableAI && models.usingDeveloperGroqKeyForAny) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using App\'s Built-in Dev API Key (Groq free tier). '
                    'Add your own Groq key in AI Provider settings for dedicated limits.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Warning: shown when the free AI tier is disabled server-side but the
        // user has no own Groq key configured.
        if (appSettings.enableAI &&
            !RemoteConfigService.freeAiEnabled &&
            !models.hasGroqKey) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.block, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The free AI tier is currently unavailable. '
                    'Please add your own Groq API key in AI Provider settings to continue using AI features.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        _buildRemoveAdsCard(context),
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
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: l10n.changelog,
          subtitle: l10n.changelogDesc,
          icon: Icons.new_releases,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Theme.of(context).colorScheme.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChangelogScreen(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: l10n.submitIssue,
          subtitle: l10n.submitIssueDesc,
          icon: Icons.bug_report,
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.25),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Colors.orange.shade700,
          onTap: () => launchUrl(
            Uri.parse('https://github.com/TheRealFalseReality/Aquarium-AI/issues'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRemoveAdsCard(BuildContext context) {
    final purchaseState = ref.watch(purchaseProvider);
    if (purchaseState.adsRemoved) {
      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.25),
                      Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.block, color: Colors.green, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ads Removed',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thank you for your support!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ],
          ),
        ),
      );
    }
    return _buildMenuCard(
      context: context,
      title: 'Remove Ads',
      subtitle: 'Support the app with a one-time purchase',
      icon: Icons.block,
      gradient: LinearGradient(
        colors: [
          Colors.green.withOpacity(0.25),
          Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconColor: Colors.green.shade700,
      onTap: () => _showRemoveAdsDialog(),
    );
  }

  void _showRemoveAdsDialog() {
    showDialog(
      context: context,
      builder: (context) => _RemoveAdsDialog(
        onBuy: () => ref.read(purchaseProvider.notifier).buyRemoveAds(),
        onRestore: () => ref.read(purchaseProvider.notifier).restorePurchases(),
      ),
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

    // ─── Segmented button style helpers ───────────────────────────────────────
    SegmentedButton<AIProvider> providerButton({
      required Set<AIProvider> selected,
      required ValueChanged<Set<AIProvider>> onChanged,
      Color? selectedBg,
      Color? selectedFg,
    }) =>
        SegmentedButton<AIProvider>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            selectedBackgroundColor:
                selectedBg ?? Theme.of(context).colorScheme.tertiaryContainer,
            selectedForegroundColor:
                selectedFg ?? Theme.of(context).colorScheme.onTertiaryContainer,
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              width: 1,
            ),
          ),
          segments: [
            ButtonSegment(
              value: AIProvider.gemini,
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome, size: 16),
                const SizedBox(width: 4),
                Text(l10n.gemini),
              ]),
            ),
            ButtonSegment(
              value: AIProvider.groq,
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.flash_on, size: 16),
                const SizedBox(width: 4),
                Text(l10n.groq),
              ]),
            ),
            ButtonSegment(
              value: AIProvider.openAI,
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.psychology, size: 16),
                const SizedBox(width: 4),
                Text(l10n.openAI),
              ]),
            ),
          ],
          selected: selected,
          onSelectionChanged: onChanged,
        );

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ─── Free-tier notice (collapsible; always shown when a dev key is available) ──
        if (RemoteConfigService.freeAiEnabled) Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: RemoteConfigService.freeAiEnabled
                    ? Colors.amber.withOpacity(0.1)
                    : Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: RemoteConfigService.freeAiEnabled
                      ? Colors.amber.withOpacity(0.4)
                      : Colors.red.withOpacity(0.4),
                ),
              ),
              child: RemoteConfigService.freeAiEnabled
                  ? ExpansionTile(
                      leading: const Icon(Icons.speed, color: Colors.amber, size: 20),
                      title: Text(
                        'Free-tier limits',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      // Collapsed subtitle: just the key numbers (from Remote Config)
                      subtitle: Text(
                        '${RemoteConfigService.maxRequestsPerDay} req/day  •  ${RemoteConfigService.maxRequestsPerMinute} req/min  •  ${RemoteConfigService.maxPhotoAnalysesPerDay} photo/day',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.amber.shade700,
                            ),
                      ),
                      initiallyExpanded: false,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${RemoteConfigService.maxRequestsPerMinute} AI requests per minute\n'
                          '• ${RemoteConfigService.maxRequestsPerDay} AI requests per day\n'
                          '• ${RemoteConfigService.maxPhotoAnalysesPerDay} photo ${RemoteConfigService.maxPhotoAnalysesPerDay == 1 ? 'analysis' : 'analyses'} per day\n'
                          '• ${RemoteConfigService.freeTierChatHistoryLimit}-message chat history per request',
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
                        const SizedBox(height: 8),
                        Text(
                          '⚠️ Disclaimer: The in-app free AI is provided as a courtesy for aquarium lovers and is funded by the developer. It may be removed or modified at any time, and limits are subject to change without notice.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade800,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    )
                  : ListTile(
                      leading: const Icon(Icons.block, color: Colors.red, size: 20),
                      title: Text(
                        'Free AI tier currently unavailable',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      subtitle: Text(
                        'The built-in free AI provider has been disabled by the developer. Please add your own API key below to continue using AI features.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                            ),
                      ),
                    ),
            ),
          ),
        // ─── Free AI toggles (global) ─────────────────────────────────────
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(Icons.bolt, size: 20, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Free AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  'Use the built-in free AI service instead of your own API key.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                _buildDevKeyToggle(
                  label: 'Use Free AI for Text / Chat',
                  value: RemoteConfigService.freeAiEnabled && _useDevGroqKeyForText,
                  onChanged: RemoteConfigService.freeAiEnabled
                      ? (v) {
                          setState(() {
                            _useDevGroqKeyForText = v;
                            // When Free AI is ON, force provider to Groq so free tier is used.
                            if (v) _selectedTextProvider = AIProvider.groq;
                          });
                          setDialogState?.call(() {
                            _useDevGroqKeyForText = v;
                            if (v) _selectedTextProvider = AIProvider.groq;
                          });
                          // Auto-save immediately so root menu and providers reflect state.
                          ref.read(modelProvider.notifier).setDevGroqKeyToggles(
                                forText: v,
                                forImage: _useDevGroqKeyForImage,
                              );
                        }
                      : null,
                ),
                const SizedBox(height: 8),
                _buildDevKeyToggle(
                  label: 'Use Free AI for Image / Photo',
                  value: RemoteConfigService.freeAiEnabled && _useDevGroqKeyForImage,
                  onChanged: RemoteConfigService.freeAiEnabled
                      ? (v) {
                          setState(() {
                            _useDevGroqKeyForImage = v;
                            // When Free AI is ON, force provider to Groq so free tier is used.
                            if (v) _selectedImageProvider = AIProvider.groq;
                          });
                          setDialogState?.call(() {
                            _useDevGroqKeyForImage = v;
                            if (v) _selectedImageProvider = AIProvider.groq;
                          });
                          // Auto-save immediately so root menu and providers reflect state.
                          ref.read(modelProvider.notifier).setDevGroqKeyToggles(
                                forText: _useDevGroqKeyForText,
                                forImage: v,
                              );
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ─── Consolidated API Keys ────────────────────────────────────────
        if (!_useDevGroqKeyForText || !_useDevGroqKeyForImage || !RemoteConfigService.freeAiEnabled) ...[
          _buildApiKeysSection(setDialogState),
          const SizedBox(height: 16),
        ],
        // ─── Text / Chat ─────────────────────────────────────────────────────
        if (!_useDevGroqKeyForText || !RemoteConfigService.freeAiEnabled) ...[
          Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section header
                Row(children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.textProvider,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ]),
                const SizedBox(height: 8),
                // Gemini recommended hint
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.geminiRecommended,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Provider selector
                providerButton(
                  selected: {_selectedTextProvider},
                  onChanged: (s) {
                    final p = s.first;
                    AnalyticsService.logSettingsChange(
                      settingName: 'ai_text_provider',
                      newValue: p.toString(),
                      oldValue: _selectedTextProvider.toString(),
                    );
                    setState(() => _selectedTextProvider = p);
                    if (setDialogState != null) {
                      setDialogState(() => _selectedTextProvider = p);
                    }
                  },
                ),
                // Provider-specific model settings for text
                switch (_selectedTextProvider) {
                  AIProvider.gemini => _buildGeminiSettings(setDialogState, true),
                  AIProvider.openAI => _buildOpenAISettings(setDialogState, true),
                  AIProvider.groq   => _buildGroqSettings(setDialogState, true),
                },
                // Chat History Limit — collapsible, defaults collapsed
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Icon(Icons.history,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      'Chat History Limit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    children: [_buildChatHistoryLimitSection(setDialogState)],
                  ),
                ),
                // Reset (hidden when using free provider) + Save (always shown)
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                        onPressed: () {
                          switch (_selectedTextProvider) {
                            case AIProvider.gemini:
                              _geminiModelController.text = RemoteConfigService.defaultGeminiModel;
                            case AIProvider.openAI:
                              _chatGPTModelController.text = RemoteConfigService.defaultOpenAIModel;
                            case AIProvider.groq:
                              _groqModelController.text = RemoteConfigService.defaultGroqModel;
                          }
                          if (setDialogState != null) setDialogState(() {});
                          context.showAccessibleMessage(l10n.modelsResetDefault);
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(l10n.resetModels),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _saveTextSettings(context),
                      icon: const Icon(Icons.save, size: 18),
                      label: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ], // end if (!_useDevGroqKeyForText)
        // ─── Image / Photo ────────────────────────────────────────────────────
        if (!_useDevGroqKeyForImage || !RemoteConfigService.freeAiEnabled) ...[
          Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section header
                Row(children: [
                  Icon(Icons.image_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.imageProvider,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ]),
                const SizedBox(height: 8),
                // Gemini recommended hint
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.geminiRecommended,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Provider selector
                providerButton(
                  selected: {_selectedImageProvider},
                  selectedBg:
                      Theme.of(context).colorScheme.secondaryContainer,
                  selectedFg:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                  onChanged: (s) {
                    final p = s.first;
                    AnalyticsService.logSettingsChange(
                      settingName: 'ai_image_provider',
                      newValue: p.toString(),
                      oldValue: _selectedImageProvider.toString(),
                    );
                    setState(() => _selectedImageProvider = p);
                    if (setDialogState != null) {
                      setDialogState(() => _selectedImageProvider = p);
                    }
                  },
                ),
                // Provider-specific model settings for image
                switch (_selectedImageProvider) {
                  AIProvider.gemini => _buildGeminiSettings(setDialogState, false),
                  AIProvider.openAI => _buildOpenAISettings(setDialogState, false),
                  AIProvider.groq   => _buildGroqSettings(setDialogState, false),
                },
                // Reset (hidden when using free provider) + Save (always shown)
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                        onPressed: () {
                          switch (_selectedImageProvider) {
                            case AIProvider.gemini:
                              _geminiImageModelController.text = RemoteConfigService.defaultGeminiImageModel;
                            case AIProvider.openAI:
                              _chatGPTImageModelController.text = RemoteConfigService.defaultOpenAIImageModel;
                            case AIProvider.groq:
                              _groqImageModelController.text = RemoteConfigService.defaultGroqImageModel;
                          }
                          if (setDialogState != null) setDialogState(() {});
                          context.showAccessibleMessage(l10n.modelsResetDefault);
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(l10n.resetModels),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _saveImageSettings(context),
                      icon: const Icon(Icons.save, size: 18),
                      label: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ], // end if (!_useDevGroqKeyForImage)
        const SizedBox(height: 16),
        // ─── Note: calculators work without an AI key ─────────────────────────
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
              Icon(Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                  ListTile(
                    leading: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Analysis History'),
                    subtitle: const Text('View saved AI analysis reports'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/analysis-history');
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
                                
                                if (mounted) {
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


  Widget _buildChatHistoryLimitSection([StateSetter? setDialogState]) {
    // Locked on free tier (dev key in use for text)
    final onFreeTier = RemoteConfigService.freeAiEnabled && _useDevGroqKeyForText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chat History Limit',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (onFreeTier)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Free Tier',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            !onFreeTier
                ? 'Control how many past messages are included with each request. More messages mean richer conversation context but uses more tokens and may hit rate limits faster.'
                : 'Without your own API key, the app uses our free service tier with a fixed limit of ${RemoteConfigService.freeTierChatHistoryLimit} past messages per request. Add your own API key above to unlock a configurable limit (up to $maxChatHistoryLimit messages).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (!onFreeTier) ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _chatHistoryLimit.toDouble(),
                    min: minChatHistoryLimit.toDouble(),
                    max: maxChatHistoryLimit.toDouble(),
                    divisions: maxChatHistoryLimit - minChatHistoryLimit,
                    label: _chatHistoryLimit.toString(),
                    onChanged: (value) {
                      final newLimit = value.round();
                      setState(() => _chatHistoryLimit = newLimit);
                      if (setDialogState != null) {
                        setDialogState(() => _chatHistoryLimit = newLimit);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_chatHistoryLimit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$minChatHistoryLimit msg', style: Theme.of(context).textTheme.labelSmall),
                Text('$maxChatHistoryLimit msgs', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: defaultChatHistoryLimit.toDouble(),
                    min: minChatHistoryLimit.toDouble(),
                    max: maxChatHistoryLimit.toDouble(),
                    divisions: maxChatHistoryLimit - minChatHistoryLimit,
                    label: defaultChatHistoryLimit.toString(),
                    onChanged: null, // disabled for free tier
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$defaultChatHistoryLimit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
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

  /// [forTextUseCase]: null = show all fields (legacy combined view),
  /// true = show text model only, false = show image model only.
  Widget _buildGeminiSettings([StateSetter? setDialogState, bool? forTextUseCase]) {
    final l10n = AppLocalizations.of(context)!;

    // When called from the text/image provider section, only show the model
    // field. The API key is entered once in the consolidated API Keys section.
    if (forTextUseCase != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (forTextUseCase == true) ...[
            TextField(
              controller: _geminiModelController,
              decoration: const InputDecoration(
                labelText: 'Gemini Text Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (forTextUseCase == false) ...[
            TextField(
              controller: _geminiImageModelController,
              decoration: const InputDecoration(
                labelText: 'Gemini Multimedia Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      );
    }

    // Legacy / combined view: show full settings including API key and guides.
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
        if (_geminiApiKeyController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: Icon(Icons.clear, size: 18,
                  color: Theme.of(context).colorScheme.error),
              label: Text('Clear Key',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () => _clearApiKey(
                  context, 'geminiApiKey', 'Google AI API Key', setDialogState),
            ),
          ),
        ],
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

  Widget _buildOpenAISettings([StateSetter? setDialogState, bool? forTextUseCase]) {
    final l10n = AppLocalizations.of(context)!;

    // When called from the text/image provider section, only show the model
    // field. The API key is entered once in the consolidated API Keys section.
    if (forTextUseCase != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (forTextUseCase == true) ...[
            TextField(
              controller: _chatGPTModelController,
              enabled: true,
              decoration: const InputDecoration(
                labelText: 'ChatGPT Text Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (forTextUseCase == false) ...[
            TextField(
              controller: _chatGPTImageModelController,
              enabled: true,
              decoration: const InputDecoration(
                labelText: 'ChatGPT Multimedia Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      );
    }

    // Legacy / combined view: show full settings including API key and guides.
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
        if (_openAIApiKeyController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: Icon(Icons.clear, size: 18,
                  color: Theme.of(context).colorScheme.error),
              label: Text('Clear Key',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () => _clearApiKey(
                  context, 'openAIApiKey', 'OpenAI API Key', setDialogState),
            ),
          ),
        ],
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

  Widget _buildGroqSettings([StateSetter? setDialogState, bool? forTextUseCase]) {
    final l10n = AppLocalizations.of(context)!;
    // When used in a sub-section, check the per-use-case free key toggle.
    // When freeAiEnabled is false, treat free key as OFF.
    final usingFreeKey = RemoteConfigService.freeAiEnabled && (forTextUseCase == true
        ? _useDevGroqKeyForText
        : forTextUseCase == false
            ? _useDevGroqKeyForImage
            : false); // legacy combined view always shows API key field

    // When called from the text/image provider section, only show the model
    // field. The API key is entered once in the consolidated API Keys section.
    if (forTextUseCase != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (forTextUseCase == true) ...[
            TextField(
              controller: _groqModelController,
              enabled: !usingFreeKey,
              decoration: InputDecoration(
                labelText: 'Groq Text Model',
                border: const OutlineInputBorder(),
                helperText: usingFreeKey ? 'Fixed when using the Free Provider.' : null,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (forTextUseCase == false) ...[
            TextField(
              controller: _groqImageModelController,
              enabled: !usingFreeKey,
              decoration: InputDecoration(
                labelText: 'Groq Multimedia Model',
                border: const OutlineInputBorder(),
                helperText: usingFreeKey
                    ? 'Fixed when using the Free Provider.'
                    : 'Must be a vision-capable model for photo analysis (e.g. meta-llama/llama-4-scout-17b-16e-instruct)',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      );
    }

    // Legacy / combined view: show full settings including API key and guides.
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
        // API key field — shown when not using the free dev key for this use-case
        if (!usingFreeKey) ...[
          TextField(
            controller: _groqApiKeyController,
            obscureText: !_isGroqApiKeyVisible,
            decoration: InputDecoration(
              labelText: 'Groq API Key',
              border: const OutlineInputBorder(),
              helperText: null,
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
          const SizedBox(height: 8),
        ],
        if (_groqApiKeyController.text.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: Icon(Icons.clear, size: 18,
                  color: Theme.of(context).colorScheme.error),
              label: Text('Clear Key',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () => _clearApiKey(
                  context, 'groqApiKey', 'Groq API Key', setDialogState),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (!usingFreeKey)
          const SizedBox(height: 16),
        TextField(
          controller: _groqModelController,
          enabled: !usingFreeKey,
          decoration: InputDecoration(
            labelText: 'Groq Text Model',
            border: const OutlineInputBorder(),
            helperText: usingFreeKey ? 'Fixed when using the Free Provider.' : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _groqImageModelController,
          enabled: !usingFreeKey,
          decoration: InputDecoration(
            labelText: 'Groq Multimedia Model',
            border: const OutlineInputBorder(),
            helperText: usingFreeKey
                ? 'Fixed when using the Free Provider.'
                : 'Must be a vision-capable model for photo analysis (e.g. meta-llama/llama-4-scout-17b-16e-instruct)',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 16),
        if (!usingFreeKey) ...[
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
        ], // end if (!usingFreeKey)
      ],
    );
  }

  /// Consolidated API Keys card — shows the API key for every provider in one
  /// place so the user only needs to enter each key once, regardless of whether
  /// the same provider is selected for both text and image.
  Widget _buildApiKeysSection([StateSetter? setDialogState]) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section header
            Row(children: [
              Icon(Icons.key, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'API Keys',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'Enter your API key for each provider once. It will be used for both text and image features.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // ── Google Gemini ──────────────────────────────────────────────
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                ),
                title: Text('Google Gemini',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        )),
                subtitle: Text(
                  "Google's most capable AI model",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                trailing: Icon(
                  _geminiApiKeyController.text.isNotEmpty
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: _geminiApiKeyController.text.isNotEmpty
                      ? Colors.green.shade600
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  TextField(
                    controller: _geminiApiKeyController,
                    obscureText: !_isGeminiApiKeyVisible,
                    // Rebuild dialog to update the key-status trailing icon.
                    onChanged: (_) => setDialogState?.call(() {}),
                    decoration: InputDecoration(
                      labelText: 'Google AI API Key',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isGeminiApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          final v = !_isGeminiApiKeyVisible;
                          setState(() => _isGeminiApiKeyVisible = v);
                          setDialogState?.call(() => _isGeminiApiKeyVisible = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_geminiApiKeyController.text.isNotEmpty)
                        OutlinedButton.icon(
                          icon: Icon(Icons.clear, size: 18,
                              color: Theme.of(context).colorScheme.error),
                          label: Text('Clear',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                          onPressed: () => _clearApiKey(
                              context, 'geminiApiKey', 'Google AI API Key',
                              setDialogState),
                        ),
                      if (_geminiApiKeyController.text.isNotEmpty &&
                          _geminiApiKeyController.text !=
                              ref.read(modelProvider).geminiApiKey)
                        const SizedBox(width: 8),
                      if (_geminiApiKeyController.text !=
                          ref.read(modelProvider).geminiApiKey)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save Key'),
                          onPressed: () => _saveApiKeys(context, setDialogState),
                        ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: 'How to get your Google AI API key:',
                    children: [
                      Text(l10n.googleAIStudioStep1),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://aistudio.google.com/app/apikey')),
                        child: Text('https://aistudio.google.com/app/apikey',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                      Text(l10n.googleAIStudioStep2),
                      Text(l10n.googleAIStudioStep3),
                      Text(l10n.googleAIStudioStep4),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://www.merge.dev/blog/gemini-api-key')),
                        child: Text('See Guide',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: 'Gemini Models & Rate Limits:',
                    children: [
                      const Text('View available models and free-tier rate limits:'),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://ai.google.dev/gemini-api/docs/models/gemini')),
                        child: Text('ai.google.dev/gemini-api/docs/models/gemini',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://ai.google.dev/gemini-api/docs/rate-limits')),
                        child: Text('Rate Limits',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 16),

            // ── Groq ──────────────────────────────────────────────────────
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.orange, size: 18),
                ),
                title: Text('Groq',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        )),
                subtitle: Text(
                  'Lightning-fast LLM inference',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                trailing: Builder(builder: (context) {
                  final usingFreeAi = RemoteConfigService.freeAiEnabled && (_useDevGroqKeyForText || _useDevGroqKeyForImage);
                  final hasKey = _groqApiKeyController.text.isNotEmpty;
                  return Icon(
                    usingFreeAi
                        ? Icons.bolt
                        : hasKey
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                    color: usingFreeAi
                        ? Colors.amber.shade700
                        : hasKey
                            ? Colors.green.shade600
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 18,
                  );
                }),
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  // Show the API key field only when at least one operation needs a user key
                  if (!_useDevGroqKeyForText || !_useDevGroqKeyForImage || !RemoteConfigService.freeAiEnabled) ...[
                    TextField(
                      controller: _groqApiKeyController,
                      obscureText: !_isGroqApiKeyVisible,
                      // Rebuild dialog to update the key-status trailing icon.
                      onChanged: (_) => setDialogState?.call(() {}),
                      decoration: InputDecoration(
                        labelText: 'Groq API Key',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isGroqApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            final v = !_isGroqApiKeyVisible;
                            setState(() => _isGroqApiKeyVisible = v);
                            setDialogState?.call(() => _isGroqApiKeyVisible = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_groqApiKeyController.text.isNotEmpty)
                          OutlinedButton.icon(
                            icon: Icon(Icons.clear, size: 18,
                                color: Theme.of(context).colorScheme.error),
                            label: Text('Clear',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.error)),
                            onPressed: () => _clearApiKey(
                                context, 'groqApiKey', 'Groq API Key',
                                setDialogState),
                          ),
                        if (_groqApiKeyController.text.isNotEmpty &&
                            _groqApiKeyController.text !=
                                ref.read(modelProvider).groqApiKey)
                          const SizedBox(width: 8),
                        if (_groqApiKeyController.text !=
                            ref.read(modelProvider).groqApiKey)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save Key'),
                            onPressed: () => _saveApiKeys(context, setDialogState),
                          ),
                      ],
                    ),
                  ],
                  _buildApiKeyGuide(
                    title: 'How to get your Groq API key:',
                    children: [
                      Text(l10n.groqCloudStep1),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://console.groq.com/keys')),
                        child: Text('https://console.groq.com/keys',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                      Text(l10n.groqCloudStep2),
                      Text(l10n.groqCloudStep3),
                      Text(l10n.groqCloudStep4),
                      InkWell(
                        onTap: () => launchUrl(
                            Uri.parse('https://docs.aicontentlabs.com/articles/groq-api-key/')),
                        child: Text('See Guide',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: 'Groq Models & Rate Limits:',
                    children: [
                      const Text('View available models and free-tier rate limits:'),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://console.groq.com/docs/models')),
                        child: Text('console.groq.com/docs/models',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://console.groq.com/docs/rate-limits')),
                        child: Text('Rate Limits',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 16),

            // ── OpenAI ────────────────────────────────────────────────────
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.green, size: 18),
                ),
                title: Text('OpenAI',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        )),
                subtitle: Text(
                  'ChatGPT and GPT models by OpenAI',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                trailing: Icon(
                  _openAIApiKeyController.text.isNotEmpty
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: _openAIApiKeyController.text.isNotEmpty
                      ? Colors.green.shade600
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  TextField(
                    controller: _openAIApiKeyController,
                    obscureText: !_isOpenAIApiKeyVisible,
                    // Rebuild dialog to update the key-status trailing icon.
                    onChanged: (_) => setDialogState?.call(() {}),
                    decoration: InputDecoration(
                      labelText: 'OpenAI API Key',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isOpenAIApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          final v = !_isOpenAIApiKeyVisible;
                          setState(() => _isOpenAIApiKeyVisible = v);
                          setDialogState?.call(() => _isOpenAIApiKeyVisible = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_openAIApiKeyController.text.isNotEmpty)
                        OutlinedButton.icon(
                          icon: Icon(Icons.clear, size: 18,
                              color: Theme.of(context).colorScheme.error),
                          label: Text('Clear',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                          onPressed: () => _clearApiKey(
                              context, 'openAIApiKey', 'OpenAI API Key',
                              setDialogState),
                        ),
                      if (_openAIApiKeyController.text.isNotEmpty &&
                          _openAIApiKeyController.text !=
                              ref.read(modelProvider).openAIApiKey)
                        const SizedBox(width: 8),
                      if (_openAIApiKeyController.text !=
                          ref.read(modelProvider).openAIApiKey)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save Key'),
                          onPressed: () => _saveApiKeys(context, setDialogState),
                        ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: 'How to get your OpenAI API key:',
                    children: [
                      Text(l10n.openAIStep1),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://platform.openai.com/api-keys')),
                        child: Text('https://platform.openai.com/api-keys',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                      Text(l10n.openAIStep2),
                      Text(l10n.openAIStep3),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(
                            'https://medium.com/@lorenzozar/how-to-get-your-own-openai-api-key-f4d44e60c327')),
                        child: Text('See Guide',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: 'OpenAI Models & Rate Limits:',
                    children: [
                      const Text('View available models and usage limits:'),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://platform.openai.com/docs/models')),
                        child: Text('platform.openai.com/docs/models',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse('https://platform.openai.com/docs/guides/rate-limits')),
                        child: Text('Rate Limits',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Modern inline toggle tile for the "Use Free Provider" dev key option.
  Widget _buildDevKeyToggle({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: value
            ? scheme.primaryContainer.withOpacity(0.35)
            : scheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? scheme.primary.withOpacity(0.5)
              : scheme.outline.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: SwitchListTile.adaptive(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        secondary: Icon(
          value ? Icons.lock_open_outlined : Icons.lock_outline,
          size: 18,
          color: value ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: value ? scheme.primary : scheme.onSurface,
              ),
        ),
        subtitle: Text(
          onChanged == null
              ? 'Free AI unavailable'
              : value ? 'Using Free Provider' : 'Use your own key',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: value
                    ? scheme.primary.withOpacity(0.8)
                    : scheme.onSurfaceVariant,
              ),
        ),
        value: value,
        onChanged: onChanged,
      ),
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

  void _applyLocaleChange(String? newLocale, String oldLocale, [StateSetter? parentSetDialogState]) {
    ref.read(appSettingsProvider.notifier).setLocale(newLocale);
    CrashlyticsService.setLocale(newLocale);
    AnalyticsService.logSettingsChange(
      settingName: 'language',
      newValue: newLocale ?? 'system',
      oldValue: oldLocale,
    );
    Navigator.of(context).pop();
    if (parentSetDialogState != null) {
      parentSetDialogState(() {});
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
                _applyLocaleChange(value, appSettings.localeCode ?? 'system', parentSetDialogState);
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                _applyLocaleChange(value, appSettings.localeCode ?? 'system', parentSetDialogState);
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageSpanish),
              value: 'es',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                _applyLocaleChange(value, appSettings.localeCode ?? 'system', parentSetDialogState);
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageFrench),
              value: 'fr',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                _applyLocaleChange(value, appSettings.localeCode ?? 'system', parentSetDialogState);
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageGerman),
              value: 'de',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                _applyLocaleChange(value, appSettings.localeCode ?? 'system', parentSetDialogState);
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

/// A clean dialog for the "Remove Ads" one-time purchase.
class _RemoveAdsDialog extends ConsumerWidget {
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  const _RemoveAdsDialog({required this.onBuy, required this.onRestore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(purchaseProvider);
    final busy = purchaseState.isPurchasing;

    // Auto-close when the purchase completes successfully.
    if (purchaseState.adsRemoved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
    }

    return AlertDialog(
      icon: const Icon(Icons.block, size: 36),
      title: const Text('Remove Ads'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Aquarium AI with a one-time purchase to remove all ads permanently.',
          ),
          const SizedBox(height: 12),
          Text(
            'Your purchase is tied to your store account and can be restored on any device.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (purchaseState.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              purchaseState.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : onRestore,
          child: const Text('Restore'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: busy ? null : onBuy,
          child: const Text('Remove Ads'),
        ),
      ],
    );
  }
}
