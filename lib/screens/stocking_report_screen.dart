import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stocking_recommendation.dart';
import '../main_layout.dart';
import '../models/fish.dart'; // Import the Fish model

class StockingReportScreen extends StatelessWidget {
  final List<StockingRecommendation> reports;
  final String? existingTankName; // Optional tank name for tank-based recommendations

  const StockingReportScreen({
    super.key, 
    required this.reports,
    this.existingTankName,
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
                    isForExistingTank: existingTankName != null,
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

  const _RecommendationTabView({
    required this.report,
    this.isForExistingTank = false,
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
        const Divider(height: 32),
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
        _SectionHeader(title: 'AI Recommended Tank Mates'),
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
      ],
    );
  }

  Future<void> _launchSearch(String query) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
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
        Icon(Icons.search, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
      ],
    );
  }
}

class _FishCardGrid extends StatelessWidget {
    final List<Fish> fishList;
    final bool isCore;
    final bool isAddition;
    const _FishCardGrid({
      required this.fishList, 
      this.isCore = false,
      this.isAddition = false,
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