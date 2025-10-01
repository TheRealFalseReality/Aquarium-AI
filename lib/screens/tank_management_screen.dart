import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_layout.dart';
import '../models/tank.dart';
import '../models/fish.dart';
import '../providers/tank_provider.dart';
import '../providers/aquarium_stocking_provider.dart';
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
  Map<String, List<Fish>>? _fishData;
  TankSortOption _currentSortOption = TankSortOption.name;
  Tank? _currentTankForRecommendations; // Track current tank for recommendations
  List<Fish>? _currentExistingFish; // Track existing fish for recommendations
  bool _isSortMenuExpanded = false; // Track sort menu expansion
  bool _isSearchVisible = false; // Track search visibility
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFishData();
    _loadSortPreference();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
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

  Future<void> _loadFishData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/fishcompat.json');
      final jsonResponse = json.decode(jsonString) as Map<String, dynamic>;
      
      final fishData = <String, List<Fish>>{};
      for (final category in ['freshwater', 'marine']) {
        if (jsonResponse.containsKey(category)) {
          fishData[category] = (jsonResponse[category] as List)
              .map((f) => Fish.fromJson(f))
              .toList();
        }
      }
      
      setState(() {
        _fishData = fishData;
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    final tankState = ref.watch(tankProvider);

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
                  : _buildTankListWithFloatingMenu(context, ref, tankState.tanks),
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

  Widget _buildTankListWithFloatingMenu(BuildContext context, WidgetRef ref, List<Tank> tanks) {
    return Stack(
      children: [
        _buildTankList(context, ref, tanks),
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
        // Search widget positioned at the bottom
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: _buildSearchWidget(),
        ),
      ],
    );
  }
  
  Widget _buildSearchWidget() {
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
          ? _buildSearchBar()
          : Align(
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton(
                key: const ValueKey('search_fab'),
                heroTag: 'search_fab',
                onPressed: () {
                  setState(() {
                    _isSearchVisible = true;
                  });
                },
                child: const Icon(Icons.search),
              ),
            ),
    );
  }
  
  Widget _buildSearchBar() {
    return Material(
      key: const ValueKey('search_bar'),
      elevation: 6,
      borderRadius: BorderRadius.circular(30),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search tanks...',
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
    );
  }

  Widget _buildTankList(BuildContext context, WidgetRef ref, List<Tank> tanks) {
    final filteredTanks = _filterTanks(tanks);
    final sortedTanks = _sortTanks(filteredTanks);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Added bottom padding
      itemCount: sortedTanks.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(context, sortedTanks.length);
        }
        
        final tank = sortedTanks[index - 1];
        return _buildTankCard(context, ref, tank);
      },
    );
  }

  List<Tank> _sortTanks(List<Tank> tanks) {
    final sortedTanks = List<Tank>.from(tanks);
    
    switch (_currentSortOption) {
      case TankSortOption.name:
        sortedTanks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case TankSortOption.type:
        sortedTanks.sort((a, b) {
          final typeOrder = {'freshwater': 0, 'marine': 1};
          final aOrder = typeOrder[a.type] ?? 2;
          final bOrder = typeOrder[b.type] ?? 2;
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase()); // Secondary sort by name
        });
        break;
      case TankSortOption.size:
        sortedTanks.sort((a, b) {
          final aSize = a.sizeGallons ?? 0;
          final bSize = b.sizeGallons ?? 0;
          if (aSize != bSize) return bSize.compareTo(aSize); // Largest first
          return a.name.toLowerCase().compareTo(b.name.toLowerCase()); // Secondary sort by name
        });
        break;
      case TankSortOption.date:
        // Sort by creation date (newest first)
        sortedTanks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    
    return sortedTanks;
  }
  
  List<Tank> _filterTanks(List<Tank> tanks) {
    if (_searchQuery.isEmpty) {
      return tanks;
    }
    
    return tanks.where((tank) {
      // Search in tank name
      if (tank.name.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      
      // Search in tank type
      final tankType = tank.type == 'freshwater' ? 'freshwater' : 'saltwater';
      if (tankType.contains(_searchQuery) || tank.type.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      
      // Search in tank size
      if (tank.sizeGallons != null) {
        if (tank.sizeGallons.toString().contains(_searchQuery)) {
          return true;
        }
      }
      if (tank.sizeLiters != null) {
        if (tank.sizeLiters.toString().contains(_searchQuery)) {
          return true;
        }
      }
      
      // Search in tags
      if (tank.tags.any((tag) => tag.toLowerCase().contains(_searchQuery))) {
        return true;
      }
      
      // Search in inhabitants
      if (tank.inhabitants.any((inhabitant) {
        return inhabitant.customName.toLowerCase().contains(_searchQuery) ||
               inhabitant.fishUnit.toLowerCase().contains(_searchQuery);
      })) {
        return true;
      }
      
      return false;
    }).toList();
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
                          _currentSortOption = option;
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

  Widget _buildTankCard(BuildContext context, WidgetRef ref, Tank tank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTankDetails(context, tank),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tank.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tank.type == 'freshwater' ? 'Freshwater' : 'Saltwater',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Tank Size Display
                        if (tank.sizeGallons != null || tank.sizeLiters != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.straighten,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTankSize(tank),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Water Weight Display
                        if (tank.sizeGallons != null || tank.sizeLiters != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.line_weight,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Water Weight: ${_formatWaterWeight(tank)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Harmony Score Display
                        if (tank.inhabitants.isNotEmpty && _fishData != null) ...[
                          const SizedBox(height: 4),
                          _buildHarmonyScoreChip(tank),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TankCreationScreen(existingTank: tank),
                            ),
                          );
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
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (tank.inhabitants.isNotEmpty)
                        const PopupMenuItem(
                          value: 'recommendations',
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Get Stocking Ideas', style: TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Inhabitants summary
              if (tank.inhabitants.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pets,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No inhabitants added',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_groupInhabitantsByFishType(tank.inhabitants).length} type${_groupInhabitantsByFishType(tank.inhabitants).length == 1 ? '' : 's'} of inhabitant${_groupInhabitantsByFishType(tank.inhabitants).length == 1 ? '' : 's'} ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Fish Display by Type
                    if (tank.inhabitants.isNotEmpty) ...[
                      ..._buildFishGroupDisplay(tank),
                    ],
                  ],
                ),
              const SizedBox(height: 8),
              
              // Tags display
              if (tank.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tank.tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              
              // Stocking recommendations button
              if (tank.inhabitants.isNotEmpty) ...[
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _getTankStockingRecommendations(context, ref, tank),
                    icon: Icon(
                      Icons.auto_awesome,
                      size: 16,
                    ),
                    label: const Text('Get Stocking Ideas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Created date
              Text(
                'Created ${_formatDate(tank.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTankDetails(BuildContext context, Tank tank) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tank.name, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    tank.type == 'freshwater' ? Icons.water_drop : Icons.waves,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tank.type == 'freshwater' ? 'Freshwater Tank' : 'Saltwater Tank',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              // Tank Size Info
              if (tank.sizeGallons != null || tank.sizeLiters != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tank Size: ${_formatTankSize(tank)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
              // Water Weight Display
              if (tank.sizeGallons != null || tank.sizeLiters != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.line_weight,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Weight: ${_formatWaterWeight(tank)}',
                      style: Theme.of(context).textTheme.titleMedium,
                      ),
                  ],
                ),
              ],
              // Harmony Score Info
              if (tank.inhabitants.isNotEmpty && _fishData != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    _buildHarmonyScoreChip(tank),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              
              Text(
                'Inhabitants (${_getTotalInhabitantCount(tank.inhabitants)})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              if (tank.inhabitants.isEmpty)
                const Text('No inhabitants added yet.')
              else
                ...tank.inhabitants.map((inhabitant) {
                  final fishImageUrl = _getFishImageUrl(tank.type, inhabitant.fishUnit, inhabitant: inhabitant);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
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
                                Icons.shape_line,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                size: 20,
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
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                inhabitant.fishUnit,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              
              // Calculation Breakdown Expandable Section
              if (tank.inhabitants.isNotEmpty && _fishData != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  hint: 'Tap to view compatibility calculation breakdown',
                  excludeSemantics: false,
                  child: ExpansionTile(
                    title: Text(
                      'Compatibility Calculation Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            _getCalculationBreakdown(tank),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              if (tank.tags.isNotEmpty) ...[
                Text(
                  'Tags:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tank.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (tank.notes != null && tank.notes!.isNotEmpty) ...[
                Text(
                  'Notes:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Text(
                    tank.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Created: ${_formatDate(tank.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (tank.updatedAt != tank.createdAt)
                Text(
                  'Updated: ${_formatDate(tank.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TankCreationScreen(existingTank: tank),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _duplicateTank(BuildContext context, WidgetRef ref, Tank tank) async {
    try {
      final duplicatedTank = Tank.create(
        name: '${tank.name} (Copy)',
        type: tank.type,
        inhabitants: List.from(tank.inhabitants),
        sizeGallons: tank.sizeGallons,
        sizeLiters: tank.sizeLiters,
        tags: List.from(tank.tags),
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

  String _getCalculationBreakdown(Tank tank) {
    if (_fishData == null || tank.inhabitants.isEmpty) return 'No calculation available';
    
    // Get fish data for the tank
    final categoryFish = _fishData![tank.type] ?? [];
    final tankFish = <Fish>[];
    
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
        tankFish.add(fish);
      }
    }
    
    return TankHarmonyCalculator.generateCalculationBreakdown(tankFish);
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

  String? _getFishImageUrl(String tankType, String fishName, {TankInhabitant? inhabitant}) {
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
    if (_fishData == null) return null;
    
    final categoryFish = _fishData![tankType] ?? [];
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

  List<Widget> _buildFishGroupDisplay(Tank tank) {
    final groupedFish = _groupInhabitantsByFishType(tank.inhabitants);
    final widgets = <Widget>[];
    
    int displayedGroups = 0;
    const maxGroups = 3; // Limit to 3 fish types to keep card compact
    
    for (final entry in groupedFish.entries) {
      if (displayedGroups >= maxGroups) break;
      
      final fishType = entry.key;
      final inhabitants = entry.value;
      final fishImageUrl = _getFishImageUrl(tank.type, fishType, inhabitant: inhabitants.first);
      
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
    
    // Calculate and store existing fish for the listener
    if (_fishData != null) {
      final categoryFish = _fishData![tank.type] ?? [];
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