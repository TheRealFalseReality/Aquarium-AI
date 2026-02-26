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

/// AdSense Display ad unit ID for web (banner placements).
const String adSenseDisplayAdUnitId = '1170950438';

/// AdSense Multiplex ad unit ID for web (native/in-feed placements).
const String adSenseMultiplexAdUnitId = '1989208084';

// In-app purchase product IDs
const String earlySupporterLifetimeProductId = 'remove_ads_early_supporter_lifetime';
const String buyMeACoffeeProductId = 'buy_me_a_coffee';
