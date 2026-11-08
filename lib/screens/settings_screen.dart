import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/dosing_entry.dart';
import '../models/dosing_preset.dart';
import '../models/notification_log.dart';
import '../models/tank.dart';
import '../models/tank_note.dart';
import '../models/tank_notification.dart';
import '../models/water_parameter.dart';
import '../providers/app_settings_provider.dart';
import '../providers/dosing_presets_provider.dart';
import '../providers/model_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/tank_provider.dart';
import '../screens/dosing_calculator.dart';
import '../services/analytics_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/auto_backup_service.dart';
import '../services/crashlytics_service.dart';
import '../services/fish_data_service.dart';
import '../services/in_app_review_service.dart';
import '../services/remote_config_service.dart';
import '../theme_colors.dart';
import '../widgets/dosing_preset_editor_dialog.dart';
import '../utils/backup_restore_utils.dart';
import '../widgets/accessible_feedback.dart';
import '../widgets/remove_ads_dialog.dart';
import '../widgets/server_message_dialog.dart';
import 'changelog_screen.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  /// When `true`, the AI Provider dialog is opened automatically after the
  /// first frame (e.g. when navigated from the onboarding API key step).
  final bool openAIProvider;

  const SettingsScreen({super.key, this.openAIProvider = false});

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
    AnalyticsService.logScreenView(screenName: 'settings_screen');
    final models = ref.read(modelProvider);
    _geminiModelController = TextEditingController(text: models.geminiModel);
    _geminiImageModelController = TextEditingController(
      text: models.geminiImageModel,
    );
    _geminiApiKeyController = TextEditingController(text: models.geminiApiKey);
    _chatGPTModelController = TextEditingController(text: models.chatGPTModel);
    _chatGPTImageModelController = TextEditingController(
      text: models.chatGPTImageModel,
    );
    _openAIApiKeyController = TextEditingController(text: models.openAIApiKey);
    _groqModelController = TextEditingController(text: models.groqModel);
    _groqImageModelController = TextEditingController(
      text: models.groqImageModel,
    );
    _groqApiKeyController = TextEditingController(text: models.groqApiKey);
    _selectedTextProvider = models.activeTextProvider;
    _selectedImageProvider = models.activeImageProvider;
    _chatHistoryLimit = models.chatHistoryLimit;
    _useDevGroqKeyForText = models.useDevGroqKeyForText;
    _useDevGroqKeyForImage = models.useDevGroqKeyForImage;

    // Auto-open the Remove Ads dialog if requested via route arguments.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['openRemoveAds'] == true && !kIsWeb) {
        _showRemoveAdsDialog();
      }
      // Auto-open the AI Provider dialog when requested (e.g. from onboarding).
      if (widget.openAIProvider) {
        _showAIProviderDialog();
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        dialogContext,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
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
                            style: Theme.of(dialogContext).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              _handleDialogClose(dialogContext, setDialogState),
                          tooltip: l10n.close,
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(child: _buildAIProviderContent(setDialogState)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDosingPresetsDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Consumer(
            builder: (dialogCtx, dialogRef, _) {
              final presets = dialogRef.watch(dosingPresetsProvider);
              return Dialog(
                insetPadding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: MediaQuery.of(dialogCtx).size.width,
                  height: MediaQuery.of(dialogCtx).size.height * 0.9,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(dialogCtx)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.science_outlined,
                              color:
                                  Theme.of(dialogCtx).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.manageDosingPresets,
                                    style: Theme.of(dialogCtx)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    l10n.dosingPresetsCount(
                                        presets.length),
                                    style: Theme.of(dialogCtx)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(dialogCtx)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  Navigator.of(dialogCtx).pop(),
                              tooltip: l10n.close,
                            ),
                          ],
                        ),
                      ),
                      // Content: reorderable preset list
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          itemCount: presets.length,
                          onReorder: (oldIdx, newIdx) {
                            dialogRef
                                .read(dosingPresetsProvider.notifier)
                                .reorder(oldIdx, newIdx);
                          },
                          itemBuilder: (ctx, index) {
                            final preset = presets[index];
                            return ListTile(
                              key: ValueKey(preset.id),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  dosingIconFromName(
                                      preset.iconName),
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                preset.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${dosingFmtNum(preset.doseAmountGal)} ${preset.unit} / ${dosingFmtNum(preset.perVolumeGal)} gal  •  ${dosingFmtNum(preset.doseAmountLiter)} ${preset.unit} / ${dosingFmtNum(preset.perVolumeLiter)} L',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20),
                                    onPressed: () =>
                                        showDosingPresetEditorDialog(
                                            dialogCtx,
                                            dialogRef,
                                            preset: preset),
                                    tooltip: l10n.editProduct,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Theme.of(ctx)
                                          .colorScheme
                                          .error,
                                    ),
                                    onPressed: () async {
                                      final confirm =
                                          await showDialog<bool>(
                                        context: dialogCtx,
                                        builder: (c) => AlertDialog(
                                          title: Text(l10n.delete),
                                          content: Text(l10n
                                              .deleteProductConfirm),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      c, false),
                                              child:
                                                  Text(l10n.cancel),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      c, true),
                                              child:
                                                  Text(l10n.delete),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        dialogRef
                                            .read(
                                                dosingPresetsProvider
                                                    .notifier)
                                            .removePreset(preset.id);
                                      }
                                    },
                                    tooltip: l10n.delete,
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(
                                        Icons.drag_handle),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Bottom actions
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final confirm =
                                    await showDialog<bool>(
                                  context: dialogCtx,
                                  builder: (c) => AlertDialog(
                                    title:
                                        Text(l10n.resetToDefaults),
                                    content: Text(
                                        l10n.resetPresetsConfirm),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                c, false),
                                        child:
                                            Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                c, true),
                                        child: Text(
                                            l10n.resetToDefaults),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  dialogRef
                                      .read(dosingPresetsProvider
                                          .notifier)
                                      .resetToDefaults();
                                }
                              },
                              icon: const Icon(
                                  Icons.restore_outlined,
                                  size: 18),
                              label:
                                  Text(l10n.resetToDefaults),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () =>
                                  showDosingPresetEditorDialog(
                                      dialogCtx, dialogRef),
                              icon: const Icon(Icons.add,
                                  size: 18),
                              label: Text(l10n.addProduct),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withOpacity(0.3),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                Expanded(child: _buildAppSettingsContent(setDialogState)),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiaryContainer.withOpacity(0.3),
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                Expanded(child: _buildDataManagementContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// **Saves the settings after validation.**
  /// Saves Text/Chat provider settings independently.
  void _saveTextSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    AnalyticsService.logFeatureUsed(
      featureName: 'settings_save_text',
      parameters: {
        'text_provider': _selectedTextProvider.toString(),
        'has_api_key': 'true',
      },
    );

    ref
        .read(modelProvider.notifier)
        .setModels(
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

  /// Saves Image/Multimedia provider settings independently.
  void _saveImageSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    AnalyticsService.logFeatureUsed(
      featureName: 'settings_save_image',
      parameters: {
        'image_provider': _selectedImageProvider.toString(),
        'has_api_key': 'true',
      },
    );

    ref
        .read(modelProvider.notifier)
        .setModels(
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

  /// Returns the display name for an [AIProvider].
  String _providerName(AIProvider p) => switch (p) {
    AIProvider.gemini => 'Gemini',
    AIProvider.openAI => 'OpenAI',
    AIProvider.groq => 'Groq',
  };

  /// Returns the current (unsaved) API key for [p] from the controller text.
  String _keyForProvider(AIProvider p) => switch (p) {
    AIProvider.gemini => _geminiApiKeyController.text.trim(),
    AIProvider.openAI => _openAIApiKeyController.text.trim(),
    AIProvider.groq => _groqApiKeyController.text.trim(),
  };

  /// Returns the best provider to default to based on currently entered keys
  /// (in order: Gemini → OpenAI → Groq → default). Used when Free AI is
  /// toggled OFF to immediately reflect the correct provider in the UI.
  AIProvider _bestProviderFromControllers() {
    if (_geminiApiKeyController.text.trim().isNotEmpty) {
      return AIProvider.gemini;
    }
    if (_openAIApiKeyController.text.trim().isNotEmpty) {
      return AIProvider.openAI;
    }
    if (_groqApiKeyController.text.trim().isNotEmpty) return AIProvider.groq;
    return defaultAIProvider;
  }

  /// Returns informational warnings when a provider is active but has no key.
  /// These warnings do NOT block saves; they are shown on dialog exit.
  List<String> _getMismatchWarnings() {
    final warnings = <String>[];
    final effectiveFreeText =
        RemoteConfigService.freeAiEnabled && _useDevGroqKeyForText;
    final effectiveFreeImage =
        RemoteConfigService.freeAiEnabled && _useDevGroqKeyForImage;

    if (!effectiveFreeText && _keyForProvider(_selectedTextProvider).isEmpty) {
      final name = _providerName(_selectedTextProvider);
      warnings.add(
        '$name is set as the Text provider, but no $name API key is provided.',
      );
    }
    if (!effectiveFreeImage &&
        _keyForProvider(_selectedImageProvider).isEmpty) {
      final name = _providerName(_selectedImageProvider);
      warnings.add(
        '$name is set as the Image provider, but no $name API key is provided.',
      );
    }

    return warnings;
  }

  /// Shows a standalone mismatch-warning dialog when the user tries to close
  /// the AI Provider dialog without unsaved changes but with a provider/key
  /// mismatch.  Offers "Stay & Fix" (keep dialog open) or "Dismiss" (close).
  void _showProviderMismatchDialog(
    BuildContext dialogContext,
    StateSetter? setDialogState,
    List<String> warnings,
  ) {
    showDialog<void>(
      context: dialogContext,
      builder: (alertContext) {
        final l10n = AppLocalizations.of(alertContext)!;
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber.shade700,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(l10n.providerMismatch),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.providerMismatchMessage),
              const SizedBox(height: 8),
              ...warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('  • $w', style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.providerMismatchHint),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(alertContext).pop(),
              child: Text(l10n.stayAndFix),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(alertContext).pop();
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.dismiss),
            ),
          ],
        );
      },
    );
  }

  /// Saves all three API keys (and full provider/model state).
  /// Validation is no longer blocking — saves always succeed.  Provider/key
  /// mismatches are reported via [_getMismatchWarnings] when the dialog closes.
  bool _saveApiKeys(BuildContext context, [StateSetter? setDialogState]) {
    final l10n = AppLocalizations.of(context)!;
    ref
        .read(modelProvider.notifier)
        .setModels(
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(dialogL10n.clearApiKeyTitle),
          content: Text(dialogL10n.clearApiKeyConfirm(label)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(dialogL10n.clear),
            ),
          ],
        );
      },
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
      context.showAccessibleMessage(l10n.apiKeyCleared(label));
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

  /// Shows an "Unsaved Changes" alert if there are pending changes, or a
  /// provider-mismatch warning if there are no unsaved changes but the active
  /// provider has no key configured.  Otherwise simply pops the dialog.
  void _handleDialogClose(
    BuildContext dialogContext, [
    StateSetter? setDialogState,
  ]) {
    final mismatchWarnings = _getMismatchWarnings();

    if (!_hasUnsavedChanges()) {
      if (mismatchWarnings.isNotEmpty) {
        _showProviderMismatchDialog(
          dialogContext,
          setDialogState,
          mismatchWarnings,
        );
      } else {
        Navigator.of(dialogContext).pop();
      }
      return;
    }

    final saved = ref.read(modelProvider);
    final providerChanged = _selectedTextProvider != saved.activeTextProvider;
    final imageProviderChanged =
        _selectedImageProvider != saved.activeImageProvider;
    final textModelChanged =
        _geminiModelController.text != saved.geminiModel ||
        _chatGPTModelController.text != saved.chatGPTModel ||
        _groqModelController.text != saved.groqModel;
    final imageModelChanged =
        _geminiImageModelController.text != saved.geminiImageModel ||
        _chatGPTImageModelController.text != saved.chatGPTImageModel ||
        _groqImageModelController.text != saved.groqImageModel;
    final keysChanged =
        _geminiApiKeyController.text != saved.geminiApiKey ||
        _openAIApiKeyController.text != saved.openAIApiKey ||
        _groqApiKeyController.text != saved.groqApiKey;

    showDialog<void>(
      context: dialogContext,
      builder: (alertContext) {
        final l10n = AppLocalizations.of(alertContext)!;
        return AlertDialog(
          title: Text(l10n.unsavedChanges),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (providerChanged) Text('• ${l10n.textProviderChanged}'),
              if (imageProviderChanged) Text('• ${l10n.imageProviderChanged}'),
              if (textModelChanged) Text('• ${l10n.textModelChanged}'),
              if (imageModelChanged) Text('• ${l10n.imageModelChanged}'),
              if (keysChanged) Text('• ${l10n.apiKeysUpdated}'),
              if (mismatchWarnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.providerKeyMismatchWarning,
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                ...mismatchWarnings.map(
                  (w) => Text(
                    '  • $w',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(alertContext).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.discard),
              onPressed: () {
                Navigator.of(alertContext).pop();
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: Text(l10n.saveAllAndClose),
              onPressed: () {
                _saveApiKeys(dialogContext, setDialogState);
                Navigator.of(alertContext).pop();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to handle stocking button toggle
  void _handleStockingButtonToggle(
    bool value,
    StateSetter? setDialogState,
    AppSettingsState appSettings,
  ) {
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

    return MainLayout(title: l10n.settings, child: _buildMainMenu());
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
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
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
          Builder(
            builder: (context) {
              final isFounder = ref.watch(isFounderProvider);
              final maxPerMin = isFounder
                  ? RemoteConfigService.founderMaxRequestsPerMinute
                  : RemoteConfigService.maxRequestsPerMinute;
              final maxPerDay = isFounder
                  ? RemoteConfigService.founderMaxRequestsPerDay
                  : RemoteConfigService.maxRequestsPerDay;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isFounder
                      ? AquaThemeColors.founderColor(context).withOpacity(0.08)
                      : Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFounder
                        ? AquaThemeColors.founderColor(context).withOpacity(0.4)
                        : Colors.amber.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFounder ? Icons.diamond : Icons.info_outline,
                      color: isFounder
                          ? AquaThemeColors.founderColor(context)
                          : Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isFounder
                            ? 'Using App\'s Built-in Dev API Key — Founder Aquarist (${RemoteConfigService.founderDefaultGroqModel}): $maxPerMin req/min, $maxPerDay req/day. Add your own API key for unlimited access.'
                            : 'Using App\'s Built-in Dev API Key (free tier). '
                                  'Add your own API key in AI Provider settings for dedicated limits.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isFounder
                              ? AquaThemeColors.founderColor(context)
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        // Indicator: shown when the user has their own API key configured and
        // is not using the built-in developer key.
        if (appSettings.enableAI &&
            !models.usingDeveloperGroqKeyForAny &&
            (models.groqApiKey.isNotEmpty ||
                models.geminiApiKey.isNotEmpty ||
                models.openAIApiKey.isNotEmpty)) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.key, color: Colors.green.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using Own API Key — No in-app limits applied. Your API provider\'s rate limits apply.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
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
              border: Border.all(color: Colors.red.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.block, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The free AI tier is currently unavailable. '
                    'Please add your own Groq API key in AI Provider settings to continue using AI features.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: l10n.revisitOnboarding,
          subtitle: l10n.revisitOnboardingDesc,
          icon: Icons.auto_awesome_outlined,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Theme.of(context).colorScheme.primary,
          onTap: () async {
            await OnboardingScreen.reset();
            if (mounted) {
              Navigator.pushNamed(context, '/onboarding');
            }
          },
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
          title: l10n.manageDosingPresets,
          subtitle: l10n.manageDosingPresetsDesc,
          icon: Icons.science_outlined,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Theme.of(context).colorScheme.primary,
          onTap: () => _showDosingPresetsDialog(),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: l10n.appearance,
          subtitle: l10n.appearanceDesc,
          icon: Icons.palette_outlined,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.4),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Theme.of(context).colorScheme.tertiary,
          onTap: () => Navigator.pushNamed(context, '/appearance'),
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
            MaterialPageRoute(builder: (context) => const ChangelogScreen()),
          ),
        ),
        const SizedBox(height: 16),
        _buildFounderSupportCard(context),
        const SizedBox(height: 16),
        _buildRemoveAdsCard(context),
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: l10n.buyMeACoffee,
          subtitle: l10n.buyMeACoffeeDesc,
          icon: Icons.coffee,
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.25),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Colors.amber.shade700,
          onTap: () => _showBuyMeACoffeeDialog(),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context: context,
          title: l10n.contactUs,
          subtitle: l10n.contactUsSubtitle,
          icon: Icons.chat_bubble_outline,
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.25),
              Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Colors.orange.shade700,
          onTap: () => _showFeedbackDialog(),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 16),
          _buildMenuCard(
            context: context,
            title: l10n.debugMenu,
            subtitle: l10n.debugMenuSubtitle,
            icon: Icons.bug_report,
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.15),
                Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            iconColor: Colors.red.shade700,
            onTap: () => _showDebugMenuDialog(),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRemoveAdsCard(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    // In debug mode, hide ads and references to removing them when debug flag is set
    if (kDebugMode && ref.watch(appSettingsProvider).debugHideAds) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
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
                      Theme.of(
                        context,
                      ).colorScheme.surfaceContainer.withOpacity(0.3),
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
              Icon(Icons.check_circle, color: Colors.green, size: 24),
            ],
          ),
        ),
      );
    }
    return _buildMenuCard(
      context: context,
      title: l10n.removeAds,
      subtitle: l10n.removeAdsSettingsSubtitle,
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
    showRemoveAdsDialog(context);
  }

  Widget _buildFounderSupportCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final founderColor = AquaThemeColors.founderColor(context);

    return _buildMenuCard(
      context: context,
      title: l10n.founderPerksScreenTitle,
      subtitle: l10n.founderSupportDesc,
      icon: Icons.diamond,
      gradient: LinearGradient(
        colors: [
          founderColor.withOpacity(0.15),
          Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconColor: founderColor,
      onTap: () => Navigator.pushNamed(context, '/founder-perks'),
    );
  }

  void _showDebugMenuDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final appSettings = ref.read(appSettingsProvider);
          final purchaseState = ref.read(purchaseProvider);
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            icon: Icon(Icons.bug_report, color: Colors.red.shade700, size: 36),
            title: Text(l10n.debugMenu),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.debugMenuDescription,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                // Hide Ads toggle
                SwitchListTile(
                  secondary: Icon(Icons.block, color: Colors.red.shade700),
                  title: Text(l10n.debugHideAds),
                  subtitle: Text(l10n.debugHideAdsDesc),
                  value: appSettings.debugHideAds,
                  onChanged: (value) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .setDebugHideAds(value);
                    setDialogState(() {});
                  },
                ),
                const Divider(),
                // Simulate Founder Tier toggle
                SwitchListTile(
                  secondary: Icon(
                    Icons.diamond,
                    color: AquaThemeColors.founderColor(context),
                  ),
                  title: const Text('Simulate Founder Tier'),
                  subtitle: Text(
                    ref.read(debugForceFounderProvider)
                        ? 'Currently: Founder Aquarist active'
                        : 'Currently: Standard tier',
                  ),
                  value: ref.read(debugForceFounderProvider),
                  onChanged: (value) {
                    ref.read(debugForceFounderProvider.notifier).state = value;
                    setDialogState(() {});
                  },
                ),
                const Divider(),
                // Simulate Ads Removed (toggle purchase state for testing)
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: const Text('Simulate Ads Removed'),
                  subtitle: Text(
                    purchaseState.adsRemoved
                        ? 'Currently: Ads removed'
                        : 'Currently: Ads active',
                  ),
                  trailing: Switch(
                    value: purchaseState.adsRemoved,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('adsRemoved', value);
                      // Re-init the purchase provider to pick up the change
                      ref.invalidate(purchaseProvider);
                      setDialogState(() {});
                    },
                  ),
                ),
                const Divider(),
                // Force refresh fish data (clear cooldown + cache)
                ListTile(
                  leading: const Icon(
                    Icons.refresh,
                    color: Colors.blue,
                  ),
                  title: const Text('Force Refresh Fish Data'),
                  subtitle: const Text(
                    'Clears the fish data cache',
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop(); // close debug menu first
                    final service = ref.read(fishDataServiceProvider);
                    await service.clearPersistentCache();
                    ref.invalidate(fishDataProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fish data cache cleared. Data will refresh on next load.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Divider(),
                // Clear all SharedPreferences
                ListTile(
                  leading: const Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text('Clear All Preferences'),
                  subtitle: const Text(
                    'Wipe all SharedPreferences',
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text('Clear All Preferences?'),
                        content: const Text(
                          'This will wipe all saved settings and preferences. '
                          'The app will need to be restarted.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(c).pop(true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'All preferences cleared. Please restart the app.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(),
                // Populate test tanks for all tank types, harmony scores, etc.
                ListTile(
                  leading: const Icon(Icons.science, color: Colors.teal),
                  title: const Text('Populate Test Tanks'),
                  subtitle: const Text(
                    'Add test tanks for all types & harmony ranges',
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _populateDebugTanks();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined, color: Colors.purple),
                  title: const Text('Show Server Message'),
                  subtitle: const Text(
                    'Fetch latest Remote Config and show server message dialog',
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showServerMessageDebugPopup();
                  },
                ),
              ],
            ),
          ),
        ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showServerMessageDebugPopup() async {
    if (!kDebugMode) return;
    try {
      await RemoteConfigService.debugFetchAndActivate();
      final messageId = RemoteConfigService.serverMessageId;
      final title = RemoteConfigService.serverMessageTitle;
      final message = RemoteConfigService.serverMessage;

      if (messageId.isEmpty || message.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No server message is currently configured.')),
        );
        return;
      }

      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => ServerMessageDialog(
          messageId: messageId,
          title: title,
          message: message,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing debug server message: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load server message.')));
    }
  }

  Future<void> _populateDebugTanks() async {
    final notifier = ref.read(tankProvider.notifier);
    final now = DateTime.now();
    const debugTag = TankTag(name: 'Debug', color: 0xFFE53935); // red

    // ── helper shortcuts ──────────────────────────────────────────────────────
    WaterParameter fw(String type, double value, String unit, int daysAgo) =>
        WaterParameter.create(
          parameterType: type,
          value: value,
          unit: unit,
          dateRecorded: now.subtract(Duration(days: daysAgo)),
        );
    WaterParameter sw(String type, double value, String unit, int daysAgo) =>
        WaterParameter.create(
          parameterType: type,
          value: value,
          unit: unit,
          dateRecorded: now.subtract(Duration(days: daysAgo)),
        );
    DosingEntry dose(
      String name,
      double amount,
      String unit,
      int daysAgo, {
      String? notes,
    }) => DosingEntry.create(
      treatmentName: name,
      amount: amount,
      unit: unit,
      dateDosed: now.subtract(Duration(days: daysAgo)),
      notes: notes,
    );
    NotificationLog log(NotificationType type, int daysAgo, {String? notes}) =>
        NotificationLog(
          id: const Uuid().v4(),
          type: type,
          loggedAt: now.subtract(Duration(days: daysAgo)),
          notes: notes,
        );
    TankNotification notif(
      NotificationType type,
      int daysFromNow,
      RepeatFrequency freq, {
      String? title,
    }) => TankNotification.create(
      type: type,
      notificationDateTime: now.add(Duration(days: daysFromNow)),
      repeatFrequency: freq,
      customTitle: title,
    );
    // ─────────────────────────────────────────────────────────────────────────

    // 1. Freshwater Community — high harmony
    notifier.addTank(Tank.create(
      name: 'Community Tank (FW)',
      type: 'freshwater',
      sizeGallons: 55.0,
      notes: 'Peaceful community tank — high harmony',
      inhabitants: [
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Tetras',
          fishUnit: 'Tetras',
          quantity: 6,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 60)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Guppies',
          fishUnit: 'Guppies',
          quantity: 4,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 45)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Cory Cats',
          fishUnit: 'Cory Cats',
          quantity: 4,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 30)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Rasboras',
          fishUnit: 'Rasboras',
          quantity: 5,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 20)),
        ),
      ],
      harmonyScore: 0.92,
      tags: [debugTag, const TankTag(name: 'Community', color: 0xFF43A047)],
      waterParameters: [
        fw('ammonia', 0.0, 'ppm', 7),
        fw('nitrite', 0.0, 'ppm', 7),
        fw('nitrate', 10.0, 'ppm', 7),
        fw('ph', 7.2, '', 7),
        fw('temperature', 76.0, '°F', 7),
        fw('ammonia', 0.0, 'ppm', 14),
        fw('nitrite', 0.0, 'ppm', 14),
        fw('nitrate', 15.0, 'ppm', 14),
      ],
      dosingEntries: [
        dose('Seachem Prime', 5.0, 'mL', 7, notes: 'Weekly water change'),
        dose('Seachem Stability', 10.0, 'mL', 7),
        dose('API Stress Coat', 3.0, 'mL', 14),
      ],
      notificationLogs: [
        log(NotificationType.waterChange, 7, notes: '20% water change'),
        log(NotificationType.waterChange, 14, notes: '20% water change'),
        log(NotificationType.testing, 7),
        log(NotificationType.testing, 14),
        log(NotificationType.feeding, 1),
        log(NotificationType.feeding, 2),
        log(NotificationType.feeding, 3),
      ],
      notifications: [
        notif(NotificationType.waterChange, 7, RepeatFrequency.weekly,
            title: 'Weekly Water Change'),
        notif(NotificationType.feeding, 1, RepeatFrequency.daily),
        notif(NotificationType.testing, 7, RepeatFrequency.weekly),
      ],
      tankNotes: [
        TankNote.create(
          content: 'Debug tank — Community FW. Fish are healthy.',
          createdAt: now.subtract(const Duration(days: 30)),
        ),
      ],
    ));

    // 2. Freshwater Betta Solo — perfect harmony
    notifier.addTank(Tank.create(
      name: 'Betta Solo (FW)',
      type: 'freshwater',
      sizeGallons: 10.0,
      notes: 'Single betta — perfect harmony',
      inhabitants: [
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'King Betta',
          fishUnit: 'Betta Male',
          quantity: 1,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 90)),
        ),
      ],
      harmonyScore: 1.0,
      tags: [debugTag, const TankTag(name: 'Species Only', color: 0xFF1E88E5)],
      waterParameters: [
        fw('ammonia', 0.0, 'ppm', 3),
        fw('nitrite', 0.0, 'ppm', 3),
        fw('nitrate', 5.0, 'ppm', 3),
        fw('ph', 7.0, '', 3),
        fw('temperature', 78.0, '°F', 3),
      ],
      dosingEntries: [
        dose('Seachem Prime', 1.0, 'mL', 3, notes: 'Small water change'),
        dose('Indian Almond Leaf Extract', 2.0, 'mL', 10),
      ],
      notificationLogs: [
        log(NotificationType.waterChange, 3, notes: '30% water change'),
        log(NotificationType.waterChange, 10),
        log(NotificationType.feeding, 1),
        log(NotificationType.feeding, 2),
      ],
      notifications: [
        notif(NotificationType.waterChange, 3, RepeatFrequency.weekly,
            title: 'Betta Water Change'),
        notif(NotificationType.feeding, 1, RepeatFrequency.daily),
      ],
      tankNotes: [
        TankNote.create(
          content: 'Debug tank — Betta solo. Very active and healthy.',
          createdAt: now.subtract(const Duration(days: 90)),
        ),
      ],
    ));

    // 3. Freshwater Aggressive Mix — low harmony
    notifier.addTank(Tank.create(
      name: 'Aggressive Mix (FW)',
      type: 'freshwater',
      sizeGallons: 75.0,
      notes: 'Aggressive cichlid mix — low harmony',
      inhabitants: [
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Big Cichlid',
          fishUnit: 'American Cichlids (Large)',
          quantity: 1,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 120)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Malawi Mix',
          fishUnit: 'African Cichlids (Malawi)',
          quantity: 3,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 60)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Angelfish',
          fishUnit: 'Angelfish',
          quantity: 2,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 30)),
        ),
      ],
      harmonyScore: 0.18,
      tags: [debugTag, const TankTag(name: 'Aggressive', color: 0xFFE53935)],
      waterParameters: [
        fw('ammonia', 0.25, 'ppm', 5),
        fw('nitrite', 0.0, 'ppm', 5),
        fw('nitrate', 40.0, 'ppm', 5),
        fw('ph', 7.8, '', 5),
        fw('temperature', 77.0, '°F', 5),
        fw('ammonia', 0.5, 'ppm', 12),
        fw('nitrate', 55.0, 'ppm', 12),
      ],
      dosingEntries: [
        dose('API Ammo Lock', 5.0, 'mL', 5, notes: 'Ammonia spike treatment'),
        dose('Seachem Prime', 7.5, 'mL', 5),
        dose('Seachem Prime', 7.5, 'mL', 12),
      ],
      notificationLogs: [
        log(NotificationType.waterChange, 5, notes: '30% — ammonia spike'),
        log(NotificationType.waterChange, 12),
        log(NotificationType.testing, 5),
        log(NotificationType.testing, 12),
        log(NotificationType.maintenance, 10, notes: 'Cleaned filter'),
      ],
      notifications: [
        notif(NotificationType.waterChange, 2, RepeatFrequency.weekly,
            title: 'Aggressive Tank Water Change'),
        notif(NotificationType.testing, 3, RepeatFrequency.weekly,
            title: 'Ammonia Check'),
      ],
      tankNotes: [
        TankNote.create(
          content: 'Debug tank — aggressive mix, low harmony. Monitor ammonia closely.',
          createdAt: now.subtract(const Duration(days: 30)),
        ),
      ],
    ));

    // 4. Freshwater Planted — medium harmony
    notifier.addTank(Tank.create(
      name: 'Planted Tank (FW)',
      type: 'freshwater',
      sizeGallons: 20.0,
      notes: 'Planted nano tank',
      inhabitants: [
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Cory Cats',
          fishUnit: 'Cory Cats',
          quantity: 4,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 45)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Rasboras',
          fishUnit: 'Rasboras',
          quantity: 6,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 45)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Gourami',
          fishUnit: 'Gourami',
          quantity: 1,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 20)),
        ),
      ],
      harmonyScore: 0.78,
      tags: [debugTag, const TankTag(name: 'Planted', color: 0xFF00897B)],
      waterParameters: [
        fw('ammonia', 0.0, 'ppm', 6),
        fw('nitrite', 0.0, 'ppm', 6),
        fw('nitrate', 8.0, 'ppm', 6),
        fw('ph', 6.8, '', 6),
        fw('temperature', 75.0, '°F', 6),
      ],
      dosingEntries: [
        dose('Flourish Excel', 1.0, 'mL', 1, notes: 'Daily plant supplement'),
        dose('Flourish Excel', 1.0, 'mL', 2),
        dose('Flourish Excel', 1.0, 'mL', 3),
        dose('Seachem Flourish', 2.0, 'mL', 6, notes: 'Weekly comprehensive'),
        dose('Seachem Prime', 2.0, 'mL', 6),
      ],
      notificationLogs: [
        log(NotificationType.waterChange, 6, notes: '20% water change'),
        log(NotificationType.dosing, 1, notes: 'Daily Excel dosing'),
        log(NotificationType.dosing, 2),
        log(NotificationType.dosing, 3),
        log(NotificationType.feeding, 1),
        log(NotificationType.feeding, 2),
      ],
      notifications: [
        notif(NotificationType.waterChange, 7, RepeatFrequency.weekly),
        notif(NotificationType.dosing, 1, RepeatFrequency.daily,
            title: 'Flourish Excel'),
        notif(NotificationType.feeding, 1, RepeatFrequency.daily),
      ],
      tankNotes: [
        TankNote.create(
          content: 'Debug tank — planted nano. CO2 injection via Excel.',
          createdAt: now.subtract(const Duration(days: 45)),
        ),
      ],
    ));

    // 5. Empty freshwater tank
    notifier.addTank(Tank.create(
      name: 'Empty Tank (FW)',
      type: 'freshwater',
      sizeGallons: 30.0,
      notes: 'Newly set up, cycling in progress',
      tags: [debugTag, const TankTag(name: 'Cycling', color: 0xFF757575)],
      waterParameters: [
        fw('ammonia', 2.0, 'ppm', 2),
        fw('nitrite', 0.5, 'ppm', 2),
        fw('nitrate', 0.0, 'ppm', 2),
        fw('ph', 7.4, '', 2),
        fw('ammonia', 4.0, 'ppm', 7),
      ],
      dosingEntries: [
        dose('API Quick Start', 10.0, 'mL', 7, notes: 'Tank cycle startup'),
        dose('Seachem Stability', 10.0, 'mL', 2),
      ],
      notificationLogs: [
        log(NotificationType.testing, 2, notes: 'Ammonia still high'),
        log(NotificationType.testing, 7, notes: 'Day 1 — started cycle'),
      ],
      notifications: [
        notif(NotificationType.testing, 2, RepeatFrequency.daily,
            title: 'Cycle Test'),
      ],
      tankNotes: [
        TankNote.create(
          content: 'Debug tank — empty, fishless cycling. Do NOT add fish yet.',
          createdAt: now.subtract(const Duration(days: 7)),
        ),
      ],
    ));

    // 6. Marine Fish-Only (FOWLR)
    notifier.addTank(Tank.create(
      name: 'FOWLR Tank (SW)',
      type: 'marine',
      isReef: false,
      sizeGallons: 90.0,
      notes: 'Fish only with live rock — medium harmony',
      inhabitants: [
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Clownfish',
          fishUnit: 'Clownfish',
          quantity: 2,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 90)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Damselfish',
          fishUnit: 'Damselfish',
          quantity: 2,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 60)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Chromis',
          fishUnit: 'Chromis',
          quantity: 3,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 30)),
        ),
      ],
      harmonyScore: 0.65,
      tags: [debugTag, const TankTag(name: 'Fish-Only', color: 0xFF3949AB)],
      waterParameters: [
        sw('ammonia', 0.0, 'ppm', 7),
        sw('nitrite', 0.0, 'ppm', 7),
        sw('nitrate', 20.0, 'ppm', 7),
        sw('salinity', 1.025, 'SG', 7),
        sw('ph', 8.2, '', 7),
        sw('temperature', 78.0, '°F', 7),
        sw('nitrate', 30.0, 'ppm', 14),
        sw('salinity', 1.024, 'SG', 14),
      ],
      dosingEntries: [
        dose('Seachem Prime', 9.0, 'mL', 7, notes: 'Weekly water change'),
        dose('Two Little Fishies ReVive', 5.0, 'mL', 7),
        dose('Kent Marine Tech CB Part A', 10.0, 'mL', 3),
        dose('Kent Marine Tech CB Part B', 10.0, 'mL', 3),
      ],
      notificationLogs: [
        log(NotificationType.waterChange, 7, notes: '15% water change'),
        log(NotificationType.waterChange, 14),
        log(NotificationType.testing, 7),
        log(NotificationType.testing, 14),
        log(NotificationType.maintenance, 14, notes: 'Cleaned skimmer cup'),
        log(NotificationType.feeding, 1),
        log(NotificationType.feeding, 2),
      ],
      notifications: [
        notif(NotificationType.waterChange, 7, RepeatFrequency.weekly),
        notif(NotificationType.maintenance, 14, RepeatFrequency.weekly,
            title: 'Clean Skimmer'),
        notif(NotificationType.feeding, 1, RepeatFrequency.daily),
      ],
      tankNotes: [
        TankNote.create(
          content: 'Debug tank — FOWLR. Salinity target 1.025.',
          createdAt: now.subtract(const Duration(days: 60)),
        ),
      ],
    ));

    // 7. Marine Reef — high harmony
    notifier.addTank(Tank.create(
      name: 'Reef Tank (SW)',
      type: 'marine',
      isReef: true,
      sizeGallons: 120.0,
      notes: 'SPS/LPS reef tank — high harmony',
      inhabitants: [
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Clownfish',
          fishUnit: 'Clownfish',
          quantity: 2,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 180)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Tangs',
          fishUnit: 'Tangs',
          quantity: 1,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 120)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Gobies',
          fishUnit: 'Gobies',
          quantity: 2,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 60)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Wrasse',
          fishUnit: 'Wrasse',
          quantity: 1,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 30)),
        ),
      ],
      harmonyScore: 0.88,
      tags: [debugTag, const TankTag(name: 'Reef', color: 0xFF8E24AA)],
      waterParameters: [
        sw('ammonia', 0.0, 'ppm', 3),
        sw('nitrite', 0.0, 'ppm', 3),
        sw('nitrate', 2.0, 'ppm', 3),
        sw('phosphate', 0.03, 'ppm', 3),
        sw('salinity', 1.026, 'SG', 3),
        sw('ph', 8.3, '', 3),
        sw('temperature', 78.0, '°F', 3),
        sw('calcium', 425.0, 'ppm', 3),
        sw('alkalinity', 9.0, 'dKH', 3),
        sw('magnesium', 1350.0, 'ppm', 3),
        sw('nitrate', 3.0, 'ppm', 10),
        sw('salinity', 1.025, 'SG', 10),
      ],
      dosingEntries: [
        dose('Two Part - Alk', 10.0, 'mL', 1, notes: 'Daily 2-part dosing'),
        dose('Two Part - Ca', 10.0, 'mL', 1),
        dose('Two Part - Alk', 10.0, 'mL', 2),
        dose('Two Part - Ca', 10.0, 'mL', 2),
        dose('Seachem Reef Fusion 1', 15.0, 'mL', 3),
        dose('Seachem Reef Fusion 2', 15.0, 'mL', 3),
        dose('Brightwell CoralAmino', 2.0, 'mL', 7),
      ],
      notificationLogs: [
        log(NotificationType.waterChange, 3, notes: '10% water change'),
        log(NotificationType.waterChange, 10),
        log(NotificationType.dosing, 1, notes: '2-part dosing'),
        log(NotificationType.dosing, 2),
        log(NotificationType.testing, 3),
        log(NotificationType.testing, 10),
        log(NotificationType.maintenance, 7, notes: 'Cleaned glass, checked coral'),
        log(NotificationType.feeding, 1),
        log(NotificationType.feeding, 2),
        log(NotificationType.feeding, 3),
      ],
      notifications: [
        notif(NotificationType.waterChange, 7, RepeatFrequency.weekly,
            title: 'Reef Water Change'),
        notif(NotificationType.dosing, 1, RepeatFrequency.daily,
            title: '2-Part Dosing'),
        notif(NotificationType.testing, 3, RepeatFrequency.weekly,
            title: 'Reef Parameter Test'),
        notif(NotificationType.maintenance, 7, RepeatFrequency.weekly,
            title: 'Coral Check'),
        notif(NotificationType.feeding, 1, RepeatFrequency.daily),
      ],
      tankNotes: [
        TankNote.create(
          content: 'Debug tank — SPS/LPS reef. Calcium 425, Alk 9 dKH, Mg 1350.',
          createdAt: now.subtract(const Duration(days: 90)),
        ),
        TankNote.create(
          content: 'Added Wrasse — watch for aggression with Gobies.',
          createdAt: now.subtract(const Duration(days: 30)),
        ),
      ],
    ));

    // 8. Marine Aggressive Predator — low harmony
    notifier.addTank(Tank.create(
      name: 'Predator Tank (SW)',
      type: 'marine',
      isReef: false,
      sizeGallons: 180.0,
      notes: 'Large predator FOWLR — low harmony',
      inhabitants: [
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Lionfish',
          fishUnit: 'Lionfish',
          quantity: 1,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 150)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Pufferfish',
          fishUnit: 'Pufferfish',
          quantity: 1,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 90)),
        ),
        TankInhabitant(
          id: const Uuid().v4(),
          customName: 'Triggerfish',
          fishUnit: 'Triggerfish',
          quantity: 1,
          speciesTags: const [],
          dateAdded: now.subtract(const Duration(days: 45)),
        ),
      ],
      harmonyScore: 0.22,
      tags: [debugTag, const TankTag(name: 'Predator', color: 0xFFEF6C00)],
      waterParameters: [
        sw('ammonia', 0.0, 'ppm', 5),
        sw('nitrite', 0.0, 'ppm', 5),
        sw('nitrate', 40.0, 'ppm', 5),
        sw('salinity', 1.023, 'SG', 5),
        sw('ph', 8.1, '', 5),
        sw('temperature', 79.0, '°F', 5),
        sw('nitrate', 50.0, 'ppm', 12),
        sw('salinity', 1.022, 'SG', 12),
      ],
      dosingEntries: [
        dose('Seachem Prime', 18.0, 'mL', 5, notes: 'Weekly water change'),
        dose('API Melafix', 5.0, 'mL', 8, notes: 'Fin nip treatment'),
        dose('API Melafix', 5.0, 'mL', 9),
        dose('API Melafix', 5.0, 'mL', 10),
      ],
      notificationLogs: [
        log(NotificationType.waterChange, 5, notes: '20% water change'),
        log(NotificationType.waterChange, 12),
        log(NotificationType.testing, 5),
        log(NotificationType.testing, 12),
        log(NotificationType.maintenance, 5, notes: 'Cleaned skimmer, checked fish'),
        log(NotificationType.dosing, 8, notes: 'Melafix — fin nip from Trigger'),
        log(NotificationType.feeding, 1, notes: 'Silversides + shrimp'),
        log(NotificationType.feeding, 2),
        log(NotificationType.feeding, 3),
      ],
      notifications: [
        notif(NotificationType.waterChange, 7, RepeatFrequency.weekly,
            title: 'Predator Water Change'),
        notif(NotificationType.testing, 5, RepeatFrequency.weekly,
            title: 'Nitrate Check'),
        notif(NotificationType.feeding, 1, RepeatFrequency.daily),
        notif(NotificationType.maintenance, 14, RepeatFrequency.weekly,
            title: 'Skimmer Clean'),
      ],
      tankNotes: [
        TankNote.create(
          content: 'Debug tank — predator FOWLR. Heavy bioload — frequent changes needed.',
          createdAt: now.subtract(const Duration(days: 90)),
        ),
        TankNote.create(
          content: 'Triggerfish nipped Puffer fins on day 8. Added Melafix.',
          createdAt: now.subtract(const Duration(days: 8)),
        ),
      ],
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('8 debug tanks added with parameters, dosing & activity logs!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showBuyMeACoffeeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.coffee, size: 36, color: Colors.amber),
        title: Text(l10n.buyMeACoffee),
        content: Text(l10n.buyMeACoffeeDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          if (!kIsWeb)
            OutlinedButton.icon(
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(l10n.buyMeACoffeeInApp),
              onPressed: () {
                Navigator.of(ctx).pop();
                _buyMeACoffeeInApp();
              },
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.buyMeACoffeeWebsite),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final urlString = RemoteConfigService.buyMeACoffeeUrl;
              final uri = Uri.tryParse(urlString);
              if (uri == null ||
                  !(uri.isScheme('http') || uri.isScheme('https'))) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.unableToOpenLink)),
                  );
                }
                return;
              }
              final launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.unableToOpenLink)));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _buyMeACoffeeInApp() async {
    try {
      final iap = InAppPurchase.instance;
      final available = await iap.isAvailable();
      if (!available) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.storeNotAvailable)));
        }
        return;
      }
      final response = await iap.queryProductDetails({buyMeACoffeeProductId});
      if (response.error != null) {
        debugPrint(
          'IAP query error for $buyMeACoffeeProductId: ${response.error}',
        );
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.storeError(response.error!.message))),
          );
        }
        return;
      }
      if (response.notFoundIDs.isNotEmpty &&
          response.notFoundIDs.contains(buyMeACoffeeProductId)) {
        debugPrint('IAP product not found: $buyMeACoffeeProductId');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.productNotFound)));
        }
        return;
      }
      if (response.productDetails.isEmpty) {
        debugPrint(
          'IAP query returned no productDetails for $buyMeACoffeeProductId '
          'and no explicit error/notFoundIDs.',
        );
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.productNotFound)));
        }
        return;
      }
      final param = PurchaseParam(
        productDetails: response.productDetails.first,
      );
      final purchaseStarted = await iap.buyConsumable(purchaseParam: param);
      if (!purchaseStarted) {
        debugPrint(
          'buyConsumable failed to initiate for product $buyMeACoffeeProductId',
        );
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.unableToInitiatePurchase)),
          );
        }
      }
    } catch (e) {
      debugPrint('Buy Me a Coffee purchase error: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchaseError(e.toString()))),
        );
      }
    }
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
                  child: Icon(icon, color: iconColor, size: 32),
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
    final isFounder = ref.read(isFounderProvider);

    // Effective per-tier limits for the built-in dev key.
    final limitPerMin = isFounder
        ? RemoteConfigService.founderMaxRequestsPerMinute
        : RemoteConfigService.maxRequestsPerMinute;
    final limitPerDay = isFounder
        ? RemoteConfigService.founderMaxRequestsPerDay
        : RemoteConfigService.maxRequestsPerDay;
    final limitPhotos = isFounder
        ? RemoteConfigService.founderMaxPhotoAnalysesPerDay
        : RemoteConfigService.maxPhotoAnalysesPerDay;
    final limitChatHistory = isFounder
        ? RemoteConfigService.founderChatHistoryLimit
        : RemoteConfigService.freeTierChatHistoryLimit;

    // ─── Segmented button style helpers ───────────────────────────────────────
    SegmentedButton<AIProvider> providerButton({
      required Set<AIProvider> selected,
      required ValueChanged<Set<AIProvider>> onChanged,
      Color? selectedBg,
      Color? selectedFg,
    }) => SegmentedButton<AIProvider>(
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
      selected: selected,
      onSelectionChanged: onChanged,
    );

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ─── Limits notice (collapsible; always shown when a dev key is available) ──
        if (RemoteConfigService.freeAiEnabled)
          Builder(
            builder: (context) {
              final usingOwnKey =
                  !_useDevGroqKeyForText && !_useDevGroqKeyForImage;
              return Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: usingOwnKey
                        ? Colors.green.withOpacity(0.08)
                        : isFounder
                            ? AquaThemeColors.founderColor(
                                context,
                              ).withOpacity(0.08)
                            : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: usingOwnKey
                          ? Colors.green.withOpacity(0.4)
                          : isFounder
                              ? AquaThemeColors.founderColor(
                                  context,
                                ).withOpacity(0.4)
                              : Colors.amber.withOpacity(0.4),
                    ),
                  ),
                  child: RemoteConfigService.freeAiEnabled
                      ? ExpansionTile(
                          leading: usingOwnKey
                              ? Icon(
                                  Icons.key,
                                  color: Colors.green.shade700,
                                  size: 20,
                                )
                              : isFounder
                                  ? Icon(
                                      Icons.diamond,
                                      color: AquaThemeColors.founderColor(
                                        context,
                                      ),
                                      size: 20,
                                    )
                                  : const Icon(
                                      Icons.speed,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                          title: Text(
                            usingOwnKey
                                ? l10n.ownApiKeyTitle
                                : isFounder
                                    ? l10n.founderAquaristTitle
                                    : l10n.freeTierLimits,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: usingOwnKey
                                      ? Colors.green.shade700
                                      : isFounder
                                          ? AquaThemeColors.founderColor(
                                              context,
                                            )
                                          : Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          // Collapsed subtitle: own-key message OR key numbers
                          subtitle: Text(
                            usingOwnKey
                                ? l10n.ownApiKeySubtitle
                                : l10n.freeTierLimitsSubtitle(
                                    limitPerDay,
                                    limitPerMin,
                                    limitPhotos,
                                  ),
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: usingOwnKey
                                  ? Colors.green.shade600
                                  : isFounder
                                      ? AquaThemeColors.founderColor(
                                          context,
                                        ).withOpacity(0.8)
                                      : Colors.amber.shade700,
                            ),
                          ),
                          initiallyExpanded: false,
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            12,
                          ),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!usingOwnKey) ...[
                              Text(
                                '• $limitPerMin ${l10n.freeTierRequestsPerMin}\n'
                                '• $limitPerDay ${l10n.freeTierRequestsPerDay}\n'
                                '• $limitPhotos ${l10n.freeTierPhotoAnalysesPerDay}\n'
                                '• $limitChatHistory-${l10n.freeTierChatHistoryPerRequest}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isFounder
                                          ? AquaThemeColors.founderColor(
                                              context,
                                            )
                                          : Colors.amber.shade900,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isFounder
                                    ? '• ${l10n.freeTierFounderModel(RemoteConfigService.founderDefaultGroqModel)} (${l10n.modelLabelText})\n'
                                      '• ${l10n.freeTierFounderModel(RemoteConfigService.founderGroqImageModel)} (${l10n.modelLabelImage})'
                                    : '• ${l10n.freeTierFounderModel(RemoteConfigService.freeDefaultGroqModel)} (${l10n.modelLabelText})\n'
                                      '• ${l10n.freeTierFounderModel(RemoteConfigService.freeGroqImageModel)} (${l10n.modelLabelImage})',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isFounder
                                          ? AquaThemeColors.founderColor(
                                              context,
                                            )
                                          : Colors.amber.shade900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.freeTierModelNote,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isFounder
                                          ? AquaThemeColors.founderColor(
                                              context,
                                            ).withOpacity(0.8)
                                          : Colors.amber.shade800,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                              if (!isFounder) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.freeTierRecommendation,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.amber.shade800,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.freeTierDisclaimer,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.amber.shade800,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.key,
                                    size: 14,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.ownApiKeySubtitle,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        )
                      : ListTile(
                      leading: const Icon(
                        Icons.block,
                        color: Colors.red,
                        size: 20,
                      ),
                      title: Text(
                        l10n.freeTierUnavailable,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      subtitle: Text(
                        l10n.freeTierUnavailableDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
              ),
            );
          },
        ),
        // ─── Free AI toggles (global) ─────────────────────────────────────
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, size: 20, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      l10n.freeAI,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.freeAIDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDevKeyToggle(
                  label: l10n.useFreeAIForText,
                  value:
                      RemoteConfigService.freeAiEnabled &&
                      _useDevGroqKeyForText,
                  onChanged: RemoteConfigService.freeAiEnabled
                      ? (v) {
                          // When turning ON: force Groq. When turning OFF: switch
                          // immediately to whichever provider has a key entered in
                          // the controllers so the segmented button reflects the
                          // correct selection without waiting for ref.listen.
                          final best = v
                              ? AIProvider.groq
                              : _bestProviderFromControllers();
                          setState(() {
                            _useDevGroqKeyForText = v;
                            _selectedTextProvider = best;
                          });
                          setDialogState?.call(() {
                            _useDevGroqKeyForText = v;
                            _selectedTextProvider = best;
                          });
                          // Auto-save immediately so root menu and providers reflect state.
                          ref
                              .read(modelProvider.notifier)
                              .setDevGroqKeyToggles(
                                forText: v,
                                forImage: _useDevGroqKeyForImage,
                              );
                        }
                      : null,
                ),
                const SizedBox(height: 8),
                _buildDevKeyToggle(
                  label: l10n.useFreeAIForImage,
                  value:
                      RemoteConfigService.freeAiEnabled &&
                      _useDevGroqKeyForImage,
                  onChanged: RemoteConfigService.freeAiEnabled
                      ? (v) {
                          final best = v
                              ? AIProvider.groq
                              : _bestProviderFromControllers();
                          setState(() {
                            _useDevGroqKeyForImage = v;
                            _selectedImageProvider = best;
                          });
                          setDialogState?.call(() {
                            _useDevGroqKeyForImage = v;
                            _selectedImageProvider = best;
                          });
                          // Auto-save immediately so root menu and providers reflect state.
                          ref
                              .read(modelProvider.notifier)
                              .setDevGroqKeyToggles(
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
        if (!_useDevGroqKeyForText ||
            !_useDevGroqKeyForImage ||
            !RemoteConfigService.freeAiEnabled) ...[
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
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.textProvider,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Gemini recommended hint
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
                    AIProvider.gemini => _buildGeminiSettings(
                      setDialogState,
                      true,
                    ),
                    AIProvider.openAI => _buildOpenAISettings(
                      setDialogState,
                      true,
                    ),
                    AIProvider.groq => _buildGroqSettings(setDialogState, true),
                  },
                  // Chat History Limit — collapsible, defaults collapsed
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(
                        Icons.history,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        l10n.chatHistoryLimit,
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
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            switch (_selectedTextProvider) {
                              case AIProvider.gemini:
                                _geminiModelController.text =
                                    RemoteConfigService.defaultGeminiModel;
                              case AIProvider.openAI:
                                _chatGPTModelController.text =
                                    RemoteConfigService.defaultOpenAIModel;
                              case AIProvider.groq:
                                _groqModelController.text =
                                    RemoteConfigService.defaultGroqModel;
                            }
                            if (setDialogState != null) setDialogState(() {});
                            context.showAccessibleMessage(
                              l10n.modelsResetDefault,
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(l10n.resetModels),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _saveTextSettings(context),
                          icon: const Icon(Icons.save, size: 18),
                          label: Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        // end if (!_useDevGroqKeyForText)
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
                  Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.imageProvider,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Gemini recommended hint
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
                    selectedBg: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    selectedFg: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
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
                    AIProvider.gemini => _buildGeminiSettings(
                      setDialogState,
                      false,
                    ),
                    AIProvider.openAI => _buildOpenAISettings(
                      setDialogState,
                      false,
                    ),
                    AIProvider.groq => _buildGroqSettings(
                      setDialogState,
                      false,
                    ),
                  },
                  // Reset (hidden when using free provider) + Save (always shown)
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            switch (_selectedImageProvider) {
                              case AIProvider.gemini:
                                _geminiImageModelController.text =
                                    RemoteConfigService.defaultGeminiImageModel;
                              case AIProvider.openAI:
                                _chatGPTImageModelController.text =
                                    RemoteConfigService.defaultOpenAIImageModel;
                              case AIProvider.groq:
                                _groqImageModelController.text =
                                    RemoteConfigService.defaultGroqImageModel;
                            }
                            if (setDialogState != null) setDialogState(() {});
                            context.showAccessibleMessage(
                              l10n.modelsResetDefault,
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(l10n.resetModels),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _saveImageSettings(context),
                          icon: const Icon(Icons.save, size: 18),
                          label: Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        // end if (!_useDevGroqKeyForImage)
        const SizedBox(height: 16),
        // ─── Recommended Models blurb ─────────────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(
                Icons.tips_and_updates_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              title: Text(
                l10n.recommendedModelsTitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                Text(
                  l10n.recommendedModelsDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                // Gemini
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.gemini,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.geminiModelTip,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Groq
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.flash_on, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.groq,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.groqModelTip,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // OpenAI
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.psychology,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.openAI,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            l10n.openAIModelTip,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // ─── Note: calculators work without an AI key ─────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.7),
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
                  l10n.aiKeysNotRequired,
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
                        Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withOpacity(0.3),
                        Theme.of(
                          context,
                        ).colorScheme.surfaceContainer.withOpacity(0.3),
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
                      Flexible(
                        child: Text(
                          l10n.appSettings,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
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
                  subtitle: Text(
                    _getLanguageDisplayName(appSettings.localeCode),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageDialog(setDialogState),
                ),
                const Divider(height: 24),

                // AI Response Language
                ListTile(
                  leading: Icon(
                    Icons.translate,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(l10n.aiResponseLanguage),
                  subtitle: Text(
                    _getAiResponseLanguageDisplayName(
                      appSettings.aiResponseLanguage,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAiResponseLanguageDialog(setDialogState),
                ),
                const Divider(height: 24),

                // AI Experience Level
                ListTile(
                  leading: Icon(
                    Icons.school_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(l10n.aiExperienceLevel),
                  subtitle: Text(
                    _getExperienceLevelDisplayName(
                      appSettings.userExperienceLevel,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () =>
                      _showExperienceLevelDialog(setDialogState),
                ),
                const Divider(height: 24),

                // Appearance shortcut
                ListTile(
                  leading: Icon(
                    Icons.palette_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  title: Text(l10n.appearance),
                  subtitle: Text(l10n.appearanceDesc),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/appearance');
                  },
                ),
                const Divider(height: 24),

                SwitchListTile(
                  title: Text(l10n.showAIStockingButton),
                  subtitle: Text(l10n.showAIStockingButtonDesc),
                  value: appSettings.showStockingButton,
                  // Disable the toggle when AI is disabled
                  onChanged: appSettings.enableAI
                      ? (value) => _handleStockingButtonToggle(
                          value,
                          setDialogState,
                          appSettings,
                        )
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
                  title: Text(l10n.analysisHistory),
                  subtitle: Text(l10n.analysisHistoryDesc),
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
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 8,
                        ),
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

                              await ref
                                  .read(appSettingsProvider.notifier)
                                  .clearAllRememberedRescheduleOptions();

                              if (mounted) {
                                context.showAccessibleMessage(
                                  l10n.reschedulePreferenceCleared,
                                );
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
                        Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer.withOpacity(0.2),
                        Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
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
                          launchUrl(
                            Uri.parse(
                              'https://github.com/TheRealFalseReality/Aquarium-AI/blob/main/TRANSLATION_GUIDE.md',
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(l10n.visitGitHub),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onTertiary,
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
                            Theme.of(
                              context,
                            ).colorScheme.tertiaryContainer.withOpacity(0.3),
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainer.withOpacity(0.3),
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
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
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
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
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
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
                              if (stats['lastBackupTime'] != null)
                                const SizedBox(height: 8),
                              _buildStatRow(
                                context,
                                Icons.restore,
                                l10n.lastRestore,
                                stats['lastRestoreTime'] as String,
                                Colors.green,
                              ),
                            ],
                            if (stats['lastCloudBackupTime'] != null) ...[
                              if (stats['lastBackupTime'] != null ||
                                  stats['lastRestoreTime'] != null)
                                const SizedBox(height: 8),
                              _buildStatRow(
                                context,
                                Icons.cloud_done,
                                l10n.lastCloudBackup,
                                stats['lastCloudBackupTime'] as String,
                                Colors.purple,
                              ),
                            ],
                            if (stats['lastAutoCloudBackupTime'] != null) ...[
                              const SizedBox(height: 8),
                              _buildStatRow(
                                context,
                                Icons.cloud_sync,
                                l10n.lastAutoCloudBackup,
                                stats['lastAutoCloudBackupTime'] as String,
                                Colors.teal,
                              ),
                            ],
                            if (stats['lastBackupTime'] == null &&
                                stats['lastRestoreTime'] == null &&
                                stats['lastCloudBackupTime'] == null &&
                                stats['lastAutoCloudBackupTime'] == null)
                              Text(
                                l10n.noBackupHistory,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.backup, color: Colors.blue),
                      ),
                      title: Text(l10n.backupData),
                      subtitle: Text(l10n.backupDataDesc),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await BackupRestoreUtils.exportData(
                          context,
                          ref,
                          source: 'settings',
                        );
                        // Rebuild to refresh statistics
                        if (mounted) setState(() {});
                      },
                    ),
                    const Divider(height: 16),
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.restore, color: Colors.green),
                      ),
                      title: Text(l10n.restoreData),
                      subtitle: Text(l10n.restoreDataDesc),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await BackupRestoreUtils.importData(
                          context,
                          ref,
                          source: 'settings',
                        );
                        // Rebuild to refresh statistics
                        if (mounted) setState(() {});
                      },
                    ),
                    const Divider(height: 16),
                    // Cloud Backup (Founder only on non-web platforms)
                    Builder(
                      builder: (context) {
                        final isFounder = ref.watch(isFounderProvider);
                        final hasCloudBackupRestoreAccess = kIsWeb || isFounder;
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.cloud_upload,
                              color: hasCloudBackupRestoreAccess
                                  ? Colors.purple
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(l10n.backupDataOnline),
                          subtitle: Text(l10n.backupDataOnlineDesc),
                          trailing: hasCloudBackupRestoreAccess
                              ? const Icon(Icons.arrow_forward_ios, size: 16)
                              : Tooltip(
                                  message: l10n.founderRequiredTooltip,
                                  child: const Icon(Icons.lock_outline,
                                      size: 16),
                                ),
                          onTap: () async {
                            await BackupRestoreUtils.exportDataOnline(
                              context,
                              ref,
                              source: 'settings',
                            );
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                    const Divider(height: 16),
                    // Cloud Restore (Founder only on non-web platforms)
                    Builder(
                      builder: (context) {
                        final isFounder = ref.watch(isFounderProvider);
                        final hasCloudBackupRestoreAccess = kIsWeb || isFounder;
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.cloud_download,
                              color: hasCloudBackupRestoreAccess
                                  ? Colors.deepPurple
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(l10n.restoreDataOnline),
                          subtitle: Text(l10n.restoreDataOnlineDesc),
                          trailing: hasCloudBackupRestoreAccess
                              ? const Icon(Icons.arrow_forward_ios, size: 16)
                              : Tooltip(
                                  message: l10n.founderRequiredTooltip,
                                  child: const Icon(Icons.lock_outline,
                                      size: 16),
                                ),
                          onTap: () async {
                            await BackupRestoreUtils.importDataOnline(
                              context,
                              ref,
                              source: 'settings',
                            );
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
                    const Divider(height: 16),
                    // Auto Cloud Backup (Founder only)
                    Builder(
                      builder: (context) {
                        final isFounder = ref.watch(isFounderProvider);
                        final settings = ref.watch(appSettingsProvider);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SwitchListTile(
                              secondary: Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.cloud_sync,
                                  color: isFounder
                                      ? Colors.teal
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(l10n.autoCloudBackupTitle),
                                  ),
                                  if (!isFounder) ...[
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: l10n.founderRequiredTooltip,
                                      child: const Icon(
                                        Icons.lock_outline,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(l10n.autoCloudBackupSubtitle),
                              value: isFounder &&
                                  settings.autoCloudBackupEnabled,
                              onChanged: isFounder
                                  ? (value) {
                                      if (value &&
                                          FirebaseAuth
                                                  .instance.currentUser ==
                                              null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.cloudBackupRequiresSignIn,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      ref
                                          .read(appSettingsProvider.notifier)
                                          .setAutoCloudBackupEnabled(value);
                                      AnalyticsService.logSettingsChange(
                                        settingName:
                                            'auto_cloud_backup_enabled',
                                        newValue: value.toString(),
                                      );
                                    }
                                  : (_) => showRemoveAdsDialog(context),
                            ),
                            if (isFounder &&
                                settings.autoCloudBackupEnabled) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 8),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 48),
                                    Expanded(
                                      child: Text(
                                        l10n.autoCloudBackupFrequencyLabel,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ),
                                    DropdownButton<String>(
                                      value:
                                          settings.autoCloudBackupFrequency,
                                      underline: const SizedBox.shrink(),
                                      items: [
                                        DropdownMenuItem(
                                          value:
                                              autoBackupFrequencyDaily,
                                          child: Text(
                                            l10n.autoCloudBackupFrequencyDaily,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value:
                                              autoBackupFrequencyWeekly,
                                          child: Text(
                                            l10n.autoCloudBackupFrequencyWeekly,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value:
                                              autoBackupFrequencyMonthly,
                                          child: Text(
                                            l10n.autoCloudBackupFrequencyMonthly,
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        ref
                                            .read(
                                              appSettingsProvider.notifier,
                                            )
                                            .setAutoCloudBackupFrequency(
                                              value,
                                            );
                                        AnalyticsService.logSettingsChange(
                                          settingName:
                                              'auto_cloud_backup_frequency',
                                          newValue: value,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
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

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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

      // Cloud backup metadata – fails silently (returns null) if not signed in or no backup exists.
      final cloudInfo = await CloudBackupService.getBackupInfo();
      if (cloudInfo != null) {
        final backedUpAt = cloudInfo['backedUpAt'] as DateTime?;
        if (backedUpAt != null) {
          stats['lastCloudBackupTime'] = _formatDateTime(backedUpAt);
        }
      }

      // Last automatic cloud backup time.
      final lastAutoBackupTime = await AutoBackupService.getLastAutoBackupTime();
      if (lastAutoBackupTime != null) {
        stats['lastAutoCloudBackupTime'] = _formatDateTime(lastAutoBackupTime);
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
    final l10n = AppLocalizations.of(context)!;
    // Locked on free tier (dev key in use for text)
    final onFreeTier =
        RemoteConfigService.freeAiEnabled && _useDevGroqKeyForText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
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
              Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.chatHistoryLimit,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (onFreeTier)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.freeTierBadge,
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
                ? l10n.chatHistoryLimitDesc
                : l10n.chatHistoryFreeTierDesc(
                    RemoteConfigService.freeTierChatHistoryLimit,
                    maxChatHistoryLimit,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                Text(
                  '$minChatHistoryLimit msg',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  '$maxChatHistoryLimit msgs',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
  Widget _buildGeminiSettings([
    StateSetter? setDialogState,
    bool? forTextUseCase,
  ]) {
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
              decoration: InputDecoration(
                labelText: l10n.geminiTextModel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            _buildModelRateLimitsLink(
              modelsUrl: 'https://ai.google.dev/gemini-api/docs/models/gemini',
              rateLimitsUrl:
                  'https://ai.google.dev/gemini-api/docs/rate-limits',
            ),
            const SizedBox(height: 12),
          ],
          if (forTextUseCase == false) ...[
            TextField(
              controller: _geminiImageModelController,
              decoration: InputDecoration(
                labelText: l10n.geminiMultimediaModel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            _buildModelRateLimitsLink(
              modelsUrl: 'https://ai.google.dev/gemini-api/docs/models/gemini',
              rateLimitsUrl:
                  'https://ai.google.dev/gemini-api/docs/rate-limits',
            ),
            const SizedBox(height: 12),
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
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
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
                      l10n.geminiDescription,
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
            labelText: l10n.googleAIApiKey,
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
              icon: Icon(
                Icons.clear,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                l10n.clearKey,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => _clearApiKey(
                context,
                'geminiApiKey',
                l10n.googleAIApiKey,
                setDialogState,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _geminiModelController,
          decoration: InputDecoration(
            labelText: l10n.geminiTextModel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _geminiImageModelController,
          decoration: InputDecoration(
            labelText: l10n.geminiMultimediaModel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildApiKeyGuide(
          title: l10n.howToGetGoogleApiKey,
          children: [
            Text(l10n.googleAIStudioStep1),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse('https://aistudio.google.com/app/apikey'),
              ),
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
              onTap: () => launchUrl(
                Uri.parse('https://www.merge.dev/blog/gemini-api-key'),
              ),
              child: Text(
                l10n.seeGuide,
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
          title: l10n.geminiModelsRateLimits,
          children: [
            Text(l10n.viewModelsRateLimits),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse(
                  'https://ai.google.dev/gemini-api/docs/models/gemini',
                ),
              ),
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
              onTap: () => launchUrl(
                Uri.parse('https://ai.google.dev/gemini-api/docs/rate-limits'),
              ),
              child: Text(
                l10n.rateLimits,
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

  Widget _buildOpenAISettings([
    StateSetter? setDialogState,
    bool? forTextUseCase,
  ]) {
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
              decoration: InputDecoration(
                labelText: l10n.chatGPTTextModel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            _buildModelRateLimitsLink(
              modelsUrl: 'https://platform.openai.com/docs/models',
              rateLimitsUrl:
                  'https://platform.openai.com/docs/guides/rate-limits',
            ),
            const SizedBox(height: 12),
          ],
          if (forTextUseCase == false) ...[
            TextField(
              controller: _chatGPTImageModelController,
              enabled: true,
              decoration: InputDecoration(
                labelText: l10n.chatGPTMultimediaModel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            _buildModelRateLimitsLink(
              modelsUrl: 'https://platform.openai.com/docs/models',
              rateLimitsUrl:
                  'https://platform.openai.com/docs/guides/rate-limits',
            ),
            const SizedBox(height: 12),
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
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
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
                      l10n.openAIDescription,
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
            labelText: l10n.openAIApiKeyLabel,
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
              icon: Icon(
                Icons.clear,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                l10n.clearKey,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => _clearApiKey(
                context,
                'openAIApiKey',
                l10n.openAIApiKeyLabel,
                setDialogState,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _chatGPTModelController,
          enabled: true,
          decoration: InputDecoration(
            labelText: l10n.chatGPTTextModel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _chatGPTImageModelController,
          enabled: true,
          decoration: InputDecoration(
            labelText: l10n.chatGPTMultimediaModel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildApiKeyGuide(
          title: l10n.howToGetOpenAIApiKey,
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
              onTap: () => launchUrl(
                Uri.parse(
                  'https://medium.com/@lorenzozar/how-to-get-your-own-openai-api-key-f4d44e60c327',
                ),
              ),
              child: Text(
                l10n.seeGuide,
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
          title: l10n.openAIModelsRateLimits,
          children: [
            Text(l10n.viewModelsUsageLimits),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse('https://platform.openai.com/docs/models'),
              ),
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
              onTap: () => launchUrl(
                Uri.parse(
                  'https://platform.openai.com/docs/guides/rate-limits',
                ),
              ),
              child: Text(
                l10n.rateLimits,
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

  Widget _buildGroqSettings([
    StateSetter? setDialogState,
    bool? forTextUseCase,
  ]) {
    final l10n = AppLocalizations.of(context)!;
    // When used in a sub-section, check the per-use-case free key toggle.
    // When freeAiEnabled is false, treat free key as OFF.
    final usingFreeKey =
        RemoteConfigService.freeAiEnabled &&
        (forTextUseCase == true
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
                labelText: l10n.groqTextModel,
                border: const OutlineInputBorder(),
                helperText: usingFreeKey
                    ? l10n.fixedWhenUsingFreeProvider
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            _buildModelRateLimitsLink(
              modelsUrl: 'https://console.groq.com/docs/models',
              rateLimitsUrl: 'https://console.groq.com/docs/rate-limits',
            ),
            const SizedBox(height: 12),
          ],
          if (forTextUseCase == false) ...[
            TextField(
              controller: _groqImageModelController,
              enabled: !usingFreeKey,
              decoration: InputDecoration(
                labelText: l10n.groqMultimediaModel,
                border: const OutlineInputBorder(),
                helperText: usingFreeKey
                    ? l10n.fixedWhenUsingFreeProvider
                    : l10n.mustBeVisionModel,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 4),
            _buildModelRateLimitsLink(
              modelsUrl: 'https://console.groq.com/docs/models',
              rateLimitsUrl: 'https://console.groq.com/docs/rate-limits',
            ),
            const SizedBox(height: 12),
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
            border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
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
                      l10n.groqDescription,
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
              labelText: l10n.groqApiKeyLabel,
              border: const OutlineInputBorder(),
              helperText: null,
              helperMaxLines: 2,
              suffixIcon: IconButton(
                icon: Icon(
                  _isGroqApiKeyVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
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
              icon: Icon(
                Icons.clear,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                l10n.clearKey,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => _clearApiKey(
                context,
                'groqApiKey',
                l10n.groqApiKeyLabel,
                setDialogState,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (!usingFreeKey)
          const SizedBox(height: 16),
        TextField(
          controller: _groqModelController,
          enabled: !usingFreeKey,
          decoration: InputDecoration(
            labelText: l10n.groqTextModel,
            border: const OutlineInputBorder(),
            helperText: usingFreeKey ? l10n.fixedWhenUsingFreeProvider : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _groqImageModelController,
          enabled: !usingFreeKey,
          decoration: InputDecoration(
            labelText: l10n.groqMultimediaModel,
            border: const OutlineInputBorder(),
            helperText: usingFreeKey
                ? l10n.fixedWhenUsingFreeProvider
                : l10n.mustBeVisionModel,
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 16),
        if (!usingFreeKey) ...[
          _buildApiKeyGuide(
            title: l10n.howToGetGroqApiKey,
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
                onTap: () => launchUrl(
                  Uri.parse(
                    'https://docs.aicontentlabs.com/articles/groq-api-key/',
                  ),
                ),
                child: Text(
                  l10n.seeGuide,
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
            title: l10n.groqModelsRateLimits,
            children: [
              Text(l10n.viewModelsRateLimits),
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://console.groq.com/docs/models'),
                ),
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
                onTap: () => launchUrl(
                  Uri.parse('https://console.groq.com/docs/rate-limits'),
                ),
                child: Text(
                  l10n.rateLimits,
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
        // end if (!usingFreeKey)
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
            Row(
              children: [
                Icon(
                  Icons.key,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.apiKeys,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.apiKeysDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // ── Google Gemini ──────────────────────────────────────────────
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.blue,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Google Gemini',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                subtitle: Text(
                  l10n.geminiDescription,
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
                      labelText: l10n.googleAIApiKey,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isGeminiApiKeyVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          final v = !_isGeminiApiKeyVisible;
                          setState(() => _isGeminiApiKeyVisible = v);
                          setDialogState?.call(
                            () => _isGeminiApiKeyVisible = v,
                          );
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
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          label: Text(
                            l10n.clear,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: () => _clearApiKey(
                            context,
                            'geminiApiKey',
                            l10n.googleAIApiKey,
                            setDialogState,
                          ),
                        ),
                      if (_geminiApiKeyController.text.isNotEmpty &&
                          _geminiApiKeyController.text !=
                              ref.read(modelProvider).geminiApiKey)
                        const SizedBox(width: 8),
                      if (_geminiApiKeyController.text !=
                          ref.read(modelProvider).geminiApiKey)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.save, size: 18),
                          label: Text(l10n.saveKey),
                          onPressed: () =>
                              _saveApiKeys(context, setDialogState),
                        ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: l10n.howToGetGoogleApiKey,
                    children: [
                      Text(l10n.googleAIStudioStep1),
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse('https://aistudio.google.com/app/apikey'),
                        ),
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
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://www.merge.dev/blog/gemini-api-key',
                          ),
                        ),
                        child: Text(
                          l10n.seeGuide,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: l10n.geminiModelsRateLimits,
                    children: [
                      Text(l10n.viewModelsRateLimits),
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://ai.google.dev/gemini-api/docs/models/gemini',
                          ),
                        ),
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
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://ai.google.dev/gemini-api/docs/rate-limits',
                          ),
                        ),
                        child: Text(
                          l10n.rateLimits,
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
              ),
            ),

            const Divider(height: 16),

            // ── Groq ──────────────────────────────────────────────────────
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.orange,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Groq',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                subtitle: Text(
                  l10n.groqDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Builder(
                  builder: (context) {
                    final usingFreeAi =
                        RemoteConfigService.freeAiEnabled &&
                        (_useDevGroqKeyForText || _useDevGroqKeyForImage);
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
                  },
                ),
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  // Show the API key field only when at least one operation needs a user key
                  if (!_useDevGroqKeyForText ||
                      !_useDevGroqKeyForImage ||
                      !RemoteConfigService.freeAiEnabled) ...[
                    TextField(
                      controller: _groqApiKeyController,
                      obscureText: !_isGroqApiKeyVisible,
                      // Rebuild dialog to update the key-status trailing icon.
                      onChanged: (_) => setDialogState?.call(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.groqApiKeyLabel,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isGroqApiKeyVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            final v = !_isGroqApiKeyVisible;
                            setState(() => _isGroqApiKeyVisible = v);
                            setDialogState?.call(
                              () => _isGroqApiKeyVisible = v,
                            );
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
                            icon: Icon(
                              Icons.clear,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            label: Text(
                              l10n.clear,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            onPressed: () => _clearApiKey(
                              context,
                              'groqApiKey',
                              l10n.groqApiKeyLabel,
                              setDialogState,
                            ),
                          ),
                        if (_groqApiKeyController.text.isNotEmpty &&
                            _groqApiKeyController.text !=
                                ref.read(modelProvider).groqApiKey)
                          const SizedBox(width: 8),
                        if (_groqApiKeyController.text !=
                            ref.read(modelProvider).groqApiKey)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.save, size: 18),
                            label: Text(l10n.saveKey),
                            onPressed: () =>
                                _saveApiKeys(context, setDialogState),
                          ),
                      ],
                    ),
                  ],
                  _buildApiKeyGuide(
                    title: l10n.howToGetGroqApiKey,
                    children: [
                      Text(l10n.groqCloudStep1),
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse('https://console.groq.com/keys'),
                        ),
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
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://docs.aicontentlabs.com/articles/groq-api-key/',
                          ),
                        ),
                        child: Text(
                          l10n.seeGuide,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: l10n.groqModelsRateLimits,
                    children: [
                      Text(l10n.viewModelsRateLimits),
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse('https://console.groq.com/docs/models'),
                        ),
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
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://console.groq.com/docs/rate-limits',
                          ),
                        ),
                        child: Text(
                          l10n.rateLimits,
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
              ),
            ),

            const Divider(height: 16),

            // ── OpenAI ────────────────────────────────────────────────────
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.green,
                    size: 18,
                  ),
                ),
                title: Text(
                  'OpenAI',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                subtitle: Text(
                  l10n.openAIDescription,
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
                      labelText: l10n.openAIApiKeyLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isOpenAIApiKeyVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          final v = !_isOpenAIApiKeyVisible;
                          setState(() => _isOpenAIApiKeyVisible = v);
                          setDialogState?.call(
                            () => _isOpenAIApiKeyVisible = v,
                          );
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
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          label: Text(
                            l10n.clear,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: () => _clearApiKey(
                            context,
                            'openAIApiKey',
                            l10n.openAIApiKeyLabel,
                            setDialogState,
                          ),
                        ),
                      if (_openAIApiKeyController.text.isNotEmpty &&
                          _openAIApiKeyController.text !=
                              ref.read(modelProvider).openAIApiKey)
                        const SizedBox(width: 8),
                      if (_openAIApiKeyController.text !=
                          ref.read(modelProvider).openAIApiKey)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.save, size: 18),
                          label: Text(l10n.saveKey),
                          onPressed: () =>
                              _saveApiKeys(context, setDialogState),
                        ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: l10n.howToGetOpenAIApiKey,
                    children: [
                      Text(l10n.openAIStep1),
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse('https://platform.openai.com/api-keys'),
                        ),
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
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://medium.com/@lorenzozar/how-to-get-your-own-openai-api-key-f4d44e60c327',
                          ),
                        ),
                        child: Text(
                          l10n.seeGuide,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildApiKeyGuide(
                    title: l10n.openAIModelsRateLimits,
                    children: [
                      Text(l10n.viewModelsUsageLimits),
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse('https://platform.openai.com/docs/models'),
                        ),
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
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://platform.openai.com/docs/guides/rate-limits',
                          ),
                        ),
                        child: Text(
                          l10n.rateLimits,
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
    final l10n = AppLocalizations.of(context)!;
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
              ? l10n.freeAIUnavailable
              : value
              ? l10n.usingFreeProvider
              : l10n.useYourOwnKey,
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

  Widget _buildModelRateLimitsLink({
    required String modelsUrl,
    required String rateLimitsUrl,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => launchUrl(Uri.parse(modelsUrl)),
              icon: Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: cs.onSecondaryContainer,
              ),
              label: Text(
                l10n.modelsButton,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSecondaryContainer,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.secondaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => launchUrl(Uri.parse(rateLimitsUrl)),
              icon: Icon(
                Icons.speed_outlined,
                size: 16,
                color: cs.onTertiaryContainer,
              ),
              label: Text(
                l10n.rateLimits,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onTertiaryContainer,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.tertiaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyGuide({
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: children.map((child) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 4.0,
            bottom: 4.0,
            right: 16.0,
          ),
          child: Align(alignment: Alignment.centerLeft, child: child),
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

  /// Bidirectional map between app locale codes and AI response language names
  /// for the four supported languages.
  static const Map<String, String> _localeToLanguageMap = {
    'en': 'English',
    'de': 'German',
    'es': 'Spanish',
    'fr': 'French',
  };

  /// Reverse map (language name → locale code), derived from [_localeToLanguageMap]
  /// to ensure a single source of truth when adding new languages.
  static final Map<String, String> _languageToLocaleMap = Map.fromEntries(
    _localeToLanguageMap.entries.map((e) => MapEntry(e.value, e.key)),
  );

  /// Returns the AI response language name for [localeCode], or null when
  /// [localeCode] is null (system default → "Follow App Language") or
  /// unrecognised.
  static String? _localeToAiLanguage(String? localeCode) {
    if (localeCode == null) return null; // system default → follow app
    return _localeToLanguageMap[localeCode]; // null for unrecognized codes
  }

  void _applyLocaleChange(
    String? newLocale,
    String oldLocale, [
    StateSetter? parentSetDialogState,
  ]) {
    ref.read(appSettingsProvider.notifier).setLocale(newLocale);
    // Sync AI response language to match the new app locale
    ref
        .read(appSettingsProvider.notifier)
        .setAiResponseLanguage(_localeToAiLanguage(newLocale));
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
                _applyLocaleChange(
                  value,
                  appSettings.localeCode ?? 'system',
                  parentSetDialogState,
                );
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                _applyLocaleChange(
                  value,
                  appSettings.localeCode ?? 'system',
                  parentSetDialogState,
                );
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageSpanish),
              value: 'es',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                _applyLocaleChange(
                  value,
                  appSettings.localeCode ?? 'system',
                  parentSetDialogState,
                );
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageFrench),
              value: 'fr',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                _applyLocaleChange(
                  value,
                  appSettings.localeCode ?? 'system',
                  parentSetDialogState,
                );
              },
            ),
            RadioListTile<String?>(
              title: Text(l10n.languageGerman),
              value: 'de',
              groupValue: appSettings.localeCode,
              onChanged: (value) {
                _applyLocaleChange(
                  value,
                  appSettings.localeCode ?? 'system',
                  parentSetDialogState,
                );
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

  String _getAiResponseLanguageDisplayName(String? aiResponseLanguage) {
    final l10n = AppLocalizations.of(context)!;
    if (aiResponseLanguage == null) return l10n.aiResponseLanguageFollowApp;
    if (aiResponseLanguage.isEmpty) return l10n.aiResponseLanguageNone;
    return _localizedLanguageName(aiResponseLanguage, l10n);
  }

  String _getExperienceLevelDisplayName(String level) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case 'intermediate':
        return l10n.profileLevelIntermediate;
      case 'advanced':
        return l10n.profileLevelAdvanced;
      case 'expert':
        return l10n.profileLevelExpert;
      default:
        return l10n.profileLevelBeginner;
    }
  }

  void _showExperienceLevelDialog([StateSetter? parentSetDialogState]) {
    final l10n = AppLocalizations.of(context)!;
    final appSettings = ref.read(appSettingsProvider);
    final levels = ['beginner', 'intermediate', 'advanced', 'expert'];
    final descriptions = [
      l10n.aiExperienceLevelBeginnerDesc,
      l10n.aiExperienceLevelIntermediateDesc,
      l10n.aiExperienceLevelAdvancedDesc,
      l10n.aiExperienceLevelExpertDesc,
    ];

    String selected = appSettings.userExperienceLevel;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(l10n.aiExperienceLevel),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(levels.length, (i) {
                  final level = levels[i];
                  final isSelected = selected == level;
                  return RadioListTile<String>(
                    value: level,
                    groupValue: selected,
                    title: Text(_getExperienceLevelDisplayName(level)),
                    subtitle: Text(descriptions[i]),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selected = value);
                      ref
                          .read(appSettingsProvider.notifier)
                          .setUserExperienceLevel(value);
                      AnalyticsService.logSettingsChange(
                        settingName: 'user_experience_level',
                        newValue: value,
                        oldValue: appSettings.userExperienceLevel,
                      );
                      if (parentSetDialogState != null) {
                        parentSetDialogState(() {});
                      }
                    },
                    selected: isSelected,
                  );
                }),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Returns the localized display name for a preset AI response language.
  /// Falls back to the raw [lang] value for custom languages.
  static String _localizedLanguageName(String lang, AppLocalizations l10n) {
    switch (lang) {
      case 'English':
        return l10n.aiResponseLanguageNameEnglish;
      case 'German':
        return l10n.aiResponseLanguageNameGerman;
      case 'Spanish':
        return l10n.aiResponseLanguageNameSpanish;
      case 'French':
        return l10n.aiResponseLanguageNameFrench;
      case 'Portuguese':
        return l10n.aiResponseLanguageNamePortuguese;
      case 'Italian':
        return l10n.aiResponseLanguageNameItalian;
      case 'Japanese':
        return l10n.aiResponseLanguageNameJapanese;
      case 'Chinese':
        return l10n.aiResponseLanguageNameChinese;
      case 'Korean':
        return l10n.aiResponseLanguageNameKorean;
      case 'Dutch':
        return l10n.aiResponseLanguageNameDutch;
      case 'Russian':
        return l10n.aiResponseLanguageNameRussian;
      case 'Arabic':
        return l10n.aiResponseLanguageNameArabic;
      default:
        return lang;
    }
  }

  void _showAiResponseLanguageDialog([StateSetter? parentSetDialogState]) {
    final l10n = AppLocalizations.of(context)!;
    final appSettings = ref.read(appSettingsProvider);

    // Preset options: null = follow app, '' = no instruction, named language otherwise.
    const List<String?> presets = [
      null, // Follow App Language
      '', // No Instruction
      'English',
      'German',
      'Spanish',
      'French',
      'Portuguese',
      'Italian',
      'Japanese',
      'Chinese',
      'Korean',
      'Dutch',
      'Russian',
      'Arabic',
    ];

    // Determine initial dropdown value.
    // Use the special sentinel 'custom' when the stored value is not in presets.
    final isCustom =
        appSettings.aiResponseLanguage != null &&
        appSettings.aiResponseLanguage!.isNotEmpty &&
        !presets.contains(appSettings.aiResponseLanguage);
    String? selectedPreset = isCustom
        ? 'custom'
        : appSettings.aiResponseLanguage;
    final customController = TextEditingController(
      text: isCustom ? appSettings.aiResponseLanguage : '',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void applyChange(String? newValue) {
            ref
                .read(appSettingsProvider.notifier)
                .setAiResponseLanguage(newValue);
            // Sync app locale when the selected AI language is null (follow app)
            // or maps to one of the 4 supported locale codes.
            if (newValue == null) {
              // "Follow App Language" → reset app locale to system default
              ref.read(appSettingsProvider.notifier).setLocale(null);
              CrashlyticsService.setLocale(null);
            } else {
              // O(1) reverse lookup: language name → locale code
              final localeCode = _languageToLocaleMap[newValue];
              if (localeCode != null) {
                ref.read(appSettingsProvider.notifier).setLocale(localeCode);
                CrashlyticsService.setLocale(localeCode);
              }
              // Custom language values: no app locale sync
            }
            AnalyticsService.logSettingsChange(
              settingName: 'ai_response_language',
              newValue: newValue ?? 'follow_app',
              oldValue: appSettings.aiResponseLanguage ?? 'follow_app',
            );
            if (parentSetDialogState != null) parentSetDialogState(() {});
          }

          return AlertDialog(
            title: Text(l10n.aiResponseLanguage),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String?>(
                    value: selectedPreset,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.aiResponseLanguageFollowApp),
                      ),
                      DropdownMenuItem<String?>(
                        value: '',
                        child: Text(l10n.aiResponseLanguageNone),
                      ),
                      ...presets
                          .whereType<String>()
                          .where((p) => p.isNotEmpty)
                          .map(
                            (lang) => DropdownMenuItem<String?>(
                              value: lang,
                              child: Text(_localizedLanguageName(lang, l10n)),
                            ),
                          ),
                      DropdownMenuItem<String?>(
                        value: 'custom',
                        child: Text(l10n.aiResponseLanguageCustom),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedPreset = value);
                      if (value != 'custom') {
                        applyChange(value);
                      }
                    },
                  ),
                  if (selectedPreset == 'custom') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: l10n.aiResponseLanguageCustomHint,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (text) {
                        if (text.trim().isNotEmpty) {
                          applyChange(text.trim());
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() => customController.dispose());
  }

  void _showFeedbackDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.chat_bubble_outline, size: 36),
        iconColor: Colors.orange.shade700,
        title: Text(l10n.contactUs, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.contactUsMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Leave a review option
            _buildFeedbackOption(
              ctx: ctx,
              icon: Icons.star_rate_outlined,
              iconColor: Colors.amber.shade700,
              title: l10n.leaveAReview,
              subtitle: l10n.leaveAReviewDesc,
              onTap: () {
                Navigator.of(ctx).pop();
                InAppReviewService.openStoreListing();
              },
            ),
            const SizedBox(height: 12),
            // Submit issue option
            _buildFeedbackOption(
              ctx: ctx,
              icon: Icons.bug_report_outlined,
              iconColor: Colors.orange.shade700,
              title: l10n.submitAnIssue,
              subtitle: l10n.submitAnIssueDesc,
              onTap: () {
                Navigator.of(ctx).pop();
                launchUrl(
                  Uri.parse(RemoteConfigService.gitHubIssuesUrl),
                  mode: LaunchMode.externalApplication,
                ).catchError((e) {
                  debugPrint('Could not open GitHub issues: $e');
                  return false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOption({
    required BuildContext ctx,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
