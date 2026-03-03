import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_helper.dart';
import 'remote_config_service.dart';

/// Manages loading and displaying an interstitial ad for free-tier AI users.
///
/// The ad is shown at most once every [RemoteConfigService.interstitialCooldownHours]
/// hours and only on supported platforms (Android / iOS).
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
        Duration(hours: RemoteConfigService.interstitialCooldownHours).inMilliseconds;
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
  /// - The cooldown period (configured via Remote Config) has elapsed
  ///
  /// [onWillShow] is called just before the ad is presented, allowing the
  /// caller to show a brief toast or notification to the user.
  ///
  /// After showing, reloads the ad for the next opportunity.
  Future<void> showIfEligible({VoidCallback? onWillShow}) async {
    if (!AdHelper.isSupportedPlatform) return;
    if (!_isAdReady || _interstitialAd == null) return;
    if (!await _canShow()) return;

    // Notify caller so it can show a toast/hint before the ad appears.
    onWillShow?.call();

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
