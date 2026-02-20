import 'dart:math';
import 'package:fish_ai/widgets/ad_component.dart';
import 'package:fish_ai/widgets/accessible_feedback.dart';
import 'package:fish_ai/widgets/modern_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../models/stocking_recommendation.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../providers/aquarium_stocking_provider.dart';
import '../services/analytics_service.dart';
import '../utils/share_utils.dart';
import '../widgets/common_buttons.dart';
import '../widgets/helper_text.dart';

class StockingReportScreen extends ConsumerStatefulWidget {
  final List<StockingRecommendation> reports;
  
  // For regeneration support
  final String? tankSize; // For general stocking regeneration
  final String? tankType; // For general stocking regeneration  
  final String? userNotes; // For general stocking regeneration

  const StockingReportScreen({
    super.key, 
    required this.reports,
    this.tankSize,
    this.tankType,
    this.userNotes,
  });

  @override
  ConsumerState<StockingReportScreen> createState() => _StockingReportScreenState();
}

class _StockingReportScreenState extends ConsumerState<StockingReportScreen>
    // SingleTickerProviderStateMixin is required so we can create an explicit
    // TabController, which lets us read _tabController.index at share-time to
    // know which tab's report the user is currently viewing.
    with SingleTickerProviderStateMixin {
  bool _isRegenerating = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.reports.length,
      vsync: this,
    );
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
        'regeneration_type': 'general',
        'has_notes': widget.userNotes?.isNotEmpty == true ? 'true' : 'false',
      },
    );
    
    setState(() {
      _isRegenerating = true;
    });

    if (widget.tankSize != null && widget.tankType != null) {
      // General stocking regeneration  
      ref.read(aquariumStockingProvider.notifier).getStockingRecommendations(
        tankSize: widget.tankSize!,
        tankType: widget.tankType!,
        userNotes: widget.userNotes ?? '',
      );
    } else {
      // Show error if we don't have enough data to regenerate
      setState(() {
        _isRegenerating = false;
      });
      context.showAccessibleMessage('Cannot regenerate - missing original parameters.');
    }
  }

  String get _getDisplayTitle {
    return 'Stocking Ideas';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Listen for new recommendations and replace current screen
    ref.listen<AquariumStockingState>(aquariumStockingProvider, (previous, next) {
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
            builder: (context) => StockingReportScreen(
              reports: next.recommendations!,
              tankSize: widget.tankSize,
              tankType: widget.tankType,
              userNotes: widget.userNotes,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      // Page title with close button
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getDisplayTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
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
                          final harmony = (widget.reports[index].harmonyScore * 100).toInt();
                          return Tab(text: 'Option ${index + 1} ($harmony%)');
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: widget.reports.map((report) {
                      return _RecommendationTabView(
                        report: report,
                        tankType: widget.tankType,
                        tankSize: widget.tankSize,
                        userNotes: widget.userNotes,
                      );
                    }).toList(),
                  ),
                ),
                // Bottom buttons with extra padding
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      ActionButtonRow(
                        onRegenerate: _regenerateRecommendations,
                        isRegenerating: _isRegenerating,
                        onShare: _shareCurrentReport,
                      ),
                      const SizedBox(height: 8), // Extra padding below buttons
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

class _RecommendationTabView extends StatelessWidget {
  final StockingRecommendation report;
  final String? tankType;
  final String? tankSize;
  final String? userNotes;

  const _RecommendationTabView({
    required this.report,
    this.tankType,
    this.tankSize,
    this.userNotes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const BannerAdWidget(),
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
        
        // Show tank info if available
        if (tankSize != null || userNotes != null) ...[
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
                      'Tank Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                if (tankSize != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Tank Size: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        tankSize!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                if (userNotes != null && userNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_outlined, size: 14, color: cs.onSurfaceVariant),
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
                          userNotes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        
        const Divider(height: 32),
        
        _SectionHeader(title: 'Stocking Options'),
        const SizedBox(height: 8),
        Text(
          'The "Core Fish" are a highly compatible group. The "Other Options" are additional fish from our database that you can add while maintaining high harmony.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _FishCardGrid(fishList: report.coreFish, isCore: true, tankType: tankType),

        if (report.otherDataBasedFish.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(l10n.otherOptions, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _FishCardGrid(fishList: report.otherDataBasedFish, tankType: tankType),
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
        const InstructionText(
          text: "(Click a fish to search)",
        ),
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
                _calculateCompatibilityBreakdown(report.coreFish),
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
            "${fishA.name} & ${fishB.name}: ${(prob * 100).toStringAsFixed(1)}%");
      }
    }

    buffer.writeln("\nGroup Harmony Score:");
    final geometricMean = _geometricMean(probabilities);
    final probStrings = probabilities.map((p) => "${(p * 100).toStringAsFixed(1)}%").join(', ');
    buffer.writeln("geometricMean([$probStrings]) = ${(geometricMean * 100).toStringAsFixed(1)}%");

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

  Future<void> _launchSearch(String query) async {
    // Log external search usage
    AnalyticsService.logFeatureUsed(
      featureName: 'external_search',
      parameters: {
        'query': query,
        'source': 'stocking_report',
      },
    );
    AnalyticsService.logUserEngagement(
      engagementType: 'external_link_click',
      content: query,
    );
    
    // Add tank type to search query if available
    final searchQuery = tankType != null ? '$query $tankType' : query;
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
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
    final String? tankType;
    const _FishCardGrid({
      required this.fishList, 
      this.isCore = false,
      this.tankType,
    });

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        return Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            // --- BUG FIX STARTS HERE ---
            // The .map function now handles the possibility of a null fish in the list.
            children: fishList.map((fish) {
                return Card(
                    elevation: 2,
                    color: cs.surfaceContainerHighest,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isCore 
                          ? BorderSide(color: cs.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                        onTap: () => _launchSearch(fish.name),
                        child: SizedBox(
                            width: 100,
                            child: Column(
                                children: [
                                    CachedNetworkImage(
                                        imageUrl: fish.imageURL,
                                        height: 80,
                                        width: 100,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Container(
                                          height: 80,
                                          width: 100,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error_outline),
                                        ),
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                            fish.name,
                                            style: theme.textTheme.bodySmall,
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
            }).toList(),
            // --- BUG FIX ENDS HERE ---
        );
    }
    
    Future<void> _launchSearch(String query) async {
        // Add tank type to search query if available
        final searchQuery = tankType != null ? '$query $tankType' : query;
        final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}');
        if (!await launchUrl(url)) {
            debugPrint('Could not launch $url');
        }
    }
}
