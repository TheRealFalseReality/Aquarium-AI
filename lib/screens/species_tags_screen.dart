import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final fishDataAsync = ref.watch(fishDataProvider);
    ref.watch(speciesTagsProvider);
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
                    segments: [
                      ButtonSegment(
                        value: 'freshwater',
                        label: Text(l10n.freshwater),
                        icon: const Icon(Icons.water_drop, size: 18),
                      ),
                      ButtonSegment(
                        value: 'marine',
                        label: Text(l10n.saltwater),
                        icon: const Icon(Icons.waves, size: 18),
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
                      ? CachedNetworkImageProvider(fish.imageURL)
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
    
    // Color scheme for tags
    final Color chipColor;
    final Color textColor;
    final Color iconColor;
    
    if (isDefault) {
      // Default tags: greyish color
      chipColor = colorScheme.surfaceVariant;
      textColor = colorScheme.onSurfaceVariant;
      iconColor = colorScheme.onSurfaceVariant;
    } else {
      // User tags: cycle through primary, secondary, tertiary, error
      final colorIndex = tag.hashCode.abs() % 4;
      switch (colorIndex) {
        case 0:
          chipColor = colorScheme.primaryContainer;
          textColor = colorScheme.onPrimaryContainer;
          iconColor = colorScheme.onPrimaryContainer;
          break;
        case 1:
          chipColor = colorScheme.secondaryContainer;
          textColor = colorScheme.onSecondaryContainer;
          iconColor = colorScheme.onSecondaryContainer;
          break;
        case 2:
          chipColor = colorScheme.tertiaryContainer;
          textColor = colorScheme.onTertiaryContainer;
          iconColor = colorScheme.onTertiaryContainer;
          break;
        case 3:
        default:
          chipColor = colorScheme.errorContainer;
          textColor = colorScheme.onErrorContainer;
          iconColor = colorScheme.onErrorContainer;
          break;
      }
    }
    
    return Chip(
      label: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isDefault ? FontWeight.w500 : FontWeight.normal,
          color: textColor,
        ),
      ),
      backgroundColor: chipColor,
      deleteIcon: Icon(
        isDefault ? Icons.lock : Icons.close,
        size: 14,
        color: iconColor,
      ),
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
