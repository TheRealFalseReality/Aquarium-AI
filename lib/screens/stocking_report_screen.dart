import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stocking_recommendation.dart';
import '../main_layout.dart';
import '../models/fish.dart'; // Import the Fish model

class StockingReportScreen extends StatelessWidget {
  final List<StockingRecommendation> reports;
  final String? existingTankName; // Optional tank name for tank-based recommendations
  final List<Fish>? existingFish; // Optional existing fish for tank-based recommendations

  const StockingReportScreen({
    super.key, 
    required this.reports,
    this.existingTankName,
    this.existingFish,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: reports.length,
      child: MainLayout(
        title: existingTankName != null 
          ? 'Stocking Ideas for "$existingTankName"'
          : 'Stocking Recommendations',
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(width: 50),
                  Expanded(
                    child: Center(
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        tabs: List.generate(reports.length, (index) {
                          final harmony = (reports[index].harmonyScore * 100).toInt();
                          return Tab(text: 'Option ${index + 1} ($harmony%)');
                        }),
                      ),
                    ),
                  ),
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
            ),
            Expanded(
              child: TabBarView(
                children: reports.map((report) {
                  return _RecommendationTabView(
                    report: report,
                    isForExistingTank: report.isAdditionRecommendation,
                    existingFish: existingFish,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationTabView extends StatelessWidget {
  final StockingRecommendation report;
  final bool isForExistingTank;
  final List<Fish>? existingFish;

  const _RecommendationTabView({
    required this.report,
    this.isForExistingTank = false,
    this.existingFish,
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
                if (existingTankName != null) ...[
                  Row(
                    children: [
                      Icon(Icons.aquarium, size: 14, color: cs.onSurfaceVariant),
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
                if (existingFish != null && existingFish!.isNotEmpty) ...[
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

        const Divider(height: 32),
        _SectionHeader(title: 'Recommended Tank Mates'),
        const SizedBox(height: 12),
        Text(
          report.aiTankMatesSummary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: report.aiRecommendedTankMates.map((mate) {
            return ActionChip(
              avatar: const Icon(Icons.search, size: 16),
              label: Text(mate),
              onPressed: () => _launchSearch(mate),
              backgroundColor: cs.secondaryContainer.withOpacity(0.4),
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
        Icon(Icons.search, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
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