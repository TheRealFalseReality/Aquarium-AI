// ============================================================
// Developer free-tier in-app rate limits
// ============================================================
// These limits apply ONLY when the app is using the built-in
// developer Groq API key (i.e. the user has NOT provided their
// own Groq key). Users who supply their own key are unaffected.
//
// Edit the values below to adjust limits:
// ============================================================

/// Maximum number of AI requests allowed per minute when using
/// the developer key. Prevents the shared key from being
/// rate-limited by Groq's free tier.
const int devMaxRequestsPerMinute = 4;

/// Maximum number of AI requests allowed per day per device
/// when using the developer key.
const int devMaxRequestsPerDay = 50;

/// Maximum number of photo analyses allowed per day per device
/// when using the developer key.
const int devMaxPhotoAnalysesPerDay = 3;
