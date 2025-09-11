// lib/screens/fish_compatibility_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_layout.dart';
import '../providers/fish_compatibility_provider.dart';
import '../models/fish.dart';
import '../models/compatibility_report.dart';

class FishCompatibilityScreen extends ConsumerStatefulWidget {
  const FishCompatibilityScreen({super.key});

  @override
  _FishCompatibilityScreenState createState() =>
      _FishCompatibilityScreenState();
}

class _FishCompatibilityScreenState
    extends ConsumerState<FishCompatibilityScreen> {
  String _selectedCategory = 'freshwater';

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(fishCompatibilityProvider);
    final notifier = ref.read(fishCompatibilityProvider.notifier);

    ref.listen<FishCompatibilityState>(fishCompatibilityProvider, (previous, next) {
      if (next.report != null && (previous?.report != next.report)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showReportDialog(context, next.report!);
          }
        });
      }
      if (next.error != null && previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                action: SnackBarAction(
                  label: 'Dismiss',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
            notifier.clearError();
          }
        });
      }
    });

    return MainLayout(
      title: 'AI Compatibility Calculator',
      child: Column(
        children: [
          _buildCategorySelector(notifier),
          Expanded(
            child: providerState.fishData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Failed to load fish data:\n$error', textAlign: TextAlign.center,),
                ),
              ),
              data: (fishData) {
                final fishList = fishData[_selectedCategory] ?? [];
                if (fishList.isEmpty) {
                  return const Center(child: Text('No fish found for this category.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: fishList.length,
                  itemBuilder: (context, index) {
                    final fish = fishList[index];
                    final isSelected = providerState.selectedFish.contains(fish);
                    return _buildFishCard(fish, isSelected, notifier);
                  },
                );
              },
            ),
          ),
          if (providerState.selectedFish.isNotEmpty)
            _buildBottomBar(providerState, notifier),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(FishCompatibilityNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('Freshwater'),
            selected: _selectedCategory == 'freshwater',
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedCategory = 'freshwater');
                notifier.clearSelection();
              }
            },
          ),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('Saltwater'),
            selected: _selectedCategory == 'marine',
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedCategory = 'marine');
                notifier.clearSelection();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFishCard(
      Fish fish, bool isSelected, FishCompatibilityNotifier notifier) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 3,
        ),
      ),
      child: InkWell(
        onTap: () => notifier.selectFish(fish),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                fish.imageURL,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                fish.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(FishCompatibilityState provider, FishCompatibilityNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: provider.selectedFish
                    .map((fish) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(fish.imageURL),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () => notifier.getCompatibilityReport(_selectedCategory),
            child: provider.isLoading
                ? const CircularProgressIndicator()
                : const Text('Get Report'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, CompatibilityReport report) {
    final notifier = ref.read(fishCompatibilityProvider.notifier);

    // Define the sections to display in the report
    final sections = {
      'Selected Fish': _buildSelectedFishSection(report.selectedFish),
      'Detailed Summary': SelectableText(report.detailedSummary),
      'Recommended Tank Size': SelectableText(report.tankSize),
      'Decorations and Setup': SelectableText(report.decorations),
      'Care Guide': SelectableText(report.careGuide),
      'Compatible Tank Mates': SelectableText(report.compatibleFish.join(', ')),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('Compatibility Report')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHarmonyCard(context, report),
                const SizedBox(height: 16),
                ...sections.entries.map((entry) {
                  final index = sections.keys.toList().indexOf(entry.key);
                  return _buildSection(
                    context,
                    entry.key,
                    entry.value,
                    index,
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notifier.clearSelection();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonyCard(BuildContext context, CompatibilityReport report) {
    final harmonyColor = _getHarmonyColor(report.groupHarmonyScore);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Group Harmony',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              report.harmonyLabel,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: harmonyColor),
              textAlign: TextAlign.center,
            ),
            SelectableText(
              '${(report.groupHarmonyScore * 100).toStringAsFixed(0)}%',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: harmonyColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              report.harmonySummary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content, int index) {
    final isEven = index % 2 == 0;
    return Card(
      color: isEven ? null : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFishSection(List<Fish> selectedFish) {
    return Column(
      children: selectedFish.map((fish) {
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(fish.imageURL),
          ),
          title: Text(fish.name),
          subtitle: Text(fish.commonNames.join(', ')),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Color _getHarmonyColor(double score) {
    if (score >= 0.75) return Colors.green;
    if (score >= 0.5) return Colors.yellow;
    if (score >= 0.25) return Colors.orange;
    return Colors.red;
  }
}