import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/analysis_result.dart';
import '../main_layout.dart';

class AnalysisResultScreen extends StatelessWidget {
  final WaterAnalysisResult result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Analysis Result',
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analysis Result',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          _buildSummaryCard(context, result.summary),
          const SizedBox(height: 16),
          ...result.parameters.map((p) => _buildParameterCard(context, p)),
          const SizedBox(height: 16),
          _buildHowAquaPiHelpsCard(context, result.howAquaPiHelps),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AnalysisSummary summary) {
    final colors = _getStatusColors(context, summary.status);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              summary.status,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors['text'],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              summary.title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              summary.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterCard(BuildContext context, ParameterAnalysis param) {
    final colors = _getStatusColors(context, param.status);
    return Card(
      color: colors['bg'],
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(param.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(param.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            fontWeight: FontWeight.bold, color: colors['text'])),
              ],
            ),
            const SizedBox(height: 4),
            Text('Ideal: ${param.idealRange}',
                style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 16),
            Text(param.advice, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildHowAquaPiHelpsCard(BuildContext context, String markdownText) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("How AquaPi Can Help",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            MarkdownBody(
              data: markdownText,
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getStatusColors(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'good':
        return {'text': Colors.green, 'bg': Colors.green.withValues(alpha: 0.1)};
      case 'needs attention':
        return {'text': Colors.orange, 'bg': Colors.orange.withValues(alpha: 0.1)};
      case 'bad':
        return {'text': Colors.red, 'bg': Colors.red.withValues(alpha: 0.1)};
      default:
        return {
          'text': Theme.of(context).colorScheme.onSurface,
          'bg': Theme.of(context).colorScheme.surface
        };
    }
  }
}