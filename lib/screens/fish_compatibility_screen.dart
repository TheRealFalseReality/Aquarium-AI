import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main_layout.dart';
import '../providers/fish_compatibility_provider.dart';
import '../models/fish.dart';
import '../models/compatibility_report.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';

class FishCompatibilityScreen extends ConsumerStatefulWidget {
  const FishCompatibilityScreen({super.key});

  @override
  FishCompatibilityScreenState createState() => FishCompatibilityScreenState();
}

class FishCompatibilityScreenState
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
                    'Analyzing Fish...',
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
                                fish.name.split(' ')[0],
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
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      ref.read(fishCompatibilityProvider.notifier).cancel();
                    },
                    child: const Text('Cancel'),
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

  void _openReport(CompatibilityReport report, {bool fromHistory = false}) {
    _showReportDialog(context, report, fromHistory: fromHistory);
  }

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(fishCompatibilityProvider);
    final notifier = ref.read(fishCompatibilityProvider.notifier);

    ref.listen<FishCompatibilityState>(fishCompatibilityProvider,
        (previous, next) {
      if (next.isLoading && !(previous?.isLoading ?? false)) {
        _showLoadingOverlay(context, next.selectedFish, _selectedCategory);
      } else if (!next.isLoading && (previous?.isLoading ?? false)) {
        _hideLoadingOverlay();
      }

      if (next.report != null && previous?.report != next.report) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _openReport(next.report!);
          }
        });
      }

      if (next.error != null && previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                duration: const Duration(seconds: 6),
                action: next.isRetryable
                    ? SnackBarAction(
                        label: 'Retry',
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          notifier.retryCompatibilityReport();
                        },
                      )
                    : SnackBarAction(
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

    final hasLastReport = providerState.lastReport != null;
    final canShowLastReportFab =
        hasLastReport && (providerState.report == null);

    final double bottomBarHeight =
        providerState.selectedFish.isNotEmpty ? 84.0 : 0.0;

    return MainLayout(
      title: 'AI Compatibility Calculator',
      bottomNavigationBar: const AdBanner(),
      child: Stack(
        children: [
          providerState.fishData.when(
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
              final fishList = fishData[_selectedCategory] ?? [];
              if (fishList.isEmpty) {
                return const Center(
                    child: Text('No fish found for this category.'));
              }
              // Use a CustomScrollView to make the header scrollable
              return CustomScrollView(
                slivers: [
                  // Header Sliver
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4),
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
                          const SizedBox(height: 6),
                          Text(
                            'Select two or more fish to generate a compatibility report.',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Category Selector Sliver
                  SliverToBoxAdapter(
                    child: _buildCategorySelector(notifier),
                  ),
                  // Grid of Fish Cards Sliver
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 210,
                        childAspectRatio: 3 / 4,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final fish = fishList[index];
                          final isSelected =
                              providerState.selectedFish.contains(fish);
                          return _buildFishCard(fish, isSelected, notifier);
                        },
                        childCount: fishList.length,
                      ),
                    ),
                  ),
                  // Disclaimer Sliver
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24,
                          bottomBarHeight + 16), // Padding to avoid bottom bar
                      child: Text(
                        'This AI-powered tool helps you check the compatibility of freshwater and marine aquarium inhabitants. Select the fish you\'re interested in, and click "Get Report" to receive a detailed analysis, including recommended tank size, decorations, care guides, and potential conflict risks.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Position the FAB above the bottom bar
          if (canShowLastReportFab)
            Positioned(
              bottom: bottomBarHeight + 24, // Adjust this value for spacing
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'last_report_fab',
                icon: const Icon(Icons.history),
                label: const Text('Last Report'),
                onPressed: () {
                  final last = providerState.lastReport;
                  if (last != null) {
                    _openReport(last, fromHistory: true);
                  }
                },
              ),
            ),
          // The Bottom Bar is now at the bottom of the Stack
          if (providerState.selectedFish.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(providerState, notifier),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(FishCompatibilityNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          ModernSelectableChip(
            label: 'Freshwater',
            emoji: '🐟',
            selected: _selectedCategory == 'freshwater',
            onTap: () {
              setState(() => _selectedCategory = 'freshwater');
              notifier.clearSelection();
            },
          ),
          ModernSelectableChip(
            label: 'Saltwater',
            emoji: '🐠',
            selected: _selectedCategory == 'marine',
            onTap: () {
              setState(() => _selectedCategory = 'marine');
              notifier.clearSelection();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFishCard(
      Fish fish, bool isSelected, FishCompatibilityNotifier notifier) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? cs.primary : cs.outlineVariant.withOpacity(0.25),
          width: isSelected ? 3 : 1.2,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: cs.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.18),
                  cs.secondary.withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Theme.of(context).cardColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => notifier.selectFish(fish),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    fish.imageURL,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.error)),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Text(
                  fish.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      FishCompatibilityState provider, FishCompatibilityNotifier notifier) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 16), // Symmetrical padding
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.05),
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withOpacity(0.05),
                width: 1.2,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => notifier.clearSelection(),
                tooltip: 'Clear Selection',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.selectedFish.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final fish = provider.selectedFish[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.network(
                          fish.imageURL,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 52,
                            height: 52,
                            color: cs.error.withOpacity(0.1),
                            child:
                                Icon(Icons.error, color: cs.error, size: 20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => notifier.getCompatibilityReport(_selectedCategory),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: const Text('Get Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, CompatibilityReport report,
      {bool fromHistory = false}) {
    final notifier = ref.read(fishCompatibilityProvider.notifier);

    // Reordered sections as requested
    final sections = {
      'Selected Fish': _buildSelectedFishSection(context, report.selectedFish),
      'Compatible Tank Mates': _buildTankMatesSection(context, report),
      'Detailed Summary':
          SelectableText(report.detailedSummary, textAlign: TextAlign.center),
      'Recommended Tank Size':
          SelectableText(report.tankSize, textAlign: TextAlign.center),
      'Decorations and Setup':
          SelectableText(report.decorations, textAlign: TextAlign.center),
      'Care Guide':
          SelectableText(report.careGuide, textAlign: TextAlign.center),
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
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (!fromHistory) {
                    notifier.clearSelection();
                  }
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
                  // Injecting the ad after the Detailed Summary
                  if (entry.key == 'Detailed Summary') {
                    return Column(
                      children: [
                        _buildSection(
                          context,
                          entry.key,
                          entry.value,
                          index,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: NativeAdWidget(),
                        ),
                      ],
                    );
                  }
                  return _buildSection(
                    context,
                    entry.key,
                    entry.value,
                    index,
                  );
                }),
                const SizedBox(height: 12),
                Text(
                  'Disclaimer: AI may occasionally provide inaccurate recommendations. Always cross-check critical information.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                  textAlign: TextAlign.center,
                ),
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
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Group Harmony',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              report.harmonyLabel,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: harmonyColor, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SelectableText(
              '${(report.groupHarmonyScore * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: harmonyColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              report.harmonySummary,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, Widget content, int index) {
    final isEven = index % 2 == 0;
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: isEven ? null : cs.surfaceContainerHighest.withOpacity(0.28),
      margin: const EdgeInsets.only(bottom: 14.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
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
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHigh
                    .withOpacity(0.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(fish.imageURL),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fish.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          fish.commonNames.join(', '),
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        const SizedBox(height: 10),
        Text(
          "(Click a fish to search)",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          children: report.compatibleFish.map((fishName) {
            return ModernSelectableChip(
              label: fishName,
              selected: false,
              dense: true,
              onTap: () async {
                final url = Uri.parse(
                    'https://www.google.com/search?q=${Uri.encodeComponent(fishName)}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getHarmonyColor(double score) {
    if (score >= 0.75) return Colors.green;
    if (score >= 0.5) return Colors.yellow.shade700;
    if (score >= 0.25) return Colors.orange;
    return Colors.red;
  }
}