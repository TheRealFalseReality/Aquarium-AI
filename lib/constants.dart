// Developer Groq API key – injected at build time via:
//   flutter build ... --dart-define=DEVELOPER_GROQ_API_KEY=<your-key>
// Used as a free fallback when the user has not provided their own Groq key.
// Leave empty to disable the fallback (users must supply their own key).
const String developerGroqApiKey =
    String.fromEnvironment('DEVELOPER_GROQ_API_KEY', defaultValue: '');

// Default model constants
const String geminiModelDefault = 'gemini-flash-latest';
const String geminiImageModelDefault = 'gemini-flash-latest';
const String openAIModelDefault = 'gpt-4o';
const String openAIImageModelDefault = 'gpt-4-vision-preview';
const String groqModelDefault = 'llama-3.1-8b-instant';
const String groqImageModelDefault = 'meta-llama/llama-4-scout-17b-16e-instruct';


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
