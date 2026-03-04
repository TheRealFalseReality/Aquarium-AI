import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fish_ai/widgets/accessible_feedback.dart';
import 'package:fish_ai/widgets/ad_component.dart';
import 'package:fish_ai/widgets/modern_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../models/stocking_recommendation.dart';
import '../models/tank.dart';
import '../providers/aquarium_stocking_provider.dart';
import '../services/analytics_service.dart';
import '../utils/share_utils.dart';
import '../widgets/helper_text.dart';

class TankStockingReportScreen extends ConsumerStatefulWidget {
  final List<StockingRecommendation> reports;
  final Tank originalTank;
  final List<Fish> existingFish;
  final String additionalNotes;

  const TankStockingReportScreen({
    super.key,
    required this.reports,
    required this.originalTank,
    required this.existingFish,
    this.additionalNotes = '',
  });

  @override
  ConsumerState<TankStockingReportScreen> createState() =>
      _TankStockingReportScreenState();
}

class _TankStockingReportScreenState
    extends
        ConsumerState<
          TankStockingReportScreen
        > // SingleTickerProviderStateMixin is required so we can create an explicit
        // TabController, which lets us read _tabController.index at share-time to
        // know which tab's report the user is currently viewing.
        with
        SingleTickerProviderStateMixin {
  bool _isRegenerating = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'tank_stocking_report_screen');
    _tabController = TabController(length: widget.reports.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _shareCurrentReport() {
    final report = widget.reports[_tabController.index];
    shareStockingReport(report);
  }

  void _regenerateRecommendations() {
    if (_isRegenerating) return; // Prevent multiple calls

    // Log regeneration analytics
    AnalyticsService.logFeatureUsed(
      featureName: 'stocking_report_regenerate',
      parameters: {
        'regeneration_type': 'tank_based',
        'has_existing_fish': 'true',
        'tank_name': widget.originalTank.name,
      },
    );

    setState(() {
      _isRegenerating = true;
    });

    // Tank-based regeneration
    ref
        .read(aquariumStockingProvider.notifier)
        .getTankStockingRecommendations(tank: widget.originalTank);
  }

  String get _getDisplayTitle {
    final tankName = widget.originalTank.name;
    if (tankName.isNotEmpty) {
      return 'Stocking Ideas for "$tankName"';
    }
    return 'Tank Stocking Ideas';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Listen for new recommendations and replace current screen
    ref.listen<AquariumStockingState>(aquariumStockingProvider, (
      previous,
      next,
    ) {
      if (next.recommendations != null &&
          next.recommendations!.isNotEmpty &&
          next.recommendations != widget.reports) {
        // Stop regenerating state
        setState(() {
          _isRegenerating = false;
        });

        // Replace current screen with new recommendations
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TankStockingReportScreen(
              reports: next.recommendations!,
              originalTank: widget.originalTank,
              existingFish: widget.existingFish,
              additionalNotes: widget.additionalNotes,
            ),
          ),
        );
      }

      if (next.error != null) {
        setState(() {
          _isRegenerating = false;
        });
        context.showAccessibleMessage(
          'Error: ${next.error}',
          onAction: next.error!.toLowerCase().contains('api key not set')
              ? () => Navigator.pushNamed(context, '/settings')
              : null,
          actionLabel: next.error!.toLowerCase().contains('api key not set')
              ? 'Settings'
              : null,
        );
      }
    });

    return Stack(
      children: [
        MainLayout(
          title: _getDisplayTitle,
          child: Column(
            children: [
              // Merged header with title, tabs, and close button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    // Page title with close button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getDisplayTitle,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Close button - stays at top right
                        SizedBox(
                          width: 50,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Close Report',
                          ),
                        ),
                      ],
                    ),
                    // Tab bar centered
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      tabs: List.generate(widget.reports.length, (index) {
                        final harmony =
                            (widget.reports[index].harmonyScore * 100).toInt();
                        return Tab(text: 'Option ${index + 1} ($harmony%)');
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    return TabBarView(
                      controller: _tabController,
                      children: widget.reports.asMap().entries.map((entry) {
                        return _TankRecommendationTabView(
                          key: ValueKey(
                            'tab_${entry.key}_${widget.additionalNotes}',
                          ),
                          report: entry.value,
                          originalTank: widget.originalTank,
                          existingFish: widget.existingFish,
                          additionalNotes: widget.additionalNotes,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              // Bottom buttons with extra padding
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Regenerate: compact icon button
                    OutlinedButton(
                      onPressed: _isRegenerating
                          ? null
                          : _regenerateRecommendations,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        minimumSize: Size.zero,
                      ),
                      child: _isRegenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 12),
                    // Share: main action button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareCurrentReport,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Close: compact icon button
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        minimumSize: Size.zero,
                      ),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Loading overlay
        if (_isRegenerating)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l10n.generatingNewRecommendations),
                      const SizedBox(height: 8),
                      const Text(
                        'This may take up to 60 seconds',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TankRecommendationTabView extends StatelessWidget {
  final StockingRecommendation report;
  final Tank originalTank;
  final List<Fish> existingFish;
  final String additionalNotes;

  const _TankRecommendationTabView({
    super.key,
    required this.report,
    required this.originalTank,
    required this.existingFish,
    this.additionalNotes = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const SizedBox(height: 16),
        Text(
          report.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          report.summary,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),

        // Show additional notes if provided
        if (additionalNotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.tertiary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.note_alt_outlined, size: 16, color: cs.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Your Preferences',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  additionalNotes,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Show existing tank info
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Adding to Existing Tank',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tank name confirmation
              Row(
                children: [
                  Icon(Icons.water, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Tank: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    originalTank.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Show tank size if available
              if (originalTank.sizeGallons != null ||
                  originalTank.sizeLiters != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Size: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _formatTankSize(originalTank),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              // Show tank notes if available
              if (originalTank.notes != null &&
                  originalTank.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Notes: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        originalTank.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'These recommendations are designed to work with your current fish community. All suggested additions have been verified for compatibility.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 32),

        // Show existing fish
        _SectionHeader(title: 'Current Tank Inhabitants'),
        const SizedBox(height: 8),
        Text(
          'These are the fish currently in your tank. All recommendations will be compatible with these inhabitants.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _FishCardGrid(
          fishList: existingFish,
          originalTank: originalTank,
          isExisting: true,
        ),

        const Divider(height: 32),

        _SectionHeader(title: 'Fish to Add'),
        const SizedBox(height: 8),
        Text(
          'The "Recommended Additions" are compatible with your existing tank inhabitants. The "Other Options" provide more choices while maintaining harmony.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _FishCardGrid(
          fishList: report.coreFish,
          originalTank: originalTank,
          isCore: true,
          isAddition: true,
        ),

        if (report.otherDataBasedFish.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(l10n.otherOptions, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _FishCardGrid(
            fishList: report.otherDataBasedFish,
            originalTank: originalTank,
            isAddition: true,
          ),
        ],

        // Show compatibility notes
        if (report.compatibilityNotes != null) ...[
          const Divider(height: 32),
          _SectionHeader(title: 'Compatibility Notes'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withOpacity(0.2)),
            ),
            child: Text(
              report.compatibilityNotes!,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),
        ],

        const Divider(height: 16),
        const NativeAdWidget(),
        const Divider(height: 8),
        _SectionHeader(title: 'Recommended Tank Mates'),
        const SizedBox(height: 12),
        Text(
          report.aiTankMatesSummary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        const InstructionText(text: "(Click a fish to search)"),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: report.aiRecommendedTankMates.map((mate) {
            return ModernSelectableChip(
              label: mate,
              onTap: () => _launchSearch(mate),
              selected: false,
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        const BannerAdWidget(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.error.withOpacity(0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI can make mistakes. Please verify the information provided in this report before making any stocking decisions.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Calculation Breakdown
        const Divider(height: 32),
        ExpansionTile(
          title: Row(
            children: [
              Icon(Icons.calculate, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Calculation Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _generateCalculationBreakdown(existingFish, report),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchSearch(String query) async {
    // Log external search usage
    AnalyticsService.logFeatureUsed(
      featureName: 'external_search',
      parameters: {'query': query, 'source': 'tank_stocking_report'},
    );
    AnalyticsService.logUserEngagement(
      engagementType: 'external_link_click',
      content: query,
    );

    // Add tank type to search query
    final searchQuery = '$query ${originalTank.type}';
    final url = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}',
    );
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  String _formatTankSize(Tank tank) {
    if (tank.sizeGallons != null && tank.sizeLiters != null) {
      return '${tank.sizeGallons!.toStringAsFixed(0)} gallons (${tank.sizeLiters!.toStringAsFixed(0)} liters)';
    } else if (tank.sizeGallons != null) {
      return '${tank.sizeGallons!.toStringAsFixed(0)} gallons';
    } else if (tank.sizeLiters != null) {
      return '${tank.sizeLiters!.toStringAsFixed(0)} liters';
    }
    return 'Size not specified';
  }

  String _generateCalculationBreakdown(
    List<Fish> existingFish,
    StockingRecommendation report,
  ) {
    // Combine existing fish with the recommended core fish to show full tank compatibility
    final allTankFish = [...existingFish, ...report.coreFish];

    final buffer = StringBuffer();
    buffer.writeln("Current Tank Analysis:");
    buffer.writeln(
      "Existing Fish: ${existingFish.map((f) => f.name).join(', ')}",
    );
    buffer.writeln(
      "Recommended Additions: ${report.coreFish.map((f) => f.name).join(', ')}",
    );
    buffer.writeln();

    return buffer.toString() + _calculateCompatibilityBreakdown(allTankFish);
  }

  double _geometricMean(List<double> values) {
    if (values.isEmpty) return 1.0;
    // If any value is 0, the geometric mean is 0.
    if (values.any((v) => v <= 0.0)) return 0.0;
    final logSum = values.fold<double>(0.0, (sum, v) => sum + log(v));
    return exp(logSum / values.length);
  }

  String _calculateCompatibilityBreakdown(List<Fish> fishList) {
    if (fishList.length < 2) {
      return "Select at least two fish to see a compatibility breakdown.";
    }

    final buffer = StringBuffer();
    buffer.writeln("Pairwise Compatibility:");

    final probabilities = <double>[];
    for (int i = 0; i < fishList.length; i++) {
      for (int j = i + 1; j < fishList.length; j++) {
        final fishA = fishList[i];
        final fishB = fishList[j];
        final prob = _getPairwiseProbability(fishA, fishB);
        probabilities.add(prob);

        buffer.writeln(
          "${fishA.name} & ${fishB.name}: ${(prob * 100).toStringAsFixed(1)}%",
        );
      }
    }

    buffer.writeln("\nGroup Harmony Score:");
    final geometricMean = _geometricMean(probabilities);
    final probStrings = probabilities
        .map((p) => "${(p * 100).toStringAsFixed(1)}%")
        .join(', ');
    buffer.writeln(
      "geometricMean([$probStrings]) = ${(geometricMean * 100).toStringAsFixed(1)}%",
    );

    return buffer.toString();
  }

  double _getPairwiseProbability(Fish fishA, Fish fishB) {
    if (fishA.compatible.contains(fishB.name) &&
        fishB.compatible.contains(fishA.name)) {
      return 1.0;
    }
    if (fishA.notCompatible.contains(fishB.name) ||
        fishB.notCompatible.contains(fishA.name)) {
      return 0.0;
    }
    if (fishA.notRecommended.contains(fishB.name) ||
        fishB.notRecommended.contains(fishA.name)) {
      return 0.25;
    }
    if (fishA.withCaution.contains(fishB.name) ||
        fishB.withCaution.contains(fishA.name)) {
      return 0.75;
    }
    return 0.5;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _FishCardGrid extends StatelessWidget {
  final List<Fish> fishList;
  final bool isCore;
  final bool isAddition;
  final bool isExisting;
  final Tank originalTank;

  const _FishCardGrid({
    required this.fishList,
    required this.originalTank,
    this.isCore = false,
    this.isAddition = false,
    this.isExisting = false,
  });

  // Group inhabitants by unique combination of fishUnit + customName + image
  List<Map<String, dynamic>> _getGroupedInhabitants() {
    if (!isExisting) {
      // For non-existing fish, just show them normally
      return fishList
          .map(
            (fish) => {
              'fish': fish,
              'quantity': 1,
              'customName': null,
              'customImage': null,
            },
          )
          .toList();
    }

    final Map<String, Map<String, dynamic>> grouped = {};

    for (final inhabitant in originalTank.inhabitants) {
      // Create a unique key based on fishUnit, customName, and custom image
      final customImage =
          inhabitant.customImageUrl ?? inhabitant.customImagePath;
      // Always show custom name if it differs from the fish unit name
      final displayName = inhabitant.customName != inhabitant.fishUnit
          ? inhabitant.customName
          : null;

      final key = '${inhabitant.fishUnit}|$displayName|$customImage';

      if (grouped.containsKey(key)) {
        grouped[key]!['quantity'] =
            (grouped[key]!['quantity'] as int) + inhabitant.quantity;
      } else {
        // Find the fish data, preferring UUID lookup for renamed-fish resilience.
        final fish = (inhabitant.fishUuid != null
                ? fishList.where((f) => f.uuid == inhabitant.fishUuid).firstOrNull
                : null) ??
            fishList.firstWhere(
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

        grouped[key] = {
          'fish': fish,
          'quantity': inhabitant.quantity,
          'customName': displayName,
          'customImage': customImage,
        };
      }
    }

    return grouped.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final items = _getGroupedInhabitants();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        final fish = item['fish'] as Fish;
        final quantity = item['quantity'] as int;
        final customName = item['customName'] as String?;
        final customImage = item['customImage'] as String?;
        final imageUrl = customImage ?? fish.imageURL;

        return Card(
          elevation: 2,
          color: cs.surfaceContainerHighest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isExisting
                ? BorderSide(color: cs.secondary, width: 2)
                : isCore
                ? BorderSide(color: cs.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => _launchSearch(fish.name),
            child: SizedBox(
              width: 100,
              child: Column(
                children: [
                  Stack(
                    children: [
                      imageUrl.isNotEmpty
                          ? (customImage != null && customImage.startsWith('/'))
                                ? Image.file(
                                    File(customImage),
                                    height: 80,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return CachedNetworkImage(
                                        imageUrl: fish.imageURL,
                                        height: 80,
                                        width: 100,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              height: 80,
                                              width: 100,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.error_outline,
                                              ),
                                            ),
                                      );
                                    },
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: 80,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) {
                                      return Container(
                                        height: 80,
                                        width: 100,
                                        color: cs.surfaceVariant,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      );
                                    },
                                  )
                          : Container(
                              height: 80,
                              width: 100,
                              color: cs.surfaceVariant,
                              child: Icon(
                                Icons.pets,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                      // Quantity badge
                      if (quantity > 1)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'x$quantity',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: cs.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          fish.name,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customName != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              customName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: cs.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  Future<void> _launchSearch(String query) async {
    // Add tank type to search query
    final searchQuery = '$query ${originalTank.type}';
    final url = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}',
    );
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }
}
