import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fish.dart';
import '../models/selected_fish_entry.dart';
import '../widgets/fish_card.dart';
import '../services/fish_data_service.dart';

/// Dialog for selecting fish to include in stocking recommendations
class FishSelectionDialog extends ConsumerStatefulWidget {
  final String category;
  final List<SelectedFishEntry> initialSelectedFish;
  
  const FishSelectionDialog({
    super.key,
    required this.category,
    this.initialSelectedFish = const [],
  });

  @override
  FishSelectionDialogState createState() => FishSelectionDialogState();
}

class FishSelectionDialogState extends ConsumerState<FishSelectionDialog> {
  late List<SelectedFishEntry> _selectedFish;
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

  /// Returns the selected entry for [fish], or `null` if not selected.
  SelectedFishEntry? _entryFor(Fish fish) {
    try {
      return _selectedFish.firstWhere((e) => e.fish.name == fish.name);
    } catch (_) {
      return null;
    }
  }

  /// Handles tapping a fish card:
  /// - If already selected → deselects it.
  /// - If not selected and fish has common names → shows a variety picker,
  ///   then adds the fish with the chosen (or no) common name.
  /// - If not selected and no common names → adds it directly.
  Future<void> _toggleFishSelection(Fish fish) async {
    final existing = _entryFor(fish);
    if (existing != null) {
      // Deselect
      setState(() {
        _selectedFish.removeWhere((e) => e.fish.name == fish.name);
      });
      return;
    }

    // Select – optionally pick a variety first
    if (fish.commonNames.isNotEmpty) {
      final chosenName = await _showVarietyPicker(fish);
      // null means the user cancelled the picker → do not add the fish
      if (chosenName == null) return;
      if (!mounted) return;
      // empty string means "Any / no specific variety"
      setState(() {
        _selectedFish.add(SelectedFishEntry(
          fish: fish,
          selectedCommonName: chosenName.isNotEmpty ? chosenName : null,
        ));
      });
    } else {
      setState(() {
        _selectedFish.add(SelectedFishEntry(fish: fish));
      });
    }
  }

  /// Shows an AlertDialog listing the fish's common names as selectable chips.
  /// Returns the chosen common name, an empty string for "Any", or `null` if
  /// the user dismissed by pressing Cancel.
  Future<String?> _showVarietyPicker(Fish fish) {
    // Pre-select "Any" so Add always returns a meaningful value.
    String picked = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setInner) {
            return AlertDialog(
              title: Text('Select a variety of ${fish.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a specific common name to send to the AI for more targeted recommendations, or leave unspecified.',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // "Any" chip – selected by default
                      FilterChip(
                        label: const Text('Any'),
                        selected: picked == '',
                        onSelected: (_) => setInner(() => picked = ''),
                        selectedColor: cs.primaryContainer,
                      ),
                      ...fish.commonNames.map(
                        (name) => FilterChip(
                          label: Text(name),
                          selected: picked == name,
                          onSelected: (_) => setInner(() => picked = name),
                          selectedColor: cs.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(picked),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
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
          maxHeight: screenHeight * 0.85, // Use 85% of screen height
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
                    'Select specific fish to include in your stocking recommendations. Tap a fish to optionally choose a specific variety.',
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
                      final entry = _entryFor(fish);
                      final isSelected = entry != null;
                      return Stack(
                        children: [
                          FishCard(
                            fish: fish,
                            isSelected: isSelected,
                            category: widget.category,
                            onTap: () => _toggleFishSelection(fish),
                          ),
                          // Show selected variety badge when a specific common
                          // name was chosen
                          if (isSelected && entry.selectedCommonName != null)
                            Positioned(
                              bottom: 8,
                              left: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.selectedCommonName!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
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
                    label: Text(_selectedFish.isEmpty ? 'Done' : 'Confirm (${_selectedFish.length})'),
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
