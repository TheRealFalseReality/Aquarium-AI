import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main_layout.dart';
import '../providers/fish_compatibility_provider.dart';
import '../models/fish.dart';
import '../models/compatibility_report.dart';
import '../widgets/ad_component.dart';

class FishCompatibilityScreen extends ConsumerStatefulWidget {
  const FishCompatibilityScreen({super.key});

  @override
  _FishCompatibilityScreenState createState() =>
      _FishCompatibilityScreenState();
}

class _FishCompatibilityScreenState
    extends ConsumerState<FishCompatibilityScreen> {
  String _selectedCategory = 'freshwater';
  OverlayEntry? _loadingOverlayEntry;

  @override
  void dispose() {
    _loadingOverlayEntry?.remove();
    super.dispose();
  }

  void _showLoadingOverlay(
      BuildContext context, List<Fish> selectedFish, String category) {
    if (_loadingOverlayEntry != null) return;

    _loadingOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Blurred background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 5,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Analyzing ${category.toUpperCase()} Fish...',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: selectedFish
                        .map(
                          (fish) => Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(fish.imageURL),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                fish.name.split(' ')[0], // Show first word of name
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Please wait while the AI generates your compatibility report.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_loadingOverlayEntry!);
  }

  void _hideLoadingOverlay() {
    _loadingOverlayEntry?.remove();
    _loadingOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(fishCompatibilityProvider);
    final notifier = ref.read(fishCompatibilityProvider.notifier);

    ref.listen<FishCompatibilityState>(fishCompatibilityProvider,
        (previous, next) {
      if (next.isLoading && ! (previous?.isLoading ?? false)) {
        _showLoadingOverlay(context, next.selectedFish, _selectedCategory);
      } else if (!next.isLoading && (previous?.isLoading ?? false)) {
        _hideLoadingOverlay();
      }

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
      bottomNavigationBar: const AdBanner(),
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      'AI Fish Compatibility',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select two or more fish to generate a compatibility report.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              _buildCategorySelector(notifier),
              Expanded(
                child: providerState.fishData.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                    final fishList = fishData[_selectedCategory] ?? [];
                    if (fishList.isEmpty) {
                      return const Center(
                          child: Text('No fish found for this category.'));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 3 / 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: fishList.length,
                      itemBuilder: (context, index) {
                        final fish = fishList[index];
                        final isSelected =
                            providerState.selectedFish.contains(fish);
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
            avatar: const Text('🐟'),
            label: const Text('Freshwater'),
            selected: _selectedCategory == 'freshwater',
            showCheckmark: false,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedCategory = 'freshwater');
                notifier.clearSelection();
              }
            },
          ),
          const SizedBox(width: 16),
          ChoiceChip(
            avatar: const Text('🐠'),
            label: const Text('Saltwater'),
            selected: _selectedCategory == 'marine',
            showCheckmark: false,
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

  Widget _buildBottomBar(
      FishCompatibilityState provider, FishCompatibilityNotifier notifier) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.3), // More transparent
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => notifier.clearSelection(),
                tooltip: 'Clear Selection',
              ),
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
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, CompatibilityReport report) {
    final notifier = ref.read(fishCompatibilityProvider.notifier);

    final sections = {
      'Selected Fish': _buildSelectedFishSection(context, report.selectedFish),
      'Detailed Summary':
          SelectableText(report.detailedSummary, textAlign: TextAlign.center),
      'Recommended Tank Size':
          SelectableText(report.tankSize, textAlign: TextAlign.center),
      'Decorations and Setup':
          SelectableText(report.decorations, textAlign: TextAlign.center),
      'Care Guide':
          SelectableText(report.careGuide, textAlign: TextAlign.center),
      'Compatible Tank Mates': _buildTankMatesSection(context, report),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        contentPadding: const EdgeInsets.all(8.0),
        title: Stack(
          alignment: Alignment.center,
          children: [
            const Text('Compatibility Report', textAlign: TextAlign.center),
            Positioned(
              right: -10,
              top: -10,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                  notifier.clearSelection();
                },
              ),
            ),
          ],
        ),
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

  Widget _buildSection(
      BuildContext context, String title, Widget content, int index) {
    final isEven = index % 2 == 0;
    return Card(
      color: isEven
          ? null
          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFishSection(
      BuildContext context, List<Fish> selectedFish) {
    return Column(
      children: selectedFish.map((fish) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(fish.imageURL),
                ),
                const SizedBox(width: 16),
                // Use a Flexible widget to prevent text overflow issues
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fish.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        fish.commonNames.join(', '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTankMatesSection(
      BuildContext context, CompatibilityReport report) {
    return Column(
      children: [
        SelectableText(report.tankMatesSummary, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          "(Click a fish to search)",
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          alignment: WrapAlignment.center,
          children: report.compatibleFish
              .map((fishName) => ActionChip(
                    label: Text(fishName),
                    onPressed: () async {
                      final url = Uri.parse(
                          'https://www.google.com/search?q=${Uri.encodeComponent(fishName)}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Color _getHarmonyColor(double score) {
    if (score >= 0.75) return Colors.green;
    if (score >= 0.5) return Colors.yellow;
    if (score >= 0.25) return Colors.orange;
    return Colors.red;
  }
}