// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../models/analysis_history_entry.dart';
import '../models/analysis_result.dart';
import '../models/automation_script.dart';
import '../models/compatibility_report.dart';
import '../models/fish_info_result.dart';
import '../models/photo_analysis_result.dart';
import '../models/stocking_recommendation.dart';
import '../providers/analysis_history_provider.dart';
import '../providers/purchase_provider.dart';
import '../widgets/ad_component.dart';
import 'analysis_result_screen.dart';
import 'automation_script_result_screen.dart';
import 'compatibility_report.dart' show showReportDialog;
import 'fish_info_result_screen.dart';
import 'photo_analysis_result_screen.dart';
import 'stocking_report_screen.dart';

class AnalysisHistoryScreen extends ConsumerWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Watch for state changes to trigger rebuilds
    final allEntries = ref.watch(analysisHistoryProvider);
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;

    // Sort: favorites first (by date), then regular (by date)
    final favorites = allEntries.where((e) => e.isFavorite).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final regular = allEntries.where((e) => !e.isFavorite).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final entries = [...favorites, ...regular];

    // Build a mixed list: insert a native ad slot every 5 history entries.
    const adEvery = 5;
    final items = <_HistoryItem>[];
    for (var i = 0; i < entries.length; i++) {
      items.add(_HistoryItem.entry(entries[i]));
      if (!adsRemoved && (i + 1) % adEvery == 0 && i + 1 < entries.length) {
        items.add(_HistoryItem.ad());
      }
    }

    return MainLayout(
      title: l10n.analysisHistoryTitle,
      child: entries.isEmpty
          ? _buildEmpty(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item.isAd) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: NativeAdWidget(),
                        );
                      }
                      final entry = item.entry;
                      if (entry == null) return const SizedBox.shrink();
                      return _HistoryEntryTile(entry: entry);
                    },
                  ),
                ),
                _buildClearButton(context, ref),
              ],
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 72, color: cs.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              l10n.noAnalysisHistory,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noAnalysisHistoryDesc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.clearHistory),
              content: Text(l10n.clearHistoryConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.clearAll),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(analysisHistoryProvider.notifier).clearAll();
          }
        },
        icon: const Icon(Icons.delete_sweep, size: 18),
        label: Text(l10n.clearAllHistory),
      ),
    );
  }
}

/// A discriminated union for list items: either a history entry or an ad slot.
class _HistoryItem {
  final AnalysisHistoryEntry? entry;
  final bool isAd;

  const _HistoryItem._({this.entry, required this.isAd});

  factory _HistoryItem.entry(AnalysisHistoryEntry e) =>
      _HistoryItem._(entry: e, isAd: false);

  factory _HistoryItem.ad() => const _HistoryItem._(isAd: true);
}

class _HistoryEntryTile extends ConsumerWidget {
  final AnalysisHistoryEntry entry;

  const _HistoryEntryTile({required this.entry});

  IconData _typeIcon(AnalysisType type) {
    switch (type) {
      case AnalysisType.waterParameters:
        return Icons.water_drop;
      case AnalysisType.photoAnalysis:
        return Icons.camera_alt;
      case AnalysisType.fishInfo:
        return Icons.info_outline;
      case AnalysisType.automationScript:
        return Icons.code;
      case AnalysisType.compatibilityReport:
        return Icons.compare_arrows;
      case AnalysisType.stockingRecommendation:
        return Icons.auto_awesome;
    }
  }

  Color _typeColor(AnalysisType type, ColorScheme cs) {
    switch (type) {
      case AnalysisType.waterParameters:
        return cs.primary;
      case AnalysisType.photoAnalysis:
        return cs.secondary;
      case AnalysisType.fishInfo:
        return cs.tertiary;
      case AnalysisType.automationScript:
        return cs.error;
      case AnalysisType.compatibilityReport:
        return Colors.teal;
      case AnalysisType.stockingRecommendation:
        return Colors.deepPurple;
    }
  }

  void _openResult(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    try {
      switch (entry.type) {
        case AnalysisType.waterParameters:
          final result = WaterAnalysisResult.fromJson(entry.resultData);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AnalysisResultScreen(result: result),
            ),
          );
          break;

        case AnalysisType.photoAnalysis:
          final result = PhotoAnalysisResult.fromJson(entry.resultData);
          Uint8List? photoBytes;
          if (entry.photoBase64 != null && entry.photoBase64!.isNotEmpty) {
            try {
              photoBytes = base64Decode(entry.photoBase64!);
            } catch (_) {}
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhotoAnalysisResultScreen(
                result: result,
                photoBytes: photoBytes,
              ),
            ),
          );
          break;

        case AnalysisType.fishInfo:
          final result = FishInfoResult.fromJson(entry.resultData);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FishInfoResultScreen(result: result),
            ),
          );
          break;

        case AnalysisType.automationScript:
          final script = AutomationScript.fromJson(entry.resultData);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AutomationScriptResultScreen(script: script),
            ),
          );
          break;

        case AnalysisType.compatibilityReport:
          final report = CompatibilityReport.fromJson(
            entry.resultData['report'] as Map<String, dynamic>? ?? {},
          );
          final fishType = entry.resultData['fishType'] as String?;
          showReportDialog(
            context,
            report,
            fromHistory: true,
            fishType: fishType,
          );
          break;

        case AnalysisType.stockingRecommendation:
          final recsRaw =
              entry.resultData['recommendations'] as List<dynamic>? ?? [];
          final recs = recsRaw
              .whereType<Map<String, dynamic>>()
              .map(StockingRecommendation.fromJson)
              .toList();
          if (recs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.noRecommendationsFound)),
            );
            break;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StockingReportScreen(
                reports: recs,
                tankSize: entry.resultData['tankSize'] as String?,
                tankType: entry.resultData['tankType'] as String?,
                userNotes: entry.resultData['userNotes'] as String?,
              ),
            ),
          );
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenReport(e.toString()))),
      );
    }
  }

  String _localizedTypeName(AnalysisType type, AppLocalizations l10n) {
    switch (type) {
      case AnalysisType.waterParameters:
        return l10n.analysisTypeWaterParameters;
      case AnalysisType.photoAnalysis:
        return l10n.analysisTypePhotoAnalysis;
      case AnalysisType.fishInfo:
        return l10n.analysisTypeFishInfo;
      case AnalysisType.automationScript:
        return l10n.analysisTypeAutomationScript;
      case AnalysisType.compatibilityReport:
        return l10n.analysisTypeCompatibilityReport;
      case AnalysisType.stockingRecommendation:
        return l10n.analysisTypeStockingRecommendation;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final color = _typeColor(entry.type, cs);
    final dateStr = DateFormat('MMM d, y • h:mm a').format(entry.timestamp);

    // For photo analyses, show a thumbnail when available.
    Uint8List? photoBytes;
    if (entry.type == AnalysisType.photoAnalysis &&
        entry.photoBase64 != null &&
        entry.photoBase64!.isNotEmpty) {
      try {
        photoBytes = base64Decode(entry.photoBase64!);
      } catch (e) {
        debugPrint(
          'Failed to decode photo base64 for history entry ${entry.id}: $e',
        );
      }
    }

    Widget leadingWidget;
    if (photoBytes != null) {
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          photoBytes,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(entry.type), color: color, size: 22),
          ),
        ),
      );
    } else {
      leadingWidget = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_typeIcon(entry.type), color: color, size: 22),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openResult(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              leadingWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _localizedTypeName(entry.type, l10n),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.modelName != null &&
                        entry.modelName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.modelName!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              // Favorite star button
              IconButton(
                tooltip: entry.isFavorite
                    ? l10n.removeFromFavorites
                    : l10n.addToFavorites,
                icon: Icon(
                  entry.isFavorite ? Icons.star : Icons.star_border,
                  color: entry.isFavorite
                      ? Colors.amber
                      : cs.onSurface.withOpacity(0.4),
                ),
                onPressed: () {
                  ref
                      .read(analysisHistoryProvider.notifier)
                      .toggleFavorite(entry.id);
                },
              ),
              // Delete button
              IconButton(
                tooltip: l10n.delete,
                icon: Icon(
                  Icons.delete_outline,
                  color: cs.onSurface.withOpacity(0.4),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.deleteEntry),
                      content: Text(l10n.deleteEntryConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(analysisHistoryProvider.notifier)
                        .deleteEntry(entry.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
