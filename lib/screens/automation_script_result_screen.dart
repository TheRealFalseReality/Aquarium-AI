import 'package:fish_ai/widgets/accessible_feedback.dart';
import 'package:fish_ai/widgets/ad_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/automation_script.dart';
import '../main_layout.dart';
import '../widgets/common_cards.dart';

class AutomationScriptResultScreen extends StatelessWidget {
  final AutomationScript script;

  const AutomationScriptResultScreen({super.key, required this.script});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MainLayout(
      title: 'Automation Script',
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SectionHeader(
            title: script.title,
            showCloseButton: true,
          ),
          const SizedBox(height: 16),
          _buildCodeBlock(context, script.code),
          const SizedBox(height: 16),
          const NativeAdWidget(),
          MarkdownBody(
            data: script.explanation,
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href));
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(BuildContext context, String code) {
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                context.showAccessibleMessage('Copied to clipboard!');
              },
            ),
          ),
        ],
      ),
    );
  }
}