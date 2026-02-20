import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/fish_info_result.dart';
import '../main_layout.dart';
import '../widgets/ad_component.dart';
import '../widgets/common_buttons.dart';
import '../widgets/modern_chip.dart';

class FishInfoResultScreen extends StatelessWidget {
  final FishInfoResult result;

  const FishInfoResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MainLayout(
      title: l10n.fishInfo,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: result.fish.length + 2, // header + fish cards + close button
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _header(context, l10n),
                const SizedBox(height: 12),
                const BannerAdWidget(),
                const SizedBox(height: 16),
              ],
            );
          }
          if (index == result.fish.length + 1) {
            return Column(
              children: [
                const SizedBox(height: 8),
                const BannerAdWidget(),
                const SizedBox(height: 12),
                const CommonCloseButton(),
                const SizedBox(height: 16),
              ],
            );
          }
          final fish = result.fish[index - 1];
          return _fishCard(context, fish);
        },
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.aiFishInfoLookup,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _fishCard(BuildContext context, FishInfoEntry fish) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name header card
        Card(
          elevation: 4,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withOpacity(0.6),
                  cs.secondaryContainer.withOpacity(0.4),
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
                  fish.commonName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (fish.scientificName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    fish.scientificName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: cs.onSurface.withOpacity(0.75),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Origin & Habitat
        if (fish.originHabitat.isNotEmpty)
          _infoSection(
            context,
            title: '📍 Origin & Habitat',
            child: Text(
              fish.originHabitat,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

        // Key Facts
        if (fish.keyFacts.isNotEmpty)
          _infoSection(
            context,
            title: '📋 Key Facts',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fish.keyFacts
                  .map(
                    (fact) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold)),
                          Expanded(child: Text(fact)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // Fun Facts
        if (fish.funFacts.isNotEmpty)
          _infoSection(
            context,
            title: '✨ Fun Facts',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fish.funFacts
                  .map(
                    (fact) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: TextStyle(
                                  color: cs.tertiary,
                                  fontWeight: FontWeight.bold)),
                          Expanded(child: Text(fact)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

        // Tank Care
        _infoSection(
          context,
          title: '🪣 Tank Care',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fish.care.minimumTankSize.isNotEmpty)
                _careRow(context, 'Minimum Tank Size:', fish.care.minimumTankSize),
              if (fish.care.difficultyLevel.isNotEmpty)
                _careRow(context, 'Difficulty:', fish.care.difficultyLevel),
              if (fish.care.waterParameters.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Water Parameters:',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                MarkdownBody(
                  data: fish.care.waterParameters,
                  selectable: true,
                  onTapLink: (_, href, __) {
                    if (href != null) launchUrl(Uri.parse(href));
                  },
                ),
              ],
              if (fish.care.tankSetup.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Tank Setup:',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                MarkdownBody(
                  data: fish.care.tankSetup,
                  selectable: true,
                  onTapLink: (_, href, __) {
                    if (href != null) launchUrl(Uri.parse(href));
                  },
                ),
              ],
            ],
          ),
        ),

        const NativeAdWidget(),
        const SizedBox(height: 12),

        // Compatible Tank Mates
        if (fish.compatibleTankMates.isNotEmpty)
          _infoSection(
            context,
            title: '🤝 Compatible Tank Mates',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: fish.compatibleTankMates.map((mate) {
                    return ModernSelectableChip(
                      label: mate,
                      selected: false,
                      dense: true,
                      onTap: () async {
                        final url = Uri.parse(
                            'https://www.google.com/search?q=${Uri.encodeComponent(mate + ' fish')}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  '(Tap a name to search)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),

        // Incompatible Species
        if (fish.incompatibleSpecies.isNotEmpty)
          _infoSection(
            context,
            title: '⚠️ Species to Avoid',
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: fish.incompatibleSpecies.map((species) {
                return Chip(
                  label: Text(species),
                  backgroundColor:
                      Theme.of(context).colorScheme.errorContainer.withOpacity(0.4),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 16),

        // Disclaimer
        Text(
          'Disclaimer: AI may occasionally provide inaccurate information. Always verify critical care details with trusted sources.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _infoSection(BuildContext context,
      {required String title, required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _careRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
