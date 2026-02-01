import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../main_layout.dart';
import '../models/tank.dart';
import '../models/fish.dart';
import '../models/water_parameter.dart';
import '../models/dosing_entry.dart';
import '../models/tank_notification.dart';
import '../models/notification_log.dart';
import '../providers/tank_provider.dart';
import '../providers/aquarium_stocking_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/fish_data_service.dart';
import '../services/notification_service.dart';
import '../utils/tank_harmony_calculator.dart';
import '../utils/backup_restore_utils.dart';
import '../widgets/accessible_feedback.dart';
import '../widgets/ad_component.dart';
import '../widgets/notification_reschedule_dialog.dart';
import '../services/analytics_service.dart';
import '../l10n/app_localizations.dart';
import 'tank_creation_screen.dart';
import 'tank_stocking_report_screen.dart';
import 'photo_analysis_screen.dart';
import 'parameter_logger_screen.dart';
import 'dosing_logger_screen.dart';
import 'notification_management_screen.dart';
import 'notification_logger_screen.dart';
import '../widgets/stocking_recommendation_options_dialog.dart';

enum TankSortOption {
  name,
  type,
  size,
  date,
}

class TankManagementScreen extends ConsumerStatefulWidget {
  const TankManagementScreen({super.key});

  @override
  TankManagementScreenState createState() => TankManagementScreenState();
}

class TankManagementScreenState extends ConsumerState<TankManagementScreen> {
  TankSortOption _currentSortOption = TankSortOption.name;
  bool _isSortAscending = true; // Track sort direction (ascending/descending)
  Tank? _currentTankForRecommendations; // Track current tank for recommendations
  List<Fish>? _currentExistingFish; // Track existing fish for recommendations
  bool _isSortMenuExpanded = false; // Track sort menu expansion
  bool _includeCustomNames = false; // Track if custom names were included
  String _additionalNotes = ''; // Track additional notes

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
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

  Future<void> _saveSortPreference(TankSortOption option) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tank_sort_option', option.index);
    } catch (e) {
      // Handle error silently
    }
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
    ref.listen<AquariumStockingState>(aquariumStockingProvider, (previous, next) {
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
          final capturedIncludeCustomNames = _includeCustomNames;
          final capturedAdditionalNotes = _additionalNotes;
          
          // Debug: Print values being passed to report screen
          debugPrint('Passing to report - includeCustomNames: $capturedIncludeCustomNames');
          debugPrint('Passing to report - additionalNotes: "$capturedAdditionalNotes"');
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TankStockingReportScreen(
                reports: next.recommendations!,
                originalTank: tank,
                existingFish: fish,
                includeCustomNames: capturedIncludeCustomNames,
                additionalNotes: capturedAdditionalNotes,
              ),
            ),
          );
          // Clear the current tank reference and options
          _currentTankForRecommendations = null;
          _currentExistingFish = null;
          _includeCustomNames = false;
          _additionalNotes = '';
        } else {
          context.showAccessibleMessage(
            'Error: Missing tank data. Please try again.'
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

    return MainLayout(
      title: l10n.myTanks,
      bottomNavigationBar: const AdBanner(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TankCreationScreen(),
            ),
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
                  : _buildTankListWithFloatingMenu(context, ref, tankState.tanks, fishData, appSettings),
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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.orRestoreFromBackup,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => BackupRestoreUtils.importData(context, ref, source: 'tank_management'),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTankListWithFloatingMenu(BuildContext context, WidgetRef ref, List<Tank> tanks, Map<String, List<Fish>>? fishData, AppSettingsState appSettings) {
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
        if (_isSortMenuExpanded) _buildFloatingSortMenu(context),
      ],
    );
  }

  Widget _buildTankList(BuildContext context, WidgetRef ref, List<Tank> tanks, Map<String, List<Fish>>? fishData, AppSettingsState appSettings) {
    final sortedTanks = _sortTanks(tanks);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use grid layout for larger screens (tablets and desktops)
    final useGridLayout = screenWidth >= 900;
    
    if (useGridLayout) {
      // Use masonry grid for larger screens
      final int columnCount = screenWidth >= 1400 ? 3 : 2;
      
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildHeader(context, sortedTanks.length),
            ),
          ),
          // Masonry grid layout with native ads
          ..._buildTankGridWithAds(context, ref, sortedTanks, fishData, appSettings, columnCount),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      );
    }
    
    // Use list layout for mobile devices with native ads
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _calculateListItemCount(sortedTanks.length),
      itemBuilder: (context, index) {
        return _buildListItem(context, ref, index, sortedTanks, fishData, appSettings);
      },
    );
  }

  List<Widget> _buildTankGridWithAds(BuildContext context, WidgetRef ref, List<Tank> tanks, Map<String, List<Fish>>? fishData, AppSettingsState appSettings, int columnCount) {
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
          padding: EdgeInsets.fromLTRB(
            16,
            startIndex == 0 ? 0 : 16,
            16,
            0,
          ),
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
              return _buildTankCard(context, ref, tanks[actualIndex], fishData, appSettings);
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
            sliver: SliverToBoxAdapter(
              child: _buildNativeAdCard(context),
            ),
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

  Widget _buildListItem(BuildContext context, WidgetRef ref, int index, List<Tank> tanks, Map<String, List<Fish>>? fishData, AppSettingsState appSettings) {
    // Configuration for ad placement
    const int tanksBeforeFirstAd = 4;
    const int tanksBetweenAds = 6;
    
    // Header is always at index 0
    if (index == 0) {
      return _buildHeader(context, tanks.length);
    }
    
    // Calculate actual tank index and whether this should be an ad
    int adjustedIndex = index - 1; // Subtract header
    int tanksSeen = 0;
    
    // Determine position
    if (adjustedIndex < tanksBeforeFirstAd) {
      // First batch, no ads yet
      return _buildTankCard(context, ref, tanks[adjustedIndex], fishData, appSettings);
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
        return _buildTankCard(context, ref, tanks[tankIndex], fishData, appSettings);
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: const ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        child: NativeAdWidget(),
      ),
    );
  }

  List<Tank> _sortTanks(List<Tank> tanks) {
    final sortedTanks = List<Tank>.from(tanks);
    
    switch (_currentSortOption) {
      case TankSortOption.name:
        sortedTanks.sort((a, b) {
          final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
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
          return a.name.toLowerCase().compareTo(b.name.toLowerCase()); // Secondary sort by name
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
          return a.name.toLowerCase().compareTo(b.name.toLowerCase()); // Secondary sort by name
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

  Widget _buildHeader(BuildContext context, int tankCount) {
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
              
              // Sort menu
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isSortMenuExpanded = !_isSortMenuExpanded;
                  });
                },
                icon: Icon(
                  _isSortMenuExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getSortOptionIcon(_currentSortOption), size: 16),
                    const SizedBox(width: 4),
                    Text(_getSortOptionLabel(_currentSortOption)),
                    const SizedBox(width: 4),
                    Icon(
                      _isSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                    ),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              
              // 3-dot menu for backup/restore
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'backup':
                      BackupRestoreUtils.exportData(context, ref, source: 'tank_management');
                      break;
                    case 'restore':
                      BackupRestoreUtils.importData(context, ref, source: 'tank_management');
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
                        Text(l10n.backup),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'restore',
                    child: Row(
                      children: [
                        const Icon(Icons.restore, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(l10n.restore),
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

  Widget _buildFloatingSortMenu(BuildContext context) {
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
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sort Options',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
                const SizedBox(height: 12),
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onPressed: () {
                        setState(() {
                          // If selecting the same option, toggle ascending/descending
                          if (_currentSortOption == option) {
                            _isSortAscending = !_isSortAscending;
                          } else {
                            _currentSortOption = option;
                            _isSortAscending = true; // Reset to ascending for new option
                          }
                          _isSortMenuExpanded = false;
                        });
                        _saveSortPreference(option);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTankCard(BuildContext context, WidgetRef ref, Tank tank, Map<String, List<Fish>>? fishData, AppSettingsState appSettings) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 900;
    
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
    
    return Container(
      margin: isLargeScreen ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        gradient: backgroundPhoto == null ? LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        image: backgroundPhoto != null ? DecorationImage(
          image: (backgroundPhoto.imageUrl?.startsWith('http') ?? false)
              ? CachedNetworkImageProvider(backgroundPhoto.imageUrl!) as ImageProvider
              : FileImage(File(backgroundPhoto.imagePath!)),
          fit: BoxFit.cover,
          opacity: 0.8,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.darken,
          ),
        ) : null,
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
              onTap: () => _showTankDetails(context, tank, fishData),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with tank name and menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Tank icon with gradient background or photo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: tank.customIconCodePoint == null && tank.customIconPhotoId == null
                            ? LinearGradient(
                                colors: tank.type == 'freshwater'
                                    ? [Colors.blue.shade300, Colors.cyan.shade400]
                                    : [Colors.indigo.shade300, Colors.purple.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: tank.customIconCodePoint == null && tank.customIconPhotoId != null
                            ? Colors.grey.shade300
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (tank.type == 'freshwater' 
                                ? Colors.blue 
                                : Colors.purple).withOpacity(0.3),
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
                                    (tank.type == 'freshwater' ? Icons.water_drop : Icons.waves),
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
                                                  errorWidget: (context, url, error) => Icon(
                                                    tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                                                    size: 24,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Image.file(File(imageUrl), fit: BoxFit.cover))
                                          : Icon(
                                              tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                                              size: 24,
                                              color: Colors.white,
                                            );
                                    } catch (e) {
                                      return Icon(
                                        tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                                        size: 24,
                                        color: Colors.white,
                                      );
                                    }
                                  }(),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tank.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                              return Text(
                                tank.type == 'freshwater' ? l10n.freshwater : l10n.saltwater,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
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
                          case 'parameters':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ParameterLoggerScreen(tank: tank),
                              ),
                            );
                            break;
                          case 'dosing':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DosingLoggerScreen(tank: tank),
                              ),
                            );
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
                            _getTankStockingRecommendations(context, ref, tank);
                            break;
                          case 'duplicate':
                            _duplicateTank(context, ref, tank);
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
                                Text(l10n.editTank),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'parameters',
                            child: Row(
                              children: [
                                const Icon(Icons.science, color: Colors.teal, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.parameterLogger, style: const TextStyle(color: Colors.teal)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'dosing',
                            child: Row(
                              children: [
                                const Icon(Icons.medication_liquid, color: Colors.purple, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.dosingDiary, style: const TextStyle(color: Colors.purple)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'notifications',
                            child: Row(
                              children: [
                                const Icon(Icons.notifications, color: Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.notificationsExperimental, style: const TextStyle(color: Colors.orange)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'activity_log',
                            child: Row(
                              children: [
                                const Icon(Icons.history, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.activityLog, style: const TextStyle(color: Colors.green)),
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
                                  Text(l10n.setCardBackground),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'set_icon',
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_emotions_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.changeIcon),
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
                                  Text(l10n.resetBackground),
                                ],
                              ),
                            ),
                          if (tank.inhabitants.isNotEmpty && appSettings.enableAI && appSettings.showStockingButton)
                            PopupMenuItem(
                              value: 'recommendations',
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                                  const SizedBox(width: 8),
                                  Text(l10n.getStockingIdeas, style: const TextStyle(color: Colors.blue)),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                const Icon(Icons.copy, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.duplicate),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.deleteTank, style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),
                
                // Tank stats row
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (tank.sizeGallons != null || tank.sizeLiters != null)
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
                
                // Inhabitants section with modern styling
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
                        Text(
                          'No inhabitants yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            Text(
                              '${_getTotalInhabitantCount(tank.inhabitants)} inhabitant${_groupInhabitantsByFishType(tank.inhabitants).length == 1 ? '' : 's'}, ${_groupInhabitantsByFishType(tank.inhabitants).length} type${_groupInhabitantsByFishType(tank.inhabitants).length == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._buildFishGroupDisplay(tank, fishData),
                    ],
                  ),
                
                const SizedBox(height: 14),
                
                // Tank photos section (if photos exist)
                if (tank.photos.isNotEmpty) ...[
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          onTap: () => _showPhotoMaximized(context, photo, tank: tank, ref: ref),
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
                                          errorWidget: (context, url, error) => Container(
                                            color: cs.errorContainer,
                                            child: Icon(
                                              Icons.error_outline,
                                              size: 20,
                                              color: cs.onErrorContainer,
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
                if (tank.notes != null && tank.notes!.isNotEmpty) ...[
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                
                // Activity Log and Upcoming Notifications section
                _buildActivitySection(context, ref, tank, cs),
                
                // Action buttons area (space for future parameters/dosing)
                Row(
                  children: [
                    // AI stocking button - conditionally shown based on app settings
                    if (tank.inhabitants.isNotEmpty && appSettings.enableAI && appSettings.showStockingButton)
                      Expanded(
                        child: Container(
                          height: 36,
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
                            onPressed: () => _getTankStockingRecommendations(context, ref, tank),
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: Text(
                              'AI Stocking Recommendations',
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
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Space for future buttons (dosing, parameters, etc.)
                    if (tank.inhabitants.isNotEmpty && appSettings.enableAI && appSettings.showStockingButton) const SizedBox(width: 8),
                  ],
                ),
                
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
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
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
  Widget _buildActivitySection(BuildContext context, WidgetRef ref, Tank tank, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    final List<Widget> recentActivityItems = [];
    final List<Widget> notificationItems = [];
    
    // Get most recent activity log
    if (tank.notificationLogs.isNotEmpty) {
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
          timeAgo = minutesAgo == 1 ? l10n.oneMinuteAgo : l10n.xMinutesAgo(minutesAgo);
        } else {
          timeAgo = l10n.justNow;
        }
      } else if (daysSince == 1) {
        timeAgo = l10n.yesterday;
      } else if (daysSince < 7) {
        timeAgo = l10n.daysAgo(daysSince);
      } else {
        timeAgo = '${recentLog.loggedAt.month}/${recentLog.loggedAt.day}/${recentLog.loggedAt.year}';
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
      // Calculate next notification date for display
      DateTime? nextDate;
      if (notification.repeatFrequency != RepeatFrequency.none) {
        nextDate = notification.getNextNotificationDateWithActivity(tank.notificationLogs);
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
        isWithin12Hours = nextDate.isBefore(twelveHoursFromNow) && nextDate.isAfter(twelveHoursAgo);
        
        if (isPast) {
          // Past - show how long ago
          final difference = now.difference(nextDate);
          final hoursAgo = difference.inHours;
          final minutesAgo = difference.inMinutes % 60;
          final daysSince = difference.inDays;
          
          if (daysSince > 0) {
            timeDisplay = daysSince == 1 ? l10n.yesterday : l10n.daysAgo(daysSince);
          } else if (hoursAgo > 0) {
            timeDisplay = hoursAgo == 1 ? l10n.oneHourAgo : l10n.xHoursAgo(hoursAgo);
          } else if (minutesAgo > 0) {
            timeDisplay = minutesAgo == 1 ? l10n.oneMinuteAgo : l10n.xMinutesAgo(minutesAgo);
          } else {
            timeDisplay = l10n.justNow;
          }
        } else {
          // Future - show time until
          final hoursUntil = nextDate.difference(now).inHours;
          final minutesUntil = nextDate.difference(now).inMinutes % 60;
          final daysUntil = nextDate.difference(now).inDays;
          
          if (daysUntil > 0) {
            timeDisplay = l10n.inXDays(daysUntil);
          } else if (hoursUntil > 0) {
            timeDisplay = hoursUntil == 1 ? l10n.inOneHour : l10n.inXHours(hoursUntil);
          } else if (minutesUntil > 0) {
            timeDisplay = minutesUntil == 1 ? l10n.inOneMinute : l10n.inXMinutes(minutesUntil);
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
        
        // Notifications section (2 per row using LayoutBuilder for responsive width)
        if (notificationItems.isNotEmpty) ...[
          if (recentActivityItems.isNotEmpty) const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate item width for 2 per row with 8px spacing
              final itemWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: notificationItems.map((item) => 
                  SizedBox(
                    width: itemWidth,
                    child: item,
                  ),
                ).toList(),
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
        onTap: () => _quickLogFromCard(context, ref, tank, notification),
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
                        color: isPast && isWithin12Hours ? Colors.red : activityColor,
                        fontSize: 10,
                        fontWeight: isWithin12Hours ? FontWeight.w500 : FontWeight.normal,
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
                child: const Icon(
                  Icons.add,
                  size: 12,
                  color: Colors.white,
                ),
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

  Future<void> _quickLogFromCard(BuildContext context, WidgetRef ref, Tank tank, TankNotification notification) async {
    // Get the latest tank state from the provider
    final currentTank = ref.read(tankProvider).tanks
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
    if (notification.repeatFrequency != RepeatFrequency.none && context.mounted) {
      // Ask user how they want to update the notification schedule BEFORE saving
      rescheduleOption = await NotificationRescheduleDialog.show(context, notification);
      
      // Refresh the app settings state to reflect any newly remembered preference
      await ref.read(appSettingsProvider.notifier).refreshRememberedRescheduleOptions();
      
      // If user cancelled (null) or chose cancelAll, don't log the activity
      if (rescheduleOption == null || rescheduleOption == RescheduleOption.cancelAll) {
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
    
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      context.showAccessibleMessage(l10n.activityLogged);
      
      // Handle the reschedule option if one was selected
      if (rescheduleOption != null && rescheduleOption != RescheduleOption.doNothing) {
        await _handleRescheduleOption(
          context,
          ref,
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
        'has_custom_category': notification.customCategory != null ? 'true' : 'false',
      },
    );
    
    AnalyticsService.logTankAction(
      action: 'quick_log_from_card',
      tankType: currentTank.type,
    );
  }

  /// Handle the reschedule option selected by the user
  Future<void> _handleRescheduleOption(
    BuildContext context,
    WidgetRef ref,
    Tank tank,
    TankNotification notification,
    NotificationLog log,
    List<NotificationLog> updatedLogs,
    RescheduleOption option,
  ) async {
    final notificationService = NotificationService();
    final l10n = AppLocalizations.of(context)!;
    
    // Get the latest tank state
    final currentTank = ref.read(tankProvider).tanks
        .firstWhere((t) => t.id == tank.id, orElse: () => tank);
    
    switch (option) {
      case RescheduleOption.rescheduleFromNow:
        // Reschedule based on the activity log date (which is now), using current time
        final updatedNotifications = await notificationService.rescheduleMatchingNotifications(
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
        
        if (context.mounted) {
          context.showAccessibleMessage(l10n.notificationUpdated);
        }
        break;
        
      case RescheduleOption.keepOriginal:
        // Reschedule to same date as rescheduleFromNow but keep original notification time
        final updatedNotifications = await notificationService.rescheduleMatchingNotifications(
          tankId: currentTank.id,
          tankName: currentTank.name,
          notifications: currentTank.notifications,
          activityLogs: updatedLogs,
          activityType: log.type,
          activityCustomCategory: log.customCategory,
          useCurrentTime: false,  // Keep original time
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
        
        if (context.mounted) {
          context.showAccessibleMessage(l10n.notificationUpdated);
        }
        break;
        
      case RescheduleOption.doNothing:
        // Don't reschedule - activity is already logged, just keep existing schedule
        break;
        
      case RescheduleOption.cancelAll:
        // Cancel - don't log activity and don't reschedule
        // Remove the log that was just added
        final logsWithoutNew = updatedLogs.where((l) => l.id != log.id).toList();
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

  void _showTankDetails(BuildContext context, Tank tank, Map<String, List<Fish>>? fishData) {
    final cs = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    // AI-inspired gradient colors based on tank type with higher opacity
    final gradientColors = tank.type == 'freshwater'
        ? [
            Colors.blue.shade400.withOpacity(0.95),
            Colors.cyan.shade300.withOpacity(0.95),
            cs.primaryContainer.withOpacity(0.98),
          ]
        : [
            Colors.indigo.shade400.withOpacity(0.95),
            Colors.purple.shade300.withOpacity(0.95),
            cs.secondaryContainer.withOpacity(0.98),
          ];
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: isMobile 
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 700,
            maxHeight: screenSize.height - 48,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient badge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      // Tank icon with gradient background
                      Container(
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
                          boxShadow: [
                            BoxShadow(
                              color: (tank.type == 'freshwater' 
                                  ? Colors.blue 
                                  : Colors.purple).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tank.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tank.type == 'freshwater' ? 'Freshwater Tank' : 'Saltwater Tank',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats chips
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (tank.sizeGallons != null || tank.sizeLiters != null)
                              _buildStatChip(context, Icons.straighten, _formatTankSize(tank)),
                            if (tank.sizeGallons != null || tank.sizeLiters != null)
                              _buildStatChip(context, Icons.line_weight, _formatWaterWeight(tank)),
                            if (tank.inhabitants.isNotEmpty && fishData != null)
                              _buildHarmonyScoreChip(tank),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tank photos section (if photos exist)
                        if (tank.photos.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.photo_library_outlined, size: 18, color: cs.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tank Photos (${tank.photos.length})',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tank.photos.map((photo) {
                                    final imageUrl = photo.imageUrl ?? photo.imagePath;
                                    return GestureDetector(
                                      onTap: () => _showPhotoMaximized(context, photo, tank: tank, ref: ref),
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: cs.outline,
                                            width: 2,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: imageUrl != null
                                                  ? (imageUrl.startsWith('http')
                                                      ? CachedNetworkImage(
                                                          imageUrl: imageUrl,
                                                          fit: BoxFit.cover,
                                                          width: double.infinity,
                                                          height: double.infinity,
                                                          errorWidget: (context, url, error) => Container(
                                                            color: cs.errorContainer,
                                                            child: Icon(
                                                              Icons.error_outline,
                                                              color: cs.onErrorContainer,
                                                            ),
                                                          ),
                                                        )
                                                      : Image.file(
                                                          File(imageUrl),
                                                          fit: BoxFit.cover,
                                                          width: double.infinity,
                                                          height: double.infinity,
                                                        ))
                                                  : Container(
                                                      color: cs.surfaceVariant,
                                                      child: Icon(
                                                        Icons.image_outlined,
                                                        color: cs.onSurfaceVariant,
                                                      ),
                                                    ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.7),
                                                  borderRadius: const BorderRadius.only(
                                                    bottomLeft: Radius.circular(6),
                                                    bottomRight: Radius.circular(6),
                                                  ),
                                                ),
                                                child: Text(
                                                  '${photo.dateTaken.month}/${photo.dateTaken.day}/${photo.dateTaken.year}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Water Parameters section
                        if (tank.waterParameters.isNotEmpty) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.science_outlined, size: 18, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Parameters',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => ParameterLoggerScreen(tank: tank),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Manage'),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: _buildLatestParameters(context, tank, cs),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          // Empty state - no parameters logged yet
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.science_outlined, size: 18, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Parameters',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Icon(
                                    Icons.water_drop_outlined,
                                    size: 48,
                                    color: cs.onSurfaceVariant.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No parameters logged yet',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start tracking your water parameters to monitor your aquarium\'s health',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ParameterLoggerScreen(tank: tank),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Parameter'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Activity Log section
                        if (tank.notificationLogs.isNotEmpty) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.history, size: 18, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!.activityLog,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => NotificationLoggerScreen(tank: tank),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: Text(AppLocalizations.of(context)!.manage),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: _buildLatestActivityLogs(context, tank, cs),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          // Empty state - no activity logs yet
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.history, size: 18, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!.activityLog,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Icon(
                                    Icons.history_outlined,
                                    size: 48,
                                    color: cs.onSurfaceVariant.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(context)!.noActivityLogsYet,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.noActivityLogsDescription,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => NotificationLoggerScreen(tank: tank),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(AppLocalizations.of(context)!.addLogEntry),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Dosing Diary section
                        if (tank.dosingEntries.isNotEmpty) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.medication_liquid, size: 18, color: Colors.purple),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Dosing Diary',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      FilledButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => DosingLoggerScreen(tank: tank),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Manage'),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: _buildLatestDosingEntries(context, tank, cs),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          // Empty state - no dosing entries logged yet
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.medication_liquid, size: 18, color: Colors.purple),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Dosing Diary',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Icon(
                                    Icons.medication_liquid_outlined,
                                    size: 48,
                                    color: cs.onSurfaceVariant.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No dosing entries yet',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start tracking treatments and supplements added to your aquarium',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => DosingLoggerScreen(tank: tank),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Dose'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Inhabitants section - now collapsable
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            leading: Icon(Icons.pets, size: 18, color: cs.onSurfaceVariant),
                            title: Text(
                              'Inhabitants (${_getTotalInhabitantCount(tank.inhabitants)})',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            initiallyExpanded: tank.inhabitants.length <= 3,
                            children: [
                              if (tank.inhabitants.isEmpty)
                                Text(
                                  'No inhabitants added yet.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                )
                              else
                                ...tank.inhabitants.map((inhabitant) {
                                  final fishImageUrl = _getFishImageUrl(tank.type, inhabitant.fishUnit, fishData, inhabitant: inhabitant);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundImage: fishImageUrl != null 
                                                ? (fishImageUrl.startsWith('http')
                                                    ? CachedNetworkImageProvider(fishImageUrl)
                                                    : FileImage(File(fishImageUrl)) as ImageProvider)
                                                : null,
                                              backgroundColor: fishImageUrl == null 
                                                ? cs.primaryContainer 
                                                : null,
                                              child: fishImageUrl == null 
                                                ? Icon(
                                                    Icons.shape_line,
                                                    color: cs.onPrimaryContainer,
                                                    size: 22,
                                                  ) 
                                                : null,
                                            ),
                                            // Quantity badge
                                            if (inhabitant.quantity > 1)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: cs.primary,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: cs.surface,
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.3),
                                                        blurRadius: 3,
                                                        offset: const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    '${inhabitant.quantity}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: cs.onPrimary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                inhabitant.quantity > 1
                                                    ? inhabitant.customName
                                                    : inhabitant.customName,
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              Text(
                                                inhabitant.fishUnit,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                              if (inhabitant.dateAdded != null)
                                                Text(
                                                  'Added: ${inhabitant.dateAdded!.month}/${inhabitant.dateAdded!.day}/${inhabitant.dateAdded!.year}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: cs.onSurfaceVariant.withOpacity(0.7),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                        
                        // Notes section
                        if (tank.notes != null && tank.notes!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.note_outlined, size: 18, color: cs.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Notes',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  tank.notes!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Calculation Breakdown Expandable Section
                        if (tank.inhabitants.isNotEmpty && fishData != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Icon(Icons.calculate, size: 18, color: cs.onSurfaceVariant),
                              title: Text(
                                'Compatibility Calculation',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tank.calculationBreakdown ?? 'No calculation available',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Dates
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event, size: 14, color: cs.onSurface),
                                const SizedBox(width: 4),
                                Text(
                                  'Created ${_formatDate(tank.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (tank.updatedAt != tank.createdAt)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.update, size: 14, color: cs.onSurface),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Updated ${_formatDate(tank.updatedAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: cs.outlineVariant.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Notifications button - aligned to the left
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NotificationManagementScreen(tank: tank),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: cs.primary,
                          size: 20,
                        ),
                        label: Text(
                          AppLocalizations.of(context)!.notify,
                          style: TextStyle(color: cs.primary),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TankCreationScreen(existingTank: tank),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Tank'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoMaximized(BuildContext context, TankPhoto photo, {Tank? tank, WidgetRef? ref}) {
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
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Image.file(
                        File(imageUrl),
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            const SnackBar(
                              content: Text('AI analysis is not supported for cloud-stored images. Please use local images.'),
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
                            content: Text('Failed to load image: $e'),
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
                    const PopupMenuItem(
                      value: 'set_background',
                      child: Row(
                        children: [
                          Icon(Icons.wallpaper, size: 18),
                          SizedBox(width: 8),
                          Text('Set as Card Background'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'set_as_icon',
                      child: Row(
                        children: [
                          Icon(Icons.image_aspect_ratio, size: 18),
                          SizedBox(width: 8),
                          Text('Set as Tank Icon'),
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
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetBackgroundDialog(BuildContext context, WidgetRef ref, Tank tank) {
    if (tank.photos.isEmpty) {
      context.showAccessibleMessage('No photos available. Add photos to your tank first.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Card Background'),
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
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
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
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey,
                                  child: const Icon(Icons.error_outline, color: Colors.white),
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _setTankBackground(BuildContext context, WidgetRef ref, Tank tank, String photoId) async {
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
    final icons = _tankIcons;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Tank Icon'),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey,
                                          child: const Icon(Icons.error_outline, color: Colors.white),
                                        ),
                                      )
                                    : Image.file(File(imageUrl), fit: BoxFit.cover))
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                    final isSelected = tank.customIconCodePoint == icon.codePoint;
                    
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
          if (tank.customIconCodePoint != null || tank.customIconPhotoId != null)
            TextButton(
              onPressed: () {
                _resetTankIcon(context, ref, tank);
                Navigator.of(context).pop();
              },
              child: const Text('Reset Icon'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _setTankIcon(BuildContext context, WidgetRef ref, Tank tank, int codePoint) async {
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

  void _setTankIconFromPhoto(BuildContext context, WidgetRef ref, Tank tank, String photoId) async {
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

  void _resetTankBackground(BuildContext context, WidgetRef ref, Tank tank) async {
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
      );
      
      await ref.read(tankProvider.notifier).addTank(duplicatedTank);
      
      if (context.mounted) {
        context.showAccessibleMessage('Tank "${tank.name}" duplicated successfully');
      }
    } catch (e) {
      if (context.mounted) {
        context.showAccessibleMessage('Failed to duplicate tank: $e');
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Tank tank) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tank', textAlign: TextAlign.center),
        content: Text('Are you sure you want to delete "${tank.name}"? This action cannot be undone.', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
            child: const Text('Delete'),
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

  String _formatWaterWeight(Tank tank) {
    if (tank.sizeGallons != null && tank.sizeLiters != null) {
      final pounds = tank.sizeGallons! * 8.34;
      final kilograms = tank.sizeLiters!; // 1 liter = 1 kg approximately
      return '${pounds.toStringAsFixed(0)} lbs (${kilograms.toStringAsFixed(0)} kg)';
    } else if (tank.sizeGallons != null) {
      final pounds = tank.sizeGallons! * 8.34;
      return '${pounds.toStringAsFixed(0)} pounds';
    } else if (tank.sizeLiters != null) {
      final kilograms = tank.sizeLiters!;
      return '${kilograms.toStringAsFixed(0)} kilograms';
    }
    return '';
  }

  Widget _buildLatestParameters(BuildContext context, Tank tank, ColorScheme cs) {
    if (tank.waterParameters.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group parameters by type and get latest for each
    final latestByType = <String, WaterParameter>{};
    for (var param in tank.waterParameters) {
      if (!latestByType.containsKey(param.parameterType) ||
          param.dateRecorded.isAfter(latestByType[param.parameterType]!.dateRecorded)) {
        latestByType[param.parameterType] = param;
      }
    }

    // Define parameter order and get labels/icons
    final paramOrder = tank.type == 'marine'
        ? ['ammonia', 'nitrite', 'nitrate', 'phosphate', 'salinity', 'calcium', 'magnesium', 'iodine', 'kh', 'gh', 'alkalinity', 'orp', 'ph', 'potassium', 'tds']
        : ['ammonia', 'nitrite', 'nitrate', 'phosphate', 'kh', 'gh', 'alkalinity', 'orp', 'ph', 'potassium', 'tds'];
    
    final paramLabels = {
      'ammonia': 'NH3',
      'nitrite': 'NO2',
      'nitrate': 'NO3',
      'phosphate': 'PO4',
      'salinity': 'Sal',
      'calcium': 'Ca',
      'magnesium': 'Mg',
      'kh': 'KH',
      'gh': 'GH',
      'alkalinity': 'Alk',
      'orp': 'ORP',
      'ph': 'pH',
      'potassium': 'K',
      'tds': 'TDS',
      'iodine': 'I',
    };

    final paramIcons = {
      'ammonia': Icons.warning,
      'nitrite': Icons.science,
      'nitrate': Icons.analytics,
      'phosphate': Icons.bubble_chart,
      'salinity': Icons.water,
      'calcium': Icons.diamond,
      'magnesium': Icons.bolt,
      'kh': Icons.shield,
      'gh': Icons.hardware,
      'alkalinity': Icons.balance,
      'orp': Icons.battery_charging_full,
      'ph': Icons.science_outlined,
      'potassium': Icons.spa,
      'tds': Icons.grain,
      'iodine': Icons.ac_unit,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: paramOrder
          .where((type) => latestByType.containsKey(type))
          .map((type) {
        final param = latestByType[type]!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                paramIcons[type] ?? Icons.water_drop,
                size: 14,
                color: cs.primary,
              ),
              const SizedBox(width: 4),
              Text(
                paramLabels[type] ?? type,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${param.value.toStringAsFixed(param.value < 10 ? 1 : 0)}${param.unit ?? ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLatestDosingEntries(BuildContext context, Tank tank, ColorScheme cs) {
    if (tank.dosingEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the 5 most recent dosing entries
    final sortedEntries = List<DosingEntry>.from(tank.dosingEntries)
      ..sort((a, b) => b.dateDosed.compareTo(a.dateDosed));
    final recentEntries = sortedEntries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...recentEntries.map((entry) {
          final daysSince = DateTime.now().difference(entry.dateDosed).inDays;
          final timeAgo = daysSince == 0
              ? 'Today'
              : daysSince == 1
                  ? 'Yesterday'
                  : daysSince < 7
                      ? '$daysSince days ago'
                      : '${entry.dateDosed.month}/${entry.dateDosed.day}/${entry.dateDosed.year}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medication_liquid,
                    size: 16,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.treatmentName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          '${entry.amount}${entry.unit} • $timeAgo',
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
        }),
        if (tank.dosingEntries.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${tank.dosingEntries.length - 5} more doses',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLatestActivityLogs(BuildContext context, Tank tank, ColorScheme cs) {
    if (tank.notificationLogs.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the 5 most recent activity logs
    final sortedLogs = List.from(tank.notificationLogs)
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final recentLogs = sortedLogs.take(5).toList();

    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...recentLogs.map((log) {
          // Use calendar day comparison instead of 24-hour periods
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final logDate = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
          final daysDifference = today.difference(logDate).inDays;
          
          final timeAgo = daysDifference == 0
              ? l10n.today
              : daysDifference == 1
                  ? l10n.yesterday
                  : daysDifference < 7
                      ? l10n.daysAgo(daysDifference)
                      : '${log.loggedAt.month}/${log.loggedAt.day}/${log.loggedAt.year}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getActivityIcon(log.type),
                    size: 16,
                    color: _getActivityColor(log.type),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.getDisplayName(),
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
        }),
        if (tank.notificationLogs.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.moreActivities(tank.notificationLogs.length - 5),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
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
          Icon(
            Icons.shape_line,
            size: 14,
            color: textColor,
          ),
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

  String? _getFishImageUrl(String tankType, String fishName, Map<String, List<Fish>>? fishData, {TankInhabitant? inhabitant}) {
    // Prioritize custom images if inhabitant is provided
    if (inhabitant != null) {
      if (inhabitant.customImageUrl != null && inhabitant.customImageUrl!.isNotEmpty) {
        return inhabitant.customImageUrl;
      }
      if (inhabitant.customImagePath != null && inhabitant.customImagePath!.isNotEmpty) {
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
    return inhabitants.fold(0, (total, inhabitant) => total + inhabitant.quantity);
  }

  Map<String, List<TankInhabitant>> _groupInhabitantsByFishType(List<TankInhabitant> inhabitants) {
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

  List<Widget> _buildFishGroupDisplay(Tank tank, Map<String, List<Fish>>? fishData) {
    final groupedFish = _groupInhabitantsByFishType(tank.inhabitants);
    final widgets = <Widget>[];
    
    int displayedGroups = 0;
    const maxGroups = 3; // Limit to 3 fish types to keep card compact
    
    for (final entry in groupedFish.entries) {
      if (displayedGroups >= maxGroups) break;
      
      final fishType = entry.key;
      final inhabitants = entry.value;
      final fishImageUrl = _getFishImageUrl(tank.type, fishType, fishData, inhabitant: inhabitants.first);
      
      // Calculate total quantity for this fish type
      final totalQuantity = inhabitants.fold<int>(0, (sum, inhabitant) => sum + inhabitant.quantity);
      
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

  Future<void> _getTankStockingRecommendations(BuildContext context, WidgetRef ref, Tank tank) async {
    if (tank.inhabitants.isEmpty) {
      context.showAccessibleMessage(
        'Tank must have existing inhabitants to get stocking recommendations.'
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
        'Fish data is not available. Please try again later.'
      );
      return;
    }

    // Show options dialog first
    final options = await showDialog<StockingRecommendationOptions>(
      context: context,
      builder: (context) => const StockingRecommendationOptionsDialog(),
    );

    // User cancelled the dialog
    if (options == null || !context.mounted) {
      return;
    }
    
    // Store the options for the listener
    _includeCustomNames = options.includeCustomNames;
    _additionalNotes = options.additionalNotes;
    
    // Debug: Print values to verify they're being stored
    debugPrint('Storing options - includeCustomNames: $_includeCustomNames');
    debugPrint('Storing options - additionalNotes: "$_additionalNotes"');
    
    // Store the current tank for the listener
    _currentTankForRecommendations = tank;
    
    // Calculate and store existing fish for the listener
    final categoryFish = fishData[tank.type] ?? [];
    final existingFish = <Fish>[];
    
    for (final inhabitant in tank.inhabitants) {
      final fish = categoryFish.firstWhere(
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
                    const Text('Getting stocking recommendations...'),
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
                      child: const Text('Cancel'),
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
        'include_custom_names': options.includeCustomNames ? 'true' : 'false',
        'has_additional_notes': options.additionalNotes.isNotEmpty ? 'true' : 'false',
      },
    );
    AnalyticsService.logTankAction(
      action: 'get_stocking_recommendations',
      tankType: tank.type,
      tankSize: tank.sizeGallons?.toInt(),
    );

    // Get recommendations for this tank
    ref.read(aquariumStockingProvider.notifier).getTankStockingRecommendations(
      tank: tank,
      includeCustomNames: options.includeCustomNames,
      additionalNotes: options.additionalNotes,
    );
  }


}