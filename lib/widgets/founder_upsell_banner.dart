import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../theme_colors.dart';
import 'remove_ads_dialog.dart';

/// A dismissible promotional banner that upsells the Founder Aquarist perk to
/// free-tier users on AI tool screens.
///
/// The banner is hidden when:
/// - The user is already a Founder Aquarist.
/// - The user is not using the free (developer) AI tier.
/// - The user has previously dismissed the banner.
/// - The app is running on web.
///
/// [usingDevAiKey] should be `true` when the current tool is running on the
/// developer's free-tier API key (e.g. `modelState.usingDeveloperGroqKeyForText`
/// for text-based tools, or `modelState.usingDeveloperGroqKeyForImage` for the
/// Photo Analyzer).
class FounderUpsellBanner extends ConsumerStatefulWidget {
  final bool usingDevAiKey;

  const FounderUpsellBanner({super.key, required this.usingDevAiKey});

  @override
  FounderUpsellBannerState createState() => FounderUpsellBannerState();
}

class FounderUpsellBannerState extends ConsumerState<FounderUpsellBanner> {
  static const String _dismissedKey = 'founder_upsell_banner_dismissed_v1';

  bool _dismissed = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dismissed = prefs.getBool(_dismissedKey) ?? false;
        _prefsLoaded = true;
      });
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    if (!_prefsLoaded) return const SizedBox.shrink();
    if (_dismissed) return const SizedBox.shrink();

    final isFounder = ref.watch(isFounderProvider);
    if (isFounder) return const SizedBox.shrink();
    if (!widget.usingDevAiKey) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final founderColor = AquaThemeColors.founderColor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: founderColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: founderColor.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.diamond, size: 20, color: founderColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.founderUpsellBannerTitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: founderColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.founderUpsellBannerBody,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => showRemoveAdsDialog(context),
                    icon: Icon(Icons.diamond, size: 14, color: founderColor),
                    label: Text(
                      l10n.becomeFounderAquarist,
                      style: TextStyle(color: founderColor, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              onPressed: _dismiss,
              tooltip: l10n.dismiss,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
