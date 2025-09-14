import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stocking_recommendation.dart';
import '../main_layout.dart'; // We will use MainLayout again

class StockingReportScreen extends StatelessWidget {
  final StockingRecommendation report;

  const StockingReportScreen({super.key, required this.report});

  Future<void> _launchSearch(String query) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final harmonyPercent = (report.harmonyScore * 100).toInt();
    final cs = Theme.of(context).colorScheme;

    return MainLayout( // Reverted to using MainLayout for a consistent AppBar title
      title: 'Stocking Recommendation',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // --- HEADER WITH TITLE AND CLOSE BUTTON ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expanded to allow title to wrap if it's long
              Expanded(
                child: Text(
                  report.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              // Close Button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close Report',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Chip(
              label: Text('Harmony Score: $harmonyPercent%', style: const TextStyle(fontWeight: FontWeight.bold)),
              avatar: Icon(Icons.shield, color: cs.primary),
              backgroundColor: cs.primaryContainer.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(report.summary, textAlign: TextAlign.center),

          const Divider(height: 32),

          // Recommended Fish
          Text('Recommended Fish', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: report.fish.map((fish) {
              return InkWell(
                onTap: () => _launchSearch(fish.name),
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(fish.imageURL),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fish.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const Divider(height: 32),

          // Tank Mates
          Text('Compatible Tank Mates', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(report.tankMatesSummary),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.tankMates.map((mate) {
              return ActionChip(
                label: Text(mate),
                onPressed: () => _launchSearch(mate),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}