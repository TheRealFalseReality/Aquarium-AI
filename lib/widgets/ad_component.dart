import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_settings_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/ad_helper.dart';
import '../services/remote_config_service.dart';
import 'remove_ads_dialog.dart';

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isDismissed = false;
  bool _canDismiss = false;
  Timer? _dismissTimer;

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
          _startDismissTimer();
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    );
    bannerAd.load();
  }

  void _startDismissTimer() {
    final seconds = RemoteConfigService.bannerAdDismissSeconds;
    if (seconds <= 0) {
      setState(() => _canDismiss = true);
      return;
    }
    _dismissTimer = Timer(Duration(seconds: seconds), () {
      if (mounted) {
        setState(() => _canDismiss = true);
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsRemoved = ref.watch(purchaseProvider).adsRemoved;
    final debugHideAds =
        kDebugMode && ref.watch(appSettingsProvider).debugHideAds;
    if (kIsWeb ||
        adsRemoved ||
        debugHideAds ||
        !_isAdLoaded ||
        _bannerAd == null ||
        _isDismissed) {
      return const SafeArea(child: SizedBox(height: 0));
    }

    final adWidget = SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );

    return SafeArea(
      child: _canDismiss
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                adWidget,
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: () => setState(() => _isDismissed = true),
                    icon: const Icon(Icons.close, size: 14),
                    tooltip: AppLocalizations.of(context)!.close,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(24, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            )
          : adWidget,
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
        callToActionTextStyle: NativeTemplateTextStyle(size: 16.0),
        primaryTextStyle: NativeTemplateTextStyle(size: 16.0),
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
    final debugHideAds =
        kDebugMode && ref.watch(appSettingsProvider).debugHideAds;
    if (kIsWeb ||
        adsRemoved ||
        debugHideAds ||
        !_isAdLoaded ||
        _nativeAd == null) {
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
          onTap: () => showRemoveAdsDialog(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.55),
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.removeAds,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.55),
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
    final debugHideAds =
        kDebugMode && ref.watch(appSettingsProvider).debugHideAds;
    if (kIsWeb ||
        adsRemoved ||
        debugHideAds ||
        !_isAdLoaded ||
        _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
