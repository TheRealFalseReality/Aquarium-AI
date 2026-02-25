import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../l10n/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../services/ad_helper.dart';
import '../services/web_ads_stub.dart'
    if (dart.library.html) '../services/web_ads_web.dart';
import 'remove_ads_dialog.dart';

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    final adUnitId = AdHelper.bannerAdUnitId; // Use the AdHelper

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    );
    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;
    if (kIsWeb || adsRemoved || !_isAdLoaded || _bannerAd == null) {
      return const SafeArea(child: SizedBox(height: 0));
    }

    return SafeArea(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({super.key});

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    final adUnitId = AdHelper.nativeAdUnitId; // Use the AdHelper

    final nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _nativeAd = ad as NativeAd;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.grey[200],
        callToActionTextStyle: NativeTemplateTextStyle(
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          size: 16.0,
        ),
      ),
    );
    nativeAd.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;
    if (kIsWeb || adsRemoved || !_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    // Use flexible constraints that work well in different contexts
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 300,
            minHeight: 250,
            maxWidth: 500,
            maxHeight: 400,
          ),
          child: AdWidget(ad: _nativeAd!),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => showRemoveAdsDialog(context, ref),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.55),
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.removeAds,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.55),
                      decoration: TextDecoration.underline,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    final adUnitId = AdHelper.bannerAdUnitId; // Use the AdHelper

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    );
    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;
    if (kIsWeb || adsRemoved || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// A zero-size widget that manages web overlay ads (defined in index.html).
///
/// Place this once in the widget tree (e.g. [MainLayout]) to synchronise the
/// AdSense overlay ads with the user's "remove ads" purchase state.  On
/// non-web platforms it is a no-op.
class WebOverlayAdController extends ConsumerStatefulWidget {
  const WebOverlayAdController({super.key});

  @override
  ConsumerState<WebOverlayAdController> createState() =>
      _WebOverlayAdControllerState();
}

class _WebOverlayAdControllerState
    extends ConsumerState<WebOverlayAdController> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    // Apply the current purchase state as soon as the widget mounts.
    final adsRemoved = ref.read(purchaseProvider).adsRemoved;
    adsRemoved ? hideOverlayAds() : showOverlayAds();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    ref.listen<PurchaseState>(purchaseProvider, (_, next) {
      next.adsRemoved ? hideOverlayAds() : showOverlayAds();
    });

    return const SizedBox.shrink();
  }
}
