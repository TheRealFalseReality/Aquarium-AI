import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

/// Key names used in Firebase Remote Config.
///
/// Set these keys in the Firebase Console → Remote Config to override the
/// in-app defaults without shipping an app update.
class RemoteConfigKeys {
  /// Boolean — when `false` the built-in developer Groq key is disabled and
  /// users must supply their own API key.  Defaults to `true`.
  static const String freeAiEnabled = 'free_ai_enabled';

  /// Integer — per-minute request cap for the free (developer-key) tier.
  static const String devMaxRequestsPerMinute = 'dev_max_requests_per_minute';

  /// Integer — per-day request cap for the free (developer-key) tier.
  static const String devMaxRequestsPerDay = 'dev_max_requests_per_day';

  /// Integer — per-day photo-analysis cap for the free (developer-key) tier.
  static const String devMaxPhotoAnalysesPerDay =
      'dev_max_photo_analyses_per_day';

  /// Integer — chat-history window (past messages per request) applied to
  /// free-tier users. Users with their own API key can configure this freely.
  static const String devDefaultChatHistoryLimit =
      'dev_default_chat_history_limit';

  // ── Model defaults ────────────────────────────────────────────────────────
  /// String — default Gemini text/chat model name.
  static const String defaultGeminiModel = 'default_gemini_model';

  /// String — default Gemini image-analysis model name.
  static const String defaultGeminiImageModel = 'default_gemini_image_model';

  /// String — default OpenAI (ChatGPT) text/chat model name.
  static const String defaultOpenAIModel = 'default_openai_model';

  /// String — default OpenAI image-analysis model name.
  static const String defaultOpenAIImageModel = 'default_openai_image_model';

  /// String — default Groq text/chat model name.
  static const String defaultGroqModel = 'default_groq_model';

  /// String — default Groq image-analysis model name.
  static const String defaultGroqImageModel = 'default_groq_image_model';

  // ── Promotion images ──────────────────────────────────────────────────────
  /// String — URL for the "original" AquaPi promotion image
  /// (`AquaPiMainSmaller.jpg`) shown in the AquaPi promotion dialog.
  /// Empty string (default) means use the bundled `assets/images/system/AquaPiMainSmaller.jpg`.
  static const String aquapiOriginalImageUrl = 'aquapi_original_image_url';

  /// String — URL for the "essential" AquaPi promotion image
  /// (`AquaPiEssentials.jpg`) shown on the welcome-screen feature card.
  /// Empty string (default) means use the bundled `assets/images/system/AquaPiEssentials.jpg`.
  static const String aquapiEssentialImageUrl = 'aquapi_essential_image_url';

  // ── Fish compatibility data ───────────────────────────────────────────────
  /// String — full JSON content of the fish compatibility database.
  /// Empty string (default) means use the bundled `assets/data/fishcompat.json`.
  static const String fishcompatJson = 'fishcompat_json';

  // ── In-app purchase pricing ───────────────────────────────────────────────
  /// String — USD price for the Early Supporter lifetime purchase.
  /// Store a positive number (e.g. `0.99`) in Remote Config.
  /// `0` or unset means no price label is shown in the Remove Ads dialog.
  static const String earlySupporterPrice = 'early_supporter_price';

  /// String — URL for the Buy Me a Coffee page.
  /// Set in Remote Config to change without an app update.
  static const String buyMeACoffeeUrl = 'buy_me_a_coffee_url';

// ── Changelog ─────────────────────────────────────────────────────────────
  /// String — full markdown content of the changelog.
  /// Empty string (default) means use the bundled `assets/docs/CHANGELOG.md`.
  static const String changelog = 'changelog';

  /// String — URL from which to fetch the changelog markdown at runtime.
  /// When set, the app fetches content from this URL instead of using the
  /// bundled asset or the [changelog] full-content key.
  /// Empty string (default) means fall back to [changelog] or bundled asset.
  static const String changelogUrl = 'changelog_url';

  /// String — URL for the German (de) changelog markdown.
  /// When set, takes priority over [changelogUrl] for German users.
  /// Empty string (default) means fall back to [changelogUrl] or bundled asset.
  static const String changelogUrlDe = 'changelog_url_de';

  /// String — URL for the Spanish (es) changelog markdown.
  /// When set, takes priority over [changelogUrl] for Spanish users.
  /// Empty string (default) means fall back to [changelogUrl] or bundled asset.
  static const String changelogUrlEs = 'changelog_url_es';

  /// String — URL for the French (fr) changelog markdown.
  /// When set, takes priority over [changelogUrl] for French users.
  /// Empty string (default) means fall back to [changelogUrl] or bundled asset.
  static const String changelogUrlFr = 'changelog_url_fr';

  // ── Fish compatibility data URL ───────────────────────────────────────────
  /// String — URL from which to fetch the fish compatibility JSON at runtime.
  /// When set, the app fetches content from this URL instead of using the
  /// bundled asset or the [fishcompatJson] full-content key.
  /// Empty string (default) means fall back to [fishcompatJson] or bundled asset.
  static const String fishcompatJsonUrl = 'fishcompat_json_url';
}

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
        RemoteConfigKeys.changelog: rcDefaultChangelog,
        RemoteConfigKeys.changelogUrl: rcDefaultChangelogUrl,
        RemoteConfigKeys.changelogUrlDe: rcDefaultChangelogUrlDe,
        RemoteConfigKeys.changelogUrlEs: rcDefaultChangelogUrlEs,
        RemoteConfigKeys.changelogUrlFr: rcDefaultChangelogUrlFr,
        RemoteConfigKeys.fishcompatJsonUrl: rcDefaultFishcompatJsonUrl,
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

  /// Full markdown content of the changelog from Remote Config.
  /// Returns an empty string when not set in Remote Config,
  /// signalling that the bundled `assets/docs/CHANGELOG.md` should be used.
  static String get changelog =>
      _modelString(RemoteConfigKeys.changelog, rcDefaultChangelog);

  /// URL from which to fetch the changelog markdown at runtime.
  /// Returns an empty string when not set, signalling that [changelog] or
  /// the bundled asset should be used.
  static String get changelogUrl =>
      _modelString(RemoteConfigKeys.changelogUrl, rcDefaultChangelogUrl);

  /// URL for the German (de) changelog markdown.
  /// Returns an empty string when not set, falling back to [changelogUrl].
  static String get changelogUrlDe =>
      _modelString(RemoteConfigKeys.changelogUrlDe, rcDefaultChangelogUrlDe);

  /// URL for the Spanish (es) changelog markdown.
  /// Returns an empty string when not set, falling back to [changelogUrl].
  static String get changelogUrlEs =>
      _modelString(RemoteConfigKeys.changelogUrlEs, rcDefaultChangelogUrlEs);

  /// URL for the French (fr) changelog markdown.
  /// Returns an empty string when not set, falling back to [changelogUrl].
  static String get changelogUrlFr =>
      _modelString(RemoteConfigKeys.changelogUrlFr, rcDefaultChangelogUrlFr);

  /// Returns the best-match changelog URL for [languageCode].
  ///
  /// Priority:
  /// 1. Locale-specific URL (e.g. `changelog_url_de` for `"de"`).
  /// 2. Generic English URL (`changelog_url`).
  /// 3. Empty string (caller should fall through to inline content or bundled asset).
  static String changelogUrlForLocale(String languageCode) {
    String localeUrl = '';
    switch (languageCode) {
      case 'de':
        localeUrl = changelogUrlDe;
      case 'es':
        localeUrl = changelogUrlEs;
      case 'fr':
        localeUrl = changelogUrlFr;
    }
    if (localeUrl.isNotEmpty) return localeUrl;
    return changelogUrl;
  }

  /// URL from which to fetch the fish compatibility JSON at runtime.
  /// Returns an empty string when not set, signalling that [fishcompatJson] or
  /// the bundled asset should be used.
  static String get fishcompatJsonUrl =>
      _modelString(RemoteConfigKeys.fishcompatJsonUrl, rcDefaultFishcompatJsonUrl);
}
