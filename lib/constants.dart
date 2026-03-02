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
