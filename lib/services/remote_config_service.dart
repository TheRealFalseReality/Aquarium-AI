import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../constants.dart';


/// Thin wrapper around [FirebaseRemoteConfig] that provides server-side
/// control over the in-app free AI (developer Groq key) feature.
///
/// Call [initialize] once during app startup (after Firebase.initializeApp).
/// All getters return safe local defaults if Remote Config is unavailable.
class RemoteConfigService {
  static FirebaseRemoteConfig? _instance;

  /// Initialize Remote Config, apply in-app defaults, then fetch & activate
  /// the latest values from the server.
  ///
  /// Errors are caught and logged; the service gracefully falls back to the
  /// in-app defaults defined in this file.
  static Future<void> initialize() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Set in-app defaults so the app works correctly even before the first
      // successful fetch or when offline.
      await remoteConfig.setDefaults({
        RemoteConfigKeys.freeAiEnabled: true,
        RemoteConfigKeys.devMaxRequestsPerMinute: rcDefaultMaxRequestsPerMinute,
        RemoteConfigKeys.devMaxRequestsPerDay: rcDefaultMaxRequestsPerDay,
        RemoteConfigKeys.devMaxPhotoAnalysesPerDay: rcDefaultMaxPhotoAnalysesPerDay,
        RemoteConfigKeys.devDefaultChatHistoryLimit: rcDefaultFreeTierChatHistoryLimit,
        RemoteConfigKeys.defaultGeminiModel: rcDefaultGeminiModel,
        RemoteConfigKeys.defaultGeminiImageModel: rcDefaultGeminiImageModel,
        RemoteConfigKeys.defaultOpenAIModel: rcDefaultOpenAIModel,
        RemoteConfigKeys.defaultOpenAIImageModel: rcDefaultOpenAIImageModel,
        RemoteConfigKeys.defaultGroqModel: rcDefaultGroqModel,
        RemoteConfigKeys.defaultGroqImageModel: rcDefaultGroqImageModel,
        RemoteConfigKeys.aquapiOriginalImageUrl: rcDefaultAquapiOriginalImageUrl,
        RemoteConfigKeys.aquapiEssentialImageUrl: rcDefaultAquapiEssentialImageUrl,
        RemoteConfigKeys.fishcompatJson: rcDefaultFishcompatJson,
        RemoteConfigKeys.earlySupporterPrice: rcDefaultEarlySupporterPrice,
        RemoteConfigKeys.buyMeACoffeeUrl: rcDefaultBuyMeACoffeeUrl,
        RemoteConfigKeys.changelogEn: rcDefaultChangelog,
        RemoteConfigKeys.changelogDe: rcDefaultChangelogDe,
        RemoteConfigKeys.changelogEs: rcDefaultChangelogEs,
        RemoteConfigKeys.changelogFr: rcDefaultChangelogFr,
        RemoteConfigKeys.communityImageUpload: rcDefaultCommunityImageUpload,
        RemoteConfigKeys.freeFishCompatEnabled: rcDefaultFreeFishCompatEnabled,
        RemoteConfigKeys.freePhotoAnalysisEnabled: rcDefaultFreePhotoAnalysisEnabled,
      });

      // Refresh at most once per hour in production; more frequently in debug.
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      // Fetch and activate in one step; ignore errors (e.g. no network).
      await remoteConfig.fetchAndActivate();

      _instance = remoteConfig;

      if (kDebugMode) {
        debugPrint(
          '[RemoteConfigService] Loaded — '
          'freeAiEnabled=$freeAiEnabled, '
          'maxReqPerMin=$maxRequestsPerMinute, '
          'maxReqPerDay=$maxRequestsPerDay, '
          'maxPhotosPerDay=$maxPhotoAnalysesPerDay, '
          'chatHistoryLimit=$freeTierChatHistoryLimit, '
          'geminiModel=$defaultGeminiModel, '
          'groqModel=$defaultGroqModel, '
          'fishcompatJsonLoaded=${fishcompatJson.isNotEmpty}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RemoteConfigService] Initialization error: $e');
        debugPrint('[RemoteConfigService] Using in-app defaults.');
      }
      // _instance stays null → all getters return local defaults.
    }
  }

  // ---------------------------------------------------------------------------
  // Getters — return Remote Config value when available, else local default
  // ---------------------------------------------------------------------------

  /// Whether the built-in developer Groq key (free AI tier) is enabled.
  /// The developer can set this to `false` in Firebase Remote Config to
  /// disable the free tier for all users without shipping an app update.
  static bool get freeAiEnabled =>
      _instance?.getBool(RemoteConfigKeys.freeAiEnabled) ?? true;

  /// Per-minute request limit for the free (developer-key) tier.
  static int get maxRequestsPerMinute =>
      _instance?.getInt(RemoteConfigKeys.devMaxRequestsPerMinute) ??
      rcDefaultMaxRequestsPerMinute;

  /// Per-day request limit for the free (developer-key) tier.
  static int get maxRequestsPerDay =>
      _instance?.getInt(RemoteConfigKeys.devMaxRequestsPerDay) ??
      rcDefaultMaxRequestsPerDay;

  /// Per-day photo-analysis limit for the free (developer-key) tier.
  static int get maxPhotoAnalysesPerDay =>
      _instance?.getInt(RemoteConfigKeys.devMaxPhotoAnalysesPerDay) ??
      rcDefaultMaxPhotoAnalysesPerDay;

  /// Chat-history window applied to free-tier users (number of past messages
  /// sent to the AI per request). Users with their own API key can configure
  /// this freely; free-tier users are capped at this value.
  static int get freeTierChatHistoryLimit =>
      _instance?.getInt(RemoteConfigKeys.devDefaultChatHistoryLimit) ??
      rcDefaultFreeTierChatHistoryLimit;

  // ── Model defaults ─────────────────────────────────────────────────────────

  /// Returns the RC string for [key] when non-empty, otherwise [fallback].
  static String _modelString(String key, String fallback) {
    final value = _instance?.getString(key);
    return (value != null && value.isNotEmpty) ? value : fallback;
  }

  /// Default Gemini text/chat model name.
  static String get defaultGeminiModel =>
      _modelString(RemoteConfigKeys.defaultGeminiModel, rcDefaultGeminiModel);

  /// Default Gemini image-analysis model name.
  static String get defaultGeminiImageModel =>
      _modelString(RemoteConfigKeys.defaultGeminiImageModel, rcDefaultGeminiImageModel);

  /// Default OpenAI (ChatGPT) text/chat model name.
  static String get defaultOpenAIModel =>
      _modelString(RemoteConfigKeys.defaultOpenAIModel, rcDefaultOpenAIModel);

  /// Default OpenAI image-analysis model name.
  static String get defaultOpenAIImageModel =>
      _modelString(RemoteConfigKeys.defaultOpenAIImageModel, rcDefaultOpenAIImageModel);

  /// Default Groq text/chat model name.
  static String get defaultGroqModel =>
      _modelString(RemoteConfigKeys.defaultGroqModel, rcDefaultGroqModel);

  /// Default Groq image-analysis model name.
  static String get defaultGroqImageModel =>
      _modelString(RemoteConfigKeys.defaultGroqImageModel, rcDefaultGroqImageModel);

  // ── Promotion images ────────────────────────────────────────────────────────

  /// URL for the "original" AquaPi promotion image (shown in the dialog).
  /// Returns an empty string when no URL is set in Remote Config,
  /// signalling that the bundled `assets/images/system/AquaPiMainSmaller.jpg` should be used.
  static String get aquapiOriginalImageUrl =>
      _modelString(RemoteConfigKeys.aquapiOriginalImageUrl, rcDefaultAquapiOriginalImageUrl);

  /// URL for the "essential" AquaPi promotion image (shown on the welcome screen).
  /// Returns an empty string when no URL is set in Remote Config,
  /// signalling that the bundled `assets/images/system/AquaPiEssentials.jpg` should be used.
  static String get aquapiEssentialImageUrl =>
      _modelString(RemoteConfigKeys.aquapiEssentialImageUrl, rcDefaultAquapiEssentialImageUrl);

  // ── Fish compatibility data ─────────────────────────────────────────────────

  /// Full JSON string of the fish compatibility database from Remote Config.
  /// Returns an empty string when not set in Remote Config,
  /// signalling that the bundled `assets/data/fishcompat.json` should be used.
  static String get fishcompatJson =>
      _modelString(RemoteConfigKeys.fishcompatJson, rcDefaultFishcompatJson);

  // ── In-app purchase pricing ─────────────────────────────────────────────────

  /// Formatted USD price string for the Early Supporter lifetime purchase
  /// (e.g. `"$0.99"`). Returns an empty string when the Remote Config value
  /// is `0` or unset, meaning no price label should be shown.
  ///
  /// Pass [locale] (e.g. `Localizations.localeOf(context).toString()`) to
  /// format the number according to the user's locale while keeping the USD
  /// currency symbol.
  static String getEarlySupporterPrice({String? locale}) {
    final raw = _instance?.getDouble(RemoteConfigKeys.earlySupporterPrice)
        ?? rcDefaultEarlySupporterPrice;
    if (raw <= 0) return '';
    return NumberFormat.currency(
      locale: locale ?? 'en_US',
      name: 'USD',
      symbol: r'$',
    ).format(raw);
  }

  // ── Buy Me a Coffee ─────────────────────────────────────────────────────────

  /// URL for the Buy Me a Coffee page. Returns the Remote Config value when
  /// set, otherwise falls back to the in-app default.
  static String get buyMeACoffeeUrl =>
      _modelString(RemoteConfigKeys.buyMeACoffeeUrl, rcDefaultBuyMeACoffeeUrl);

  // ── Changelog ───────────────────────────────────────────────────────────────

  /// Full markdown content of the English changelog from Remote Config.
  /// Returns an empty string when not set in Remote Config,
  /// signalling that the bundled `assets/docs/CHANGELOG.md` should be used.
  static String get changelogEn =>
      _modelString(RemoteConfigKeys.changelogEn, rcDefaultChangelog);

  /// Full markdown content of the German (de) changelog from Remote Config.
  /// Returns an empty string when not set, falling back to [changelogEn].
  static String get changelogDe =>
      _modelString(RemoteConfigKeys.changelogDe, rcDefaultChangelogDe);

  /// Full markdown content of the Spanish (es) changelog from Remote Config.
  /// Returns an empty string when not set, falling back to [changelogEn].
  static String get changelogEs =>
      _modelString(RemoteConfigKeys.changelogEs, rcDefaultChangelogEs);

  /// Full markdown content of the French (fr) changelog from Remote Config.
  /// Returns an empty string when not set, falling back to [changelogEn].
  static String get changelogFr =>
      _modelString(RemoteConfigKeys.changelogFr, rcDefaultChangelogFr);

  /// Returns the best-match changelog content for [languageCode].
  ///
  /// Priority:
  /// 1. Locale-specific content (e.g. `changelog_de` for `"de"`).
  /// 2. English content (`changelogEn`).
  /// 3. Empty string (caller should fall through to bundled asset).
  static String changelogForLocale(String languageCode) {
    String localeContent = '';
    switch (languageCode) {
      case 'de':
        localeContent = changelogDe;
      case 'es':
        localeContent = changelogEs;
      case 'fr':
        localeContent = changelogFr;
    }
    if (localeContent.isNotEmpty) return localeContent;
    return changelogEn;
  }

  /// Whether community image uploads are enabled.
  /// Defaults to `true`. Can be disabled globally via Remote Config.
  static bool get communityImageUploadEnabled =>
      _instance?.getBool(RemoteConfigKeys.communityImageUpload) ??
      rcDefaultCommunityImageUpload;

  /// Whether the AI Fish Compatibility tool is available to free-tier users.
  /// Defaults to `true`. Set to `false` in Firebase Remote Config to disable
  /// the tool for users on the free (developer Groq key) tier.
  static bool get freeFishCompatEnabled =>
      _instance?.getBool(RemoteConfigKeys.freeFishCompatEnabled) ??
      rcDefaultFreeFishCompatEnabled;

  /// Whether the Photo Analysis tool is available to free-tier users.
  /// Defaults to `true`. Set to `false` in Firebase Remote Config to disable
  /// the tool for users on the free (developer Groq key) tier.
  static bool get freePhotoAnalysisEnabled =>
      _instance?.getBool(RemoteConfigKeys.freePhotoAnalysisEnabled) ??
      rcDefaultFreePhotoAnalysisEnabled;
}
