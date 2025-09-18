import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_layout.dart';
import '../models/tank.dart';
import '../models/fish.dart';
import '../providers/tank_provider.dart';
import '../utils/tank_harmony_calculator.dart';
import '../widgets/ad_component.dart';
import 'tank_creation_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFishData();
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
                  ? _buildEmptyState(context)
                  : _buildTankList(context, ref, tankState.tanks),
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

  Widget _buildEmptyState(BuildContext context) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildTankList(BuildContext context, WidgetRef ref, List<Tank> tanks) {
    final sortedTanks = _sortTanks(tanks);
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
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

  Widget _buildHeader(BuildContext context, int tankCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Aquarium Collection',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You have $tankCount tank${tankCount == 1 ? '' : 's'} in your collection',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Sort Options
          Row(
            children: [
              Text(
                'Sort by:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TankSortOption.values.map((option) {
                      final isSelected = _currentSortOption == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getSortOptionLabel(option)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _currentSortOption = option;
                              });
                              _saveSortPreference(option);
                            }
                          },
                          backgroundColor: Colors.transparent,
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
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
                          Icons.pets,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tank.inhabitants.length} type${tank.inhabitants.length == 1 ? '' : 's'} of fish',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Fish Thumbnails Row
                    if (tank.inhabitants.isNotEmpty) ...[
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tank.inhabitants.take(5).length,
                          itemBuilder: (context, index) {
                            final inhabitant = tank.inhabitants[index];
                            final fishImageUrl = _getFishImageUrl(tank.type, inhabitant.fishUnit);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Tooltip(
                                message: '${inhabitant.quantity}x ${inhabitant.customName}',
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: fishImageUrl != null 
                                        ? NetworkImage(fishImageUrl) 
                                        : null,
                                      backgroundColor: fishImageUrl == null 
                                        ? Theme.of(context).colorScheme.primaryContainer 
                                        : null,
                                      child: fishImageUrl == null 
                                        ? Icon(
                                            Icons.pets,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            size: 20,
                                          ) 
                                        : null,
                                    ),
                                    if (inhabitant.quantity > 1)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${inhabitant.quantity}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (tank.inhabitants.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${tank.inhabitants.length - 5} more fish',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              const SizedBox(height: 8),
              
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
              // Harmony Score Info
              if (tank.inhabitants.isNotEmpty && _fishData != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.pets,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Harmony Score: ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _buildHarmonyScoreChip(tank),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              
              Text(
                'Inhabitants (${tank.inhabitants.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              if (tank.inhabitants.isEmpty)
                const Text('No inhabitants added yet.')
              else
                ...tank.inhabitants.map((inhabitant) {
                  final fishImageUrl = _getFishImageUrl(tank.type, inhabitant.fishUnit);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: fishImageUrl != null 
                                ? NetworkImage(fishImageUrl) 
                                : null,
                              backgroundColor: fishImageUrl == null 
                                ? Theme.of(context).colorScheme.primaryContainer 
                                : null,
                              child: fishImageUrl == null 
                                ? Icon(
                                    Icons.pets,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    size: 20,
                                  ) 
                                : null,
                            ),
                            if (inhabitant.quantity > 1)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '${inhabitant.quantity}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
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
                                inhabitant.customName,
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
                ExpansionTile(
                  title: Text(
                    'Compatibility Calculation Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        _getCalculationBreakdown(tank),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              Text(
                'Created: ${_formatDateTime(tank.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (tank.updatedAt != tank.createdAt)
                Text(
                  'Updated: ${_formatDateTime(tank.updatedAt)}',
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
      );
      
      await ref.read(tankProvider.notifier).addTank(duplicatedTank);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tank "${tank.name}" duplicated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate tank: $e')),
        );
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
              await ref.read(tankProvider.notifier).deleteTank(tank.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tank "${tank.name}" deleted')),
                );
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
      if (!tankFish.any((f) => f.name == fish.name)) {
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

  Widget _buildHarmonyScoreChip(Tank tank) {
    final harmonyScore = TankHarmonyCalculator.calculateTankHarmonyScore(tank, _fishData);
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
            Icons.pets,
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

  String? _getFishImageUrl(String tankType, String fishName) {
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
}