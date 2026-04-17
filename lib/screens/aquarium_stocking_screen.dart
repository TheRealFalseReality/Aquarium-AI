import 'package:cached_network_image/cached_network_image.dart';
import 'package:fish_ai/widgets/ad_component.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../providers/app_settings_provider.dart';
import '../providers/aquarium_stocking_provider.dart';
import '../providers/model_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/species_tags_provider.dart';
import '../services/analytics_service.dart';
import '../services/interstitial_ad_service.dart';
import '../widgets/ai_error_dialog.dart';
import '../widgets/fish_selection_dialog.dart';
import '../widgets/founder_upsell_banner.dart';
import '../widgets/interstitial_ad_blurb.dart';
import '../widgets/modern_chip.dart';
import 'stocking_report_screen.dart';

class AquariumStockingScreen extends ConsumerStatefulWidget {
  const AquariumStockingScreen({super.key});

  @override
  AquariumStockingScreenState createState() => AquariumStockingScreenState();
}

class AquariumStockingScreenState
    extends ConsumerState<AquariumStockingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tankSizeController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'freshwater';
  String _selectedUnit = 'gallons';
  Map<String, List<String>>? _speciesSelections;
  final InterstitialAdService _interstitialAdService = InterstitialAdService();

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'aquarium_stocking_screen');
    _interstitialAdService.load();
  }

  @override
  void dispose() {
    _tankSizeController.dispose();
    _notesController.dispose();
    _interstitialAdService.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    if (_formKey.currentState!.validate()) {
      // Show interstitial ad for eligible free-tier users when they tap
      // Get Recommendations (before analysis starts).
      final modelState = ref.read(modelProvider);
      final adsRemoved = ref.read(purchaseProvider).adsRemoved;
      final debugHideAds =
          kDebugMode && ref.read(appSettingsProvider).debugHideAds;
      final interstitialEligible =
          !kIsWeb &&
          modelState.usingDeveloperGroqKeyForText &&
          !adsRemoved &&
          !debugHideAds;
      if (interstitialEligible) {
        _interstitialAdService.showIfEligible(
          onWillShow: () {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.freeTierAdNotice),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      }

      // Build tank size string with unit (empty if not provided)
      final rawTankSize = _tankSizeController.text.trim();
      final tankSizeWithUnit = rawTankSize.isEmpty
          ? ''
          : '$rawTankSize $_selectedUnit';
      final state = ref.read(aquariumStockingProvider);

      // Log actual feature usage
      AnalyticsService.logFeatureUsed(
        featureName: 'aquarium_stocking_assistant',
        parameters: {
          'tank_size': tankSizeWithUnit,
          'tank_type': _selectedCategory,
          'tank_unit': _selectedUnit,
          'has_notes': _notesController.text.isNotEmpty ? 'true' : 'false',
          'notes_length': _notesController.text.length,
          'selected_fish_count': state.selectedFish.length,
          'has_selected_fish': state.selectedFish.isNotEmpty ? 'true' : 'false',
        },
      );

      ref
          .read(aquariumStockingProvider.notifier)
          .getStockingRecommendations(
            tankSize: tankSizeWithUnit,
            tankType: _selectedCategory,
            userNotes: _notesController.text,
            speciesSelections: _speciesSelections,
          );
    }
  }

  Future<void> _openFishSelectionDialog() async {
    final state = ref.read(aquariumStockingProvider);
    final result = await showDialog(
      context: context,
      builder: (context) => FishSelectionDialog(
        category: _selectedCategory,
        initialSelectedFish: state.selectedFish,
      ),
    );

    if (result != null && result is List) {
      final fishList = result.cast<Fish>();
      // Clear and set selected fish
      ref.read(aquariumStockingProvider.notifier).clearSelectedFish();
      for (var fish in fishList) {
        ref.read(aquariumStockingProvider.notifier).selectFish(fish);
      }
      // Show species selection popup immediately after confirming fish
      if (mounted) {
        final selections = await _showSpeciesSelectionDialog(fishList);
        if (mounted) {
          setState(() {
            _speciesSelections = selections;
          });
        }
      }
    }
  }

  /// Shows a species selection dialog for the selected fish, matching the
  /// AI Compatibility Tool's flow. Returns a map of fishName -> selected species,
  /// an empty map if no selections were made, or null if the user cancelled.
  Future<Map<String, List<String>>?> _showSpeciesSelectionDialog(
    List<Fish> selectedFish,
  ) async {
    // Wait for default tags to be fully initialized before reading
    await ref.read(speciesTagsProvider.notifier).initialized;
    if (!mounted) return null;
    final speciesTagsState = ref.read(speciesTagsProvider);

    // Only show dialog if any selected fish have commonNames or species tags
    final fishWithTags = selectedFish.where((fish) {
      final tags = speciesTagsState.tags[fish.name] ?? [];
      return tags.isNotEmpty || fish.commonNames.isNotEmpty;
    }).toList();

    // No fish have any tags/commonNames – proceed directly without a dialog
    if (fishWithTags.isEmpty) return {};

    // Merge fish.commonNames with user-added species tags
    final Map<String, List<String>> localTags = {
      for (final fish in fishWithTags)
        fish.name: {
          ...fish.commonNames,
          ...List<String>.from(speciesTagsState.tags[fish.name] ?? []),
        }.toList(),
    };

    final Map<String, TextEditingController> addControllers = {
      for (final fish in fishWithTags) fish.name: TextEditingController(),
    };
    final Map<String, bool> addTagVisible = {};
    final Map<String, bool> showAllTags = {};
    final Map<String, Set<String>> selectedSpecies = {};

    Map<String, List<String>>? result;
    try {
      result = await showDialog<Map<String, List<String>>>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final hasAnySelection = selectedSpecies.values.any(
                (set) => set.isNotEmpty,
              );
              return AlertDialog(
                insetPadding: kIsWeb
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                title: Row(
                  children: [
                    const Expanded(child: Text('Select Specific Species')),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                content: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: kIsWeb ? 500 : 0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Optionally select specific species to refine the AI analysis.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        ...fishWithTags.map((fish) {
                          final tags = localTags[fish.name] ?? [];
                          final selected =
                              selectedSpecies[fish.name] ?? <String>{};
                          final controller = addControllers[fish.name]!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ExpansionTile(
                              title: Text(
                                fish.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              initiallyExpanded: false,
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(bottom: 8),
                              children: [
                                if (tags.isNotEmpty)
                                  Builder(
                                    builder: (context) {
                                      const int defaultLimit = 3;
                                      final showAll =
                                          showAllTags[fish.name] == true;
                                      final visibleTags = showAll
                                          ? tags
                                          : tags.take(defaultLimit).toList();
                                      final hiddenCount =
                                          tags.length > defaultLimit
                                          ? tags.length - defaultLimit
                                          : 0;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: visibleTags.map((tag) {
                                              final isSelected = selected
                                                  .contains(tag);
                                              return FilterChip(
                                                label: Text(
                                                  tag,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isSelected
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .onPrimary
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                selected: isSelected,
                                                selectedColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                checkmarkColor: Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                                side: BorderSide(
                                                  color: isSelected
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.primary
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .outline
                                                            .withOpacity(0.5),
                                                ),
                                                onSelected: (value) {
                                                  setDialogState(() {
                                                    final set = selectedSpecies
                                                        .putIfAbsent(
                                                          fish.name,
                                                          () => <String>{},
                                                        );
                                                    if (value) {
                                                      set.add(tag);
                                                    } else {
                                                      set.remove(tag);
                                                    }
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          ),
                                          if (!showAll && hiddenCount > 0)
                                            TextButton(
                                              onPressed: () => setDialogState(
                                                () => showAllTags[fish.name] =
                                                    true,
                                              ),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 0,
                                                    ),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Text(
                                                'Show $hiddenCount more...',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          if (showAll &&
                                              tags.length > defaultLimit)
                                            TextButton(
                                              onPressed: () => setDialogState(
                                                () => showAllTags[fish.name] =
                                                    false,
                                              ),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 0,
                                                    ),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: const Text(
                                                'Show less',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                const SizedBox(height: 6),
                                if (addTagVisible[fish.name] == true)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: controller,
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                            hintText: 'Add species...',
                                            hintStyle: TextStyle(fontSize: 12),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(20),
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                          textCapitalization:
                                              TextCapitalization.words,
                                          onSubmitted: (value) {
                                            if (value.trim().isNotEmpty) {
                                              ref
                                                  .read(
                                                    speciesTagsProvider
                                                        .notifier,
                                                  )
                                                  .addTag(
                                                    fish.name,
                                                    value.trim(),
                                                  );
                                              setDialogState(() {
                                                if (!localTags[fish.name]!
                                                    .contains(value.trim())) {
                                                  localTags[fish.name]!.add(
                                                    value.trim(),
                                                  );
                                                }
                                              });
                                            }
                                            setDialogState(() {
                                              controller.clear();
                                              addTagVisible[fish.name] = false;
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          final value = controller.text;
                                          if (value.trim().isNotEmpty) {
                                            ref
                                                .read(
                                                  speciesTagsProvider.notifier,
                                                )
                                                .addTag(
                                                  fish.name,
                                                  value.trim(),
                                                );
                                            setDialogState(() {
                                              if (!localTags[fish.name]!
                                                  .contains(value.trim())) {
                                                localTags[fish.name]!.add(
                                                  value.trim(),
                                                );
                                              }
                                            });
                                          }
                                          setDialogState(() {
                                            controller.clear();
                                            addTagVisible[fish.name] = false;
                                          });
                                        },
                                        icon: const Icon(Icons.check, size: 18),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        tooltip: 'Confirm',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            controller.clear();
                                            addTagVisible[fish.name] = false;
                                          });
                                        },
                                        icon: const Icon(Icons.close, size: 18),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        tooltip: 'Cancel',
                                      ),
                                    ],
                                  )
                                else
                                  TextButton.icon(
                                    onPressed: () => setDialogState(
                                      () => addTagVisible[fish.name] = true,
                                    ),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text(
                                      'Add Custom Species',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      side: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline.withOpacity(0.4),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (hasAnySelection)
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedSpecies.clear();
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      final result = selectedSpecies.map(
                        (key, value) => MapEntry(key, value.toList()),
                      );
                      Navigator.pop(context, result);
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      for (final c in addControllers.values) {
        c.dispose();
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AquariumStockingState>(aquariumStockingProvider, (
      previous,
      next,
    ) {
      if (!context.mounted) return;
      // Show/hide loading overlay
      if (next.isLoading && !(previous?.isLoading ?? false)) {
        _showLoadingOverlay(context);
      } else if (!next.isLoading && (previous?.isLoading ?? false)) {
        _hideLoadingOverlay();
      }

      // Show error dialog when a new error is received.
      if (next.error != null && previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showAiErrorDialog(
              context,
              errorMessage: next.error!,
              isApiKeyError: next.isApiKeyError,
              isRetryable: next.isRetryable,
              isRateLimitError: next.isRateLimitError,
              isQuotaError: next.isQuotaError,
              isNetworkError: next.isNetworkError,
            );
            ref.read(aquariumStockingProvider.notifier).cancel();
          }
        });
      }

      if (next.recommendations != null && next.recommendations!.isNotEmpty) {
        // Build tank size string with unit (empty if not provided)
        final rawTankSize = _tankSizeController.text.trim();
        final tankSizeWithUnit = rawTankSize.isEmpty
            ? ''
            : '$rawTankSize $_selectedUnit';
        // Capture recommendations before clearing them from state so the
        // report screen keeps a valid reference.
        final reports = next.recommendations!;
        // Clear recommendations immediately so that subsequent state changes
        // (e.g. tapping a different fish-type chip) don't re-trigger navigation.
        ref.read(aquariumStockingProvider.notifier).clearRecommendations();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StockingReportScreen(
              reports: reports,
              tankSize: tankSizeWithUnit,
              tankType: _selectedCategory,
              userNotes: _notesController.text,
            ),
          ),
        );
      }
    });

    final state = ref.watch(aquariumStockingProvider);
    final modelState = ref.watch(modelProvider);
    final cs = Theme.of(context).colorScheme;
    final hasLastReport =
        state.lastRecommendations != null &&
        state.lastRecommendations!.isNotEmpty;

    return MainLayout(
      title: 'Aquarium Stocking Assistant',
      bottomNavigationBar: const AdBanner(),
      floatingActionButton: hasLastReport
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StockingReportScreen(
                      reports: state.lastRecommendations!,
                    ),
                  ),
                );
              },
              label: Text(l10n.lastReport),
              icon: const Icon(Icons.history),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FounderUpsellBanner(
            usingDevAiKey: modelState.usingDeveloperGroqKeyForText,
          ),
          InterstitialAdBlurb(
            usingDevAiKey: modelState.usingDeveloperGroqKeyForText,
          ),
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'AI Stocking Assistant',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get AI-powered stocking ideas for your aquarium.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  ModernSelectableChip(
                    label: 'Freshwater',
                    emoji: '🐟',
                    selected: _selectedCategory == 'freshwater',
                    onTap: () {
                      setState(() => _selectedCategory = 'freshwater');
                      // Clear selected fish when changing category
                      ref
                          .read(aquariumStockingProvider.notifier)
                          .clearSelectedFish();
                    },
                  ),
                  ModernSelectableChip(
                    label: 'Saltwater',
                    emoji: '🐠',
                    selected: _selectedCategory == 'marine',
                    onTap: () {
                      setState(() => _selectedCategory = 'marine');
                      // Clear selected fish when changing category
                      ref
                          .read(aquariumStockingProvider.notifier)
                          .clearSelectedFish();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Species selection – shown right after fish type so the user can
              // optionally pick specific species from the chosen category before
              // entering tank details.
              OutlinedButton.icon(
                onPressed: _openFishSelectionDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  state.selectedFish.isEmpty
                      ? l10n.selectFishTypes
                      : '${l10n.selectFishTypes} (${state.selectedFish.length})',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: cs.tertiaryContainer,
                ),
              ),
              if (state.selectedFish.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.selectedFish,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final currentFish = ref
                                      .read(aquariumStockingProvider)
                                      .selectedFish;
                                  if (currentFish.isEmpty) return;
                                  final selections =
                                      await _showSpeciesSelectionDialog(
                                        currentFish,
                                      );
                                  if (mounted && selections != null) {
                                    setState(() {
                                      _speciesSelections = selections.isEmpty
                                          ? null
                                          : selections;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.tune, size: 16),
                                label: Text(l10n.selectSpecies),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  ref
                                      .read(aquariumStockingProvider.notifier)
                                      .clearSelectedFish();
                                  setState(() {
                                    _speciesSelections = null;
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 16),
                                label: Text(l10n.clear),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.selectedFish.map((fish) {
                          final speciesForFish = _speciesSelections?[fish.name];
                          final speciesLabel =
                              (speciesForFish != null &&
                                  speciesForFish.isNotEmpty)
                              ? speciesForFish.join(', ')
                              : null;
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                fish.imageURL,
                              ),
                            ),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(fish.name),
                                if (speciesLabel != null)
                                  Text(
                                    speciesLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cs.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            onDeleted: () {
                              ref
                                  .read(aquariumStockingProvider.notifier)
                                  .selectFish(fish);
                            },
                            deleteIcon: const Icon(Icons.close, size: 18),
                            backgroundColor: cs.secondaryContainer,
                            side: BorderSide(
                              color: cs.secondary.withOpacity(0.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _tankSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Tank Size (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if ((value == null || value.trim().isEmpty) &&
                            state.selectedFish.isEmpty &&
                            _notesController.text.trim().isEmpty) {
                          return 'Enter a tank size, select fish, or add notes';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'gallons',
                          child: Text(l10n.gallons),
                        ),
                        DropdownMenuItem(
                          value: 'liters',
                          child: Text(l10n.liters),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedUnit = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (e.g., "I want a peaceful community tank")',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade400,
                      Colors.blue.shade500,
                      Colors.cyan.shade400,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: state.isLoading ? null : _getRecommendations,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(l10n.getRecommendations),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const NativeAdWidget(),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
        ],
      ),
    );
  }

  void _showLoadingOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false, // Prevent back button during loading
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.gettingStockingRecommendations),
                    const SizedBox(height: 8),
                    const Text(
                      'This may take up to 60 seconds',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        ref.read(aquariumStockingProvider.notifier).cancel();
                        Navigator.pop(context);
                      },
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingOverlay() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
