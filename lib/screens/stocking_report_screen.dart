import 'package:fish_ai/widgets/ad_component.dart';
import 'package:fish_ai/widgets/modern_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stocking_recommendation.dart';
import '../models/tank.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../providers/aquarium_stocking_provider.dart';

class StockingReportScreen extends ConsumerStatefulWidget {
  final List<StockingRecommendation> reports;
  final String? existingTankName; // Optional tank name for tank-based recommendations
  final List<Fish>? existingFish; // Optional existing fish for tank-based recommendations
  
  // For regeneration support
  final Tank? originalTank; // For tank-based regeneration
  final String? tankSize; // For general stocking regeneration
  final String? tankType; // For general stocking regeneration  
  final String? userNotes; // For general stocking regeneration

  const StockingReportScreen({
    super.key, 
    required this.reports,
    this.existingTankName,
    this.existingFish,
    this.originalTank,
    this.tankSize,
    this.tankType,
    this.userNotes,
  });

  @override
  ConsumerState<StockingReportScreen> createState() => _StockingReportScreenState();
}

class _StockingReportScreenState extends ConsumerState<StockingReportScreen> {
  bool _isRegenerating = false;

  void _regenerateRecommendations() {
    if (_isRegenerating) return; // Prevent multiple calls
    
    setState(() {
      _isRegenerating = true;
    });

    if (widget.originalTank != null) {
      // Tank-based regeneration
      ref.read(aquariumStockingProvider.notifier).getTankStockingRecommendations(tank: widget.originalTank!);
    } else if (widget.tankSize != null && widget.tankType != null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot regenerate - missing original parameters.'),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  String get _getDisplayTitle {
    // Check if it's a tank-based recommendation
    if (widget.reports.isNotEmpty && widget.reports.first.isAdditionRecommendation) {
      // Use original tank name if available, otherwise existing tank name
      final tankName = widget.originalTank?.name ?? widget.existingTankName ?? 'Unknown Tank';
      return 'Stocking Ideas for "$tankName"';
    }
    return 'Recommendations';
  }

  @override
  Widget build(BuildContext context) {
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
              existingTankName: widget.existingTankName,
              existingFish: widget.existingFish,
              originalTank: widget.originalTank,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    });

    return Stack(
      children: [
        DefaultTabController(
          length: widget.reports.length,
          child: MainLayout(
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
                    children: widget.reports.map((report) {
                      return _RecommendationTabView(
                        report: report,
                        isForExistingTank: report.isAdditionRecommendation,
                        existingFish: widget.existingFish,
                        existingTankName: widget.originalTank?.name ?? widget.existingTankName,
                      );
                    }).toList(),
                  ),
                ),
                // Bottom buttons
                Container(
                  padding: const EdgeInsets.all(16),
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
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isRegenerating ? null : _regenerateRecommendations,
                          icon: _isRegenerating 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                          label: Text(_isRegenerating ? 'Regenerating...' : 'Regenerate'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Loading overlay
        if (_isRegenerating)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating new recommendations...'),
                      SizedBox(height: 8),
                      Text(
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
  final bool isForExistingTank;
  final List<Fish>? existingFish;
  final String? existingTankName;

  const _RecommendationTabView({
    required this.report,
    this.isForExistingTank = false,
    this.existingFish,
    this.existingTankName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
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
        
        // Show existing tank info for tank-based recommendations
        if (isForExistingTank) ...[
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
                if (isForExistingTank && existingTankName != null) ...[
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
                        existingTankName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                // Existing fish confirmation list
                if (isForExistingTank && existingFish != null && existingFish!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.pets, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Current Fish: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          existingFish!.map((fish) => fish.name).join(', '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'These recommendations are designed to work with your current fish community. All suggested additions have been verified for compatibility.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const Divider(height: 32),
        
        // Show existing fish for tank-based recommendations
        if (isForExistingTank && existingFish != null && existingFish!.isNotEmpty) ...[
          _SectionHeader(title: 'Current Tank Inhabitants'),
          const SizedBox(height: 8),
          Text(
            'These are the fish currently in your tank. All recommendations will be compatible with these inhabitants.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _FishCardGrid(fishList: existingFish!, isExisting: true),
          const Divider(height: 32),
        ],
        
        _SectionHeader(title: isForExistingTank ? 'Fish to Add' : 'Stocking Options'),
        const SizedBox(height: 8),
        Text(
            isForExistingTank
                ? 'The "Recommended Additions" are compatible with your existing tank inhabitants. The "Other Options" provide more choices while maintaining harmony.'
                : 'The "Core Fish" are a highly compatible group. The "Other Options" are additional fish from our database that you can add while maintaining high harmony.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        _FishCardGrid(fishList: report.coreFish, isCore: true, isAddition: isForExistingTank),

        if (report.otherDataBasedFish.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Other Options', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _FishCardGrid(fishList: report.otherDataBasedFish, isAddition: isForExistingTank),
        ],

        // Show compatibility notes for tank-based recommendations
        if (isForExistingTank && report.compatibilityNotes != null) ...[
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
              ),
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
        Text(
          "(Click a fish to search)",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
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
        
        // Calculation Breakdown for tank-based recommendations
        if (isForExistingTank && existingFish != null && existingFish!.isNotEmpty) ...[
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
                  _generateCalculationBreakdown(existingFish!, report),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _launchSearch(String query) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }
  
  String _generateCalculationBreakdown(List<Fish> existingFish, StockingRecommendation report) {
    // Combine existing fish with the recommended core fish to show full tank compatibility
    final allTankFish = [...existingFish, ...report.coreFish];
    
    final buffer = StringBuffer();
    buffer.writeln("Current Tank Analysis:");
    buffer.writeln("Existing Fish: ${existingFish.map((f) => f.name).join(', ')}");
    buffer.writeln("Recommended Additions: ${report.coreFish.map((f) => f.name).join(', ')}");
    buffer.writeln();
    
    // Import the harmony calculator method here
    return buffer.toString() + _calculateCompatibilityBreakdown(allTankFish);
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
    final minScore = probabilities.reduce((a, b) => a < b ? a : b);
    final probStrings = probabilities.map((p) => "${(p * 100).toStringAsFixed(1)}%").join(', ');
    buffer.writeln("min($probStrings) = ${(minScore * 100).toStringAsFixed(1)}%");

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
    const _FishCardGrid({
      required this.fishList, 
      this.isCore = false,
      this.isAddition = false,
      this.isExisting = false,
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
                // If fish is null for any reason, return an empty container.
                // Otherwise, build the card as normal. `fish` is now guaranteed to be non-null.
                return Card(
                    elevation: 2,
                    color: cs.surfaceContainerHighest,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isExisting
                          ? BorderSide(color: cs.secondary, width: 2)  // Different color for existing fish
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
                                    Image.network(
                                        fish.imageURL,
                                        height: 80,
                                        width: 100,
                                        fit: BoxFit.cover,
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
        final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
        if (!await launchUrl(url)) {
            debugPrint('Could not launch $url');
        }
    }
}