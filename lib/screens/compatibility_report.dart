import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/compatibility_report.dart';
import '../models/fish.dart';
import '../models/tank.dart';
import '../models/tank_notification.dart';
import '../providers/fish_compatibility_provider.dart';
import '../providers/tank_provider.dart';
import '../services/analytics_service.dart';
import '../utils/share_utils.dart';
import '../widgets/ad_component.dart';
import '../widgets/modern_chip.dart';
import 'notification_management_screen.dart';

// ADDED: New helper function to format AI-generated text with bold headers.
Widget _formatAIResponse(BuildContext context, String text) {
  final theme = Theme.of(context);
  final defaultStyle = theme.textTheme.bodyMedium;
  final boldStyle = theme.textTheme.bodyMedium?.copyWith(
    fontWeight: FontWeight.bold,
  );

  final List<TextSpan> spans = [];
  // Standardize the bold markers and then split by them.
  final cleanText = text.replaceAll('* **', '**');
  final parts = cleanText.split('**');

  for (int i = 0; i < parts.length; i++) {
    // Every odd part was inside the markers, so it should be bold.
    spans.add(
      TextSpan(text: parts[i], style: i.isOdd ? boldStyle : defaultStyle),
    );
  }

  return SelectableText.rich(
    TextSpan(children: spans),
    textAlign: TextAlign.center,
  );
}

void showReportDialog(
  BuildContext context,
  CompatibilityReport report, {
  bool fromHistory = false,
  String? fishType,
  Tank? contextTank,
}) {
  // Capture the parent context before the dialog builder so it remains valid
  // after Navigator.of(dialogContext).pop() disposes the dialog route.
  final parentContext = context;
  showDialog(
    context: context,
    builder: (dialogContext) => Consumer(
      builder: (dialogContext, ref, child) {
        final context = dialogContext;
        final l10n = AppLocalizations.of(context)!;
        final notifier = ref.read(fishCompatibilityProvider.notifier);
        final sections = [
          (
            'selectedFish',
            l10n.selectedFish,
            _buildSelectedFishSection(
              context,
              report.selectedFish,
              fishType,
              selectedSpecies: report.selectedSpecies,
            ),
          ),
          (
            'compatibleTankMates',
            l10n.compatibleTankMates,
            _buildTankMatesSection(context, report, fishType),
          ),
          (
            'detailedSummary',
            l10n.detailedSummary,
            _formatAIResponse(context, report.detailedSummary),
          ),
          (
            'recommendedTankSize',
            l10n.recommendedTankSize,
            SelectableText(report.tankSize, textAlign: TextAlign.center),
          ),
          (
            'decorationsAndSetup',
            l10n.decorationsAndSetup,
            _formatAIResponse(context, report.decorations),
          ),
          (
            'careGuide',
            l10n.careGuide,
            _formatAIResponse(context, report.careGuide),
          ),
        ];
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 24.0,
          ),
          contentPadding: const EdgeInsets.all(8.0),
          title: Stack(
            alignment: Alignment.center,
            children: [
              Text(l10n.compatibilityReport, textAlign: TextAlign.center),
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
                  const SizedBox(height: 12),
                  _buildHarmonyCard(context, report),
                  const SizedBox(height: 16),
                  ...sections.asMap().entries.map((entry) {
                    final index = entry.key;
                    final (sectionKey, sectionTitle, sectionContent) =
                        entry.value;
                    if (sectionKey == 'detailedSummary') {
                      return Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 0.0),
                            child: NativeAdWidget(),
                          ),
                          _buildSection(
                            context,
                            sectionTitle,
                            sectionContent,
                            index,
                          ),
                        ],
                      );
                    }
                    return _buildSection(
                      context,
                      sectionTitle,
                      sectionContent,
                      index,
                    );
                  }),
                  const SizedBox(height: 12),
                  _buildCalculationBreakdown(context, report),
                  const BannerAdWidget(),
                  const SizedBox(height: 12),
                  Text(
                    l10n.aiDisclaimer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => shareCompatibilityReport(report),
                    icon: const Icon(Icons.share),
                    label: Text(l10n.shareReport),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      l10n.setCareRemindersPrompt,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      AnalyticsService.logFeatureUsed(
                        featureName: 'compatibility_care_reminders_offer_tapped',
                        parameters: {
                          'selected_fish_count': report.selectedFish.length,
                        },
                      );
                      Navigator.of(context).pop();
                      if (!fromHistory) {
                        notifier.clearSelection();
                      }
                      await _openCareReminderFlow(
                        parentContext,
                        ref,
                        contextTank: contextTank,
                        selectedFish: report.selectedFish,
                      );
                    },
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(l10n.setCareReminders),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
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

Future<void> _openCareReminderFlow(
  BuildContext context,
  WidgetRef ref, {
  Tank? contextTank,
  List<Fish> selectedFish = const [],
}) async {
  final l10n = AppLocalizations.of(context)!;
  final tanks = ref.read(tankProvider).tanks;

  // Determine the target tank
  Tank? targetTank = contextTank;

  if (targetTank == null) {
    if (tanks.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.noTanksYetTitle),
          content: Text(l10n.globalNotificationsNoTanksDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/tank-management');
              },
              child: Text(l10n.createTank),
            ),
          ],
        ),
      );
      return;
    } else if (tanks.length == 1) {
      targetTank = tanks.first;
    } else {
      final selectedTank = await showModalBottomSheet<Tank>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.chooseTankForCareRemindersTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.chooseTankForCareRemindersSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tanks.length,
                    itemBuilder: (context, index) {
                      final tank = tanks[index];
                      return ListTile(
                        leading: const Icon(Icons.water),
                        title: Text(tank.name),
                        subtitle: tank.type.isEmpty ? null : Text(tank.type),
                        onTap: () => Navigator.of(context).pop(tank),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
      if (selectedTank == null || !context.mounted) return;
      targetTank = selectedTank;
    }
  }

  if (!context.mounted) return;

  // Show the care-reminders preview sheet
  final confirmed = await _showCareRemindersPreviewSheet(
    context,
    targetTank,
    selectedFish,
    l10n,
  );
  if (confirmed != true || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => NotificationManagementScreen(tank: targetTank!),
    ),
  );
}

// Icon and colour for each suggested reminder type shown in the preview sheet.
const _reminderPreviewTypes = [
  (NotificationType.feeding, Color(0xFFFF9800), Icons.restaurant),
  (NotificationType.waterChange, Color(0xFF2196F3), Icons.water_drop),
  (NotificationType.testing, Color(0xFF009688), Icons.science),
  (NotificationType.maintenance, Color(0xFF795548), Icons.build),
];

Future<bool> _showCareRemindersPreviewSheet(
  BuildContext context,
  Tank tank,
  List<Fish> selectedFish,
  AppLocalizations l10n,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.careRemindersPreviewTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.careRemindersPreviewSubtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (selectedFish.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: selectedFish
                              .map(
                                (f) => Chip(
                                  label: Text(
                                    f.name,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      ..._reminderPreviewTypes.map((tuple) {
                        final (type, color, icon) = tuple;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Flexible(
                                child: Text(
                                  type.displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(l10n.careRemindersSetUpForTank(tank.name)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

Widget _buildHarmonyCard(BuildContext context, CompatibilityReport report) {
  final l10n = AppLocalizations.of(context)!;
  final harmonyColor = _getHarmonyColor(report.groupHarmonyScore);
  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.groupHarmony,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SelectableText(
            report.harmonyLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: harmonyColor,
              fontWeight: FontWeight.w700,
            ),
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
  BuildContext context,
  String title,
  Widget content,
  int index,
) {
  final isEven = index % 2 == 0;
  final cs = Theme.of(context).colorScheme;
  return Card(
    color: isEven ? null : cs.surfaceContainerHighest.withOpacity(0.28),
    margin: const EdgeInsets.only(bottom: 14.0),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: cs.outlineVariant.withOpacity(0.4), width: 0.8),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    ),
  );
}

Widget _buildCalculationBreakdown(
  BuildContext context,
  CompatibilityReport report,
) {
  final l10n = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  return Card(
    margin: const EdgeInsets.only(bottom: 14.0),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: cs.outlineVariant.withOpacity(0.4), width: 0.8),
    ),
    child: ExpansionTile(
      title: Text(
        l10n.calculationBreakdown,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18.0, bottom: 18.0),
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
  BuildContext context,
  List<Fish> selectedFish,
  String? fishType, {
  Map<String, List<String>> selectedSpecies = const {},
}) {
  return Column(
    children: selectedFish.map((fish) {
      // Show selected species when chosen; otherwise show up to the first 3 from commonNames.
      final fishSpecies = selectedSpecies[fish.name];
      final subtitleText = (fishSpecies?.isNotEmpty ?? false)
          ? fishSpecies!.join(', ')
          : fish.commonNames.take(3).join(', ');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: InkWell(
          onTap: () async {
            // Add fish type to search query
            final searchQuery = fishType != null
                ? '${fish.name} $fishType'
                : fish.name;
            final url = Uri.parse(
              'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}',
            );
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHigh.withOpacity(0.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: CachedNetworkImageProvider(fish.imageURL),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fish.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          // MODIFIED: Allow fish name to wrap to two lines.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitleText.isNotEmpty)
                          Text(
                            subtitleText,
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
        ),
      );
    }).toList(),
  );
}

Widget _buildTankMatesSection(
  BuildContext context,
  CompatibilityReport report,
  String? fishType,
) {
  final l10n = AppLocalizations.of(context)!;
  return Column(
    children: [
      SelectableText(report.tankMatesSummary, textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text(
        l10n.clickFishToSearch,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
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
              // Add fish type to search query
              final searchQuery = fishType != null
                  ? '$fishName $fishType'
                  : fishName;
              final url = Uri.parse(
                'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}',
              );
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
