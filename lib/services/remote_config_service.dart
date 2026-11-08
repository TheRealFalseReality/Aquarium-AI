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

  /// Debug helper that forces a fresh Remote Config fetch and activate cycle.
  ///
  /// Useful when testing server-message updates in debug builds.
  static Future<bool> debugFetchAndActivate() async {
    if (!kDebugMode) return false;
    return fetchAndActivateLatest();
  }

  /// Fetches and activates the latest Remote Config values.
  ///
  /// Safe to call multiple times; errors are caught and return `false`.
  static Future<bool> fetchAndActivateLatest() async {
    try {
      final remoteConfig = _instance ?? FirebaseRemoteConfig.instance;
      _instance = remoteConfig;
      return await remoteConfig.fetchAndActivate();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RemoteConfigService] Fetch error: $e');
      }
      return false;
    }
  }

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
        RemoteConfigKeys.devMaxPhotoAnalysesPerDay:
            rcDefaultMaxPhotoAnalysesPerDay,
        RemoteConfigKeys.devDefaultChatHistoryLimit:
            rcDefaultFreeTierChatHistoryLimit,
        RemoteConfigKeys.defaultGeminiModel: rcDefaultGeminiModel,
        RemoteConfigKeys.defaultGeminiImageModel: rcDefaultGeminiImageModel,
        RemoteConfigKeys.defaultOpenAIModel: rcDefaultOpenAIModel,
        RemoteConfigKeys.defaultOpenAIImageModel: rcDefaultOpenAIImageModel,
        RemoteConfigKeys.defaultGroqModel: rcDefaultGroqModel,
        RemoteConfigKeys.defaultGroqImageModel: rcDefaultGroqImageModel,
        RemoteConfigKeys.founderDefaultGroqModel: rcDefaultFounderGroqModel,
        RemoteConfigKeys.freeDefaultGroqModel: rcDefaultFreeGroqModel,
        RemoteConfigKeys.freeGroqImageModel: rcDefaultFreeGroqImageModel,
        RemoteConfigKeys.founderGroqImageModel: rcDefaultFounderGroqImageModel,
        RemoteConfigKeys.aquapiOriginalImageUrl:
            rcDefaultAquapiOriginalImageUrl,
        RemoteConfigKeys.aquapiEssentialImageUrl:
            rcDefaultAquapiEssentialImageUrl,
        RemoteConfigKeys.earlySupporterPrice: rcDefaultEarlySupporterPrice,
        RemoteConfigKeys.buyMeACoffeeUrl: rcDefaultBuyMeACoffeeUrl,
        RemoteConfigKeys.changelogEn: rcDefaultChangelog,
        RemoteConfigKeys.changelogDe: rcDefaultChangelogDe,
        RemoteConfigKeys.changelogEs: rcDefaultChangelogEs,
        RemoteConfigKeys.changelogFr: rcDefaultChangelogFr,
        RemoteConfigKeys.communityImageUpload: rcDefaultCommunityImageUpload,
        RemoteConfigKeys.freeFishCompatEnabled: rcDefaultFreeFishCompatEnabled,
        RemoteConfigKeys.freePhotoAnalysisEnabled:
            rcDefaultFreePhotoAnalysisEnabled,
        RemoteConfigKeys.hideFacebookLogin: rcDefaultHideFacebookLogin,
        RemoteConfigKeys.interstitialCooldownHours:
            rcDefaultInterstitialCooldownHours,
        RemoteConfigKeys.founderMaxRequestsPerMinute:
            rcDefaultFounderMaxRequestsPerMinute,
        RemoteConfigKeys.founderMaxRequestsPerDay:
            rcDefaultFounderMaxRequestsPerDay,
        RemoteConfigKeys.founderMaxPhotoAnalysesPerDay:
            rcDefaultFounderMaxPhotoAnalysesPerDay,
        RemoteConfigKeys.founderChatHistoryLimit:
            rcDefaultFounderChatHistoryLimit,
        RemoteConfigKeys.fishDataCooldownHours:
            rcDefaultFishDataCooldownHours,
        RemoteConfigKeys.signedInRateLimitMultiplier:
            rcDefaultSignedInRateLimitMultiplier,
        RemoteConfigKeys.aquapiStoreUrl: rcDefaultAquapiStoreUrl,
        RemoteConfigKeys.groqProxyUrl: rcDefaultGroqProxyUrl,
        RemoteConfigKeys.ccaWebsiteUrl: rcDefaultCcaWebsiteUrl,
        RemoteConfigKeys.gitHubRepoUrl: rcDefaultGitHubRepoUrl,
        RemoteConfigKeys.gitHubIssuesUrl: rcDefaultGitHubIssuesUrl,
        RemoteConfigKeys.serverMessageId: rcDefaultServerMessageId,
        RemoteConfigKeys.serverMessageTitle: rcDefaultServerMessageTitle,
        RemoteConfigKeys.serverMessage: rcDefaultServerMessage,
      });

      // Refresh every launch in debug and at most once per day in release.
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(days: 1),
        ),
      );

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
          'groqModel=$defaultGroqModel',
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

  static bool get _isAnyServerMessageKeyUsingInAppDefault {
    final remoteConfig = _instance;
    if (remoteConfig == null) return true;

    bool usesInAppDefault(String key) =>
        remoteConfig.getValue(key).source == ValueSource.valueDefault;

    return usesInAppDefault(RemoteConfigKeys.serverMessageId) ||
        usesInAppDefault(RemoteConfigKeys.serverMessageTitle) ||
        usesInAppDefault(RemoteConfigKeys.serverMessage);
  }

  /// Default Gemini text/chat model name.
  static String get defaultGeminiModel =>
      _modelString(RemoteConfigKeys.defaultGeminiModel, rcDefaultGeminiModel);

  /// Default Gemini image-analysis model name.
  static String get defaultGeminiImageModel => _modelString(
    RemoteConfigKeys.defaultGeminiImageModel,
    rcDefaultGeminiImageModel,
  );

  /// Default OpenAI (ChatGPT) text/chat model name.
  static String get defaultOpenAIModel =>
      _modelString(RemoteConfigKeys.defaultOpenAIModel, rcDefaultOpenAIModel);

  /// Default OpenAI image-analysis model name.
  static String get defaultOpenAIImageModel => _modelString(
    RemoteConfigKeys.defaultOpenAIImageModel,
    rcDefaultOpenAIImageModel,
  );

  /// Default Groq text/chat model name (used as placeholder in settings).
  static String get defaultGroqModel =>
      _modelString(RemoteConfigKeys.defaultGroqModel, rcDefaultGroqModel);

  /// Default Groq image-analysis model name (placeholder in settings and
  /// image model for free-tier users).
  static String get defaultGroqImageModel => _modelString(
    RemoteConfigKeys.defaultGroqImageModel,
    rcDefaultGroqImageModel,
  );

  /// Groq text model for Founder Aquarist free-tier users.
  static String get founderDefaultGroqModel => _modelString(
    RemoteConfigKeys.founderDefaultGroqModel,
    rcDefaultFounderGroqModel,
  );

  /// Groq text model for standard free-tier (developer Groq key) users.
  static String get freeDefaultGroqModel => _modelString(
    RemoteConfigKeys.freeDefaultGroqModel,
    rcDefaultFreeGroqModel,
  );

  /// Groq image model for free-tier (developer Groq key) users.
  static String get freeGroqImageModel => _modelString(
    RemoteConfigKeys.freeGroqImageModel,
    rcDefaultFreeGroqImageModel,
  );

  /// Groq image model for Founder Aquarist free-tier users.
  static String get founderGroqImageModel => _modelString(
    RemoteConfigKeys.founderGroqImageModel,
    rcDefaultFounderGroqImageModel,
  );

  // ── Promotion images ────────────────────────────────────────────────────────

  /// URL for the "original" AquaPi promotion image (shown in the dialog).
  /// Returns an empty string when no URL is set in Remote Config,
  /// signalling that the bundled `assets/images/system/AquaPiMainSmaller.jpg` should be used.
  static String get aquapiOriginalImageUrl => _modelString(
    RemoteConfigKeys.aquapiOriginalImageUrl,
    rcDefaultAquapiOriginalImageUrl,
  );

  /// URL for the "essential" AquaPi promotion image (shown on the welcome screen).
  /// Returns an empty string when no URL is set in Remote Config,
  /// signalling that the bundled `assets/images/system/AquaPiEssentials.jpg` should be used.
  static String get aquapiEssentialImageUrl => _modelString(
    RemoteConfigKeys.aquapiEssentialImageUrl,
    rcDefaultAquapiEssentialImageUrl,
  );

  // ── In-app purchase pricing ─────────────────────────────────────────────────

  /// Formatted USD price string for the Early Supporter lifetime purchase
  /// (e.g. `"$0.99"`). Returns an empty string when the Remote Config value
  /// is `0` or unset, meaning no price label should be shown.
  ///
  /// Pass [locale] (e.g. `Localizations.localeOf(context).toString()`) to
  /// format the number according to the user's locale while keeping the USD
  /// currency symbol.
  static String getEarlySupporterPrice({String? locale}) {
    final raw =
        _instance?.getDouble(RemoteConfigKeys.earlySupporterPrice) ??
        rcDefaultEarlySupporterPrice;
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
  /// signalling that the bundled `assets/docs/en/CHANGELOG_en.md` should be used.
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

  /// Whether the Facebook Login button is hidden on the auth screen.
  /// Defaults to `false` (button is visible). Set to `true` in Firebase
  /// Remote Config to hide Facebook Login without shipping an app update.
  static bool get hideFacebookLogin =>
      _instance?.getBool(RemoteConfigKeys.hideFacebookLogin) ??
      rcDefaultHideFacebookLogin;

  // ── Ads ─────────────────────────────────────────────────────────────────────

  /// Minimum hours between interstitial ad impressions for free-tier users.
  /// Defaults to [rcDefaultInterstitialCooldownHours] (6).
  /// Increase this value in Firebase Remote Config to reduce ad frequency.
  static int get interstitialCooldownHours =>
      _instance?.getInt(RemoteConfigKeys.interstitialCooldownHours) ??
      rcDefaultInterstitialCooldownHours;

  // ── Founder Aquarist AI limits ──────────────────────────────────────────────

  /// Per-minute request limit for Founder Aquarist users.
  static int get founderMaxRequestsPerMinute =>
      _instance?.getInt(RemoteConfigKeys.founderMaxRequestsPerMinute) ??
      rcDefaultFounderMaxRequestsPerMinute;

  /// Per-day request limit for Founder Aquarist users.
  static int get founderMaxRequestsPerDay =>
      _instance?.getInt(RemoteConfigKeys.founderMaxRequestsPerDay) ??
      rcDefaultFounderMaxRequestsPerDay;

  /// Per-day photo-analysis limit for Founder Aquarist users.
  static int get founderMaxPhotoAnalysesPerDay =>
      _instance?.getInt(RemoteConfigKeys.founderMaxPhotoAnalysesPerDay) ??
      rcDefaultFounderMaxPhotoAnalysesPerDay;

  /// Chat-history window for Founder Aquarist users.
  static int get founderChatHistoryLimit =>
      _instance?.getInt(RemoteConfigKeys.founderChatHistoryLimit) ??
      rcDefaultFounderChatHistoryLimit;

  /// Multiplier applied to the per-minute, per-day, and per-photo limits
  /// for users who are signed in with a real account (non-anonymous,
  /// non-founder).  Defaults to 2× the anonymous free-tier baseline.
  static double get signedInRateLimitMultiplier =>
      _instance?.getDouble(RemoteConfigKeys.signedInRateLimitMultiplier) ??
      rcDefaultSignedInRateLimitMultiplier;

  // ── Fish compatibility data ─────────────────────────────────────────────

  /// Minimum hours between Firestore fetches for fish compatibility data.
  /// Defaults to [rcDefaultFishDataCooldownHours] (12).
  static int get fishDataCooldownHours =>
      _instance?.getInt(RemoteConfigKeys.fishDataCooldownHours) ??
      rcDefaultFishDataCooldownHours;

  // ── App / store URLs ─────────────────────────────────────────────────────

  /// URL for the AquaPi store/product page.
  /// Defaults to [rcDefaultAquapiStoreUrl].
  static String get aquapiStoreUrl =>
      _modelString(RemoteConfigKeys.aquapiStoreUrl, rcDefaultAquapiStoreUrl);

  /// Groq proxy Cloud Function endpoint URL.
  /// Defaults to [rcDefaultGroqProxyUrl].
  static String get groqProxyUrl =>
      _modelString(RemoteConfigKeys.groqProxyUrl, rcDefaultGroqProxyUrl);

  /// Capital City Aquatics website URL.
  /// Defaults to [rcDefaultCcaWebsiteUrl].
  static String get ccaWebsiteUrl =>
      _modelString(RemoteConfigKeys.ccaWebsiteUrl, rcDefaultCcaWebsiteUrl);

  /// Aquarium AI GitHub repository URL.
  /// Defaults to [rcDefaultGitHubRepoUrl].
  static String get gitHubRepoUrl =>
      _modelString(RemoteConfigKeys.gitHubRepoUrl, rcDefaultGitHubRepoUrl);

  /// Aquarium AI GitHub issues URL.
  /// Defaults to [rcDefaultGitHubIssuesUrl].
  static String get gitHubIssuesUrl =>
      _modelString(RemoteConfigKeys.gitHubIssuesUrl, rcDefaultGitHubIssuesUrl);

  // ── Server message ─────────────────────────────────────────────────────────

  /// Unique identifier for the active server message.
  /// An empty string means no message is configured.
  /// Updating this value in Remote Config causes the popup to appear again
  /// for all users (including those who previously snoozed).
  static String get serverMessageId {
    if (_isAnyServerMessageKeyUsingInAppDefault) return '';
    return _modelString(RemoteConfigKeys.serverMessageId, rcDefaultServerMessageId);
  }

  /// Title of the server message dialog.
  /// An empty string signals the UI to use a generic fallback title.
  static String get serverMessageTitle {
    if (_isAnyServerMessageKeyUsingInAppDefault) return '';
    return _modelString(
      RemoteConfigKeys.serverMessageTitle,
      rcDefaultServerMessageTitle,
    );
  }

  /// Body text of the server message dialog.
  /// An empty string means no message should be shown.
  static String get serverMessage {
    if (_isAnyServerMessageKeyUsingInAppDefault) return '';
    return _modelString(RemoteConfigKeys.serverMessage, rcDefaultServerMessage);
  }
}
