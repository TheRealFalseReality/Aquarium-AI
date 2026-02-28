import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// In-app fallback defaults
// These are used when Firebase Remote Config is unreachable (offline / first
// launch). Update these values when you change the defaults in the Firebase
// Console so that a first-run experience is still sensible.
// ---------------------------------------------------------------------------

/// Default per-minute request cap for the free (developer-key) tier.
const int _defaultMaxRequestsPerMinute = 4;

/// Default per-day request cap for the free (developer-key) tier.
const int _defaultMaxRequestsPerDay = 50;

/// Default per-day photo-analysis cap for the free (developer-key) tier.
const int _defaultMaxPhotoAnalysesPerDay = 3;

/// Default chat-history window (number of past messages sent per request)
/// applied to free-tier users. Users with their own API key can configure
/// this freely; free-tier users are capped at this value.
const int _defaultFreeTierChatHistoryLimit = 3;

// Model string fallbacks — these mirror what used to live in constants.dart.
const String _defaultGeminiModel = 'gemini-flash-latest';
const String _defaultGeminiImageModel = 'gemini-flash-latest';
const String _defaultOpenAIModel = 'gpt-4o';
const String _defaultOpenAIImageModel = 'gpt-4-vision-preview';
const String _defaultGroqModel = 'llama-3.1-8b-instant';
const String _defaultGroqImageModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

// AquaPi promotion images.
// Empty string = use the bundled local asset as fallback.
// Set a URL in Remote Config to override with a newer image without an app update.
/// Fallback for the "original" AquaPi image (AquaPiMainSmaller.jpg).
const String _defaultAquapiOriginalImageUrl = '';
/// Fallback for the "essential" AquaPi image (AquaPiEssentials.jpg).
const String _defaultAquapiEssentialImageUrl = '';

// Fish compatibility data.
// Empty string = use the bundled local assets/fishcompat.json as fallback.
// Set a JSON string in Remote Config to override without an app update.
/// Fallback fish compatibility JSON (empty = use bundled local asset).
const String _defaultFishcompatJson = '';

// Early Supporter lifetime purchase pricing.
// 0.0 = do not display a price label in the Remove Ads dialog.
// Set a positive USD amount (e.g. 0.99) in Remote Config to show a formatted
// price on the purchase button without shipping an app update.
/// Fallback USD price for the Early Supporter lifetime purchase.
const double _defaultEarlySupporterPrice = 0.99;

/// Fallback Buy Me a Coffee URL.
const String _defaultBuyMeACoffeeUrl = 'https://buymeacoffee.com/capitalcityaquatics';

/// Fallback changelog markdown content (empty = use bundled local asset).
const String _defaultChangelog = '';

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
  /// Empty string (default) means use the bundled `assets/AquaPiMainSmaller.jpg`.
  static const String aquapiOriginalImageUrl = 'aquapi_original_image_url';

  /// String — URL for the "essential" AquaPi promotion image
  /// (`AquaPiEssentials.jpg`) shown on the welcome-screen feature card.
  /// Empty string (default) means use the bundled `assets/AquaPiEssentials.jpg`.
  static const String aquapiEssentialImageUrl = 'aquapi_essential_image_url';

  // ── Fish compatibility data ───────────────────────────────────────────────
  /// String — full JSON content of the fish compatibility database.
  /// Empty string (default) means use the bundled `assets/fishcompat.json`.
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
        RemoteConfigKeys.devMaxRequestsPerMinute: _defaultMaxRequestsPerMinute,
        RemoteConfigKeys.devMaxRequestsPerDay: _defaultMaxRequestsPerDay,
        RemoteConfigKeys.devMaxPhotoAnalysesPerDay: _defaultMaxPhotoAnalysesPerDay,
        RemoteConfigKeys.devDefaultChatHistoryLimit: _defaultFreeTierChatHistoryLimit,
        RemoteConfigKeys.defaultGeminiModel: _defaultGeminiModel,
        RemoteConfigKeys.defaultGeminiImageModel: _defaultGeminiImageModel,
        RemoteConfigKeys.defaultOpenAIModel: _defaultOpenAIModel,
        RemoteConfigKeys.defaultOpenAIImageModel: _defaultOpenAIImageModel,
        RemoteConfigKeys.defaultGroqModel: _defaultGroqModel,
        RemoteConfigKeys.defaultGroqImageModel: _defaultGroqImageModel,
        RemoteConfigKeys.aquapiOriginalImageUrl: _defaultAquapiOriginalImageUrl,
        RemoteConfigKeys.aquapiEssentialImageUrl: _defaultAquapiEssentialImageUrl,
        RemoteConfigKeys.fishcompatJson: _defaultFishcompatJson,
        RemoteConfigKeys.earlySupporterPrice: _defaultEarlySupporterPrice,
        RemoteConfigKeys.buyMeACoffeeUrl: _defaultBuyMeACoffeeUrl,
        RemoteConfigKeys.changelog: _defaultChangelog,
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
      _defaultMaxRequestsPerMinute;

  /// Per-day request limit for the free (developer-key) tier.
  static int get maxRequestsPerDay =>
      _instance?.getInt(RemoteConfigKeys.devMaxRequestsPerDay) ??
      _defaultMaxRequestsPerDay;

  /// Per-day photo-analysis limit for the free (developer-key) tier.
  static int get maxPhotoAnalysesPerDay =>
      _instance?.getInt(RemoteConfigKeys.devMaxPhotoAnalysesPerDay) ??
      _defaultMaxPhotoAnalysesPerDay;

  /// Chat-history window applied to free-tier users (number of past messages
  /// sent to the AI per request). Users with their own API key can configure
  /// this freely; free-tier users are capped at this value.
  static int get freeTierChatHistoryLimit =>
      _instance?.getInt(RemoteConfigKeys.devDefaultChatHistoryLimit) ??
      _defaultFreeTierChatHistoryLimit;

  // ── Model defaults ─────────────────────────────────────────────────────────

  /// Returns the RC string for [key] when non-empty, otherwise [fallback].
  static String _modelString(String key, String fallback) {
    final value = _instance?.getString(key);
    return (value != null && value.isNotEmpty) ? value : fallback;
  }

  /// Default Gemini text/chat model name.
  static String get defaultGeminiModel =>
      _modelString(RemoteConfigKeys.defaultGeminiModel, _defaultGeminiModel);

  /// Default Gemini image-analysis model name.
  static String get defaultGeminiImageModel =>
      _modelString(RemoteConfigKeys.defaultGeminiImageModel, _defaultGeminiImageModel);

  /// Default OpenAI (ChatGPT) text/chat model name.
  static String get defaultOpenAIModel =>
      _modelString(RemoteConfigKeys.defaultOpenAIModel, _defaultOpenAIModel);

  /// Default OpenAI image-analysis model name.
  static String get defaultOpenAIImageModel =>
      _modelString(RemoteConfigKeys.defaultOpenAIImageModel, _defaultOpenAIImageModel);

  /// Default Groq text/chat model name.
  static String get defaultGroqModel =>
      _modelString(RemoteConfigKeys.defaultGroqModel, _defaultGroqModel);

  /// Default Groq image-analysis model name.
  static String get defaultGroqImageModel =>
      _modelString(RemoteConfigKeys.defaultGroqImageModel, _defaultGroqImageModel);

  // ── Promotion images ────────────────────────────────────────────────────────

  /// URL for the "original" AquaPi promotion image (shown in the dialog).
  /// Returns an empty string when no URL is set in Remote Config,
  /// signalling that the bundled `assets/AquaPiMainSmaller.jpg` should be used.
  static String get aquapiOriginalImageUrl =>
      _modelString(RemoteConfigKeys.aquapiOriginalImageUrl, _defaultAquapiOriginalImageUrl);

  /// URL for the "essential" AquaPi promotion image (shown on the welcome screen).
  /// Returns an empty string when no URL is set in Remote Config,
  /// signalling that the bundled `assets/AquaPiEssentials.jpg` should be used.
  static String get aquapiEssentialImageUrl =>
      _modelString(RemoteConfigKeys.aquapiEssentialImageUrl, _defaultAquapiEssentialImageUrl);

  // ── Fish compatibility data ─────────────────────────────────────────────────

  /// Full JSON string of the fish compatibility database from Remote Config.
  /// Returns an empty string when not set in Remote Config,
  /// signalling that the bundled `assets/fishcompat.json` should be used.
  static String get fishcompatJson =>
      _modelString(RemoteConfigKeys.fishcompatJson, _defaultFishcompatJson);

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
        ?? _defaultEarlySupporterPrice;
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
      _modelString(RemoteConfigKeys.buyMeACoffeeUrl, _defaultBuyMeACoffeeUrl);

  // ── Changelog ───────────────────────────────────────────────────────────────

  /// Full markdown content of the changelog from Remote Config.
  /// Returns an empty string when not set in Remote Config,
  /// signalling that the bundled `assets/docs/CHANGELOG.md` should be used.
  static String get changelog =>
      _modelString(RemoteConfigKeys.changelog, _defaultChangelog);
}
