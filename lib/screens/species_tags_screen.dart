import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../providers/species_tags_provider.dart';
import '../services/fish_data_service.dart';
import '../models/fish.dart';
import '../widgets/accessible_feedback.dart';
import '../services/analytics_service.dart';

class SpeciesTagsScreen extends ConsumerStatefulWidget {
  const SpeciesTagsScreen({super.key});

  @override
  ConsumerState<SpeciesTagsScreen> createState() => _SpeciesTagsScreenState();
}

class _SpeciesTagsScreenState extends ConsumerState<SpeciesTagsScreen> {
  String _selectedCategory = 'freshwater';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, TextEditingController> _tagControllers = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Log screen visit
    AnalyticsService.logFeatureUsed(
      featureName: 'species_tags_screen',
      parameters: {'action': 'opened'},
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _tagControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String fishType) {
    if (!_tagControllers.containsKey(fishType)) {
      _tagControllers[fishType] = TextEditingController();
    }
    return _tagControllers[fishType]!;
  }

  List<Fish> _filterFish(List<Fish> fishList) {
    if (_searchQuery.isEmpty) {
      return fishList;
    }
    return fishList.where((fish) {
      final nameMatches = fish.name.toLowerCase().contains(_searchQuery);
      final commonNamesMatch = fish.commonNames
          .any((name) => name.toLowerCase().contains(_searchQuery));
      final tagsMatch = ref
          .read(speciesTagsProvider.notifier)
          .getTagsForFishType(fish.name)
          .any((tag) => tag.toLowerCase().contains(_searchQuery));
      return nameMatches || commonNamesMatch || tagsMatch;
    }).toList();
  }

  void _addTag(String fishType, String tag) {
    if (tag.trim().isEmpty) return;
    
    ref.read(speciesTagsProvider.notifier).addTag(fishType, tag.trim());
    _getController(fishType).clear();
    context.showAccessibleMessage('Tag "$tag" added');

    // Log tag addition
    AnalyticsService.logFeatureUsed(
      featureName: 'species_tag_added',
      parameters: {
        'fish_type': fishType,
        'category': _selectedCategory,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fishDataAsync = ref.watch(fishDataProvider);
    final tagsState = ref.watch(speciesTagsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return MainLayout(
      title: 'Species Tags',
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
          final allFish = fishData[_selectedCategory] ?? [];
          final filteredFish = _filterFish(allFish);

          return CustomScrollView(
            slivers: [
              // Compact Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Text(
                        'Species Tags',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tag fish with searchable species names',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Category Selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'freshwater',
                        label: Text('Freshwater'),
                        icon: Icon(Icons.water_drop, size: 18),
                      ),
                      ButtonSegment(
                        value: 'marine',
                        label: Text('Saltwater'),
                        icon: Icon(Icons.waves, size: 18),
                      ),
                    ],
                    selected: {_selectedCategory},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedCategory = newSelection.first;
                        _searchController.clear();
                      });
                    },
                  ),
                ),
              ),

              // Compact Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search fish...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
              ),

              // Fish Cards Grid
              if (filteredFish.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No fish found in this category.'
                            : 'No fish found matching "$_searchQuery".',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final fish = filteredFish[index];
                        return _buildFishCard(fish, colorScheme);
                      },
                      childCount: filteredFish.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFishCard(Fish fish, ColorScheme colorScheme) {
    final tags = ref.read(speciesTagsProvider.notifier).getTagsForFishType(fish.name);
    final controller = _getController(fish.name);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fish header with image and name
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: fish.imageURL.isNotEmpty
                      ? NetworkImage(fish.imageURL)
                      : null,
                  child: fish.imageURL.isEmpty
                      ? const Icon(Icons.pets, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fish.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            
            // Tags section
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((tag) => _buildTagChip(fish.name, tag, colorScheme)).toList(),
              ),
            ],
            
            // Add tag input
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Add species name...',
                      hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (value) => _addTag(fish.name, value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _addTag(fish.name, controller.text),
                  icon: const Icon(Icons.add, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: 'Add tag',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String fishType, String tag, ColorScheme colorScheme) {
    final isDefault = ref.read(speciesTagsProvider.notifier).isDefaultTag(fishType, tag);
    
    // Generate color based on tag
    final colorIndex = tag.hashCode.abs() % 8;
    final chipColor = isDefault
        ? colorScheme.secondaryContainer
        : [
            colorScheme.primaryContainer,
            colorScheme.tertiaryContainer,
            colorScheme.errorContainer.withOpacity(0.3),
            Colors.purple.withOpacity(0.2),
            Colors.teal.withOpacity(0.2),
            Colors.orange.withOpacity(0.2),
            Colors.indigo.withOpacity(0.2),
            Colors.pink.withOpacity(0.2),
          ][colorIndex];
    
    return Chip(
      label: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isDefault ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      backgroundColor: chipColor,
      deleteIcon: isDefault 
          ? const Icon(Icons.lock, size: 14)
          : const Icon(Icons.close, size: 14),
      onDeleted: isDefault
          ? null
          : () {
              ref.read(speciesTagsProvider.notifier).removeTag(fishType, tag);
              context.showAccessibleMessage('Tag "$tag" removed');
            },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }
}
