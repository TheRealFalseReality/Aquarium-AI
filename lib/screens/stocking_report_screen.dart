import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stocking_recommendation.dart';
import '../main_layout.dart';

class StockingReportScreen extends StatelessWidget {
  final List<StockingRecommendation> reports;

  const StockingReportScreen({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: reports.length,
      child: MainLayout(
        title: 'Stocking Recommendations',
        child: Column(
          children: [
            // Header with a centered TabBar and a close button
            Container(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  // Spacer to help with centering
                  const SizedBox(width: 50),
                  // Centered TabBar
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
                  // Close button aligned to the right
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
            // The content of the tabs
            Expanded(
              child: TabBarView(
                children: reports.map((report) {
                  return _RecommendationTabView(report: report);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable widget for displaying a single report's content
class _RecommendationTabView extends StatelessWidget {
  final StockingRecommendation report;

  const _RecommendationTabView({required this.report});

  Future<void> _launchSearch(String query) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Header
        Text(
          report.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary, // Added color
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          report.summary,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant, // Softer text color
          ),
        ),
        const Divider(height: 32),
        // Recommended Fish
        Text('Recommended Fish', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: report.fish.map((fish) {
            return InkWell(
              onTap: () => _launchSearch(fish.name),
              borderRadius: BorderRadius.circular(12),
              child: Card(
                elevation: 2,
                color: cs.surfaceContainerHighest, // Added color
                clipBehavior: Clip.antiAlias,
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
        ),
        const Divider(height: 32),
        // Tank Mates
        Text('Compatible Tank Mates', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          report.tankMatesSummary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: report.tankMates.map((mate) {
            return ActionChip(
              label: Text(mate),
              onPressed: () => _launchSearch(mate),
              backgroundColor: cs.secondaryContainer.withOpacity(0.4), // Added color
            );
          }).toList(),
        ),
      ],
    );
  }
}