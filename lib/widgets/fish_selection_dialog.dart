import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fish.dart';
import '../widgets/fish_card.dart';
import '../services/fish_data_service.dart';

/// Dialog for selecting fish to include in stocking recommendations
class FishSelectionDialog extends ConsumerStatefulWidget {
  final String category;
  final List<Fish> initialSelectedFish;
  
  const FishSelectionDialog({
    super.key,
    required this.category,
    this.initialSelectedFish = const [],
  });

  @override
  FishSelectionDialogState createState() => FishSelectionDialogState();
}

class FishSelectionDialogState extends ConsumerState<FishSelectionDialog> {
  late List<Fish> _selectedFish;
  List<Fish> _filteredFishList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFish = List.from(widget.initialSelectedFish);
    _searchController.addListener(_filterFishList);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFishList);
    _searchController.dispose();
    super.dispose();
  }

  void _filterFishList() {
    final fishDataAsync = ref.read(fishDataProvider);
    final allFish = fishDataAsync.valueOrNull?[widget.category] ?? [];
    final query = _searchController.text;

    setState(() {
      if (query.isEmpty) {
        _filteredFishList = allFish;
      } else {
        _filteredFishList = allFish.where((fish) {
          final nameMatches = fish.name.toLowerCase().contains(query.toLowerCase());
          final commonNamesMatch = fish.commonNames
              .any((name) => name.toLowerCase().contains(query.toLowerCase()));
          return nameMatches || commonNamesMatch;
        }).toList();
      }
    });
  }

  void _toggleFishSelection(Fish fish) {
    setState(() {
      if (_selectedFish.contains(fish)) {
        _selectedFish.remove(fish);
      } else {
        _selectedFish.add(fish);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fishDataAsync = ref.watch(fishDataProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 800, 
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pets,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select Fish',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select specific fish to include in your stocking recommendations',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_selectedFish.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_selectedFish.length} fish selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
            ),
            // Fish grid
            Expanded(
              child: fishDataAsync.when(
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
                    _filteredFishList = fishData[widget.category] ?? [];
                  }
                  
                  if (_filteredFishList.isEmpty) {
                    return Center(
                      child: Text(
                        'No fish found matching "${_searchController.text}"',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      childAspectRatio: 3 / 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _filteredFishList.length,
                    itemBuilder: (context, index) {
                      final fish = _filteredFishList[index];
                      final isSelected = _selectedFish.contains(fish);
                      return FishCard(
                        fish: fish,
                        isSelected: isSelected,
                        category: widget.category,
                        onTap: () => _toggleFishSelection(fish),
                      );
                    },
                  );
                },
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_selectedFish.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedFish.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedFish);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(() {
                      if (_selectedFish.isEmpty) return 'Done';
                      final hasSpecies = _selectedFish.any((f) => f.commonNames.isNotEmpty);
                      return hasSpecies
                          ? 'Confirm & Select Species (${_selectedFish.length})'
                          : 'Confirm (${_selectedFish.length})';
                    }()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
