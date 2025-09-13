import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/analysis_result.dart';
import '../main_layout.dart';

class AnalysisResultScreen extends StatelessWidget {
  final WaterAnalysisResult result;

  const AnalysisResultScreen({super.key, required this.result});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
      case 'good':
        return Colors.green;
      case 'needs attention':
        return Colors.orange;
      case 'bad':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Analysis Result',
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _header(context),
          const SizedBox(height: 12),
          _summaryCard(context, result.summary),
          const SizedBox(height: 18),
          ...result.parameters.map((p) => _parameterCard(context, p)),
          const SizedBox(height: 18),
          _howAquaPiHelpsCard(context, result.howAquaPiHelps),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Water Parameter Analysis',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _summaryCard(BuildContext context, AnalysisSummary summary) {
    final color = _statusColor(summary.status);
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.10),
              cs.surfaceVariant.withOpacity(0.20),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              summary.status,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              summary.title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Markdown for bold rendering inside summary message
            MarkdownBody(
              data: summary.message,
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null) launchUrl(Uri.parse(href));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _parameterCard(BuildContext context, ParameterAnalysis param) {
    final color = _statusColor(param.status);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.08),
              cs.surfaceVariant.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    param.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    param.value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Ideal: ${param.idealRange}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withOpacity(0.75),
                  ),
            ),
            const Divider(height: 18),
            // Markdown to render **bold** inside advice
            MarkdownBody(
              data: param.advice,
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null) launchUrl(Uri.parse(href));
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _howAquaPiHelpsCard(BuildContext context, String markdownText) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(0.10),
              cs.secondary.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("How AquaPi Can Help",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            MarkdownBody(
              data: markdownText,
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null) launchUrl(Uri.parse(href));
              },
            ),
          ],
        ),
      ),
    );
  }
}