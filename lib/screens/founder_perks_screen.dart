import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../providers/purchase_provider.dart';
import '../services/analytics_service.dart';
import '../theme_colors.dart';
import '../widgets/remove_ads_dialog.dart';

/// Informative screen listing all Founder Aquarist perks and how to access
/// each one. For non-founders it serves as an upsell page.
class FounderPerksScreen extends ConsumerStatefulWidget {
  const FounderPerksScreen({super.key});

  @override
  ConsumerState<FounderPerksScreen> createState() => _FounderPerksScreenState();
}

class _FounderPerksScreenState extends ConsumerState<FounderPerksScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'founder_perks_screen');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFounder = ref.watch(isFounderProvider);
    final founderColor = AquaThemeColors.founderColor(context);
    final cs = Theme.of(context).colorScheme;

    return MainLayout(
      title: l10n.founderPerksScreenTitle,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Icon(Icons.diamond, color: founderColor, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.founderPerksScreenTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: founderColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isFounder
                ? l10n.founderPerksScreenSubtitle
                : l10n.founderPerksNonFounderSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Status badge for founders
          if (isFounder) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: founderColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: founderColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: founderColor, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.founderAquaristTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: founderColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── Perks list ───────────────────────────────────────────────
          _PerkCard(
            icon: Icons.block,
            title: l10n.founderPerkAdsRemoved,
            accessText: l10n.perkAccessAutomatic,
            accentColor: founderColor,
            isActive: isFounder,
          ),
          _PerkCard(
            icon: Icons.speed,
            title: l10n.founderPerkIncreasedAILimits,
            accessText: l10n.perkAccessAITools,
            accentColor: founderColor,
            isActive: isFounder,
          ),
          _PerkCard(
            icon: Icons.smart_toy,
            title: l10n.founderPerkMoreCapableModels,
            accessText: l10n.perkAccessAITools,
            accentColor: founderColor,
            isActive: isFounder,
          ),
          _PerkCard(
            icon: Icons.dashboard_customize,
            title: l10n.founderPerkCustomization,
            accessText: l10n.perkAccessAppearance,
            accentColor: founderColor,
            isActive: isFounder,
          ),
          _PerkCard(
            icon: Icons.border_all,
            title: l10n.founderPerkPostBorder,
            accessText: l10n.perkAccessCommunity,
            accentColor: founderColor,
            isActive: isFounder,
          ),
          _PerkCard(
            icon: Icons.verified,
            title: l10n.founderPerkBadge,
            accessText: l10n.perkAccessProfile,
            accentColor: founderColor,
            isActive: isFounder,
          ),

          // CTA for non-founders
          if (!isFounder && !kIsWeb) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => showRemoveAdsDialog(context),
                icon: const Icon(Icons.diamond),
                label: Text(l10n.becomeFounderAquarist),
                style: FilledButton.styleFrom(
                  backgroundColor: founderColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// A card displaying a single founder perk with an icon, title, and
/// how-to-access subtitle.
class _PerkCard extends StatelessWidget {
  const _PerkCard({
    required this.icon,
    required this.title,
    required this.accessText,
    required this.accentColor,
    required this.isActive,
  });

  final IconData icon;
  final String title;
  final String accessText;
  final Color accentColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isActive ? accentColor : cs.onSurfaceVariant)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isActive ? accentColor : cs.onSurfaceVariant,
              size: 22,
            ),
          ),
          title: Text(title),
          subtitle: Row(
            children: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: accentColor,
                  ),
                ),
              Flexible(
                child: Text(
                  accessText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isActive ? accentColor : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
