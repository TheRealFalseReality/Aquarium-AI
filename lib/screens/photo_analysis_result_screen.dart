import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/photo_analysis_result.dart';
import '../main_layout.dart';
import '../providers/chat_provider.dart';
import '../widgets/ad_component.dart';
import '../widgets/common_buttons.dart';
import '../widgets/common_cards.dart';
import '../widgets/helper_text.dart';

class PhotoAnalysisResultScreen extends ConsumerStatefulWidget {
  final PhotoAnalysisResult result;
  final Uint8List? photoBytes;

  const PhotoAnalysisResultScreen({
    super.key,
    required this.result,
    required this.photoBytes,
  });

  @override
  ConsumerState<PhotoAnalysisResultScreen> createState() =>
      _PhotoAnalysisResultScreenState();
}

class _PhotoAnalysisResultScreenState
    extends ConsumerState<PhotoAnalysisResultScreen> {
  bool _regenerating = false;

  Color _confidenceColor(double c) {
    if (c >= 0.8) return Colors.green;
    if (c >= 0.55) return Colors.orange;
    return Colors.red;
  }

  Future<void> _regenerate() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    await ref.read(chatProvider.notifier).regeneratePhotoAnalysis();
    if (mounted) {
      setState(() => _regenerating = false);
      // Pop this screen; the chat listener will push the new regenerated result automatically
      Navigator.pop(context);
    }
  }

  void _openFullImage() {
    if (widget.photoBytes == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.black.withOpacity(0.95),
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      maxScale: 5,
                      child: Image.memory(widget.photoBytes!),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MainLayout(
      title: 'Photo Analysis',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context),
          const SizedBox(height: 12),
          const BannerAdWidget(),
          const SizedBox(height: 12),
          _thumbnail(context),
          const SizedBox(height: 16),
          _summaryCard(context),
          const SizedBox(height: 16),
          // Insert a Native Ad early in the scroll (after summary)
          const NativeAdWidget(),
          const SizedBox(height: 16),
          _fishCard(context),
          const SizedBox(height: 16),
          _tankHealthCard(context),
          const SizedBox(height: 16),
          // Another Native Ad between sections (optional – remove if you only want one)
          const NativeAdWidget(),
          const SizedBox(height: 16),
          _waterGuessesCard(context),
          const SizedBox(height: 16),
          _howAquaPiHelps(context),
          const SizedBox(height: 14),
          const BannerAdWidget(),
          const SizedBox(height: 14),
          ActionButtonRow(
            onRegenerate: _regenerate,
            isRegenerating: _regenerating,
            regenerateLabel: 'Regenerate Analysis',
          ),
          const SizedBox(height: 12),
          const TipText(
            text: 'Tip: Regenerating may produce slightly different identifications or wording.',
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return const SectionHeader(
      title: 'Aquarium Photo Analysis',
      showCloseButton: true,
    );
  }

  Widget _thumbnail(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _openFullImage,
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.08),
                cs.secondary.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.photoBytes == null
              ? Text(
                  'Original photo not available.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        widget.photoBytes!,
                        fit: BoxFit.cover,
                        height: 180,
                        width: double.infinity,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.open_in_full,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Tap to Zoom',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MarkdownBody(
          data: widget.result.summary,
          selectable: true,
          onTapLink: (text, href, title) {
            if (href != null) launchUrl(Uri.parse(href));
          },
        ),
      ),
    );
  }

  Widget _fishCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.result.identifiedFish.isEmpty
            ? Text(
                'No fish confidently identified.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Identified Fish',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ...widget.result.identifiedFish.map((f) {
                    final c = f.confidence.clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: cs.surfaceVariant.withOpacity(0.25),
                        border: Border.all(
                          color: _confidenceColor(c).withOpacity(0.55),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${f.commonName}  (${f.scientificName})',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Confidence: ${(c * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: _confidenceColor(c),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: c,
                                  minHeight: 6,
                                  color: _confidenceColor(c),
                                  backgroundColor:
                                      _confidenceColor(c).withOpacity(0.18),
                                ),
                              ),
                            ],
                          ),
                          if (f.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              f.notes,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ]
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _tankHealthCard(BuildContext context) {
    final th = widget.result.tankHealth;
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Tank Health',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (th.observations.isNotEmpty)
              SectionCard(
                title: 'Observations',
                items: th.observations,
                icon: Icons.visibility_outlined,
                color: cs.primary.withOpacity(0.8),
              ),
            if (th.potentialIssues.isNotEmpty)
              SectionCard(
                title: 'Potential Issues',
                items: th.potentialIssues,
                icon: Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
              ),
            if (th.recommendedActions.isNotEmpty)
              SectionCard(
                title: 'Recommended Actions',
                items: th.recommendedActions,
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _waterGuessesCard(BuildContext context) {
    final g = widget.result.waterQualityGuesses;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Visual Water Quality Guesses',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InfoRow(label: 'Clarity', value: g.clarity),
            InfoRow(label: 'Algae Level', value: g.algaeLevel),
            InfoRow(label: 'Stocking', value: g.stockingAssessment),
            const SizedBox(height: 10),
            const DisclaimerText(
              text: 'Visual impressions only — not actual measurements.',
            )
          ],
        ),
      ),
    );
  }

  Widget _howAquaPiHelps(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Text('How AquaPi Helps',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: widget.result.howAquaPiHelps,
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null) launchUrl(Uri.parse(href));
              },
            ),
          ),
        ],
      ),
    );
  }
}