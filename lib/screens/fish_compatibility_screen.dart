// lib/screens/fish_compatibility_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main_layout.dart';
import '../providers/fish_compatibility_provider.dart';
import '../models/fish.dart';
import '../models/compatibility_report.dart';

class FishCompatibilityScreen extends StatefulWidget {
  const FishCompatibilityScreen({super.key});

  @override
  _FishCompatibilityScreenState createState() =>
      _FishCompatibilityScreenState();
}

class _FishCompatibilityScreenState extends State<FishCompatibilityScreen> {
  String _selectedCategory = 'freshwater';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FishCompatibilityProvider(),
      child: Consumer<FishCompatibilityProvider>(
        builder: (context, provider, child) {
          // Show the report dialog when a report is generated
          if (provider.report != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showReportDialog(context, provider.report!);
              provider.clearSelection(); 
            });
          }

          return MainLayout(
            title: 'AI Compatibility Calculator',
            child: Column(
              children: [
                _buildCategorySelector(provider),
                Expanded(
                  child: provider.fishData.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 3 / 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: provider.fishData[_selectedCategory]?.length ?? 0,
                          itemBuilder: (context, index) {
                            final fish = provider.fishData[_selectedCategory]![index];
                            final isSelected =
                                provider.selectedFish.contains(fish);
                            return _buildFishCard(fish, isSelected, provider);
                          },
                        ),
                ),
                if (provider.selectedFish.isNotEmpty)
                  _buildBottomBar(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector(FishCompatibilityProvider notifier) {
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
      Fish fish, bool isSelected, FishCompatibilityProvider notifier) {
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

  Widget _buildBottomBar(FishCompatibilityProvider provider) {
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
                : () => provider.getCompatibilityReport(_selectedCategory),
            child: provider.isLoading
                ? const CircularProgressIndicator()
                : const Text('Get Report'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, CompatibilityReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compatibility Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHarmonyCard(context, report),
              const SizedBox(height: 16),
              _buildSection(context, 'Detailed Summary', report.detailedSummary),
              _buildSection(context, 'Recommended Tank Size', report.tankSize),
              _buildSection(
                  context, 'Decorations and Setup', report.decorations),
              _buildSection(context, 'Care Guide', report.careGuide),
              _buildSection(
                context,
                'Compatible Tank Mates',
                report.compatibleFish.join(', '),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonyCard(BuildContext context, CompatibilityReport report) {
    final harmonyColor = _getHarmonyColor(report.groupHarmonyScore);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Group Harmony',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              report.harmonyLabel,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: harmonyColor),
            ),
            Text(
              '${(report.groupHarmonyScore * 100).toStringAsFixed(0)}%',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: harmonyColor),
            ),
            const SizedBox(height: 8),
            Text(
              report.harmonySummary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  Color _getHarmonyColor(double score) {
    if (score >= 0.75) return Colors.green;
    if (score >= 0.5) return Colors.yellow;
    if (score >= 0.25) return Colors.orange;
    return Colors.red;
  }
}