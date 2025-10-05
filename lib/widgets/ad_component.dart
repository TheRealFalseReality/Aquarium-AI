import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';

// Conditional import for web-specific AdSense implementation
import 'adsense_stub.dart'
    if (dart.library.html) 'adsense_web.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  String? _webAdViewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebAd();
    } else {
      _loadAd();
    }
  }

  void _initWebAd() {
    _webAdViewId = 'adsense-banner-${DateTime.now().millisecondsSinceEpoch}';
    registerAdSenseView(_webAdViewId!);
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
    if (kIsWeb && _webAdViewId != null) {
      return SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 90,
          child: HtmlElementView(viewType: _webAdViewId!),
        ),
      );
    }
    
    if (!_isAdLoaded || _bannerAd == null) {
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

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  String? _webAdViewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebAd();
    } else {
      _loadAd();
    }
  }

  void _initWebAd() {
    _webAdViewId = 'adsense-native-${DateTime.now().millisecondsSinceEpoch}';
    registerAdSenseView(_webAdViewId!);
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
    if (kIsWeb && _webAdViewId != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 250,
          maxWidth: 500,
          maxHeight: 400,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 280,
          child: HtmlElementView(viewType: _webAdViewId!),
        ),
      );
    }
    
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    // Use flexible constraints that work well in different contexts
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 300,
        minHeight: 250,
        maxWidth: 500,
        maxHeight: 400,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  String? _webAdViewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebAd();
    } else {
      _loadAd();
    }
  }

  void _initWebAd() {
    _webAdViewId = 'adsense-banner-widget-${DateTime.now().millisecondsSinceEpoch}';
    registerAdSenseView(_webAdViewId!);
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
    if (kIsWeb && _webAdViewId != null) {
      return SizedBox(
        width: double.infinity,
        height: 90,
        child: HtmlElementView(viewType: _webAdViewId!),
      );
    }
    
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}