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
    super.dispose();
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

  void _showAddTagDialog(BuildContext context, String fishType) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Tag to $fishType'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Species Name',
            hintText: 'e.g., Neon Tetra, Guppy, etc.',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                ref.read(speciesTagsProvider.notifier).addTag(fishType, tag);
                Navigator.pop(context);
                context.showAccessibleMessage('Tag "$tag" added successfully!');

                // Log tag addition
                AnalyticsService.logFeatureUsed(
                  featureName: 'species_tag_added',
                  parameters: {
                    'fish_type': fishType,
                    'category': _selectedCategory,
                  },
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTagsDialog(BuildContext context, String fishType) {
    final tags =
        ref.read(speciesTagsProvider.notifier).getTagsForFishType(fishType);
    final controller = TextEditingController(text: tags.join(', '));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Tags for $fishType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter species names separated by commas:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Neon Tetra, Cardinal Tetra',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final input = controller.text.trim();
              final newTags = input
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              ref
                  .read(speciesTagsProvider.notifier)
                  .setTagsForFishType(fishType, newTags);
              Navigator.pop(context);
              context.showAccessibleMessage('Tags updated successfully!');

              // Log tag edit
              AnalyticsService.logFeatureUsed(
                featureName: 'species_tags_edited',
                parameters: {
                  'fish_type': fishType,
                  'tag_count': newTags.length,
                },
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fishDataAsync = ref.watch(fishDataProvider);
    final tagsState = ref.watch(speciesTagsProvider);

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
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Species Tags',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add searchable species names to each fish type to help with filtering and organization.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Category Selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'freshwater',
                              label: Text('Freshwater'),
                              icon: Icon(Icons.water_drop),
                            ),
                            ButtonSegment(
                              value: 'marine',
                              label: Text('Saltwater'),
                              icon: Icon(Icons.waves),
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
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by fish type or tag...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),

              // Fish List
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                        final tags = ref
                            .read(speciesTagsProvider.notifier)
                            .getTagsForFishType(fish.name);
                        final hasTags = tags.isNotEmpty;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: fish.imageURL.isNotEmpty
                                  ? NetworkImage(fish.imageURL)
                                  : null,
                              child: fish.imageURL.isEmpty
                                  ? const Icon(Icons.pets)
                                  : null,
                            ),
                            title: Text(
                              fish.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: hasTags
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: tags.map((tag) {
                                        return Chip(
                                          label: Text(
                                            tag,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                          onDeleted: () {
                                            ref
                                                .read(speciesTagsProvider.notifier)
                                                .removeTag(fish.name, tag);
                                            context.showAccessibleMessage(
                                                'Tag "$tag" removed');
                                          },
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                    ),
                                  )
                                : const Text('No tags yet'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Add tag',
                                  onPressed: () =>
                                      _showAddTagDialog(context, fish.name),
                                ),
                                if (hasTags)
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit tags',
                                    onPressed: () =>
                                        _showEditTagsDialog(context, fish.name),
                                  ),
                              ],
                            ),
                          ),
                        );
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
}
