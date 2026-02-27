import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../providers/fish_compatibility_provider.dart';
import '../providers/species_tags_provider.dart';
import '../models/fish.dart';
import '../models/compatibility_report.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';
import '../widgets/fish_card.dart';
import '../widgets/ai_error_dialog.dart';
import 'compatibility_report.dart';
import '../services/analytics_service.dart';

class FishCompatibilityScreen extends ConsumerStatefulWidget {
  const FishCompatibilityScreen({super.key});

  @override
  FishCompatibilityScreenState createState() => FishCompatibilityScreenState();
}

class FishCompatibilityScreenState
    extends ConsumerState<FishCompatibilityScreen> {
  String _selectedCategory = 'freshwater';
  OverlayEntry? _loadingOverlayEntry;
  List<Fish> _filteredFishList = [];
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterFishList);
    // Initialize the list on the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAndFilterFishList();
    });
  }

  @override
  void dispose() {
    _loadingOverlayEntry?.remove();
    _searchController.removeListener(_filterFishList);
    _searchController.dispose();
    super.dispose();
  }

  // New method to handle both category changes and search filtering
  void _updateAndFilterFishList() {
    final fishData = ref.read(fishCompatibilityProvider).fishData;
    final allFish = fishData.value?[_selectedCategory] ?? [];
    final query = _searchController.text;

    setState(() {
      if (query.isEmpty) {
        _filteredFishList = allFish;
      } else {
        _filteredFishList = allFish.where((fish) {
          final nameMatches =
              fish.name.toLowerCase().contains(query.toLowerCase());
          final commonNamesMatch = fish.commonNames
              .any((name) => name.toLowerCase().contains(query.toLowerCase()));
          
          // Check species tags
          final tags = ref.read(speciesTagsProvider).tags[fish.name] ?? [];
          final tagsMatch = tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
          
          return nameMatches || commonNamesMatch || tagsMatch;
        }).toList();
      }
    });
  }

  List<Widget> _buildFishGridWithAds(FishCompatibilityState providerState) {
    List<Widget> slivers = [];
    final int totalFish = _filteredFishList.length;
    
    // On web, don't split the grid - use a single continuous grid
    if (kIsWeb) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 210,
              childAspectRatio: 3 / 4,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _filteredFishList.length) {
                  return const SizedBox.shrink();
                }
                final fish = _filteredFishList[index];
                final isSelected = providerState.selectedFish.contains(fish);
                return FishCard(
                  fish: fish,
                  isSelected: isSelected,
                  category: _selectedCategory,
                  showSpeciesTags: _searchController.text.isNotEmpty,
                );
              },
              childCount: totalFish,
            ),
          ),
        ),
      );
    } else {
      // On mobile, split the grid to insert ads
      // Configuration for ad placement
      const int itemsBeforeFirstAd = 6; // Show ad after first 6 fish
      const int itemsBetweenAds = 8; // Show ad every 8 fish thereafter
      
      int fishIndex = 0;
      
      while (fishIndex < totalFish) {
        // Determine how many fish to show before the next ad
        int fishToShow;
        bool shouldShowAd = false;
        
        if (fishIndex == 0) {
          // First batch of fish
          fishToShow = itemsBeforeFirstAd.clamp(0, totalFish - fishIndex);
          shouldShowAd = totalFish > itemsBeforeFirstAd;
        } else {
          // Subsequent batches
          fishToShow = itemsBetweenAds.clamp(0, totalFish - fishIndex);
          shouldShowAd = fishIndex + fishToShow < totalFish;
        }
        
        // Capture the starting index for this section to avoid issues with list changes
        final int startIndex = fishIndex;
        
        // Add a grid of fish cards
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              startIndex == 0 ? 16 : 0,
              16,
              0,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final actualIndex = startIndex + index;
                  // Safety check to prevent index out of bounds
                  if (actualIndex >= _filteredFishList.length) {
                    return const SizedBox.shrink();
                  }
                  final fish = _filteredFishList[actualIndex];
                  final isSelected = providerState.selectedFish.contains(fish);
                  return FishCard(
                    fish: fish,
                    isSelected: isSelected,
                    category: _selectedCategory,
                  );
                },
                childCount: fishToShow,
              ),
            ),
          ),
        );
        
        fishIndex += fishToShow;
        
        // Add native ad if needed
        if (shouldShowAd) {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              sliver: SliverToBoxAdapter(
                child: _buildNativeAdCard(),
              ),
            ),
          );
        }
      }
    }
    
    // Add bottom padding to last sliver
    if (slivers.isNotEmpty) {
      slivers.add(
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 24),
        ),
      );
    }
    
    return slivers;
  }

  Widget _buildNativeAdCard() {
    // This method is only called on mobile platforms
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the width for 2 fish cards plus spacing
        // maxCrossAxisExtent is 210, spacing is 18
        // For 2 cards: (210 * 2) + 18 = 438
        // But we need to be responsive, so we calculate based on available width
        final availableWidth = constraints.maxWidth;
        
        // Calculate approximately how many columns would fit
        final columns = (availableWidth / (210 + 18)).floor();
        
        // Ad should span 2 columns if possible, otherwise full width
        final adWidth = columns >= 2 
            ? (2 * 210.0 + 18.0).clamp(0.0, availableWidth)
            : availableWidth;
        
        return Center(
          child: Container(
            width: adWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            child: const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              child: NativeAdWidget(),
            ),
          ),
        );
      },
    );
  }

  // Renamed for clarity
  void _filterFishList() {
    _updateAndFilterFishList();
  }

  void _showLoadingOverlay(
      BuildContext context, List<Fish> selectedFish, String category) {
    final l10n = AppLocalizations.of(context)!;
    if (_loadingOverlayEntry != null) return;

    _loadingOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 5,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Analyzing Fish...',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: selectedFish
                        .map(
                          (fish) => Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: CachedNetworkImageProvider(fish.imageURL),
                              ),
                              const SizedBox(height: 8),
                              // MODIFIED: This section is now corrected to allow wrapping.
                              SizedBox(
                                width: 100, // Constrains the text width
                                child: Text(
                                  fish.name, // Use the full name
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: Colors.white),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Please wait while the AI generates your compatibility report.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      ref.read(fishCompatibilityProvider.notifier).cancel();
                    },
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_loadingOverlayEntry!);
  }

  void _hideLoadingOverlay() {
    _loadingOverlayEntry?.remove();
    _loadingOverlayEntry = null;
  }

  void _openReport(CompatibilityReport report, {bool fromHistory = false}) {
    showReportDialog(context, report, fromHistory: fromHistory, fishType: _selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final providerState = ref.watch(fishCompatibilityProvider);
    final notifier = ref.read(fishCompatibilityProvider.notifier);

    ref.listen<FishCompatibilityState>(fishCompatibilityProvider,
        (previous, next) {
      if (next.isLoading && !(previous?.isLoading ?? false)) {
        _showLoadingOverlay(context, next.selectedFish, _selectedCategory);
      } else if (!next.isLoading && (previous?.isLoading ?? false)) {
        _hideLoadingOverlay();
      }

      if (next.report != null && previous?.report != next.report) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _openReport(next.report!);
          }
        });
      }

      if (next.error != null && previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showAiErrorDialog(
              context,
              errorMessage: next.error!,
              isApiKeyError: next.isApiKeyError,
              isRetryable: next.isRetryable,
              onRetry: next.isRetryable
                  ? () => notifier.retryCompatibilityReport()
                  : null,
            );
            notifier.clearError();
          }
        });
      }
    });

    final hasLastReport = providerState.lastReport != null;
    final canShowLastReportFab =
        hasLastReport && (providerState.report == null) && !_isSearchVisible;

    final double bottomBarHeight =
        providerState.selectedFish.isNotEmpty ? 84.0 : 0.0;

    return MainLayout(
      title: 'AI Compatibility Calculator',
      bottomNavigationBar: const AdBanner(),
      child: Stack(
        children: [
          providerState.fishData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Failed to load fish data:\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (fishData) {
              if (_filteredFishList.isEmpty && _searchController.text.isEmpty) {
                _filteredFishList = fishData[_selectedCategory] ?? [];
              }
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4),
                      child: Column(
                        children: [
                          Text(
                            'AI Inhabitant Compatibility',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select two or more inhabitants to generate a compatibility report.',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Species tags link
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, '/species-tags'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.label,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tag fish with species names for better search',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildCategorySelector(notifier),
                  ),
                  ..._buildFishGridWithAds(providerState),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24,
                          bottomBarHeight + 80),
                      child: Column(
                        children: [
                          const BannerAdWidget(),
                          const SizedBox(height: 16),
                          Text(
                            'This AI-powered tool helps you check the compatibility of freshwater and marine aquarium inhabitants. Select the fish you\'re interested in, and click "Get Report" to receive a detailed analysis, including recommended tank size, decorations, care guides, and potential conflict risks.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (canShowLastReportFab)
            Positioned(
              bottom: bottomBarHeight + 24,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'last_report_fab',
                icon: const Icon(Icons.history),
                label: Text(l10n.lastReport),
                onPressed: () {
                  final last = providerState.lastReport;
                  if (last != null) {
                    _openReport(last, fromHistory: true);
                  }
                },
              ),
            ),
          Positioned(
            bottom: bottomBarHeight + 24,
            left: 16,
            right: 16,
            child: _buildSearchWidget(canShowLastReportFab),
          ),
          if (providerState.selectedFish.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(providerState, notifier),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchWidget(bool canShowLastReportFab) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _isSearchVisible
          ? _buildSearchBar(canShowLastReportFab)
          : Align(
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton.extended(
                key: const ValueKey('search_fab'),
                heroTag: 'search_fab',
                icon: const Icon(Icons.search),
                label: Text(l10n.search),
                onPressed: () {
                  setState(() {
                    _isSearchVisible = true;
                  });
                },
              ),
            ),
    );
  }

  Widget _buildSearchBar(bool canShowLastReportFab) {
    return Material(
      key: const ValueKey('search_bar'),
      elevation: 6,
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        width: canShowLastReportFab
            ? MediaQuery.of(context).size.width - 180
            : double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name, species...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearchVisible = false;
                    });
                    FocusScope.of(context).unfocus();
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(FishCompatibilityNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          ModernSelectableChip(
            label: 'Freshwater',
            emoji: '🐟',
            selected: _selectedCategory == 'freshwater',
            onTap: () {
              setState(() => _selectedCategory = 'freshwater');
              notifier.clearSelection();
              _searchController.clear();
              _updateAndFilterFishList(); // Bug fix is here
            },
          ),
          ModernSelectableChip(
            label: 'Saltwater',
            emoji: '🪼',
            selected: _selectedCategory == 'marine',
            onTap: () {
              setState(() => _selectedCategory = 'marine');
              notifier.clearSelection();
              _searchController.clear();
              _updateAndFilterFishList(); // And also here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      FishCompatibilityState provider, FishCompatibilityNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.05),
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withOpacity(0.05),
                width: 1.2,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => notifier.clearSelection(),
                tooltip: 'Clear Selection',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.selectedFish.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final fish = provider.selectedFish[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: CachedNetworkImage(
                          imageUrl: fish.imageURL,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 52,
                            height: 52,
                            color: cs.surfaceVariant,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          errorWidget: (c, url, error) => Container(
                            width: 52,
                            height: 52,
                            color: cs.error.withOpacity(0.1),
                            child:
                                Icon(Icons.error, color: cs.error, size: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          // Log fish compatibility report generation analytics
                          AnalyticsService.logFeatureUsed(
                            featureName: 'fish_compatibility_report',
                            parameters: {
                              'selected_category': _selectedCategory,
                              'selected_fish_count': provider.selectedFish.length,
                              'has_fish_selected': provider.selectedFish.isNotEmpty ? 'true' : 'false',
                            },
                          );

                          // Show species selection dialog if any fish have species tags
                          final speciesSelections = await _showSpeciesSelectionDialog(provider.selectedFish);
                          if (!mounted || speciesSelections == null) return;

                          // Build additional notes from species selections
                          String? additionalNotes;
                          final selectedEntries = speciesSelections.entries
                              .where((e) => e.value.isNotEmpty)
                              .toList();
                          if (selectedEntries.isNotEmpty) {
                            final lines = selectedEntries
                                .map((e) => '- ${e.key}: ${e.value.join(', ')}')
                                .join('\n');
                            additionalNotes = 'Specific species selected by user:\n$lines';
                          }

                          // Build filtered selections map (only entries with selections)
                          final filteredSelections = Map<String, List<String>>.fromEntries(
                            speciesSelections.entries.where((e) => e.value.isNotEmpty),
                          );

                          notifier.getCompatibilityReport(
                            _selectedCategory,
                            additionalNotes: additionalNotes,
                            selectedSpecies: filteredSelections,
                          );
                        },
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : const Icon(Icons.analytics_outlined),
                  label: Text(l10n.getReport),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 0.3),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a dialog for the user to select specific species for each selected fish.
  /// Returns a map of fishType -> selected species, or null if the user cancelled.
  Future<Map<String, List<String>>?> _showSpeciesSelectionDialog(List<Fish> selectedFish) async {
    // Wait for default tags to be fully initialized before reading
    await ref.read(speciesTagsProvider.notifier).initialized;

    if (!mounted) return null;
    final speciesTagsState = ref.read(speciesTagsProvider);

    // Only show dialog if any selected fish have commonNames or species tags
    final fishWithTags = selectedFish.where((fish) {
      final tags = speciesTagsState.tags[fish.name] ?? [];
      return tags.isNotEmpty || fish.commonNames.isNotEmpty;
    }).toList();

    if (fishWithTags.isEmpty) return {};

    // Local mutable copy of tags for live updates within the dialog.
    // Merge fish.commonNames with user-added species tags so that new
    // commonNames entries in fish_data.json are always reflected here,
    // just like they are in search and everywhere else in the app.
    final Map<String, List<String>> localTags = {
      for (final fish in fishWithTags)
        fish.name: {
          ...fish.commonNames,
          ...List<String>.from(speciesTagsState.tags[fish.name] ?? [])
        }.toList()
    };

    // Controllers for quick-add inputs (one per fish shown in dialog)
    final Map<String, TextEditingController> addControllers = {
      for (final fish in fishWithTags) fish.name: TextEditingController()
    };

    // Tracks whether the inline add-tag input is visible for each fish
    final Map<String, bool> addTagVisible = {};

    // Tracks whether all species tags are shown (default: show only 3)
    final Map<String, bool> showAllTags = {};

    final Map<String, Set<String>> selectedSpecies = {};

    Map<String, List<String>>? result;
    try {
      result = await showDialog<Map<String, List<String>>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasAnySelection =
                selectedSpecies.values.any((set) => set.isNotEmpty);
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
                constraints: BoxConstraints(
                  // On web, enforce a minimum width so the dialog is
                  // spacious enough to display species chips comfortably.
                  minWidth: kIsWeb ? 500 : 0,
                ),
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
                      final selected = selectedSpecies[fish.name] ?? <String>{};
                      final controller = addControllers[fish.name]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ExpansionTile(
                          title: Text(
                            fish.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          initiallyExpanded: false,
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          children: [
                            if (tags.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  const int defaultLimit = 3;
                                  final showAll = showAllTags[fish.name] == true;
                                  final visibleTags = showAll ? tags : tags.take(defaultLimit).toList();
                                  final hiddenCount = tags.length > defaultLimit ? tags.length - defaultLimit : 0;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: visibleTags.map((tag) {
                                          final isSelected = selected.contains(tag);
                                          return FilterChip(
                                            label: Text(tag, style: TextStyle(
                                              fontSize: 12,
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.onSurface,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            )),
                                            selected: isSelected,
                                            selectedColor: Theme.of(context).colorScheme.primary,
                                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                                            side: BorderSide(
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                            ),
                                            onSelected: (value) {
                                              setDialogState(() {
                                                final set = selectedSpecies.putIfAbsent(
                                                    fish.name, () => <String>{});
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
                                          onPressed: () => setDialogState(() => showAllTags[fish.name] = true),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            'Show $hiddenCount more...',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      if (showAll && tags.length > defaultLimit)
                                        TextButton(
                                          onPressed: () => setDialogState(() => showAllTags[fish.name] = false),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                                          borderRadius: BorderRadius.all(Radius.circular(20)),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        isDense: true,
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                      textCapitalization: TextCapitalization.words,
                                      onSubmitted: (value) {
                                        if (value.trim().isNotEmpty) {
                                          ref.read(speciesTagsProvider.notifier).addTag(fish.name, value.trim());
                                          setDialogState(() {
                                            if (!localTags[fish.name]!.contains(value.trim())) {
                                              localTags[fish.name]!.add(value.trim());
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
                                        ref.read(speciesTagsProvider.notifier).addTag(fish.name, value.trim());
                                        setDialogState(() {
                                          if (!localTags[fish.name]!.contains(value.trim())) {
                                            localTags[fish.name]!.add(value.trim());
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
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    tooltip: 'Cancel',
                                  ),
                                ],
                              )
                            else
                              TextButton.icon(
                                onPressed: () => setDialogState(() => addTagVisible[fish.name] = true),
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(
                                  AppLocalizations.of(context)!.addCustomSpecies,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
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
                  child: const Text('Get Report'),
                ),
              ],
            );
          },
        );
      },
    );
    } finally {
      // Dispose quick-add controllers after dialog closes
      for (final c in addControllers.values) {
        c.dispose();
      }
    }

    return result;
  }
}
