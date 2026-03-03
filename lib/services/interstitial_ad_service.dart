import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'ad_helper.dart';

/// Manages loading and displaying an interstitial ad for free-tier AI users.
///
/// The ad is shown at most once every [admobInterstitialCooldownHours] hours
/// and only on supported platforms (Android / iOS).
class InterstitialAdService {
  static const String _lastShownKey = 'interstitialAdLastShownMs';

  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  /// Loads an interstitial ad so it is ready to show when needed.
  void load() {
    if (!AdHelper.isSupportedPlatform) return;
    final adUnitId = AdHelper.interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (err) {
          if (kDebugMode) {
            debugPrint('InterstitialAd failed to load: $err');
          }
          _isAdReady = false;
        },
      ),
    );
  }

  /// Returns `true` if enough time has passed since the last interstitial was shown.
  Future<bool> _canShow() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownMs = prefs.getInt(_lastShownKey) ?? 0;
    final cooldownMs =
        Duration(hours: admobInterstitialCooldownHours).inMilliseconds;
    return DateTime.now().millisecondsSinceEpoch - lastShownMs >= cooldownMs;
  }

  Future<void> _recordShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastShownKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Shows the interstitial ad if:
  /// - The platform is supported
  /// - The ad is loaded
  /// - The 6-hour cooldown has elapsed
  ///
  /// After showing, reloads the ad for the next opportunity.
  Future<void> showIfEligible() async {
    if (!AdHelper.isSupportedPlatform) return;
    if (!_isAdReady || _interstitialAd == null) return;
    if (!await _canShow()) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) async {
        // Record the timestamp as soon as the ad is shown to the user.
        await _recordShown();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isAdReady = false;
        _interstitialAd = null;
        // Preload the next ad for a future session.
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        if (kDebugMode) {
          debugPrint('InterstitialAd failed to show: $err');
        }
        ad.dispose();
        _isAdReady = false;
        _interstitialAd = null;
        load();
      },
    );

    await _interstitialAd!.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdReady = false;
  }
}
