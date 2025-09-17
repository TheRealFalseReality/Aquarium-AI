import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/compatibility_report.dart';
import '../models/fish.dart';
import '../providers/fish_compatibility_provider.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';

void showReportDialog(BuildContext context, CompatibilityReport report,
    {bool fromHistory = false}) {
  final sections = {
    'Selected Fish': _buildSelectedFishSection(context, report.selectedFish),
    'Compatible Tank Mates': _buildTankMatesSection(context, report),
    'Detailed Summary':
        SelectableText(report.detailedSummary, textAlign: TextAlign.center),
    'Recommended Tank Size':
        SelectableText(report.tankSize, textAlign: TextAlign.center),
    'Decorations and Setup':
        SelectableText(report.decorations, textAlign: TextAlign.center),
    'Care Guide': SelectableText(report.careGuide, textAlign: TextAlign.center),
  };

  showDialog(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, child) {
        final notifier = ref.read(fishCompatibilityProvider.notifier);
        return AlertDialog(
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
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 0.0),
                            child: NativeAdWidget(),
                          ),
                          _buildSection(
                            context,
                            entry.key,
                            entry.value,
                            index,
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
                  // ADDED: New expandable section for the calculation breakdown.
                  _buildCalculationBreakdown(context, report),
                  const BannerAdWidget(),
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
        );
      },
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

// ADDED: New function to build the expandable calculation breakdown section.
Widget _buildCalculationBreakdown(
    BuildContext context, CompatibilityReport report) {
  final cs = Theme.of(context).colorScheme;
  return Card(
    margin: const EdgeInsets.only(bottom: 14.0),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: cs.outlineVariant.withOpacity(0.4),
        width: 0.8,
      ),
    ),
    child: ExpansionTile(
      title: Text(
        'Calculation Breakdown',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        textAlign: TextAlign.center,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: SelectableText(
            report.calculationBreakdown,
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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