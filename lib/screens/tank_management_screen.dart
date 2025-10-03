import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../main_layout.dart';
import '../models/tank.dart';
import '../models/fish.dart';
import '../providers/tank_provider.dart';
import '../providers/aquarium_stocking_provider.dart';
import '../services/fish_data_service.dart';
import '../utils/tank_harmony_calculator.dart';
import '../widgets/accessible_feedback.dart';
import '../widgets/ad_component.dart';
import '../services/analytics_service.dart';
import 'tank_creation_screen.dart';
import 'stocking_report_screen.dart';

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
    final tankState = ref.watch(tankProvider);
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
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StockingReportScreen(
              reports: next.recommendations!,
              existingTankName: _currentTankForRecommendations?.name,
              existingFish: _currentExistingFish,
              originalTank: _currentTankForRecommendations, // For regeneration
            ),
          ),
        );
        // Clear the current tank reference
        _currentTankForRecommendations = null;
        _currentExistingFish = null;
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
      title: 'My Tanks',
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
        label: const Text('Create Tank'),
      ),
      child: tankState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tankState.error != null
              ? _buildErrorState(context, ref, tankState.error!)
              : tankState.tanks.isEmpty
                  ? _buildEmptyState(context, ref)
                  : _buildTankListWithFloatingMenu(context, ref, tankState.tanks, fishData),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
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
              'Error Loading Tanks',
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
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
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
              'No Tanks Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first custom tank to get started!\n\nDesign your perfect aquarium with custom names, types, and inhabitants.',
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
                  label: const Text('Create Your First Tank'),
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
                      'Or restore from backup:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _importTanks(context, ref),
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text('Restore'),
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

  Widget _buildTankListWithFloatingMenu(BuildContext context, WidgetRef ref, List<Tank> tanks, Map<String, List<Fish>>? fishData) {
    return Stack(
      children: [
        _buildTankList(context, ref, tanks, fishData),
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

  Widget _buildTankList(BuildContext context, WidgetRef ref, List<Tank> tanks, Map<String, List<Fish>>? fishData) {
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
          // Masonry grid layout
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: columnCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childCount: sortedTanks.length,
              itemBuilder: (context, index) {
                return _buildTankCard(context, ref, sortedTanks[index], fishData);
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      );
    }
    
    // Use list layout for mobile devices
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedTanks.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context, sortedTanks.length);
        }
        
        final tank = sortedTanks[index - 1];
        return _buildTankCard(context, ref, tank, fishData);
      },
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
                  'My Tanks ($tankCount)',
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
                      _exportTanks(context, ref);
                      break;
                    case 'restore':
                      _importTanks(context, ref);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'backup',
                    child: Row(
                      children: [
                        Icon(Icons.backup, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Backup Tanks'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(Icons.restore, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Restore Tanks'),
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
    switch (option) {
      case TankSortOption.name:
        return 'Name';
      case TankSortOption.type:
        return 'Type';
      case TankSortOption.size:
        return 'Size';
      case TankSortOption.date:
        return 'Date';
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

  Widget _buildTankCard(BuildContext context, WidgetRef ref, Tank tank, Map<String, List<Fish>>? fishData) {
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
            cs.surfaceContainerHighest.withOpacity(0.5),
          ]
        : [
            Colors.indigo.shade400.withOpacity(0.15),
            Colors.purple.shade300.withOpacity(0.15),
            cs.surfaceContainerHighest.withOpacity(0.5),
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
              ? NetworkImage(backgroundPhoto.imageUrl!) as ImageProvider
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
                                IconData(tank.customIconCodePoint!, fontFamily: 'MaterialIcons'),
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
                                              ? Image.network(imageUrl, fit: BoxFit.cover)
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
                          Text(
                            tank.type == 'freshwater' ? 'Freshwater' : 'Saltwater',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
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
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (tank.photos.isNotEmpty)
                          const PopupMenuItem(
                            value: 'set_background',
                            child: Row(
                              children: [
                                Icon(Icons.wallpaper, size: 18),
                                SizedBox(width: 8),
                                Text('Set Card Background'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'set_icon',
                          child: Row(
                            children: [
                              Icon(Icons.emoji_emotions_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Change Icon'),
                            ],
                          ),
                        ),
                        if (tank.customBackgroundPhotoId != null)
                          const PopupMenuItem(
                            value: 'reset_background',
                            child: Row(
                              children: [
                                Icon(Icons.restore, size: 18),
                                SizedBox(width: 8),
                                Text('Reset Background'),
                              ],
                            ),
                          ),
                        if (tank.inhabitants.isNotEmpty)
                          const PopupMenuItem(
                            value: 'recommendations',
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text('Get Stocking Ideas', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 18),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
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
                
                // Action buttons area (space for future parameters/dosing)
                Row(
                  children: [
                    // AI stocking button
                    if (tank.inhabitants.isNotEmpty)
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
                    if (tank.inhabitants.isNotEmpty) const SizedBox(width: 8),
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
            // Floating quick action buttons
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick add photo button
                  FloatingActionButton.small(
                    heroTag: 'photo_${tank.id}',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TankCreationScreen(existingTank: tank),
                        ),
                      );
                    },
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    elevation: 4,
                    child: const Icon(Icons.add_a_photo, size: 20),
                  ),
                  const SizedBox(height: 8),
                  // Quick add inhabitant button
                  FloatingActionButton.small(
                    heroTag: 'inhabitant_${tank.id}',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TankCreationScreen(existingTank: tank),
                        ),
                      );
                    },
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    elevation: 4,
                    child: const Icon(Icons.add, size: 20),
                  ),
                ],
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

  void _showTankDetails(BuildContext context, Tank tank, Map<String, List<Fish>>? fishData) {
    final cs = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    // AI-inspired gradient colors based on tank type with higher opacity
    final gradientColors = tank.type == 'freshwater'
        ? [
            Colors.blue.shade400.withOpacity(0.95),
            Colors.cyan.shade300.withOpacity(0.95),
            cs.surfaceContainerHighest.withOpacity(0.98),
          ]
        : [
            Colors.indigo.shade400.withOpacity(0.95),
            Colors.purple.shade300.withOpacity(0.95),
            cs.surfaceContainerHighest.withOpacity(0.98),
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
                                                      ? Image.network(
                                                          imageUrl,
                                                          fit: BoxFit.cover,
                                                          width: double.infinity,
                                                          height: double.infinity,
                                                          errorBuilder: (context, error, stackTrace) => Container(
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
                        
                        // Inhabitants section
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
                                  Icon(Icons.pets, size: 18, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Inhabitants (${_getTotalInhabitantCount(tank.inhabitants)})',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
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
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundImage: fishImageUrl != null 
                                            ? (fishImageUrl.startsWith('http')
                                                ? NetworkImage(fishImageUrl)
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
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                inhabitant.quantity > 1
                                                    ? '${inhabitant.quantity}x ${inhabitant.customName}'
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
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
                            ? Image.network(imageUrl, fit: BoxFit.cover)
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

  void _showSetIconDialog(BuildContext context, WidgetRef ref, Tank tank) {
    // Predefined icons for tanks
    final icons = [
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
                                    ? Image.network(imageUrl, fit: BoxFit.cover)
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
                      ? NetworkImage(fishImageUrl)
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
                      totalQuantity > 1
                          ? '${totalQuantity}x ${inhabitants.map((i) => i.customName).join(', ')}'
                          : inhabitants.map((i) => i.customName).join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fishType,
                  
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

  void _getTankStockingRecommendations(BuildContext context, WidgetRef ref, Tank tank) {
    if (tank.inhabitants.isEmpty) {
      context.showAccessibleMessage(
        'Tank must have existing inhabitants to get stocking recommendations.'
      );
      return;
    }

    // Store the current tank for the listener
    _currentTankForRecommendations = tank;
    
    // Get fish data from provider
    final fishDataAsync = ref.read(fishDataProvider);
    final fishData = fishDataAsync.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );
    
    // Calculate and store existing fish for the listener
    if (fishData != null) {
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
        for (int i = 0; i < inhabitant.quantity; i++) {
          existingFish.add(fish);
        }
      }
      _currentExistingFish = existingFish;
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
      },
    );
    AnalyticsService.logTankAction(
      action: 'get_stocking_recommendations',
      tankType: tank.type,
      tankSize: tank.sizeGallons?.toInt(),
    );

    // Get recommendations for this tank
    ref.read(aquariumStockingProvider.notifier).getTankStockingRecommendations(tank: tank);
  }

  Future<void> _exportTanks(BuildContext context, WidgetRef ref) async {
    final tankNotifier = ref.read(tankProvider.notifier);
    final tankState = ref.read(tankProvider);

    if (tankState.tanks.isEmpty) {
      context.showAccessibleMessage('No tanks to backup');
      return;
    }

    // Show confirmation dialog with backup info
    final backupInfo = tankNotifier.createBackupInfo();
    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.blue),
            SizedBox(width: 8),
            Text('Backup Tanks'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will create a backup file containing:'),
            const SizedBox(height: 8),
            Text('• ${backupInfo['tankCount']} tank(s)'),
            Text('• All fish and tank configurations'),
            Text('• Export date: ${DateTime.now().toString().split('.')[0]}'),
            const SizedBox(height: 16),
            Text(
              'The backup file will be saved to your device.',
              style: TextStyle(
                fontSize: 12,
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
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );

    if (shouldExport == true) {
      final filePath = await tankNotifier.exportTanksToFile();
      
      if (context.mounted) {
        if (filePath != null) {
          context.showAccessibleMessage(
            'Backup created successfully!\nSaved to: ${filePath.split('/').last}',
            duration: const Duration(seconds: 4),
          );
        } else {
          // Check if there's an actual error or if user just cancelled
          final error = ref.read(tankProvider).error;
          if (error != null) {
            context.showAccessibleMessage(
              'Failed to create backup: $error',
              duration: const Duration(seconds: 4),
            );
          }
          // If no error, user probably cancelled the save dialog - no message needed
        }
      }
    }
  }

  Future<void> _importTanks(BuildContext context, WidgetRef ref) async {
    // Show warning dialog first
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.green),
            SizedBox(width: 8),
            Text('Restore Tanks'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ Important',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            SizedBox(height: 8),
            Text('Restoring from backup will:'),
            SizedBox(height: 8),
            Text('• Replace ALL current tanks'),
            Text('• Cannot be undone'),
            SizedBox(height: 16),
            Text('Make sure you have a current backup before proceeding.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Choose File'),
          ),
        ],
      ),
    );

    if (shouldImport == true) {
      final success = await ref.read(tankProvider.notifier).importTanksFromFile();
      
      if (context.mounted) {
        if (success) {
          context.showAccessibleMessage('Tanks restored successfully!');
        } else {
          // Error message will be shown from the provider's error state
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