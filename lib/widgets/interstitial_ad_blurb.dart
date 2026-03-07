import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../services/remote_config_service.dart';
import 'remove_ads_dialog.dart';

/// A dismissible informational blurb shown on free-tier AI tool screens when
/// the user has ads enabled.
///
/// Explains that a full-screen interstitial ad may appear every
/// [RemoteConfigService.interstitialCooldownHours] hours to offset AI costs
/// and offers a "Remove Ads" button to open the purchase dialog.
///
/// The blurb is hidden when:
/// - The user's ads are removed (they purchased "Remove Ads" or Founder).
/// - The user is not using the developer's free-tier AI key.
/// - The app is running on web (no interstitial ads on web).
/// - The user has previously dismissed the blurb.
///
/// [usingDevAiKey] should be `true` when the tool is running on the
/// developer's free-tier API key.
class InterstitialAdBlurb extends ConsumerStatefulWidget {
  final bool usingDevAiKey;

  const InterstitialAdBlurb({super.key, required this.usingDevAiKey});

  @override
  InterstitialAdBlurbState createState() => InterstitialAdBlurbState();
}

class InterstitialAdBlurbState extends ConsumerState<InterstitialAdBlurb> {
  static const String _dismissedKey = 'interstitial_ad_blurb_dismissed_v1';

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
    if (!widget.usingDevAiKey) return const SizedBox.shrink();

    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;
    if (adsRemoved) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final hours = RemoteConfigService.interstitialCooldownHours;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.ondemand_video_outlined, size: 20, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.interstitialAdBlurbTitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.interstitialAdBlurbBody(hours),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => showRemoveAdsDialog(context),
                    icon: Icon(Icons.block, size: 14, color: cs.primary),
                    label: Text(
                      l10n.interstitialAdBlurbCta,
                      style: TextStyle(color: cs.primary, fontSize: 12),
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
                color: cs.onSurfaceVariant.withOpacity(0.7),
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
