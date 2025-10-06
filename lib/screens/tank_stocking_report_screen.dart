import 'package:fish_ai/widgets/ad_component.dart';
import 'package:fish_ai/widgets/accessible_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stocking_recommendation.dart';
import '../models/tank.dart';
import '../main_layout.dart';
import '../models/fish.dart';
import '../providers/aquarium_stocking_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/common_buttons.dart';
import '../widgets/helper_text.dart';

/// Dedicated screen for tank-based stocking recommendations
/// Shows existing tank inhabitants and recommended additions
class TankStockingReportScreen extends ConsumerStatefulWidget {
  final List<StockingRecommendation> reports;
  final Tank tank;
  final List<Fish> existingFish;
  final bool useCustomNames;
  final String additionalNotes;

  const TankStockingReportScreen({
    super.key,
    required this.reports,
    required this.tank,
    required this.existingFish,
    this.useCustomNames = false,
    this.additionalNotes = '',
  });

  @override
  ConsumerState<TankStockingReportScreen> createState() => _TankStockingReportScreenState();
}

class _TankStockingReportScreenState extends ConsumerState<TankStockingReportScreen> {
  bool _isRegenerating = false;

  void _regenerateRecommendations() {
    if (_isRegenerating) return;

    AnalyticsService.logFeatureUsed(
      featureName: 'tank_stocking_report_regenerate',
      parameters: {
        'tank_name': widget.tank.name,
        'existing_fish_count': widget.existingFish.length,
        'use_custom_names': widget.useCustomNames.toString(),
      },
    );

    setState(() {
      _isRegenerating = true;
    });

    ref.read(aquariumStockingProvider.notifier).getTankStockingRecommendations(
      tank: widget.tank,
      useCustomNames: widget.useCustomNames,
      additionalNotes: widget.additionalNotes,
    );
  }

  List<Fish> _getUniqueFish(List<Fish> fishList) {
    final uniqueFishMap = <String, Fish>{};
    for (final fish in fishList) {
      if (!uniqueFishMap.containsKey(fish.name)) {
        uniqueFishMap[fish.name] = fish;
      }
    }
    return uniqueFishMap.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AquariumStockingState>(aquariumStockingProvider, (previous, next) {
      if (next.recommendations != null &&
          next.recommendations!.isNotEmpty &&
          next.recommendations != widget.reports) {
        setState(() {
          _isRegenerating = false;
        });

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TankStockingReportScreen(
              reports: next.recommendations!,
              tank: widget.tank,
              existingFish: widget.existingFish,
              useCustomNames: widget.useCustomNames,
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
        DefaultTabController(
          length: widget.reports.length,
          child: MainLayout(
            title: 'Stocking Ideas for "${widget.tank.name}"',
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Stocking Ideas for "${widget.tank.name}"',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
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
                      return _TankRecommendationTabView(
                        report: report,
                        tank: widget.tank,
                        existingFish: widget.existingFish,
                        useCustomNames: widget.useCustomNames,
                        getUniqueFish: _getUniqueFish,
                      );
                    }).toList(),
                  ),
                ),
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
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _TankRecommendationTabView extends StatelessWidget {
  final StockingRecommendation report;
  final Tank tank;
  final List<Fish> existingFish;
  final bool useCustomNames;
  final List<Fish> Function(List<Fish>) getUniqueFish;

  const _TankRecommendationTabView({
    required this.report,
    required this.tank,
    required this.existingFish,
    required this.useCustomNames,
    required this.getUniqueFish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final uniqueExistingFish = getUniqueFish(existingFish);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const BannerAdWidget(),
        const SizedBox(height: 16),
        
        // Recommendation title and summary
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
        
        const SizedBox(height: 24),
        
        // Tank info box
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
                    tank.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.pets, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Current Fish (Types): ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      uniqueExistingFish.map((fish) => fish.name).join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (useCustomNames) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.label, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Custom Names: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _buildCustomNamesList(),
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
        
        // Current Tank Inhabitants Section - ALWAYS SHOWN
        _SectionHeader(title: 'Current Tank Inhabitants'),
        const SizedBox(height: 8),
        Text(
          'These are the fish currently in your tank. All recommendations will be compatible with these inhabitants.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        if (useCustomNames) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.label, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Names Included',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        _buildCustomNamesList(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _FishCardGrid(fishList: uniqueExistingFish, isExisting: true),
        const Divider(height: 32),
        
        // Recommended Additions
        _SectionHeader(title: 'Fish to Add'),
        const SizedBox(height: 8),
        Text(
          'The "Recommended Additions" are compatible with your existing tank inhabitants. The "Other Options" provide more choices while maintaining harmony.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _FishCardGrid(fishList: report.coreFish, isCore: true, isAddition: true),

        if (report.otherDataBasedFish.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Other Options', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          _FishCardGrid(fishList: report.otherDataBasedFish, isAddition: true),
        ],

        if (report.aiRecommendedTankMates.isNotEmpty) ...[
          const Divider(height: 32),
          _SectionHeader(title: 'Additional Suggestions (AI Generated)'),
          const SizedBox(height: 8),
          Text(
            report.aiTankMatesSummary,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.aiRecommendedTankMates.map((fishName) {
              return ActionChip(
                label: Text(fishName),
                onPressed: () => _launchSearch(fishName),
              );
            }).toList(),
          ),
        ],

        if (report.compatibilityNotes != null && report.compatibilityNotes!.isNotEmpty) ...[
          const Divider(height: 32),
          _SectionHeader(title: 'Compatibility Notes'),
          const SizedBox(height: 8),
          Text(
            report.compatibilityNotes!,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  String _buildCustomNamesList() {
    final customNames = <String>[];
    for (final inhabitant in tank.inhabitants) {
      customNames.add(inhabitant.customName);
    }
    return customNames.join(', ');
  }

  void _launchSearch(String fishName) async {
    final query = Uri.encodeComponent(fishName);
    final url = Uri.parse('https://www.google.com/search?q=$query+aquarium+fish');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
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
      children: fishList.map((fish) {
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
    );
  }

  void _launchSearch(String fishName) async {
    final query = Uri.encodeComponent(fishName);
    final url = Uri.parse('https://www.google.com/search?q=$query+aquarium+fish');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
