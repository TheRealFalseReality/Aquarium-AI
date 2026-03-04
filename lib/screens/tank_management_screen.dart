import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../models/notification_log.dart';
import '../models/tank.dart';
import '../models/tank_notification.dart';
import '../providers/app_settings_provider.dart';
import '../providers/aquarium_stocking_provider.dart';
import '../providers/fish_compatibility_provider.dart';
import '../providers/model_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/tank_provider.dart';
import '../providers/tank_tags_provider.dart';
import '../services/analytics_service.dart';
import '../services/fish_data_service.dart';
import '../services/interstitial_ad_service.dart';
import '../services/notification_service.dart';
import '../utils/backup_restore_utils.dart';
import '../utils/tank_harmony_calculator.dart';
import '../widgets/accessible_feedback.dart';
import '../widgets/ad_component.dart';
import '../widgets/notification_reschedule_dialog.dart';
import '../widgets/stocking_recommendation_options_dialog.dart';
import '../widgets/tag_picker_dialog.dart';
import 'compatibility_report.dart';
import 'notification_logger_screen.dart';
import 'notification_management_screen.dart';
import 'photo_analysis_screen.dart';
import 'tank_creation_screen.dart';
import 'tank_details_screen.dart';
import 'tank_stocking_report_screen.dart';

enum TankSortOption { name, type, size, date }

class TankManagementScreen extends ConsumerStatefulWidget {
  const TankManagementScreen({super.key});

  @override
  TankManagementScreenState createState() => TankManagementScreenState();
}

class TankManagementScreenState extends ConsumerState<TankManagementScreen> {
  TankSortOption _currentSortOption = TankSortOption.name;
  bool _isSortAscending = true; // Track sort direction (ascending/descending)
  Tank?
  _currentTankForRecommendations; // Track current tank for recommendations
  List<Fish>? _currentExistingFish; // Track existing fish for recommendations
  bool _isSortMenuExpanded = false; // Track sort menu expansion
  String _additionalNotes = ''; // Track additional notes
  Tank?
  _currentTankForCompatibility; // Track current tank for compatibility analysis
  bool _isCompatibilityLoading =
      false; // Track if compatibility analysis is in progress
  String? _filterByType; // Filter by tank type ('freshwater' or 'marine')
  bool _filterByReef =
      false; // Filter to reef tanks only (only applies when _filterByType == 'marine')
  Set<String> _filterByTags = {}; // Filter by selected tank tags
  bool _showSortFilterAttention = false; // First-launch animation flag
  static const String _sortFilterAttentionKey =
      'tank_sort_filter_attention_shown';
  final InterstitialAdService _interstitialAdService = InterstitialAdService();

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    _checkSortFilterAttention();
    _interstitialAdService.load();
  }

  Future<void> _loadSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sortIndex = prefs.getInt('tank_sort_option') ?? 0;
      if (sortIndex < TankSortOption.values.length) {
        setState(() {
          _currentSortOption = TankSortOption.values[sortIndex];
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _checkSortFilterAttention() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool(_sortFilterAttentionKey) ?? false;
      if (!shown) {
        setState(() {
          _showSortFilterAttention = true;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _markSortFilterAttentionShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sortFilterAttentionKey, true);
      if (mounted) {
        setState(() {
          _showSortFilterAttention = false;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveSortPreference(TankSortOption option) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tank_sort_option', option.index);
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _interstitialAdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tankState = ref.watch(tankProvider);
    final appSettings = ref.watch(appSettingsProvider);
    // Watch the centralized fish data provider
    final fishDataAsync = ref.watch(fishDataProvider);
    final fishData = fishDataAsync.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );

    // Listen for stocking recommendations globally
    ref.listen<AquariumStockingState>(aquariumStockingProvider, (
      previous,
      next,
    ) {
      if (!context.mounted) return;
      if (next.recommendations != null && next.recommendations!.isNotEmpty) {
        // Hide loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        // Check if we have the required data
        final tank = _currentTankForRecommendations;
        final fish = _currentExistingFish;

        if (tank != null && fish != null) {
          // Capture values before clearing to ensure they're available in the builder
          final capturedAdditionalNotes = _additionalNotes;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TankStockingReportScreen(
                reports: next.recommendations!,
                originalTank: tank,
                existingFish: fish,
                additionalNotes: capturedAdditionalNotes,
              ),
            ),
          );
          // Clear the current tank reference and options
          _currentTankForRecommendations = null;
          _currentExistingFish = null;
          _additionalNotes = '';
        } else {
          context.showAccessibleMessage(
            'Error: Missing tank data. Please try again.',
          );
        }
      }
      if (next.error != null) {
        // Hide loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        // Show error with appropriate action
        context.showAccessibleMessage(
          'Error: ${next.error}',
          onAction: next.error!.toLowerCase().contains('api key not set')
              ? () => Navigator.pushNamed(context, '/settings')
              : null,
          actionLabel: next.error!.toLowerCase().contains('api key not set')
              ? 'Settings'
              : null,
        );
      }
    });

    // Listen for compatibility analysis reports
    ref.listen<FishCompatibilityState>(fishCompatibilityProvider, (
      previous,
      next,
    ) {
      if (!context.mounted) return;
      if (next.report != null &&
          previous?.report != next.report &&
          _currentTankForCompatibility != null) {
        // Hide loading dialog if it's showing
        if (_isCompatibilityLoading && Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close loading dialog
          _isCompatibilityLoading = false;
        }

        // Show the compatibility report
        if (context.mounted) {
          showReportDialog(
            context,
            next.report!,
            fishType: _currentTankForCompatibility!.type,
          );
        }

        // Clear the current tank reference
        _currentTankForCompatibility = null;
      }

      if (next.error != null &&
          previous?.error != next.error &&
          _currentTankForCompatibility != null) {
        // Hide loading dialog if it's showing
        if (_isCompatibilityLoading && Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close loading dialog
          _isCompatibilityLoading = false;
        }

        // Show error with appropriate action
        if (context.mounted) {
          context.showAccessibleMessage(
            next.error!,
            onAction: next.error!.toLowerCase().contains('api key not set')
                ? () => Navigator.pushNamed(context, '/settings')
                : null,
            actionLabel: next.error!.toLowerCase().contains('api key not set')
                ? 'Settings'
                : null,
          );
          ref.read(fishCompatibilityProvider.notifier).clearError();
        }

        // Clear the current tank reference
        _currentTankForCompatibility = null;
      }
    });

    return MainLayout(
      title: l10n.myTanks,
      bottomNavigationBar: const AdBanner(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const TankCreationScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.createTank),
      ),
      child: tankState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tankState.error != null
          ? _buildErrorState(context, ref, tankState.error!)
          : tankState.tanks.isEmpty
          ? _buildEmptyState(context, ref)
          : _buildTankListWithFloatingMenu(
              context,
              ref,
              tankState.tanks,
              fishData,
              appSettings,
            ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingTanks,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(tankProvider.notifier).clearError();
                // Trigger reload by creating a new notifier
                ref.invalidate(tankProvider);
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.water,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noTanksYetTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noTanksYetDescription,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action buttons
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TankCreationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createFirstTank),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      l10n.orRestoreFromBackup,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => BackupRestoreUtils.importData(
                        context,
                        ref,
                        source: 'tank_management',
                      ),
                      icon: const Icon(Icons.restore, size: 18),
                      label: Text(l10n.restore),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => BackupRestoreUtils.importTankShare(
                    context,
                    ref,
                    source: 'tank_management_empty',
                  ),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(l10n.importTank),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTankListWithFloatingMenu(
    BuildContext context,
    WidgetRef ref,
    List<Tank> tanks,
    Map<String, List<Fish>>? fishData,
    AppSettingsState appSettings,
  ) {
    return Stack(
      children: [
        _buildTankList(context, ref, tanks, fishData, appSettings),
        if (_isSortMenuExpanded)
          GestureDetector(
            onTap: () {
              setState(() {
                _isSortMenuExpanded = false;
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.3),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        if (_isSortMenuExpanded) _buildFloatingSortMenu(context, tanks),
      ],
    );
  }

  Widget _buildTankList(
    BuildContext context,
    WidgetRef ref,
    List<Tank> tanks,
    Map<String, List<Fish>>? fishData,
    AppSettingsState appSettings,
  ) {
    final filteredTanks = _filterTanks(tanks);
    final sortedTanks = _sortTanks(filteredTanks);
    final screenWidth = MediaQuery.of(context).size.width;
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;

    // Use grid layout for larger screens (tablets and desktops) OR when user enables grid on mobile
    final useGridLayout = screenWidth >= 900 || appSettings.tankGridLayout;

    if (useGridLayout) {
      // Column count: 3 for large screens, 2 otherwise
      final int columnCount = screenWidth >= 1400 ? 3 : 2;

      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildHeader(
                context,
                ref,
                sortedTanks.length,
                appSettings,
              ),
            ),
          ),
          // Masonry grid layout with native ads
          ..._buildTankGridWithAds(
            context,
            ref,
            sortedTanks,
            fishData,
            appSettings,
            columnCount,
            adsRemoved: adsRemoved,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      );
    }

    // Use list layout for mobile devices with native ads
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _calculateListItemCount(sortedTanks.length),
      itemBuilder: (context, index) {
        return _buildListItem(
          context,
          ref,
          index,
          sortedTanks,
          fishData,
          appSettings,
        );
      },
    );
  }

  List<Widget> _buildTankGridWithAds(
    BuildContext context,
    WidgetRef ref,
    List<Tank> tanks,
    Map<String, List<Fish>>? fishData,
    AppSettingsState appSettings,
    int columnCount, {
    bool adsRemoved = false,
  }) {
    // If ads are removed, render all tanks in a single unbroken masonry grid
    if (adsRemoved) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: columnCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: tanks.length,
            itemBuilder: (context, index) {
              return _buildTankCard(
                context,
                ref,
                tanks[index],
                fishData,
                appSettings,
              );
            },
          ),
        ),
      ];
    }

    // Configuration for ad placement
    const int tanksBeforeFirstAd = 4; // Show ad after first 4 tanks
    const int tanksBetweenAds = 6; // Show ad every 6 tanks thereafter

    List<Widget> slivers = [];
    int tankIndex = 0;

    while (tankIndex < tanks.length) {
      // Determine how many tanks to show before the next ad
      int tanksToShow;
      bool shouldShowAd = false;

      if (tankIndex == 0) {
        // First batch of tanks
        tanksToShow = tanksBeforeFirstAd.clamp(0, tanks.length - tankIndex);
        shouldShowAd = tanks.length > tanksBeforeFirstAd;
      } else {
        // Subsequent batches
        tanksToShow = tanksBetweenAds.clamp(0, tanks.length - tankIndex);
        shouldShowAd = tankIndex + tanksToShow < tanks.length;
      }

      // Capture the starting index for this section
      final int startIndex = tankIndex;

      // Add a grid section with N tanks
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, startIndex == 0 ? 0 : 16, 16, 0),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: columnCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: tanksToShow,
            itemBuilder: (context, index) {
              final actualIndex = startIndex + index;
              if (actualIndex >= tanks.length) {
                return const SizedBox.shrink();
              }
              return _buildTankCard(
                context,
                ref,
                tanks[actualIndex],
                fishData,
                appSettings,
              );
            },
          ),
        ),
      );

      tankIndex += tanksToShow;

      // Add native ad if needed
      if (shouldShowAd) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(child: _buildNativeAdCard(context)),
          ),
        );
      }
    }

    return slivers;
  }

  int _calculateListItemCount(int tankCount) {
    // Configuration for ad placement
    const int tanksBeforeFirstAd = 4;
    const int tanksBetweenAds = 6;

    int itemCount = 1; // Start with header
    int remainingTanks = tankCount;

    if (remainingTanks <= tanksBeforeFirstAd) {
      return itemCount + remainingTanks;
    }

    // Add first batch
    itemCount += tanksBeforeFirstAd;
    remainingTanks -= tanksBeforeFirstAd;

    // Add ad after first batch
    if (remainingTanks > 0) {
      itemCount++; // Native ad
    }

    // Add remaining batches with ads
    while (remainingTanks > 0) {
      final batch = tanksBetweenAds.clamp(0, remainingTanks);
      itemCount += batch;
      remainingTanks -= batch;

      if (remainingTanks > 0) {
        itemCount++; // Native ad
      }
    }

    return itemCount;
  }

  Widget _buildListItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    List<Tank> tanks,
    Map<String, List<Fish>>? fishData,
    AppSettingsState appSettings,
  ) {
    // Configuration for ad placement
    const int tanksBeforeFirstAd = 4;
    const int tanksBetweenAds = 6;

    // Header is always at index 0
    if (index == 0) {
      return _buildHeader(context, ref, tanks.length, appSettings);
    }

    // Calculate actual tank index and whether this should be an ad
    int adjustedIndex = index - 1; // Subtract header
    int tanksSeen = 0;

    // Determine position
    if (adjustedIndex < tanksBeforeFirstAd) {
      // First batch, no ads yet
      return _buildTankCard(
        context,
        ref,
        tanks[adjustedIndex],
        fishData,
        appSettings,
      );
    }

    adjustedIndex -= tanksBeforeFirstAd;
    tanksSeen = tanksBeforeFirstAd;

    // Check if we should show first ad
    if (adjustedIndex == 0 && tanks.length > tanksBeforeFirstAd) {
      return _buildNativeAdCard(context);
    }

    if (adjustedIndex > 0) {
      adjustedIndex -= 1; // Account for first ad
    }

    // Remaining items alternate between tank batches and ads
    final batchSize = tanksBetweenAds + 1; // tanks + ad
    final batchNumber = adjustedIndex ~/ batchSize;
    final positionInBatch = adjustedIndex % batchSize;

    tanksSeen += batchNumber * tanksBetweenAds;

    if (positionInBatch < tanksBetweenAds) {
      // Tank position
      final tankIndex = tanksSeen + positionInBatch;
      if (tankIndex < tanks.length) {
        return _buildTankCard(
          context,
          ref,
          tanks[tankIndex],
          fishData,
          appSettings,
        );
      }
    } else {
      // Ad position
      final tankIndex = tanksSeen + tanksBetweenAds;
      if (tankIndex < tanks.length) {
        return _buildNativeAdCard(context);
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildNativeAdCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: const ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        child: NativeAdWidget(),
      ),
    );
  }

  List<Tank> _filterTanks(List<Tank> tanks) {
    return tanks.where((tank) {
      // Filter by type
      if (_filterByType != null && tank.type != _filterByType) {
        return false;
      }
      // Filter by reef (only applicable when filtering by marine)
      if (_filterByReef && !tank.isReef) {
        return false;
      }
      // Filter by tags (tank must have ANY of the selected tag names)
      if (_filterByTags.isNotEmpty &&
          !_filterByTags.any((name) => tank.tags.any((t) => t.name == name))) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Tank> _sortTanks(List<Tank> tanks) {
    final sortedTanks = List<Tank>.from(tanks);

    switch (_currentSortOption) {
      case TankSortOption.name:
        sortedTanks.sort((a, b) {
          final comparison = a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          );
          return _isSortAscending ? comparison : -comparison;
        });
        break;
      case TankSortOption.type:
        sortedTanks.sort((a, b) {
          final typeOrder = {'freshwater': 0, 'marine': 1};
          final aOrder = typeOrder[a.type] ?? 2;
          final bOrder = typeOrder[b.type] ?? 2;
          if (aOrder != bOrder) {
            final comparison = aOrder.compareTo(bOrder);
            return _isSortAscending ? comparison : -comparison;
          }
          return a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ); // Secondary sort by name
        });
        break;
      case TankSortOption.size:
        sortedTanks.sort((a, b) {
          final aSize = a.sizeGallons ?? 0;
          final bSize = b.sizeGallons ?? 0;
          if (aSize != bSize) {
            final comparison = bSize.compareTo(aSize); // Default largest first
            return _isSortAscending ? comparison : -comparison;
          }
          return a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ); // Secondary sort by name
        });
        break;
      case TankSortOption.date:
        // Sort by creation date (default newest first)
        sortedTanks.sort((a, b) {
          final comparison = b.createdAt.compareTo(a.createdAt);
          return _isSortAscending ? comparison : -comparison;
        });
        break;
    }

    return sortedTanks;
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    int tankCount,
    AppSettingsState appSettings,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with 3-dot menu
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.myTanks} ($tankCount)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Sort & Filter & View menu (with optional first-launch pulse animation)
              _showSortFilterAttention
                  ? _PulseRingWidget(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isSortMenuExpanded = !_isSortMenuExpanded;
                          });
                          _markSortFilterAttentionShown();
                        },
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              _isSortMenuExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                            ),
                            if (_filterByType != null ||
                                _filterByReef ||
                                _filterByTags.isNotEmpty)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getSortOptionIcon(_currentSortOption),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(_getSortOptionLabel(_currentSortOption)),
                            const SizedBox(width: 4),
                            Icon(
                              _isSortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                            ),
                          ],
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          side:
                              (_filterByType != null ||
                                  _filterByReef ||
                                  _filterByTags.isNotEmpty)
                              ? BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isSortMenuExpanded = !_isSortMenuExpanded;
                        });
                      },
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            _isSortMenuExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                          ),
                          if (_filterByType != null ||
                              _filterByReef ||
                              _filterByTags.isNotEmpty)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSortOptionIcon(_currentSortOption),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(_getSortOptionLabel(_currentSortOption)),
                          const SizedBox(width: 4),
                          Icon(
                            _isSortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                          ),
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        side:
                            (_filterByType != null ||
                                _filterByReef ||
                                _filterByTags.isNotEmpty)
                            ? BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                    ),
              const SizedBox(width: 8),

              // 3-dot menu for backup/restore/import
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'backup':
                      BackupRestoreUtils.exportData(
                        context,
                        ref,
                        source: 'tank_management',
                      );
                      break;
                    case 'restore':
                      BackupRestoreUtils.importData(
                        context,
                        ref,
                        source: 'tank_management',
                      );
                      break;
                    case 'import_tank':
                      BackupRestoreUtils.importTankShare(
                        context,
                        ref,
                        source: 'tank_management',
                      );
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'backup',
                    child: Row(
                      children: [
                        const Icon(Icons.backup, color: Colors.blue),
                        const SizedBox(width: 8),
                        Flexible(child: Text(l10n.backup)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'restore',
                    child: Row(
                      children: [
                        const Icon(Icons.restore, color: Colors.green),
                        const SizedBox(width: 8),
                        Flexible(child: Text(l10n.restore)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'import_tank',
                    child: Row(
                      children: [
                        const Icon(Icons.download, color: Colors.teal),
                        const SizedBox(width: 8),
                        Flexible(child: Text(l10n.importTank)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getSortOptionLabel(TankSortOption option) {
    final l10n = AppLocalizations.of(context)!;

    switch (option) {
      case TankSortOption.name:
        return l10n.sortByName;
      case TankSortOption.type:
        return l10n.sortByType;
      case TankSortOption.size:
        return l10n.sortBySize;
      case TankSortOption.date:
        return l10n.sortByDate;
    }
  }

  IconData _getSortOptionIcon(TankSortOption option) {
    switch (option) {
      case TankSortOption.name:
        return Icons.sort_by_alpha;
      case TankSortOption.type:
        return Icons.category;
      case TankSortOption.size:
        return Icons.straighten;
      case TankSortOption.date:
        return Icons.schedule;
    }
  }

  Widget _buildFloatingSortMenu(BuildContext context, List<Tank> allTanks) {
    final l10n = AppLocalizations.of(context)!;
    // Collect unique TankTag objects (by name) across all tanks for filter chips.
    final tagsByName = <String, TankTag>{};
    for (final tank in allTanks) {
      for (final tag in tank.tags) {
        tagsByName.putIfAbsent(tag.name, () => tag);
      }
    }
    final sortedAllTags = tagsByName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final hasActiveFilters =
        _filterByType != null || _filterByReef || _filterByTags.isNotEmpty;

    return Positioned(
      top: 100, // Position below the header
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isSortMenuExpanded ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _isSortMenuExpanded ? 1.0 : 0.8,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.sortAndFilter,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasActiveFilters)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _filterByType = null;
                                  _filterByReef = false;
                                  _filterByTags = {};
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.clearFilters,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isSortMenuExpanded = false;
                              });
                            },
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sort section
                  Text(
                    l10n.sortBy,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TankSortOption.values.map((option) {
                      final isSelected = _currentSortOption == option;
                      return ActionChip(
                        avatar: Icon(
                          _getSortOptionIcon(option),
                          size: 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        label: Text(_getSortOptionLabel(option)),
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_currentSortOption == option) {
                              _isSortAscending = !_isSortAscending;
                            } else {
                              _currentSortOption = option;
                              _isSortAscending = true;
                            }
                            _isSortMenuExpanded = false;
                          });
                          _saveSortPreference(option);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  // Filter by tank type
                  Text(
                    l10n.filterByType,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        avatar: const Text(
                          '🐟',
                          style: TextStyle(fontSize: 14),
                        ),
                        label: Text(l10n.freshwater),
                        selected: _filterByType == 'freshwater',
                        onSelected: (selected) {
                          setState(() {
                            _filterByType = selected ? 'freshwater' : null;
                            _filterByReef = false;
                          });
                        },
                      ),
                      FilterChip(
                        avatar: const Text(
                          '🪼',
                          style: TextStyle(fontSize: 14),
                        ),
                        label: Text(l10n.saltwater),
                        selected: _filterByType == 'marine',
                        onSelected: (selected) {
                          setState(() {
                            _filterByType = selected ? 'marine' : null;
                            _filterByReef = false;
                          });
                        },
                      ),
                      if (_filterByType == 'marine')
                        FilterChip(
                          avatar: const Text(
                            '🪸',
                            style: TextStyle(fontSize: 14),
                          ),
                          label: Text(l10n.filterByReef),
                          selected: _filterByReef,
                          onSelected: (selected) {
                            setState(() {
                              _filterByReef = selected;
                            });
                          },
                        ),
                    ],
                  ),
                  // Filter by tags (only shown if any tanks have tags)
                  if (sortedAllTags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.filterByTag,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sortedAllTags.map((tag) {
                        final isSelected = _filterByTags.contains(tag.name);
                        final tagColor = tag.color != null
                            ? Color(tag.color!)
                            : Theme.of(context).colorScheme.secondary;
                        final onTagColor = tagColor.computeLuminance() > 0.4
                            ? Colors.black87
                            : Colors.white;
                        return FilterChip(
                          label: Text(
                            tag.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? onTagColor : null,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: tagColor.withOpacity(0.85),
                          checkmarkColor: onTagColor,
                          side: isSelected
                              ? BorderSide(color: tagColor, width: 1.5)
                              : null,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _filterByTags = {..._filterByTags, tag.name};
                              } else {
                                _filterByTags = _filterByTags
                                    .where((n) => n != tag.name)
                                    .toSet();
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  // View section
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.viewSection,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final appSettings = ref.watch(appSettingsProvider);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile.adaptive(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              appSettings.tankGridLayout
                                  ? l10n.switchToListView
                                  : l10n.switchToGridView,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            secondary: Icon(
                              appSettings.tankGridLayout
                                  ? Icons.view_list
                                  : Icons.grid_view,
                              size: 20,
                            ),
                            value: appSettings.tankGridLayout,
                            onChanged: (val) {
                              ref
                                  .read(appSettingsProvider.notifier)
                                  .setTankGridLayout(val);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.cardContent,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildVisibilityChip(
                                context,
                                Icons.image_outlined,
                                l10n.tankIconLabel,
                                appSettings.tankHideIcon,
                                (v) => ref
                                    .read(appSettingsProvider.notifier)
                                    .setTankHideIcon(v),
                              ),
                              _buildVisibilityChip(
                                context,
                                Icons.bar_chart,
                                l10n.metricsLabel,
                                appSettings.tankHideMetrics,
                                (v) => ref
                                    .read(appSettingsProvider.notifier)
                                    .setTankHideMetrics(v),
                              ),
                              _buildVisibilityChip(
                                context,
                                Icons.pets,
                                l10n.inhabitantsLabel,
                                appSettings.tankHideInhabitants,
                                (v) => ref
                                    .read(appSettingsProvider.notifier)
                                    .setTankHideInhabitants(v),
                              ),
                              _buildVisibilityChip(
                                context,
                                Icons.note_outlined,
                                l10n.notes,
                                appSettings.tankHideNotes,
                                (v) => ref
                                    .read(appSettingsProvider.notifier)
                                    .setTankHideNotes(v),
                              ),
                              _buildVisibilityChip(
                                context,
                                Icons.bolt_outlined,
                                l10n.quickLogs,
                                appSettings.tankHideQuickLogs,
                                (v) => ref
                                    .read(appSettingsProvider.notifier)
                                    .setTankHideQuickLogs(v),
                              ),
                              _buildVisibilityChip(
                                context,
                                Icons.history,
                                l10n.activityHistory,
                                appSettings.tankHideActivity,
                                (v) => ref
                                    .read(appSettingsProvider.notifier)
                                    .setTankHideActivity(v),
                              ),
                              _buildVisibilityChip(
                                context,
                                Icons.photo_library_outlined,
                                l10n.photos,
                                appSettings.tankHidePhotos,
                                (v) => ref
                                    .read(appSettingsProvider.notifier)
                                    .setTankHidePhotos(v),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityChip(
    BuildContext context,
    IconData icon,
    String label,
    bool isHidden,
    void Function(bool) onToggle,
  ) {
    final isVisible = !isHidden;
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isVisible ? cs.onPrimary : cs.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isVisible ? cs.onPrimary : cs.onSurfaceVariant,
        ),
      ),
      selected: isVisible,
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceVariant,
      showCheckmark: false,
      onSelected: (selected) => onToggle(!selected),
    );
  }

  Widget _buildTankCard(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
    Map<String, List<Fish>>? fishData,
    AppSettingsState appSettings,
  ) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 900;
    // Grid mode: mobile grid (not tablet/desktop which always uses the masonry grid)
    final isGridMode = appSettings.tankGridLayout && !isLargeScreen;

    // Get custom background photo if set
    TankPhoto? backgroundPhoto;
    if (tank.customBackgroundPhotoId != null) {
      try {
        backgroundPhoto = tank.photos.firstWhere(
          (photo) => photo.id == tank.customBackgroundPhotoId,
        );
      } catch (e) {
        // Photo not found, use default
      }
    }

    // AI-inspired gradient colors based on tank type
    final gradientColors = tank.type == 'freshwater'
        ? [
            Colors.blue.shade400.withOpacity(0.15),
            Colors.cyan.shade300.withOpacity(0.15),
            cs.primaryContainer.withOpacity(0.5),
          ]
        : [
            Colors.indigo.shade400.withOpacity(0.15),
            Colors.purple.shade300.withOpacity(0.15),
            cs.secondaryContainer.withOpacity(0.5),
          ];

    // Build the tank icon widget (reused in both list and grid headers)
    final tankIconWidget = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient:
            tank.customIconCodePoint == null && tank.customIconPhotoId == null
            ? LinearGradient(
                colors: tank.type == 'freshwater'
                    ? [Colors.blue.shade300, Colors.cyan.shade400]
                    : [Colors.indigo.shade300, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color:
            tank.customIconCodePoint == null && tank.customIconPhotoId != null
            ? Colors.grey.shade300
            : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (tank.type == 'freshwater' ? Colors.blue : Colors.purple)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tank.customIconCodePoint != null
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tank.type == 'freshwater'
                      ? [Colors.blue.shade300, Colors.cyan.shade400]
                      : [Colors.indigo.shade300, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getIconFromCodePoint(tank.customIconCodePoint) ??
                    (tank.type == 'freshwater'
                        ? Icons.water_drop
                        : Icons.waves),
                size: 24,
                color: Colors.white,
              ),
            )
          : (tank.customIconPhotoId != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: () {
                      try {
                        final photo = tank.photos.firstWhere(
                          (p) => p.id == tank.customIconPhotoId,
                        );
                        final imageUrl = photo.imageUrl ?? photo.imagePath;
                        return imageUrl != null
                            ? (imageUrl.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            tank.type == 'freshwater'
                                                ? Icons.water_drop
                                                : Icons.waves,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                    )
                                  : Image.file(
                                      File(imageUrl),
                                      fit: BoxFit.cover,
                                    ))
                            : Icon(
                                tank.type == 'freshwater'
                                    ? Icons.water_drop
                                    : Icons.waves,
                                size: 24,
                                color: Colors.white,
                              );
                      } catch (e) {
                        return Icon(
                          tank.type == 'freshwater'
                              ? Icons.water_drop
                              : Icons.waves,
                          size: 24,
                          color: Colors.white,
                        );
                      }
                    }(),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      tank.type == 'freshwater'
                          ? Icons.water_drop
                          : Icons.waves,
                      size: 24,
                      color: Colors.white,
                    ),
                  )),
    );

    // Build the 3-dot popup menu (shared between list/grid)
    final menuButton = PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.more_vert, size: 18),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TankCreationScreen(existingTank: tank),
              ),
            );
            break;
          case 'manage_tags':
            _showManageTagsDialog(context, ref, tank);
            break;
          case 'notifications':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NotificationManagementScreen(tank: tank),
              ),
            );
            break;
          case 'activity_log':
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NotificationLoggerScreen(tank: tank),
              ),
            );
            break;
          case 'set_background':
            _showSetBackgroundDialog(context, ref, tank);
            break;
          case 'set_icon':
            _showSetIconDialog(context, ref, tank);
            break;
          case 'reset_background':
            _resetTankBackground(context, ref, tank);
            break;
          case 'recommendations':
            _getTankStockingRecommendations(tank);
            break;
          case 'compatibility_analysis':
            _getTankCompatibilityAnalysis(tank);
            break;
          case 'duplicate':
            _duplicateTank(context, ref, tank);
            break;
          case 'share_tank':
            BackupRestoreUtils.shareTank(context, ref, tank);
            break;
          case 'delete':
            _confirmDelete(context, ref, tank);
            break;
        }
      },
      itemBuilder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.editTank)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'manage_tags',
            child: Row(
              children: [
                const Icon(Icons.label_outline, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.manageTags)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'notifications',
            child: Row(
              children: [
                const Icon(Icons.notifications, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.notificationsExperimental,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'activity_log',
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.activityLog,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          if (tank.photos.isNotEmpty)
            PopupMenuItem(
              value: 'set_background',
              child: Row(
                children: [
                  const Icon(Icons.wallpaper, size: 18),
                  const SizedBox(width: 8),
                  Flexible(child: Text(l10n.setCardBackground)),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'set_icon',
            child: Row(
              children: [
                const Icon(Icons.emoji_emotions_outlined, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.changeIcon)),
              ],
            ),
          ),
          if (tank.customBackgroundPhotoId != null)
            PopupMenuItem(
              value: 'reset_background',
              child: Row(
                children: [
                  const Icon(Icons.restore, size: 18),
                  const SizedBox(width: 8),
                  Flexible(child: Text(l10n.resetBackground)),
                ],
              ),
            ),
          if (tank.inhabitants.isNotEmpty && appSettings.enableAI)
            PopupMenuItem(
              value: 'recommendations',
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.getStockingIdeas,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          if (tank.inhabitants.isNotEmpty && appSettings.enableAI)
            PopupMenuItem(
              value: 'compatibility_analysis',
              child: Row(
                children: [
                  const Icon(Icons.biotech, color: Colors.teal, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.compatibilityAnalysis,
                      style: const TextStyle(color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                const Icon(Icons.copy, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.duplicate)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'share_tank',
            child: Row(
              children: [
                const Icon(Icons.share, color: Colors.teal, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.shareTank,
                    style: const TextStyle(color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.deleteTank,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );

    return Container(
      margin: (isLargeScreen || appSettings.tankGridLayout)
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        gradient: backgroundPhoto == null
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: backgroundPhoto != null
            ? DecorationImage(
                image: (backgroundPhoto.imageUrl?.startsWith('http') ?? false)
                    ? CachedNetworkImageProvider(backgroundPhoto.imageUrl!)
                          as ImageProvider
                    : FileImage(File(backgroundPhoto.imagePath!)),
                fit: BoxFit.cover,
                opacity: 0.8,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              )
            : null,
        color: backgroundPhoto != null ? cs.surfaceContainerHighest : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TankDetailsScreen(tank: tank),
                  ),
                );
              },
              child: Padding(
                padding: isGridMode
                    ? const EdgeInsets.all(12.0)
                    : const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: isGridMode
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    // Header: grid mode = icon centered + name below;
                    //         list mode = icon + name side-by-side + menu
                    if (isGridMode) ...[
                      if (!appSettings.tankHideIcon)
                        Center(child: tankIconWidget),
                      if (!appSettings.tankHideIcon) const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          String typeLabel;
                          if (tank.type == 'freshwater') {
                            typeLabel = l10n.freshwater;
                          } else if (tank.isReef) {
                            typeLabel = l10n.reefTank;
                          } else {
                            typeLabel = l10n.saltwater;
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                tank.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (tank.type == 'marine' && tank.isReef)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Text(
                                        '🪸',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  Text(
                                    typeLabel,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!appSettings.tankHideIcon) tankIconWidget,
                          if (!appSettings.tankHideIcon)
                            const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tank.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Builder(
                                  builder: (context) {
                                    final l10n = AppLocalizations.of(context)!;
                                    String typeLabel;
                                    if (tank.type == 'freshwater') {
                                      typeLabel = l10n.freshwater;
                                    } else if (tank.isReef) {
                                      typeLabel = l10n.reefTank;
                                    } else {
                                      typeLabel = l10n.saltwater;
                                    }
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (tank.type == 'marine' &&
                                            tank.isReef)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 4),
                                            child: Text(
                                              '🪸',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        Text(
                                          typeLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: cs.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          menuButton,
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Tank stats row
                    if (!appSettings.tankHideMetrics) ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (tank.sizeGallons != null ||
                              tank.sizeLiters != null)
                            _buildStatChip(
                              context,
                              Icons.straighten,
                              _formatTankSize(tank),
                            ),
                          if (tank.inhabitants.isNotEmpty && fishData != null)
                            _buildHarmonyScoreChip(tank),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Inhabitants section with modern styling
                    if (!appSettings.tankHideInhabitants) ...[
                      if (tank.inhabitants.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pets,
                                color: cs.onSurfaceVariant,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Builder(
                                  builder: (context) {
                                    final l10n = AppLocalizations.of(context)!;
                                    return Text(
                                      l10n.noInhabitantsYet,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: isGridMode
                              ? CrossAxisAlignment.center
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pets,
                                    size: 14,
                                    color: cs.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 6),
                                  if (isGridMode) ...[
                                    // 2-line layout in grid mode
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_getTotalInhabitantCount(tank.inhabitants)} inhabitant${_getTotalInhabitantCount(tank.inhabitants) == 1 ? '' : 's'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: cs.onPrimaryContainer,
                                              ),
                                        ),
                                        Text(
                                          '${_groupInhabitantsByFishType(tank.inhabitants).length} type${_groupInhabitantsByFishType(tank.inhabitants).length == 1 ? '' : 's'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: cs.onPrimaryContainer,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Text(
                                      '${_getTotalInhabitantCount(tank.inhabitants)} inhabitant${_getTotalInhabitantCount(tank.inhabitants) == 1 ? '' : 's'}, ${_groupInhabitantsByFishType(tank.inhabitants).length} type${_groupInhabitantsByFishType(tank.inhabitants).length == 1 ? '' : 's'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: cs.onPrimaryContainer,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._buildFishGroupDisplay(tank, fishData),
                          ],
                        ),
                    ],

                    // end tankHideInhabitants
                    const SizedBox(height: 14),

                    // Tank photos section (if photos exist)
                    if (!appSettings.tankHidePhotos &&
                        tank.photos.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tank Photos (${tank.photos.length})',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tank.photos.length,
                          itemBuilder: (context, index) {
                            final photo = tank.photos[index];
                            final imageUrl = photo.imageUrl ?? photo.imagePath;
                            return GestureDetector(
                              onTap: () => _showPhotoMaximized(
                                context,
                                photo,
                                tank: tank,
                                ref: ref,
                              ),
                              child: Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: cs.outline,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: imageUrl != null
                                      ? (imageUrl.startsWith('http')
                                            ? CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Container(
                                                      color: cs.errorContainer,
                                                      child: Icon(
                                                        Icons.error_outline,
                                                        size: 20,
                                                        color:
                                                            cs.onErrorContainer,
                                                      ),
                                                    ),
                                              )
                                            : Image.file(
                                                File(imageUrl),
                                                fit: BoxFit.cover,
                                              ))
                                      : Container(
                                          color: cs.surfaceVariant,
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 20,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Tank notes section (if notes exist)
                    if (!appSettings.tankHideNotes &&
                        tank.notes != null &&
                        tank.notes!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tank.notes!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Tank tags section (if tags exist)
                    if (tank.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tank.tags.map((tag) {
                          final tagColor = tag.color != null
                              ? Color(tag.color!)
                              : cs.secondary;
                          final onTagColor = tagColor.computeLuminance() > 0.4
                              ? Colors.black87
                              : Colors.white;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: tagColor, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.label_outline,
                                  size: 12,
                                  color: onTagColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tag.name,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: onTagColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Activity Log and Upcoming Notifications section
                    _buildActivitySection(
                      context,
                      ref,
                      tank,
                      cs,
                      inGridMode: isGridMode,
                      hideActivity: appSettings.tankHideActivity,
                      hideQuickLogs: appSettings.tankHideQuickLogs,
                    ),

                    // Action buttons - hidden in grid mode (accessible via 3-dot menu)
                    if (!isGridMode) ...[
                      Row(
                        children: [
                          // AI stocking button - conditionally shown based on app settings
                          if (tank.inhabitants.isNotEmpty &&
                              appSettings.enableAI &&
                              appSettings.showStockingButton)
                            Expanded(
                              child: Container(
                                height: 44,
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
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _getTankStockingRecommendations(tank),
                                  icon: const Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Stocking Ideas',
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (tank.inhabitants.isNotEmpty &&
                              appSettings.enableAI &&
                              appSettings.showStockingButton)
                            const SizedBox(width: 8),
                          // AI compatibility analysis button
                          if (tank.inhabitants.isNotEmpty &&
                              appSettings.enableAI &&
                              appSettings.showStockingButton)
                            Expanded(
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.shade400,
                                      Colors.green.shade500,
                                      Colors.cyan.shade300,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _getTankCompatibilityAnalysis(tank),
                                  icon: const Icon(Icons.biotech, size: 16),
                                  label: Text(
                                    'Compatibility',
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Footer with date
                    Text(
                      'Created ${_formatDate(tank.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isGridMode) Positioned(top: 4, right: 4, child: menuButton),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the activity section for the tank card showing:
  /// 1. Most recent activity log entry
  /// 2. ALL configured notifications as quick log buttons (2 per row)
  ///    - Shows time until next occurrence
  ///    - Highlights notifications within 12 hours
  ///    - Tapping logs the activity instantly
  Widget _buildActivitySection(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
    ColorScheme cs, {
    bool inGridMode = false,
    bool hideActivity = false,
    bool hideQuickLogs = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final List<Widget> recentActivityItems = [];
    final List<Widget> notificationItems = [];

    // Get most recent activity log
    if (!hideActivity && tank.notificationLogs.isNotEmpty) {
      final sortedLogs = List.from(tank.notificationLogs)
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      final recentLog = sortedLogs.first;

      // Calculate time ago in hours/minutes for today, otherwise days
      final now = DateTime.now();
      final difference = now.difference(recentLog.loggedAt);
      final hoursAgo = difference.inHours;
      final minutesAgo = difference.inMinutes % 60;
      final daysSince = difference.inDays;

      String timeAgo;
      if (daysSince == 0) {
        // Today - show hours/minutes ago
        if (hoursAgo > 0) {
          timeAgo = hoursAgo == 1 ? l10n.oneHourAgo : l10n.xHoursAgo(hoursAgo);
        } else if (minutesAgo > 0) {
          timeAgo = minutesAgo == 1
              ? l10n.oneMinuteAgo
              : l10n.xMinutesAgo(minutesAgo);
        } else {
          timeAgo = l10n.justNow;
        }
      } else if (daysSince == 1) {
        timeAgo = l10n.yesterday;
      } else if (daysSince < 7) {
        timeAgo = l10n.daysAgo(daysSince);
      } else {
        timeAgo =
            '${recentLog.loggedAt.month}/${recentLog.loggedAt.day}/${recentLog.loggedAt.year}';
      }

      recentActivityItems.add(
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getActivityIcon(recentLog.type),
                size: 16,
                color: _getActivityColor(recentLog.type),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recentLog.getDisplayName(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show ALL configured notifications as quick log buttons (2 per row)
    // Quick log cards are shown regardless of whether the notification is enabled
    // because activity logging is separate from receiving device notifications
    final now = DateTime.now();

    for (final notification in tank.notifications) {
      if (hideQuickLogs) continue;
      // Calculate next notification date for display
      DateTime? nextDate;
      if (notification.repeatFrequency != RepeatFrequency.none) {
        nextDate = notification.getNextNotificationDateWithActivity(
          tank.notificationLogs,
        );
      } else {
        nextDate = notification.notificationDateTime;
      }

      // Calculate time display for the next occurrence
      String timeDisplay;
      bool isPast = false;
      bool isWithin12Hours = false;

      if (nextDate != null) {
        isPast = nextDate.isBefore(now);
        final twelveHoursFromNow = now.add(const Duration(hours: 12));
        final twelveHoursAgo = now.subtract(const Duration(hours: 12));
        isWithin12Hours =
            nextDate.isBefore(twelveHoursFromNow) &&
            nextDate.isAfter(twelveHoursAgo);

        if (isPast) {
          // Past - show how long ago
          final difference = now.difference(nextDate);
          final hoursAgo = difference.inHours;
          final minutesAgo = difference.inMinutes % 60;
          final daysSince = difference.inDays;

          if (daysSince > 0) {
            timeDisplay = daysSince == 1
                ? l10n.yesterday
                : l10n.daysAgo(daysSince);
          } else if (hoursAgo > 0) {
            timeDisplay = hoursAgo == 1
                ? l10n.oneHourAgo
                : l10n.xHoursAgo(hoursAgo);
          } else if (minutesAgo > 0) {
            timeDisplay = minutesAgo == 1
                ? l10n.oneMinuteAgo
                : l10n.xMinutesAgo(minutesAgo);
          } else {
            timeDisplay = l10n.justNow;
          }
        } else {
          // Future - show time until
          final hoursUntil = nextDate.difference(now).inHours;
          final minutesUntil = nextDate.difference(now).inMinutes % 60;
          final daysUntil = nextDate.difference(now).inDays;

          if (daysUntil > 0) {
            if (daysUntil == 1) {
              timeDisplay = l10n.inLessThan2Days;
            } else {
              timeDisplay = l10n.inXDays(daysUntil);
            }
          } else if (hoursUntil > 0) {
            if (hoursUntil == 1) {
              timeDisplay = l10n.inLessThan2Hours;
            } else {
              timeDisplay = l10n.inXHours(hoursUntil);
            }
          } else if (minutesUntil > 0) {
            timeDisplay = minutesUntil == 1
                ? l10n.inOneMinute
                : l10n.inXMinutes(minutesUntil);
          } else {
            timeDisplay = l10n.inLessThanAMinute;
          }
        }
      } else {
        timeDisplay = notification.repeatFrequency.displayName;
      }

      notificationItems.add(
        _buildNotificationQuickLogItem(
          context,
          ref,
          tank,
          notification,
          cs,
          timeDisplay,
          isPast,
          isWithin12Hours,
        ),
      );
    }

    if (recentActivityItems.isEmpty && notificationItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent activity section
        ...recentActivityItems,

        // Notifications section (1 per row in grid mode, 2 per row otherwise)
        if (notificationItems.isNotEmpty) ...[
          if (recentActivityItems.isNotEmpty) const SizedBox(height: 10),
          // Use LayoutBuilder directly (avoid adding a flex child inside an
          // unbounded Column which causes RenderFlex assertions).
          LayoutBuilder(
            builder: (context, constraints) {
              // In grid mode use full width (1 per row), otherwise 2 per row
              final itemWidth = inGridMode
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: notificationItems
                    .map((item) => SizedBox(width: itemWidth, child: item))
                    .toList(),
              );
            },
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  /// Build a compact notification quick log item for 2-per-row layout
  Widget _buildNotificationQuickLogItem(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
    TankNotification notification,
    ColorScheme cs,
    String timeDisplay,
    bool isPast,
    bool isWithin12Hours,
  ) {
    final activityColor = _getActivityColor(notification.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _quickLogFromCard(tank, notification),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: activityColor.withOpacity(isWithin12Hours ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activityColor.withOpacity(isWithin12Hours ? 0.4 : 0.2),
              width: isWithin12Hours ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getActivityIcon(notification.type),
                size: 16,
                color: activityColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.getDisplayName(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timeDisplay,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPast && isWithin12Hours
                            ? Colors.red
                            : activityColor,
                        fontSize: 10,
                        fontWeight: isWithin12Hours
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: activityColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Icons.restaurant;
      case NotificationType.dosing:
        return Icons.medication_liquid;
      case NotificationType.waterChange:
        return Icons.water_drop;
      case NotificationType.testing:
        return Icons.science;
      case NotificationType.maintenance:
        return Icons.build;
      case NotificationType.other:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(NotificationType type) {
    switch (type) {
      case NotificationType.feeding:
        return Colors.orange;
      case NotificationType.dosing:
        return Colors.purple;
      case NotificationType.waterChange:
        return Colors.blue;
      case NotificationType.testing:
        return Colors.teal;
      case NotificationType.maintenance:
        return Colors.brown;
      case NotificationType.other:
        return Colors.grey;
    }
  }

  Future<void> _quickLogFromCard(
    Tank tank,
    TankNotification notification,
  ) async {
    // Get the latest tank state from the provider
    final currentTank = ref
        .read(tankProvider)
        .tanks
        .firstWhere((t) => t.id == tank.id, orElse: () => tank);

    // Create a new log entry based on the notification type and custom category
    final log = NotificationLog.create(
      type: notification.type,
      customCategory: notification.type == NotificationType.other
          ? (notification.customCategory ?? 'Other')
          : null,
      notes: notification.notes,
      notificationId: notification.id,
    );

    // Check if this notification has a repeat frequency (only repeating notifications need rescheduling dialog)
    RescheduleOption? rescheduleOption;
    if (notification.repeatFrequency != RepeatFrequency.none && mounted) {
      // Ask user how they want to update the notification schedule BEFORE saving
      rescheduleOption = await NotificationRescheduleDialog.show(
        context,
        notification,
      );

      // Refresh the app settings state to reflect any newly remembered preference
      await ref
          .read(appSettingsProvider.notifier)
          .refreshRememberedRescheduleOptions();

      // If user cancelled (null) or chose cancelAll, don't log the activity
      if (rescheduleOption == null ||
          rescheduleOption == RescheduleOption.cancelAll) {
        return; // Exit early - don't log or reschedule
      }
    }

    // Now save the activity log
    final updatedLogs = [...currentTank.notificationLogs, log];
    final updatedTank = currentTank.copyWith(
      notificationLogs: updatedLogs,
      updatedAt: DateTime.now(),
    );

    await ref.read(tankProvider.notifier).updateTank(updatedTank);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showAccessibleMessage(l10n.activityLogged);

      // Handle the reschedule option if one was selected
      if (rescheduleOption != null &&
          rescheduleOption != RescheduleOption.doNothing) {
        await _handleRescheduleOption(
          currentTank,
          notification,
          log,
          updatedLogs,
          rescheduleOption,
        );
      }
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'quick_log_from_card',
      parameters: {
        'type': notification.type.name,
        'has_custom_category': notification.customCategory != null
            ? 'true'
            : 'false',
      },
    );

    AnalyticsService.logTankAction(
      action: 'quick_log_from_card',
      tankType: currentTank.type,
    );
  }

  /// Handle the reschedule option selected by the user
  Future<void> _handleRescheduleOption(
    Tank tank,
    TankNotification notification,
    NotificationLog log,
    List<NotificationLog> updatedLogs,
    RescheduleOption option,
  ) async {
    final notificationService = NotificationService();
    final l10n = AppLocalizations.of(context)!;

    // Get the latest tank state
    final currentTank = ref
        .read(tankProvider)
        .tanks
        .firstWhere((t) => t.id == tank.id, orElse: () => tank);

    switch (option) {
      case RescheduleOption.rescheduleFromNow:
        // Reschedule based on the activity log date (which is now), using current time
        final updatedNotifications = await notificationService
            .rescheduleMatchingNotifications(
              tankId: currentTank.id,
              tankName: currentTank.name,
              notifications: currentTank.notifications,
              activityLogs: updatedLogs,
              activityType: log.type,
              activityCustomCategory: log.customCategory,
              useCurrentTime: true,
            );

        // Persist the updated notifications
        if (updatedNotifications.isNotEmpty) {
          final notificationsList = currentTank.notifications.map((n) {
            final updated = updatedNotifications.firstWhere(
              (u) => u.id == n.id,
              orElse: () => n,
            );
            return updated;
          }).toList();
          final updatedTank = currentTank.copyWith(
            notifications: notificationsList,
            updatedAt: DateTime.now(),
          );
          await ref.read(tankProvider.notifier).updateTank(updatedTank);
        }

        if (mounted) {
          context.showAccessibleMessage(l10n.notificationUpdated);
        }
        break;

      case RescheduleOption.keepOriginal:
        // Reschedule to same date as rescheduleFromNow but keep original notification time
        final updatedNotifications = await notificationService
            .rescheduleMatchingNotifications(
              tankId: currentTank.id,
              tankName: currentTank.name,
              notifications: currentTank.notifications,
              activityLogs: updatedLogs,
              activityType: log.type,
              activityCustomCategory: log.customCategory,
              useCurrentTime: false, // Keep original time
            );

        // Persist the updated notifications
        if (updatedNotifications.isNotEmpty) {
          final notificationsList = currentTank.notifications.map((n) {
            final updated = updatedNotifications.firstWhere(
              (u) => u.id == n.id,
              orElse: () => n,
            );
            return updated;
          }).toList();
          final updatedTank = currentTank.copyWith(
            notifications: notificationsList,
            updatedAt: DateTime.now(),
          );
          await ref.read(tankProvider.notifier).updateTank(updatedTank);
        }

        if (mounted) {
          context.showAccessibleMessage(l10n.notificationUpdated);
        }
        break;

      case RescheduleOption.doNothing:
        // Don't reschedule - activity is already logged, just keep existing schedule
        break;

      case RescheduleOption.cancelAll:
        // Cancel - don't log activity and don't reschedule
        // Remove the log that was just added
        final logsWithoutNew = updatedLogs
            .where((l) => l.id != log.id)
            .toList();
        final updatedTank = currentTank.copyWith(
          notificationLogs: logsWithoutNew,
          updatedAt: DateTime.now(),
        );
        await ref.read(tankProvider.notifier).updateTank(updatedTank);
        break;
    }

    AnalyticsService.logFeatureUsed(
      featureName: 'notification_reschedule_option',
      parameters: {
        'option': option.name,
        'notification_type': notification.type.name,
      },
    );
  }

  void _showPhotoMaximized(
    BuildContext context,
    TankPhoto photo, {
    Tank? tank,
    WidgetRef? ref,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final imageUrl = photo.imageUrl ?? photo.imagePath;
    if (imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.failedToLoadImage(error.toString()),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Image.file(File(imageUrl), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Date taken: ${photo.dateTaken.month}/${photo.dateTaken.day}/${photo.dateTaken.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Navigator.of(context).pop(); // Close maximized view first

                    // Load image bytes
                    Uint8List? imageBytes;
                    try {
                      if (imageUrl.startsWith('http')) {
                        // For network images, we'd need to download them
                        // For simplicity, we'll show a message that this is not supported
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.aiAnalysisNotSupportedForCloudImages,
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                        return;
                      } else {
                        // Read local file
                        final file = File(imageUrl);
                        imageBytes = await file.readAsBytes();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.failedToLoadImage(e.toString())),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                      return;
                    }

                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PhotoAnalysisScreen(
                            initialImageBytes: imageBytes,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.9),
                          Colors.blue.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            if (tank != null && ref != null)
              Positioned(
                top: 40,
                right: 70,
                child: PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onSelected: (value) {
                    Navigator.of(context).pop(); // Close maximized view first
                    switch (value) {
                      case 'set_background':
                        _setTankBackground(context, ref, tank, photo.id);
                        break;
                      case 'set_as_icon':
                        _setTankIconFromPhoto(context, ref, tank, photo.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'set_background',
                      child: Row(
                        children: [
                          Icon(Icons.wallpaper, size: 18),
                          SizedBox(width: 8),
                          Flexible(child: Text(l10n.setAsCardBackground)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'set_as_icon',
                      child: Row(
                        children: [
                          Icon(Icons.image_aspect_ratio, size: 18),
                          SizedBox(width: 8),
                          Flexible(child: Text(l10n.setAsTankIcon)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageTagsDialog(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
  ) async {
    final allExistingTags = mergeTagSuggestions(
      globalTags: ref.read(tankTagsProvider),
      tanks: ref.read(tankProvider).tanks,
    );

    if (!context.mounted) return;
    final result = await showDialog<List<TankTag>>(
      context: context,
      builder: (_) => TagPickerDialog(
        allExistingTags: allExistingTags,
        currentTags: List.from(tank.tags),
      ),
    );
    if (result != null && context.mounted) {
      final updated = tank.copyWith(tags: result);
      await ref.read(tankProvider.notifier).updateTank(updated);
    }
  }

  void _showSetBackgroundDialog(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (tank.photos.isEmpty) {
      context.showAccessibleMessage(
        'No photos available. Add photos to your tank first.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setCardBackground),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: tank.photos.length,
            itemBuilder: (context, index) {
              final photo = tank.photos[index];
              final imageUrl = photo.imageUrl ?? photo.imagePath;
              final isSelected = tank.customBackgroundPhotoId == photo.id;

              return GestureDetector(
                onTap: () {
                  _setTankBackground(context, ref, tank, photo.id);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: imageUrl != null
                        ? (imageUrl.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey,
                                        child: const Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                        ),
                                      ),
                                )
                              : Image.file(File(imageUrl), fit: BoxFit.cover))
                        : Container(color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _setTankBackground(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
    String photoId,
  ) async {
    try {
      final updatedTank = tank.copyWith(customBackgroundPhotoId: photoId);
      await ref.read(tankProvider.notifier).updateTank(updatedTank);
      if (context.mounted) {
        context.showAccessibleMessage('Card background updated');
      }
    } catch (e) {
      if (context.mounted) {
        context.showAccessibleMessage('Failed to update background: $e');
      }
    }
  }

  // Predefined icons for tanks - keeping this as a static constant list
  static const List<IconData> _tankIcons = [
    Icons.water_drop,
    Icons.waves,
    Icons.pool,
    Icons.bubble_chart,
    Icons.water,
    Icons.shower,
    Icons.opacity,
    Icons.water_damage,
    Icons.pets,
    Icons.set_meal,
    Icons.spa,
    Icons.emoji_nature,
    Icons.grass,
    Icons.eco,
    Icons.forest,
    Icons.park,
  ];

  // Helper method to get const IconData from codePoint
  IconData? _getIconFromCodePoint(int? codePoint) {
    if (codePoint == null) return null;
    try {
      return _tankIcons.firstWhere((icon) => icon.codePoint == codePoint);
    } catch (e) {
      return null;
    }
  }

  void _showSetIconDialog(BuildContext context, WidgetRef ref, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    final icons = _tankIcons;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeTankIcon),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tank photos section (if available)
                if (tank.photos.isNotEmpty) ...[
                  Text(
                    'Tank Photos',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: tank.photos.length,
                    itemBuilder: (context, index) {
                      final photo = tank.photos[index];
                      final imageUrl = photo.imageUrl ?? photo.imagePath;
                      final isSelected = tank.customIconPhotoId == photo.id;

                      return GestureDetector(
                        onTap: () {
                          _setTankIconFromPhoto(context, ref, tank, photo.id);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: imageUrl != null
                                ? (imageUrl.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color: Colors.grey,
                                                child: const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.white,
                                                ),
                                              ),
                                        )
                                      : Image.file(
                                          File(imageUrl),
                                          fit: BoxFit.cover,
                                        ))
                                : Container(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Material icons section
                Text(
                  'Material Icons',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: icons.length,
                  itemBuilder: (context, index) {
                    final icon = icons[index];
                    final isSelected =
                        tank.customIconCodePoint == icon.codePoint;

                    return GestureDetector(
                      onTap: () {
                        _setTankIcon(context, ref, tank, icon.codePoint);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceVariant,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 32),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (tank.customIconCodePoint != null ||
              tank.customIconPhotoId != null)
            TextButton(
              onPressed: () {
                _resetTankIcon(context, ref, tank);
                Navigator.of(context).pop();
              },
              child: Text(l10n.resetIcon),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _setTankIcon(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
    int codePoint,
  ) async {
    try {
      final updatedTank = tank.copyWith(customIconCodePoint: codePoint);
      await ref.read(tankProvider.notifier).updateTank(updatedTank);
      if (context.mounted) {
        context.showAccessibleMessage('Tank icon updated');
      }
    } catch (e) {
      if (context.mounted) {
        context.showAccessibleMessage('Failed to update icon: $e');
      }
    }
  }

  void _setTankIconFromPhoto(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
    String photoId,
  ) async {
    try {
      // Set the icon photo and clear custom icon code point to use photo as icon
      final updatedTank = tank.copyWith(
        customIconPhotoId: photoId,
        clearCustomIconCodePoint: true,
      );
      await ref.read(tankProvider.notifier).updateTank(updatedTank);
      if (context.mounted) {
        context.showAccessibleMessage('Tank icon set to photo');
      }
    } catch (e) {
      if (context.mounted) {
        context.showAccessibleMessage('Failed to update icon: $e');
      }
    }
  }

  void _resetTankIcon(BuildContext context, WidgetRef ref, Tank tank) async {
    try {
      final updatedTank = tank.copyWith(
        clearCustomIconCodePoint: true,
        clearCustomIconPhotoId: true,
      );
      await ref.read(tankProvider.notifier).updateTank(updatedTank);
      if (context.mounted) {
        context.showAccessibleMessage('Tank icon reset to default');
      }
    } catch (e) {
      if (context.mounted) {
        context.showAccessibleMessage('Failed to reset icon: $e');
      }
    }
  }

  void _resetTankBackground(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
  ) async {
    try {
      final updatedTank = tank.copyWith(clearCustomBackgroundPhotoId: true);
      await ref.read(tankProvider.notifier).updateTank(updatedTank);
      if (context.mounted) {
        context.showAccessibleMessage('Background reset to default');
      }
    } catch (e) {
      if (context.mounted) {
        context.showAccessibleMessage('Failed to reset background: $e');
      }
    }
  }

  void _duplicateTank(BuildContext context, WidgetRef ref, Tank tank) async {
    try {
      final duplicatedTank = Tank.create(
        name: '${tank.name} (Copy)',
        type: tank.type,
        inhabitants: List.from(tank.inhabitants),
        sizeGallons: tank.sizeGallons,
        sizeLiters: tank.sizeLiters,
        notes: tank.notes,
        harmonyScore: tank.harmonyScore,
        calculationBreakdown: tank.calculationBreakdown,
        tags: List.from(tank.tags),
      );

      await ref.read(tankProvider.notifier).addTank(duplicatedTank);

      if (context.mounted) {
        context.showAccessibleMessage(
          'Tank "${tank.name}" duplicated successfully',
        );
      }
    } catch (e) {
      if (context.mounted) {
        context.showAccessibleMessage('Failed to duplicate tank: $e');
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Tank tank) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTankTitle, textAlign: TextAlign.center),
        content: Text(
          l10n.deleteTankConfirm(tank.name),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Log tank deletion
              AnalyticsService.logTankAction(
                action: 'delete_tank',
                tankType: tank.type,
                tankSize: tank.sizeGallons?.toInt() ?? 0,
              );

              await ref.read(tankProvider.notifier).deleteTank(tank.id);
              if (context.mounted) {
                context.showAccessibleMessage('Tank "${tank.name}" deleted');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatTankSize(Tank tank) {
    if (tank.sizeGallons != null && tank.sizeLiters != null) {
      return '${tank.sizeGallons!.toStringAsFixed(0)} gal (${tank.sizeLiters!.toStringAsFixed(0)} L)';
    } else if (tank.sizeGallons != null) {
      return '${tank.sizeGallons!.toStringAsFixed(0)} gallons';
    } else if (tank.sizeLiters != null) {
      return '${tank.sizeLiters!.toStringAsFixed(0)} liters';
    }
    return '';
  }

  Widget _buildHarmonyScoreChip(Tank tank) {
    final harmonyScore = tank.harmonyScore;
    if (harmonyScore == null) return const SizedBox.shrink();

    final label = TankHarmonyCalculator.getHarmonyLabel(harmonyScore);
    final percentage = (harmonyScore * 100).toStringAsFixed(0);

    Color chipColor;
    Color textColor;
    if (harmonyScore >= 0.8) {
      chipColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
    } else if (harmonyScore >= 0.7) {
      chipColor = Colors.yellow.shade100;
      textColor = Colors.yellow.shade800;
    } else if (harmonyScore >= 0.6) {
      chipColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else {
      chipColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shape_line, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$label ($percentage%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _getFishImageUrl(
    String tankType,
    String fishName,
    Map<String, List<Fish>>? fishData, {
    TankInhabitant? inhabitant,
  }) {
    // Prioritize custom images if inhabitant is provided
    if (inhabitant != null) {
      if (inhabitant.customImageUrl != null &&
          inhabitant.customImageUrl!.isNotEmpty) {
        return inhabitant.customImageUrl;
      }
      if (inhabitant.customImagePath != null &&
          inhabitant.customImagePath!.isNotEmpty) {
        return inhabitant.customImagePath;
      }
    }

    // Fall back to default fish image
    if (fishData == null) return null;

    final categoryFish = fishData[tankType] ?? [];
    final fish = categoryFish.firstWhere(
      (f) => f.name == fishName,
      orElse: () => Fish(
        name: '',
        commonNames: [],
        imageURL: '',
        compatible: [],
        notRecommended: [],
        notCompatible: [],
        withCaution: [],
      ),
    );

    return fish.imageURL.isNotEmpty ? fish.imageURL : null;
  }

  int _getTotalInhabitantCount(List<TankInhabitant> inhabitants) {
    return inhabitants.fold(
      0,
      (total, inhabitant) => total + inhabitant.quantity,
    );
  }

  Map<String, List<TankInhabitant>> _groupInhabitantsByFishType(
    List<TankInhabitant> inhabitants,
  ) {
    final grouped = <String, List<TankInhabitant>>{};
    for (final inhabitant in inhabitants) {
      final fishType = inhabitant.fishUnit;
      if (!grouped.containsKey(fishType)) {
        grouped[fishType] = [];
      }
      grouped[fishType]!.add(inhabitant);
    }
    return grouped;
  }

  List<Widget> _buildFishGroupDisplay(
    Tank tank,
    Map<String, List<Fish>>? fishData,
  ) {
    final groupedFish = _groupInhabitantsByFishType(tank.inhabitants);
    final widgets = <Widget>[];

    int displayedGroups = 0;
    const maxGroups = 3; // Limit to 3 fish types to keep card compact

    for (final entry in groupedFish.entries) {
      if (displayedGroups >= maxGroups) break;

      final fishType = entry.key;
      final inhabitants = entry.value;
      final fishImageUrl = _getFishImageUrl(
        tank.type,
        fishType,
        fishData,
        inhabitant: inhabitants.first,
      );

      // Calculate total quantity for this fish type
      final totalQuantity = inhabitants.fold<int>(
        0,
        (sum, inhabitant) => sum + inhabitant.quantity,
      );

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              // Fish image
              CircleAvatar(
                radius: 12,
                backgroundImage: fishImageUrl != null
                    ? (fishImageUrl.startsWith('http')
                          ? CachedNetworkImageProvider(fishImageUrl)
                          : FileImage(File(fishImageUrl)) as ImageProvider)
                    : null,
                backgroundColor: fishImageUrl == null
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: fishImageUrl == null
                    ? Icon(
                        Icons.pets,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 12,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              // Fish type and names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inhabitants.map((i) => i.customName).join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${totalQuantity}x $fishType',

                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      displayedGroups++;
    }

    // Add "more fish types" indicator if needed
    if (groupedFish.length > maxGroups) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '+${groupedFish.length - maxGroups} more fish type${groupedFish.length - maxGroups == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Future<void> _getTankStockingRecommendations(Tank tank) async {
    final l10n = AppLocalizations.of(context)!;
    if (tank.inhabitants.isEmpty) {
      context.showAccessibleMessage(
        'Tank must have existing inhabitants to get stocking recommendations.',
      );
      return;
    }

    // Get fish data from provider
    final fishDataAsync = ref.read(fishDataProvider);
    final fishData = fishDataAsync.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );

    // Check if fish data is available
    if (fishData == null) {
      context.showAccessibleMessage(
        'Fish data is not available. Please try again later.',
      );
      return;
    }

    // Show options dialog first
    final options = await showDialog<StockingRecommendationOptions>(
      context: context,
      builder: (context) => const StockingRecommendationOptionsDialog(),
    );

    // User cancelled the dialog
    if (options == null || !mounted) {
      return;
    }

    // Show interstitial ad for eligible free-tier users when the stocking
    // analysis is requested from the tank card.
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

    // Store the options for the listener
    _additionalNotes = options.additionalNotes;

    // Store the current tank for the listener
    _currentTankForRecommendations = tank;

    // Calculate and store existing fish for the listener
    final categoryFish = fishData[tank.type] ?? [];
    final existingFish = <Fish>[];

    for (final inhabitant in tank.inhabitants) {
      // Prefer UUID-based lookup for renamed-fish resilience; fall back to name.
      final fish = (inhabitant.fishUuid != null
              ? categoryFish.where((f) => f.uuid == inhabitant.fishUuid).firstOrNull
              : null) ??
          categoryFish.firstWhere(
            (f) => f.name == inhabitant.fishUnit,
            orElse: () => Fish(
              name: inhabitant.fishUnit,
              commonNames: [],
              imageURL: '',
              compatible: [],
              notRecommended: [],
              notCompatible: [],
              withCaution: [],
            ),
          );
      // Add individual fish based on quantity for proper compatibility calculations
      // This is used for calculating harmony scores
      for (int i = 0; i < inhabitant.quantity; i++) {
        existingFish.add(fish);
      }
    }
    _currentExistingFish = existingFish;

    // Show loading overlay
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

    // Log tank stocking recommendations request
    AnalyticsService.logFeatureUsed(
      featureName: 'tank_stocking_recommendations',
      parameters: {
        'tank_type': tank.type,
        'tank_size_gallons': tank.sizeGallons?.toInt() ?? 0,
        'existing_inhabitants_count': tank.inhabitants.length,
        'has_notes': tank.notes?.isNotEmpty == true ? 'true' : 'false',
        'source': 'tank_management',
        'has_additional_notes': options.additionalNotes.isNotEmpty
            ? 'true'
            : 'false',
      },
    );
    AnalyticsService.logTankAction(
      action: 'get_stocking_recommendations',
      tankType: tank.type,
      tankSize: tank.sizeGallons?.toInt(),
    );

    // Get recommendations for this tank
    ref
        .read(aquariumStockingProvider.notifier)
        .getTankStockingRecommendations(
          tank: tank,
          additionalNotes: options.additionalNotes,
        );
  }

  Future<void> _getTankCompatibilityAnalysis(Tank tank) async {
    final l10n = AppLocalizations.of(context)!;
    if (tank.inhabitants.isEmpty) {
      context.showAccessibleMessage(
        l10n.tankMustHaveInhabitantsForCompatibility,
      );
      return;
    }

    // Get fish data from provider
    final fishDataAsync = ref.read(fishDataProvider);
    final fishData = fishDataAsync.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );

    // Check if fish data is available
    if (fishData == null) {
      context.showAccessibleMessage(l10n.fishDataNotAvailable);
      return;
    }

    // Show options dialog first
    final options = await showDialog<StockingRecommendationOptions>(
      context: context,
      builder: (context) => const StockingRecommendationOptionsDialog(
        isCompatibilityAnalysis: true,
      ),
    );

    // User cancelled the dialog
    if (options == null || !mounted) {
      return;
    }

    // Show interstitial ad for eligible free-tier users when the compatibility
    // analysis is requested from the tank card.
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

    // Get the fish from the tank inhabitants
    final categoryFish = fishData[tank.type] ?? [];
    final tankFishList = <Fish>[];
    final addedSpecies =
        <String>{}; // Track species by their fishUnit to avoid duplicates
    // Build species tags map from inhabitants for granular AI analysis
    final Map<String, List<String>> selectedSpecies = {};

    for (final inhabitant in tank.inhabitants) {
      // Skip if we've already added this species
      if (addedSpecies.contains(inhabitant.fishUnit)) {
        continue;
      }

      // Use the database fish name, preferring UUID lookup for renamed-fish resilience.
      final fish = (inhabitant.fishUuid != null
              ? categoryFish.where((f) => f.uuid == inhabitant.fishUuid).firstOrNull
              : null) ??
          categoryFish.firstWhere(
            (f) => f.name == inhabitant.fishUnit,
            orElse: () => Fish(
              name: inhabitant.fishUnit,
              commonNames: [],
              imageURL: '',
              compatible: [],
              notRecommended: [],
              notCompatible: [],
              withCaution: [],
            ),
          );

      // Collect species tags for this inhabitant
      if (inhabitant.speciesTags.isNotEmpty) {
        selectedSpecies[inhabitant.fishUnit] = inhabitant.speciesTags;
      }

      // Add the fish and mark this species as added
      tankFishList.add(fish);
      addedSpecies.add(inhabitant.fishUnit);
    }

    // Build additional notes from species tags and user notes
    String? compatibilityNotes;
    final speciesTagEntries = selectedSpecies.entries.toList();
    if (speciesTagEntries.isNotEmpty) {
      final lines = speciesTagEntries
          .map((e) => '- ${e.key}: ${e.value.join(', ')}')
          .join('\n');
      final speciesNote = 'Specific species selected by user:\n$lines';
      compatibilityNotes = options.additionalNotes.isNotEmpty
          ? '$speciesNote\n${options.additionalNotes}'
          : speciesNote;
    } else if (options.additionalNotes.isNotEmpty) {
      compatibilityNotes = options.additionalNotes;
    }

    // Show loading overlay
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
                    Text(l10n.analyzingTankCompatibility),
                    const SizedBox(height: 8),
                    Text(
                      l10n.mayTakeUpToSeconds,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        ref.read(fishCompatibilityProvider.notifier).cancel();
                        _isCompatibilityLoading = false;
                        _currentTankForCompatibility = null;
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

    // Log tank compatibility analysis request
    AnalyticsService.logFeatureUsed(
      featureName: 'tank_compatibility_analysis',
      parameters: {
        'tank_type': tank.type,
        'tank_size_gallons': tank.sizeGallons?.toInt() ?? 0,
        'existing_inhabitants_count': tank.inhabitants.length,
        'source': 'tank_management',
        'has_additional_notes': options.additionalNotes.isNotEmpty
            ? 'true'
            : 'false',
      },
    );
    AnalyticsService.logTankAction(
      action: 'compatibility_analysis',
      tankType: tank.type,
      tankSize: tank.sizeGallons?.toInt(),
    );

    // Store the current tank for the listener
    _currentTankForCompatibility = tank;
    _isCompatibilityLoading = true;

    // Clear any previous selection and set the tank fish as selected
    ref.read(fishCompatibilityProvider.notifier).clearSelection();
    for (final fish in tankFishList) {
      ref.read(fishCompatibilityProvider.notifier).selectFish(fish);
    }

    // Get the compatibility report, passing species tags as selected species
    ref
        .read(fishCompatibilityProvider.notifier)
        .getCompatibilityReport(
          tank.type,
          additionalNotes: compatibilityNotes,
          selectedSpecies: selectedSpecies.isNotEmpty ? selectedSpecies : null,
        );
  }
}

class _PulseRingWidget extends StatefulWidget {
  const _PulseRingWidget({required this.child});

  final Widget child;

  @override
  State<_PulseRingWidget> createState() => _PulseRingWidgetState();
}

class _PulseRingWidgetState extends State<_PulseRingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.6,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(_opacity.value),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}
