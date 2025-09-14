import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../providers/fish_compatibility_provider.dart';
import '../models/fish.dart';
import '../models/compatibility_report.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';
import '../widgets/fish_card.dart'; // Import the new fish card
import 'compatibility_report.dart';

class FishCompatibilityScreen extends ConsumerStatefulWidget {
  const FishCompatibilityScreen({super.key});

  @override
  FishCompatibilityScreenState createState() => FishCompatibilityScreenState();
}

class FishCompatibilityScreenState
    extends ConsumerState<FishCompatibilityScreen> {
  String _selectedCategory = 'freshwater';
  OverlayEntry? _loadingOverlayEntry;
  // The _filteredFishList state variable has been removed to prevent state inconsistencies.
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Renamed for clarity. This listener just triggers a rebuild.
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _loadingOverlayEntry?.remove();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // This method simply calls setState to trigger a rebuild.
  // The actual filtering logic is now handled declaratively in the build method.
  void _onSearchChanged() {
    setState(() {});
  }

  void _showLoadingOverlay(
      BuildContext context, List<Fish> selectedFish, String category) {
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
                                backgroundImage: NetworkImage(fish.imageURL),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                fish.name.split(' ')[0],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
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
                    child: const Text('Cancel'),
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
    showReportDialog(context, report, fromHistory: fromHistory);
  }

  @override
  Widget build(BuildContext context) {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                duration: const Duration(seconds: 6),
                action: next.isRetryable
                    ? SnackBarAction(
                        label: 'Retry',
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          notifier.retryCompatibilityReport();
                        },
                      )
                    : SnackBarAction(
                        label: 'Dismiss',
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
              ),
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
              final allFish = fishData[_selectedCategory] ?? [];
              
              // The list is now filtered directly within the build method.
              // This ensures the UI is always in sync with the state.
              final query = _searchController.text;
              final filteredFishList = allFish.where((fish) {
                if (query.isEmpty) {
                  return true;
                }
                final nameMatches =
                    fish.name.toLowerCase().contains(query.toLowerCase());
                final commonNamesMatch = fish.commonNames.any(
                    (name) => name.toLowerCase().contains(query.toLowerCase()));
                return nameMatches || commonNamesMatch;
              }).toList();

              if (allFish.isEmpty) {
                return const Center(
                    child: Text('No fish found for this category.'));
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
                            'AI Fish Compatibility',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select two or more fish to generate a compatibility report.',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildCategorySelector(notifier),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 210,
                        childAspectRatio: 3 / 4,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final fish = filteredFishList[index];
                          final isSelected =
                              providerState.selectedFish.contains(fish);
                          return FishCard(
                            fish: fish,
                            isSelected: isSelected,
                          );
                        },
                        childCount: filteredFishList.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: BannerAdWidget(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24,
                          bottomBarHeight + 80), // Padding to avoid bottom bar
                      child: Text(
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
                label: const Text('Last Report'),
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
                label: const Text('Search'),
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
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search by name...',
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
              if (_selectedCategory != 'freshwater') {
                setState(() => _selectedCategory = 'freshwater');
                notifier.clearSelection();
                _searchController.clear();
              }
            },
          ),
          ModernSelectableChip(
            label: 'Saltwater',
            emoji: '🐠',
            selected: _selectedCategory == 'marine',
            onTap: () {
              if (_selectedCategory != 'marine') {
                setState(() => _selectedCategory = 'marine');
                notifier.clearSelection();
                _searchController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      FishCompatibilityState provider, FishCompatibilityNotifier notifier) {
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
                        child: Image.network(
                          fish.imageURL,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
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
              ElevatedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => notifier.getCompatibilityReport(_selectedCategory),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: const Text('Get Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}