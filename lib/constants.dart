// Developer Groq API key – injected at build time via:
//   flutter build ... --dart-define=DEVELOPER_GROQ_API_KEY=<your-key>
// Used as a free fallback when the user has not provided their own Groq key.
// Leave empty to disable the fallback (users must supply their own key).
const String developerGroqApiKey =
    String.fromEnvironment('DEVELOPER_GROQ_API_KEY', defaultValue: '');

// AdMob constants
const String admobAppId = 'ca-app-pub-5701077439648731~1582287080';

// Test IDs from Google
const String admobAppIdTest = 'ca-app-pub-3940256099942544~3347511713';

const String admobBannerAdUnitIdAndroidTest = 'ca-app-pub-3940256099942544/9214589741';
const String admobNativeAdUnitIdAndroidTest = 'ca-app-pub-3940256099942544/2247696110';
const String admobBannerAdUnitIdIOSTest = 'ca-app-pub-3940256099942544/2435281174';
const String admobNativeAdUnitIdIOSTest = 'ca-app-pub-3940256099942544/3986624511';

// Real AdMob IDs
const String admobBannerAdUnitId = 'ca-app-pub-5701077439648731/8630162735';
const String admobNativeAdUnitId = 'ca-app-pub-5701077439648731/9085458306';

// AdSense constants
const String adSenseAppId = 'ca-pub-5701077439648731';
const String adSenseAdUnitId = '9994371406';

// In-app purchase product IDs
const String earlySupporterLifetimeProductId = 'remove_ads_early_supporter_lifetime';
const String buyMeACoffeeProductId = 'buy_me_a_coffee';

// ---------------------------------------------------------------------------
// Remote Config in-app fallback defaults
// These are used when Firebase Remote Config is unreachable (offline / first
// launch).  Update these values to match whatever you set in the Firebase
// Console so that first-run behavior stays sensible.
// ---------------------------------------------------------------------------

// Free (developer-key) tier limits
const int rcDefaultMaxRequestsPerMinute = 4;
const int rcDefaultMaxRequestsPerDay = 50;
const int rcDefaultMaxPhotoAnalysesPerDay = 3;
const int rcDefaultFreeTierChatHistoryLimit = 3;

// Default AI model names
const String rcDefaultGeminiModel = 'gemini-flash-latest';
const String rcDefaultGeminiImageModel = 'gemini-flash-latest';
const String rcDefaultOpenAIModel = 'gpt-4o';
const String rcDefaultOpenAIImageModel = 'gpt-4-vision-preview';
const String rcDefaultGroqModel = 'llama-3.1-8b-instant';
const String rcDefaultGroqImageModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

// AquaPi promotion image URLs (empty = use bundled asset)
const String rcDefaultAquapiOriginalImageUrl = '';
const String rcDefaultAquapiEssentialImageUrl = '';

// Fish compatibility data (empty = use bundled assets/data/fishcompat.json)
const String rcDefaultFishcompatJson = '';
const String rcDefaultFishcompatJsonUrl = '';

// In-app purchase pricing (0.0 = do not show a price label)
const double rcDefaultEarlySupporterPrice = 0.99;

// Buy Me a Coffee URL
const String rcDefaultBuyMeACoffeeUrl = 'https://buymeacoffee.com/capitalcityaquatics';

// Changelog (empty = use bundled assets/docs/CHANGELOG.md)
const String rcDefaultChangelog = '';
const String rcDefaultChangelogUrl = '';
const String rcDefaultChangelogUrlDe = '';
const String rcDefaultChangelogUrlEs = '';
const String rcDefaultChangelogUrlFr = '';

// ---------------------------------------------------------------------------
// Firebase Remote Config key names
// These string constants are the exact key names used in the Firebase Console.
// Update them here if you ever rename a key in the Console.
// ---------------------------------------------------------------------------

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
  static const String devMaxPhotoAnalysesPerDay = 'dev_max_photo_analyses_per_day';

  /// Integer — chat-history window (past messages per request) applied to
  /// free-tier users. Users with their own API key can configure this freely.
  static const String devDefaultChatHistoryLimit = 'dev_default_chat_history_limit';

  // ── Model defaults ──────────────────────────────────────────────────────
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

  // ── Promotion images ────────────────────────────────────────────────────
  /// String — URL for the "original" AquaPi promotion image.
  /// Empty string (default) means use the bundled `assets/images/system/AquaPiMainSmaller.jpg`.
  static const String aquapiOriginalImageUrl = 'aquapi_original_image_url';

  /// String — URL for the "essential" AquaPi promotion image.
  /// Empty string (default) means use the bundled `assets/images/system/AquaPiEssentials.jpg`.
  static const String aquapiEssentialImageUrl = 'aquapi_essential_image_url';

  // ── Fish compatibility data ─────────────────────────────────────────────
  /// String — full JSON content of the fish compatibility database.
  /// Empty string (default) means use the bundled `assets/data/fishcompat.json`.
  static const String fishcompatJson = 'fishcompat_json';

  // ── In-app purchase pricing ─────────────────────────────────────────────
  /// String — USD price for the Early Supporter lifetime purchase.
  /// Store a positive number (e.g. `0.99`) in Remote Config.
  /// `0` or unset means no price label is shown in the Remove Ads dialog.
  static const String earlySupporterPrice = 'early_supporter_price';

  /// String — URL for the Buy Me a Coffee page.
  static const String buyMeACoffeeUrl = 'buy_me_a_coffee_url';

  // ── Changelog ───────────────────────────────────────────────────────────
  /// String — full markdown content of the changelog.
  /// Empty string (default) means use the bundled `assets/docs/CHANGELOG.md`.
  static const String changelog = 'changelog';

  /// String — URL for the German (de) changelog markdown.
  /// Empty string (default) means fall back to [changelogUrl] or bundled asset.
  static const String changelogUrlDe = 'changelog_de';

  /// String — URL for the Spanish (es) changelog markdown.
  /// Empty string (default) means fall back to [changelogUrl] or bundled asset.
  static const String changelogUrlEs = 'changelog_es';

  /// String — URL for the French (fr) changelog markdown.
  /// Empty string (default) means fall back to [changelogUrl] or bundled asset.
  static const String changelogUrlFr = 'changelog_fr';
}
