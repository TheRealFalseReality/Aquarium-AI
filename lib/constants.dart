// Developer Groq API key – injected at build time via:
//   flutter build ... --dart-define=DEVELOPER_GROQ_API_KEY=<your-key>
// Used as a free fallback when the user has not provided their own Groq key.
// Leave empty to disable the fallback (users must supply their own key).
const String developerGroqApiKey = String.fromEnvironment(
  'DEVELOPER_GROQ_API_KEY',
  defaultValue: '',
);

// reCAPTCHA v3 site key – injected at build time via:
//   flutter build ... --dart-define=RECAPTCHA_V3_SITE_KEY=<your-key>
// Required for Firebase App Check on the Web platform.
// Obtain your key at https://www.google.com/recaptcha/admin and register it
// in Firebase Console → Build → App Check → Web app → reCAPTCHA v3.
// The default below is the production site key for this app.  Site keys are
// public (safe to embed in client-side code); only the server-side secret key
// must be kept private.
const String reCaptchaV3SiteKey = String.fromEnvironment(
  'RECAPTCHA_V3_SITE_KEY',
  defaultValue: '6Lc6P4AsAAAAANB5aWATibw1Aada7IUq6IttLI5a',
);

// Facebook App ID – public, safe to embed in client code.
// This is the production app ID for Aquarium AI on Facebook.
// Register and manage this at: https://developers.facebook.com/apps/941109785269057/
// The App ID is a public identifier; only the Client Token (below) and the
// App Secret (server-side only) must be kept out of source control.
const String facebookAppId = '941109785269057';

// Facebook Client Token – injected at build time via:
//   flutter build ... --dart-define=FACEBOOK_CLIENT_TOKEN=<your-token>
// Required for flutter_facebook_auth web initialisation and for the native
// Facebook SDK on Android/iOS. Obtain this from:
//   Facebook Developer Console → Your App → Settings → Advanced → Client Token.
// The token is embedded in the app binary by the Facebook SDK regardless, so
// it is not a secret in the server-side sense, but it is kept out of source
// control as a best practice.
const String facebookClientToken = String.fromEnvironment(
  'FACEBOOK_CLIENT_TOKEN',
  defaultValue: '',
);

// AdMob constants
const String admobAppId = 'ca-app-pub-5701077439648731~1582287080';

// Test IDs from Google
const String admobAppIdTest = 'ca-app-pub-3940256099942544~3347511713';

const String admobBannerAdUnitIdAndroidTest =
    'ca-app-pub-3940256099942544/9214589741';
const String admobNativeAdUnitIdAndroidTest =
    'ca-app-pub-3940256099942544/2247696110';
const String admobInterstitialAdUnitIdAndroidTest =
    'ca-app-pub-3940256099942544/1033173712';
const String admobBannerAdUnitIdIOSTest =
    'ca-app-pub-3940256099942544/2435281174';
const String admobNativeAdUnitIdIOSTest =
    'ca-app-pub-3940256099942544/3986624511';
const String admobInterstitialAdUnitIdIOSTest =
    'ca-app-pub-3940256099942544/4411468910';

// Real AdMob IDs
const String admobBannerAdUnitId = 'ca-app-pub-5701077439648731/8630162735';
const String admobNativeAdUnitId = 'ca-app-pub-5701077439648731/9085458306';
const String admobInterstitialAdUnitId =
    'ca-app-pub-5701077439648731/4488121170';

// Interstitial ad cooldown: once every N hours for free-tier AI users.
// This is the in-app fallback default; the actual value is controlled via
// Firebase Remote Config (RemoteConfigKeys.interstitialCooldownHours).
const int rcDefaultInterstitialCooldownHours = 6;

// AdSense constants
const String adSenseAppId = 'ca-pub-5701077439648731';
const String adSenseAdUnitId = '9994371406';

// Google Play Store listing URL (production package ID).
// Used as the fallback URL when the in-app review API is unavailable.
// Not yet available on iOS.
const String googlePlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.cca.fishai';

// In-app purchase product IDs
const String earlySupporterLifetimeProductId =
    'remove_ads_early_supporter_lifetime';
const String buyMeACoffeeProductId = 'buy_me_a_coffee';

/// Product IDs that grant "Founder Aquarist" status.
/// Add new founder product IDs here as they are introduced — every entry in
/// this list will be treated as a Founder Aquarist purchase.
const List<String> founderProductIds = [earlySupporterLifetimeProductId];

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
// Placeholder model shown in API Provider settings for the Groq text field.
const String rcDefaultGroqModel = 'llama-3.3-70b-versatile';
const String rcDefaultGroqImageModel =
    'meta-llama/llama-4-scout-17b-16e-instruct';
// Free-tier model names (used when the developer Groq key is active).
const String rcDefaultFounderGroqModel = 'llama-3.3-70b-versatile';
const String rcDefaultFreeGroqModel = 'llama-3.1-8b-instant';
const String rcDefaultFounderGroqImageModel =
    'meta-llama/llama-4-maverick-17b-128e-instruct';
const String rcDefaultFreeGroqImageModel =
    'meta-llama/llama-4-scout-17b-16e-instruct';

// AquaPi promotion image URLs (empty = use bundled asset)
const String rcDefaultAquapiOriginalImageUrl = '';
const String rcDefaultAquapiEssentialImageUrl = '';

// In-app purchase pricing (0.0 = do not show a price label)
const double rcDefaultEarlySupporterPrice = 0.99;

// Buy Me a Coffee URL
const String rcDefaultBuyMeACoffeeUrl =
    'https://buymeacoffee.com/capitalcityaquatics';

// Changelog (empty = use bundled assets/docs/en/CHANGELOG_en.md)
const String rcDefaultChangelog = '';
const String rcDefaultChangelogDe = '';
const String rcDefaultChangelogEs = '';
const String rcDefaultChangelogFr = '';

// Community image upload (true = enabled)
const bool rcDefaultCommunityImageUpload = true;

// Per-tool free-tier availability (true = enabled on free tier)
const bool rcDefaultFreeFishCompatEnabled = true;
const bool rcDefaultFreePhotoAnalysisEnabled = true;

// Feature visibility toggles (false = visible by default)
const bool rcDefaultHideFacebookLogin = false;

// Fish compatibility data cooldown (hours between Firestore fetches)
const int rcDefaultFishDataCooldownHours = 12;

// Founder Aquarist tier limits (increased vs standard free tier)
const int rcDefaultFounderMaxRequestsPerMinute = 10;
const int rcDefaultFounderMaxRequestsPerDay = 150;
const int rcDefaultFounderMaxPhotoAnalysesPerDay = 10;
const int rcDefaultFounderChatHistoryLimit = 10;

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
  static const String devMaxPhotoAnalysesPerDay =
      'dev_max_photo_analyses_per_day';

  /// Integer — chat-history window (past messages per request) applied to
  /// free-tier users. Users with their own API key can configure this freely.
  static const String devDefaultChatHistoryLimit =
      'dev_default_chat_history_limit';

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
  /// Used as the placeholder hint in API Provider settings.
  static const String defaultGroqModel = 'default_groq_model';

  /// String — default Groq image-analysis model name.
  /// Used as the placeholder hint in API Provider settings and as the
  /// image model for free-tier (developer Groq key) users.
  static const String defaultGroqImageModel = 'default_groq_image_model';

  /// String — Groq text model used for Founder Aquarist free-tier users.
  static const String founderDefaultGroqModel = 'founder_default_groq_model';

  /// String — Groq text model used for standard free-tier users.
  static const String freeDefaultGroqModel = 'free_default_groq_model';

  /// String — Groq image model used for free-tier (developer Groq key) users.
  static const String freeGroqImageModel = 'free_groq_image_model';

  /// String — Groq image model used for Founder Aquarist free-tier users.
  static const String founderGroqImageModel = 'founder_groq_image_model';

  // ── Promotion images ────────────────────────────────────────────────────
  /// String — URL for the "original" AquaPi promotion image.
  /// Empty string (default) means use the bundled `assets/images/system/AquaPiMainSmaller.jpg`.
  static const String aquapiOriginalImageUrl = 'aquapi_original_image_url';

  /// String — URL for the "essential" AquaPi promotion image.
  /// Empty string (default) means use the bundled `assets/images/system/AquaPiEssentials.jpg`.
  static const String aquapiEssentialImageUrl = 'aquapi_essential_image_url';

  // ── Fish compatibility data ─────────────────────────────────────────────
  /// Integer — minimum hours between Firestore fetches for fish compatibility
  /// data.  Defaults to [rcDefaultFishDataCooldownHours] (12).
  /// Reduce to fetch more often, or increase to reduce network usage.
  static const String fishDataCooldownHours = 'fish_data_cooldown_hours';

  // ── In-app purchase pricing ─────────────────────────────────────────────
  /// String — USD price for the Early Supporter lifetime purchase.
  /// Store a positive number (e.g. `0.99`) in Remote Config.
  /// `0` or unset means no price label is shown in the Remove Ads dialog.
  static const String earlySupporterPrice = 'early_supporter_price';

  /// String — URL for the Buy Me a Coffee page.
  static const String buyMeACoffeeUrl = 'buy_me_a_coffee_url';

  // ── Changelog ───────────────────────────────────────────────────────────
  /// String — full markdown content of the changelog (English).
  /// Empty string (default) means use the bundled `assets/docs/en/CHANGELOG_en.md`.
  static const String changelogEn = 'changelog_en';

  /// String — full markdown content of the changelog (German).
  /// Empty string (default) means fall back to [changelogEn] or bundled asset.
  static const String changelogDe = 'changelog_de';

  /// String — full markdown content of the changelog (Spanish).
  /// Empty string (default) means fall back to [changelogEn] or bundled asset.
  static const String changelogEs = 'changelog_es';

  /// String — full markdown content of the changelog (French).
  /// Empty string (default) means fall back to [changelogEn] or bundled asset.
  static const String changelogFr = 'changelog_fr';

  // ── Community ──────────────────────────────────────────────────────────────
  /// Boolean — when `false` nobody can upload images to community posts.
  /// Defaults to `true`. Set to `false` in Firebase Remote Config to disable
  /// image uploads globally without shipping an app update.
  static const String communityImageUpload = 'community_image_upload';

  // ── Per-tool free-tier toggles ─────────────────────────────────────────────
  /// Boolean — when `false` the AI Fish Compatibility tool is disabled for
  /// free-tier (developer Groq key) users.  Defaults to `true`.
  static const String freeFishCompatEnabled = 'free_fish_compat_enabled';

  /// Boolean — when `false` the Photo Analysis tool is disabled for
  /// free-tier (developer Groq key) users.  Defaults to `true`.
  static const String freePhotoAnalysisEnabled = 'free_photo_analysis_enabled';

  // ── Ads ───────────────────────────────────────────────────────────────────
  /// Integer — minimum hours between interstitial ad impressions for
  /// free-tier users.  Defaults to [rcDefaultInterstitialCooldownHours] (6).
  static const String interstitialCooldownHours =
      'admob_interstitial_cooldown_hours';

  // ── Feature visibility ─────────────────────────────────────────────────────
  /// Boolean — when `true` the Facebook Login button is hidden on the auth
  /// screen.  Defaults to `false` (button is shown).  Set to `true` in
  /// Firebase Remote Config to temporarily hide Facebook Login without
  /// shipping an app update (e.g. while the Facebook App is under review).
  static const String hideFacebookLogin = 'hide_facebook_login';

  // ── Founder Aquarist AI limits ──────────────────────────────────────────────
  /// Integer — per-minute request cap for Founder Aquarist users.
  static const String founderMaxRequestsPerMinute =
      'founder_max_requests_per_minute';

  /// Integer — per-day request cap for Founder Aquarist users.
  static const String founderMaxRequestsPerDay = 'founder_max_requests_per_day';

  /// Integer — per-day photo-analysis cap for Founder Aquarist users.
  static const String founderMaxPhotoAnalysesPerDay =
      'founder_max_photo_analyses_per_day';

  /// Integer — chat-history window for Founder Aquarist users.
  static const String founderChatHistoryLimit = 'founder_chat_history_limit';
}
